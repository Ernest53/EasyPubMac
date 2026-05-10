#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="/tmp/easypub-build"
DESKTOP_DIR="$HOME/Desktop"
APP_NAME="EasyPubMac"

echo "=== 清理旧构建 ==="
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR/EasyPubMac.app/Contents/MacOS"
mkdir -p "$BUILD_DIR/EasyPubMac.app/Contents/Resources"

echo "=== 生成图标（从 PNG） ==="
ICON_SOURCE="$ROOT_DIR/easypub ai icon.png"
ICONSET_DIR="$BUILD_DIR/EasyPubMac.iconset"
mkdir -p "$ICONSET_DIR"
clang -fobjc-arc -framework Cocoa "$ROOT_DIR/IconMaker.m" -o "$BUILD_DIR/IconMaker"
"$BUILD_DIR/IconMaker" "$ICONSET_DIR" "$BUILD_DIR/EasyPubMac.icns" "$ICON_SOURCE"

echo "=== 编译主程序 ==="
clang -fobjc-arc -framework Cocoa -framework UniformTypeIdentifiers -framework QuartzCore "$ROOT_DIR/EasyPubMac.m" -o "$BUILD_DIR/EasyPubMac"

echo "=== 打包 .app ==="
cp "$ROOT_DIR/Info.plist" "$BUILD_DIR/EasyPubMac.app/Contents/Info.plist"
cp "$ROOT_DIR/easypub_mac.py" "$BUILD_DIR/EasyPubMac.app/Contents/Resources/easypub_mac.py"
cp "$ROOT_DIR/analysis.md" "$BUILD_DIR/EasyPubMac.app/Contents/Resources/analysis.md"
cp "$BUILD_DIR/EasyPubMac.icns" "$BUILD_DIR/EasyPubMac.app/Contents/Resources/EasyPubMac.icns"
cp "$BUILD_DIR/EasyPubMac" "$BUILD_DIR/EasyPubMac.app/Contents/MacOS/EasyPubMac"

echo "=== 签名 ==="
codesign --force --deep --sign - "$BUILD_DIR/EasyPubMac.app"

echo "=== 复制到桌面 ==="
rm -rf "$DESKTOP_DIR/$APP_NAME.app"
cp -R "$BUILD_DIR/EasyPubMac.app" "$DESKTOP_DIR/$APP_NAME.app"

echo "=== 解除 macOS 隔离（如果打不开则执行） ==="
xattr -dr com.apple.quarantine "$DESKTOP_DIR/$APP_NAME.app" 2>/dev/null || true

echo ""
echo "✅ 已构建到桌面：$DESKTOP_DIR/$APP_NAME.app"
echo "直接双击打开即可使用。如果还是打不开，运行："
echo "  xattr -dr com.apple.quarantine \"$DESKTOP_DIR/$APP_NAME.app\""
