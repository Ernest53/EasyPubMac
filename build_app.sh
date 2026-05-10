#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="/tmp/easypub-build"
APP_DIR="$ROOT_DIR/EasyPubMac.app"
DIST_DIR="$ROOT_DIR/dist"
RELEASE_DIR="$DIST_DIR/EasyPubMac-0.1.0"

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
rm -rf "$APP_DIR"
cp "$ROOT_DIR/Info.plist" "$BUILD_DIR/EasyPubMac.app/Contents/Info.plist"
cp "$ROOT_DIR/easypub_mac.py" "$BUILD_DIR/EasyPubMac.app/Contents/Resources/easypub_mac.py"
cp "$ROOT_DIR/analysis.md" "$BUILD_DIR/EasyPubMac.app/Contents/Resources/analysis.md"
cp "$BUILD_DIR/EasyPubMac.icns" "$BUILD_DIR/EasyPubMac.app/Contents/Resources/EasyPubMac.icns"
cp "$BUILD_DIR/EasyPubMac" "$BUILD_DIR/EasyPubMac.app/Contents/MacOS/EasyPubMac"

echo "=== 签名 ==="
codesign --force --deep --sign - "$BUILD_DIR/EasyPubMac.app"

echo "=== 复制到工作区 ==="
cp -R "$BUILD_DIR/EasyPubMac.app" "$APP_DIR"

echo "=== 创建发布包 ==="
rm -rf "$RELEASE_DIR" "$DIST_DIR/EasyPubMac-0.1.0.zip"
mkdir -p "$RELEASE_DIR"
cp -R "$APP_DIR" "$RELEASE_DIR/EasyPubMac.app"
cp "$ROOT_DIR/README.md" "$RELEASE_DIR/README.md" 2>/dev/null || true
ditto -c -k --norsrc --noextattr --noqtn --keepParent "$RELEASE_DIR" "$DIST_DIR/EasyPubMac-0.1.0.zip"

echo ""
echo "✅ 构建完成"
echo "  App: $APP_DIR"
echo "  发布: $RELEASE_DIR"
echo "  压缩包: $DIST_DIR/EasyPubMac-0.1.0.zip"
