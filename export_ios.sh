#!/bin/bash
# 在 macOS 上导出 iOS 包。
# 前置：Godot 4.7 + 导出模板 + Xcode + Apple 开发者证书。
# 用法：./export_ios.sh [TEAM_ID]
set -e
TEAM_ID="${1:-}"
PROJ="$(cd "$(dirname "$0")" && pwd)"
GODOT="${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}"

if [ -n "$TEAM_ID" ]; then
  /usr/bin/sed -i '' "s|application/app_store_team_id=\"[^\"]*\"|application/app_store_team_id=\"$TEAM_ID\"|" "$PROJ/export_presets.cfg"
  echo "Team ID -> $TEAM_ID"
fi

mkdir -p "$PROJ/build/ios"
"$GODOT" --headless --path "$PROJ" --export-release "iOS" "$PROJ/build/ios/PingPongLife.ipa"
echo "完成：$PROJ/build/ios/PingPongLife.ipa"
