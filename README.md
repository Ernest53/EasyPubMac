# EasyPubMac

这是一个基于原版 `EasyPub.exe` 功能思路重建的 macOS 版本。

当前版本支持：

- 选择 `TXT` 文件
- 自动识别中文/英文常见章节标题
- 调整字号、行距、首行缩进、空白行处理和对齐方式
- 选择自定义图片作为书籍封面
- 未选择封面图时生成文字封面页
- 导出标准 `EPUB`

## 原版分析

详细分析见 [analysis.md](analysis.md)。

结论很明确：

- 原版是 Windows `.NET WinForms` 应用
- 目录内没有源码，无法直接编译成 macOS 版本
- `MOBI` 流程依赖 Windows 下的 `kindlegen.exe`

所以这里采用的是“按核心能力重建 macOS 版”的路线。

## 运行后端

```bash
python3 easypub_mac.py --help
```

## 打包为 `.app`

```bash
./build_app.sh
```

构建完成后会生成：

- `EasyPubMac.app`：当前工作区内的可运行应用
- `dist/EasyPubMac-0.1.0/EasyPubMac.app`：发布目录
- `dist/EasyPubMac-0.1.0.zip`：可分发压缩包

## 打包为 `.dmg`

```bash
./build_dmg.sh
```

构建完成后会生成：

- `dist/EasyPubMac-0.1.0.dmg`：可分发的 macOS 磁盘镜像
