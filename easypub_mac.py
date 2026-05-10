#!/usr/bin/env python3
"""EasyPubMac backend — TXT → EPUB converter with custom CSS support."""
import argparse
import html
import json
import os
import shutil
import re
import tempfile
import uuid
import zipfile
from dataclasses import dataclass, field
from datetime import datetime, timezone
from pathlib import Path
from typing import List

CHAPTER_PATTERNS = [
    re.compile(r"^\s*[第卷][0-9一二三四五六七八九十零〇百千两]*[章回节集卷].*"),
    re.compile(r"^\s*Chapter\s*[0-9]+.*", re.IGNORECASE),
    re.compile(r"^\s*(简介|序言|序[1-9]|序曲|后记|尾声|前言|自序|附录)\s*$"),
]
ENCODINGS = ["utf-8", "utf-16", "gb18030", "big5"]
COVER_MEDIA_TYPES = {
    ".jpg": "image/jpeg", ".jpeg": "image/jpeg", ".png": "image/png",
    ".gif": "image/gif", ".webp": "image/webp", ".svg": "image/svg+xml",
}
MAX_ANALYZE_CHAPTERS = 800
MAX_EXCERPT_CHARS = 600

DEFAULT_CSS = """/* EasyPubMac — 现代艺术排版 */
@charset "UTF-8";

body {
  font-family: "PingFang SC", "Hiragino Sans GB", "Noto Serif CJK SC",
               "Songti SC", Georgia, "Times New Roman", serif;
  line-height: 1.9;
  margin: 5% 7%;
  color: #2c2c2c;
  text-align: justify;
  font-size: 1em;
  word-spacing: 0.05em;
  -webkit-font-smoothing: antialiased;
}

/* ── 封面 ── */
.cover {
  display: flex;
  min-height: 95vh;
  flex-direction: column;
  justify-content: center;
  align-items: center;
  text-align: center;
  page-break-after: always;
}
.cover-title {
  font-size: 2.4em;
  font-weight: bold;
  margin-bottom: 0.5em;
  color: #1a1a1a;
  letter-spacing: 0.12em;
}
.cover-author {
  font-size: 1.2em;
  color: #888;
  letter-spacing: 0.06em;
}
.cover-image {
  display: block; max-width: 100%; max-height: 95vh;
  margin: 0 auto; object-fit: contain;
}

/* ── 卷 / 章标题 ── */
h1, h2 {
  text-align: center;
  margin: 2.2em 0 1.2em;
  font-weight: bold;
  color: #1a1a1a;
  letter-spacing: 0.1em;
}
h1 { font-size: 1.6em; }
h2 { font-size: 1.4em; }

/* ── 正文段落 ── */
p {
  margin: 0.3em 0;
  text-indent: 2em;
  line-height: 1.9;
}
"""


@dataclass
class LayoutOptions:
    font_size: int = 100
    line_height: int = 130
    indent: int = 2
    remove_blank_lines: bool = True
    justify_text: bool = True
    generate_cover: bool = True
    custom_css: str = ""
    font_path: str = ""


@dataclass
class Chapter:
    title: str
    paragraphs: List[str]


def read_text_with_fallbacks(path: Path) -> str:
    data = path.read_bytes()
    for encoding in ENCODINGS:
        try:
            return data.decode(encoding)
        except UnicodeDecodeError:
            continue
    raise ValueError("无法识别这个 TXT 文件的编码。")


def _is_chapter_heading(stripped: str, raw_lines: List[str], idx: int) -> bool:
    """综合上下文判断一行匹配到章节模式的文本是否真是章节标题。

    考察因素（按权重排序）：
    1. 长度 — 真正章节标题不会太长（＞60 字的几乎一定是正文）
    2. 强模式 — "第 X 章/回/节/集/卷"格式直接跳过标点检查
    3. 句末标点 — 非强模式标题不以 。！？，；：结尾
    4. 句中标点 — 非强模式标题中间不出现 。！？
    5. 空行上下文 — 前后有空行分隔的极大概率是标题
    6. 上文结尾 — 前一行以句末标点结尾说明上章结束
    7. 后缀检测 — 无上下文时强模式行还需检查后缀是否像标题
    """
    # ── 1. 基本格式检查 ──
    if len(stripped) > 60:
        return False
    if not stripped:
        return False

    # ── 2. 强模式检测：第X章/回/节/集/卷 ──
    # 网文标题常有"第X章【封神？】""第X章 封帝！"等带标点的装饰性写法，
    # 对这类强模式匹配的行跳过标点检查，直接依赖上下文判断。
    strong_match = re.match(r'^\s*第[0-9一二三四五六七八九十百千零〇]+[章回节集卷]\s*', stripped)
    is_strong = strong_match is not None
    suffix = stripped[strong_match.end():] if is_strong else ""

    if not is_strong:
        # ── 3. 句末标点检查（仅限非强模式）──
        if stripped[-1] in '。！？，；：…、':
            return False

        # ── 4. 句中标点检查（仅限非强模式）──
        for ch in stripped[:-1]:
            if ch in '。！？':
                return False

    # ── 5. 上下文分析 ──
    prev_line = raw_lines[idx - 1].strip() if idx > 0 else ""
    next_line = raw_lines[idx + 1].strip() if idx < len(raw_lines) - 1 else ""
    prev_blank = (prev_line == "")
    next_blank = (next_line == "")

    # 正文特征检测：后缀以正文常用字开头（标题通常不会以这些字开头）
    BODY_TEXT_STARTERS = '的里在被就把很正'
    def suffix_is_body_text(s: str) -> bool:
        return bool(s and s[0] in BODY_TEXT_STARTERS)

    # 前后都有空行 → 强信号，一定是章节标题
    if prev_blank and next_blank:
        return True
    # 前有空行 → 检查后缀防止正文冒充
    if prev_blank:
        if is_strong and suffix and suffix_is_body_text(suffix):
            pass  # 后缀以正文字开头，交给 step 6 二次裁决
        else:
            return True
    # 前一行以句末标点结尾 → 上章正文结束，当前行是新章
    if prev_line and prev_line[-1] in '。！？”"':
        return True

    # ── 6. 无上下文信号或上下文不足：嵌入正文段落 ──
    if is_strong:
        if not suffix:
            return True
        if suffix[0] in '：:【】《》『』':
            return True
        # 后缀以正文特征字开头（被和在可能是合法标题如"被没收的书""在路上"）
        if suffix[0] in '的里就把很正':
            return False
        if len(suffix) <= 8:
            return True
        if len(suffix) <= 20:
            return True

    return False


def parse_chapters(text: str, title: str, options: LayoutOptions) -> List[Chapter]:
    text = text.replace("\r\n", "\n").replace("\r", "\n")
    if not text.strip():
        raise ValueError("文件内容为空，无法生成 EPUB。")
    raw_lines = text.split("\n")
    chapters: List[Chapter] = []
    current_title = "开始"
    current_paragraphs: List[str] = []
    for idx, raw_line in enumerate(raw_lines):
        line = raw_line.strip()
        if not line:
            if not options.remove_blank_lines and current_paragraphs:
                current_paragraphs.append("")
            continue
        if any(pattern.search(line) for pattern in CHAPTER_PATTERNS):
            if _is_chapter_heading(line, raw_lines, idx):
                if current_paragraphs:
                    chapters.append(Chapter(current_title, current_paragraphs))
                current_title = line
                current_paragraphs = []
                continue
        current_paragraphs.append(line)
    if current_paragraphs:
        chapters.append(Chapter(current_title, current_paragraphs))
    if not chapters:
        chapters = [Chapter(title or "正文", [line.strip() for line in raw_lines if line.strip()])]
    return chapters


def container_xml() -> str:
    return '''<?xml version="1.0" encoding="UTF-8"?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
  <rootfiles>
    <rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/>
  </rootfiles>
</container>
'''


def stylesheet(options: LayoutOptions) -> str:
    css = DEFAULT_CSS

    # If a custom TTF/OTF font is specified, add @font-face
    font_face_block = ""
    if options.font_path:
        fp = Path(options.font_path)
        if fp.exists() and fp.suffix.lower() in ('.ttf', '.otf'):
            fmt = "truetype" if fp.suffix.lower() == '.ttf' else "opentype"
            font_name = fp.stem
            font_face_block = f"""@font-face {{
  font-family: "CustomFont";
  src: url("../Fonts/{fp.name}") format("{fmt}");
}}

"""
            css = font_face_block + css
            css += f"""
body {{
  font-family: "CustomFont", "PingFang SC", "Hiragino Sans GB", serif;
}}
"""

    css += f"""
body {{
  line-height: {options.line_height / 100:.2f};
  font-size: {options.font_size / 100:.2f}em;
  text-align: {"justify" if options.justify_text else "left"};
}}
p {{
  text-indent: {max(options.indent, 0)}em;
}}
"""
    if options.custom_css:
        css += "\n/* ── Custom CSS ── */\n" + options.custom_css
    return css


def cover_page(title: str, author: str, language: str) -> str:
    return f'''<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml" lang="{html.escape(language)}">
<head><title>封面</title><link rel="stylesheet" type="text/css" href="../Styles/book.css"/></head>
<body><section class="cover" id="cover">
  <div class="cover-title">{html.escape(title)}</div>
  <div class="cover-author">{html.escape(author)}</div>
</section></body></html>
'''


def image_cover_page(title: str, language: str, image_href: str) -> str:
    return f'''<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml" lang="{html.escape(language)}">
<head><title>封面</title><link rel="stylesheet" type="text/css" href="../Styles/book.css"/></head>
<body><section class="cover" id="cover">
  <img class="cover-image" src="{html.escape(image_href)}" alt="{html.escape(title)}"/>
</section></body></html>
'''


def chapter_page(chapter: Chapter, language: str, anchor_id: str) -> str:
    paragraphs = "\n".join(f"<p>{html.escape(p)}</p>" for p in chapter.paragraphs)
    return f'''<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml" lang="{html.escape(language)}">
<head><title>{html.escape(chapter.title)}</title><link rel="stylesheet" type="text/css" href="../Styles/book.css"/></head>
<body id="{html.escape(anchor_id)}"><h2>{html.escape(chapter.title)}</h2>
{paragraphs}</body></html>
'''


def nav_page(title: str, nav_items: List[str]) -> str:
    return f'''<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops">
<head><title>目录</title></head>
<body><nav epub:type="toc" id="toc"><h1>{html.escape(title)}</h1><ol>
{"".join(nav_items)}</ol></nav></body></html>
'''


def toc_ncx(title: str, book_id: str, nav: List[str]) -> str:
    points = []
    for idx, item in enumerate(nav, start=1):
        m = re.search(r'href="([^"]*)"[^>]*>([^<]*)', item)
        if m:
            href = html.escape(m.group(1), quote=True)
            text = html.escape(m.group(2))
            points.append(f'''    <navPoint id="navpoint-{idx}" playOrder="{idx}">
      <navLabel><text>{text}</text></navLabel>
      <content src="{href}"/>
    </navPoint>''')
    return f'''<?xml version="1.0" encoding="UTF-8"?>
<ncx xmlns="http://www.daisy.org/z3986/2005/ncx/" version="2005-1">
  <head>
    <meta name="dtb:uid" content="{html.escape(book_id)}"/>
    <meta name="dtb:depth" content="1"/>
    <meta name="dtb:totalPageCount" content="0"/>
    <meta name="dtb:maxPageNumber" content="0"/>
  </head>
  <docTitle><text>{html.escape(title)}</text></docTitle>
  <navMap>
{"".join(points)}
  </navMap>
</ncx>
'''


def opf(title, author, language, book_id, modified, manifest, spine, cover_image_id="", toc_id=""):
    cover_meta = f'\n    <meta name="cover" content="{html.escape(cover_image_id)}"/>' if cover_image_id else ""
    spine_attr = f' toc="{html.escape(toc_id)}"' if toc_id else ""
    return f'''<?xml version="1.0" encoding="UTF-8"?>
<package version="3.0" xmlns="http://www.idpf.org/2007/opf" unique-identifier="bookid">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:identifier id="bookid">{html.escape(book_id)}</dc:identifier>
    <dc:title>{html.escape(title)}</dc:title>
    <dc:creator>{html.escape(author)}</dc:creator>
    <dc:language>{html.escape(language)}</dc:language>
    <meta property="dcterms:modified">{modified}</meta>{cover_meta}
  </metadata>
  <manifest>
    {"".join(manifest)}
  </manifest>
  <spine{spine_attr}>
    {"".join(spine)}
  </spine>
</package>
'''


def cover_media_type(path: Path) -> str:
    suffix = path.suffix.lower()
    if suffix not in COVER_MEDIA_TYPES:
        raise ValueError("封面图片仅支持 JPG、PNG、GIF、WebP 或 SVG。")
    if not path.exists():
        raise ValueError("找不到所选封面图片。")
    return COVER_MEDIA_TYPES[suffix]


FONT_MEDIA_TYPES = {
    ".ttf": "application/x-font-truetype",
    ".otf": "application/x-font-opentype",
}

def build_epub(chapters: List[Chapter], output_path: Path, options: LayoutOptions, title: str, author: str, language: str, cover_image_path: Path = None) -> None:
    book_id = f"urn:uuid:{uuid.uuid4()}"
    modified = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

    with tempfile.TemporaryDirectory(prefix="easypub-mac-") as temp_dir:
        root = Path(temp_dir)
        (root / "META-INF").mkdir(parents=True)
        oebps = root / "OEBPS"
        text_dir = oebps / "Text"
        styles_dir = oebps / "Styles"
        images_dir = oebps / "Images"
        fonts_dir = oebps / "Fonts"
        text_dir.mkdir(parents=True)
        styles_dir.mkdir(parents=True)

        (root / "mimetype").write_text("application/epub+zip", encoding="utf-8")
        (root / "META-INF" / "container.xml").write_text(container_xml(), encoding="utf-8")
        (styles_dir / "book.css").write_text(stylesheet(options), encoding="utf-8")

        manifest = [
            '<item id="css" href="Styles/book.css" media-type="text/css"/>',
            '<item id="nav" href="nav.xhtml" media-type="application/xhtml+xml" properties="nav"/>',
        ]

        # Embed custom font if specified
        if options.font_path:
            fp = Path(options.font_path)
            if fp.exists() and fp.suffix.lower() in FONT_MEDIA_TYPES:
                fonts_dir.mkdir(exist_ok=True)
                shutil.copy2(fp, fonts_dir / fp.name)
                mt = FONT_MEDIA_TYPES[fp.suffix.lower()]
                manifest.append(f'<item id="font-{fp.stem}" href="Fonts/{fp.name}" media-type="{mt}"/>')
        spine: List[str] = []
        nav: List[str] = []
        cover_image_id = ""

        if options.generate_cover:
            if cover_image_path:
                cover_path = Path(cover_image_path)
                media_type = cover_media_type(cover_path)
                images_dir.mkdir(parents=True, exist_ok=True)
                cover_file = f"cover{cover_path.suffix.lower()}"
                shutil.copyfile(cover_path, images_dir / cover_file)
                (text_dir / "cover.xhtml").write_text(image_cover_page(title, language, f"../Images/{cover_file}"), encoding="utf-8")
                cover_image_id = "cover-image"
                manifest.append(f'<item id="{cover_image_id}" href="Images/{cover_file}" media-type="{media_type}" properties="cover-image"/>')
            else:
                (text_dir / "cover.xhtml").write_text(cover_page(title, author, language), encoding="utf-8")
            manifest.append('<item id="cover" href="Text/cover.xhtml" media-type="application/xhtml+xml"/>')
            spine.append('<itemref idref="cover"/>')
            nav.append('<li><a href="Text/cover.xhtml#cover">封面</a></li>')

        spine.append('<itemref idref="nav" linear="no"/>')

        for index, chapter in enumerate(chapters, start=1):
            fn = f"chapter{index}.xhtml"
            anchor_id = f"chapter-{index}"
            (text_dir / fn).write_text(chapter_page(chapter, language, anchor_id), encoding="utf-8")
            manifest.append(f'<item id="chapter{index}" href="Text/{fn}" media-type="application/xhtml+xml"/>')
            spine.append(f'<itemref idref="chapter{index}"/>')
            nav.append(f'<li><a href="Text/{fn}#{anchor_id}">{html.escape(chapter.title)}</a></li>')

        (oebps / "nav.xhtml").write_text(nav_page(title, nav), encoding="utf-8")
        manifest.append('<item id="ncx" href="toc.ncx" media-type="application/x-dtbncx+xml"/>')
        (oebps / "toc.ncx").write_text(toc_ncx(title, book_id, nav), encoding="utf-8")
        (oebps / "content.opf").write_text(opf(title, author, language, book_id, modified, manifest, spine, cover_image_id, toc_id="ncx"), encoding="utf-8")

        if output_path.exists():
            output_path.unlink()

        with zipfile.ZipFile(output_path, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=1) as archive:
            archive.writestr("mimetype", "application/epub+zip", compress_type=zipfile.ZIP_STORED)
            for path in sorted(root.rglob("*")):
                if path.name == "mimetype" or path.is_dir():
                    continue
                archive.write(path, path.relative_to(root).as_posix())


def analyze_file(input_path: Path, title: str, options: LayoutOptions) -> dict:
    text = read_text_with_fallbacks(input_path)
    chapters = parse_chapters(text, title or input_path.stem, options)
    word_count = sum(len(p.replace(" ", "")) for c in chapters for p in c.paragraphs)
    visible = chapters[:MAX_ANALYZE_CHAPTERS]
    return {
        "file_name": input_path.name,
        "title": title or input_path.stem,
        "chapter_count": len(chapters),
        "word_count": word_count,
        "preview_limit": MAX_ANALYZE_CHAPTERS,
        "is_truncated": len(chapters) > MAX_ANALYZE_CHAPTERS,
        "chapters": [
            {
                "title": c.title,
                "preview": " ".join([p for p in c.paragraphs[:2] if p])[:120],
                "excerpt": ("\n\n".join(c.paragraphs[:10]).strip() or "这个章节目前没有可展示的正文。")[:MAX_EXCERPT_CHARS],
                "paragraph_count": sum(1 for p in c.paragraphs if p.strip()),
            }
            for c in visible
        ],
    }


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="EasyPub backend")
    subparsers = parser.add_subparsers(dest="command", required=True)

    for name in ("analyze", "export"):
        sub = subparsers.add_parser(name)
        sub.add_argument("--input", required=True)
        sub.add_argument("--title", default="")
        sub.add_argument("--author", default="佚名")
        sub.add_argument("--language", default="zh-CN")
        sub.add_argument("--font-size", type=int, default=100)
        sub.add_argument("--line-height", type=int, default=130)
        sub.add_argument("--indent", type=int, default=2)
        sub.add_argument("--remove-blank-lines", action="store_true")
        sub.add_argument("--no-remove-blank-lines", action="store_true")
        sub.add_argument("--justify-text", action="store_true")
        sub.add_argument("--no-justify-text", action="store_true")
        sub.add_argument("--generate-cover", action="store_true")
        sub.add_argument("--no-generate-cover", action="store_true")
        sub.add_argument("--cover-image", default="")
        sub.add_argument("--custom-css", default="", help="自定义 CSS 样式内容（直接传入）")
        sub.add_argument("--font-path", default="", help="自定义 TTF/OTF 字体文件路径")
    export = subparsers.choices["export"]
    export.add_argument("--output", required=True)
    return parser.parse_args()


def options_from_args(args: argparse.Namespace) -> LayoutOptions:
    def _flag(name):
        on = getattr(args, name, False)
        no = getattr(args, f"no_{name}", False)
        if no: return False
        if on: return True
        return None

    remove_blank = _flag("remove_blank_lines")
    justify = _flag("justify_text")
    generate_cover = _flag("generate_cover")

    return LayoutOptions(
        font_size=args.font_size,
        line_height=args.line_height,
        indent=args.indent,
        remove_blank_lines=True if remove_blank is None else remove_blank,
        justify_text=True if justify is None else justify,
        generate_cover=True if generate_cover is None else generate_cover,
        custom_css=args.custom_css or "",
        font_path=args.font_path or "",
    )


def main() -> None:
    args = parse_args()
    input_path = Path(args.input)
    options = options_from_args(args)

    if args.command == "analyze":
        print(json.dumps(analyze_file(input_path, args.title, options), ensure_ascii=False))
        return

    chapters = parse_chapters(read_text_with_fallbacks(input_path), args.title or input_path.stem, options)
    cover_image_path = Path(args.cover_image) if args.cover_image else None
    build_epub(chapters, Path(args.output), options, args.title or input_path.stem, args.author, args.language, cover_image_path)
    print(Path(args.output))


if __name__ == "__main__":
    main()
