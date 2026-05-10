# 原版 EasyPub 解析

## 软件类型

- `EasyPub.exe` 是一个 Windows `.NET 4.0 WinForms` 程序。
- 可执行文件中可以看到 `System.Windows.Forms`、`EasyPub.Properties.Settings`、`Ionic.Zip` 等符号。
- 目录里还包含 `config.xml`、`ereaders.xml`、`css`、`bin/kindlegen_v2.9.exe`，说明它不是单纯阅读器，而是电子书制作工具。

## 核心功能

- `TXT -> EPUB`
- `EPUB -> MOBI`
- 自动识别章节标题
- 生成目录、CSS、封面页
- 调整字号、行距、边距、缩进、空行处理
- 为不同阅读器准备字体路径配置

## 关键判断

- 原版 `MOBI` 输出依赖 `kindlegen.exe`，这是 Windows 可执行程序，不能直接原样用于 macOS。
- 现有目录里没有原项目源码，所以无法做“原样编译”的 mac 版。
- 最合理的做法是重建一个 macOS 版本，把最核心、最稳定的流程先做出来。

## 当前 macOS 版范围

- 已重建：`TXT -> EPUB`、章节识别、排版参数、文字封面、目录输出
- 暂未重建：`MOBI`、阅读器专用字体嵌入、复杂 EPUB 二次加工
