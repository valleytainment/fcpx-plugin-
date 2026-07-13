#!/usr/bin/env bash
# Builds the FCP AI Operator host app + workflow extension without full Xcode.
# Links against Apple's ProExtension frameworks shipped inside Final Cut Pro.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD="$ROOT/.build/plugin"
DIST="$ROOT/dist"
FCP_APP="${FCP_APP:-/Applications/Final Cut Pro 2.app}"
FCP_FW="$FCP_APP/Contents/Frameworks"
LOCAL_FW="$ROOT/build/local-frameworks"
HOST_ID="com.valleytainment.fcpai.host"
EXT_ID="com.valleytainment.fcpai.workflow"
PRO_EXT_UUID="${PRO_EXT_UUID:-7C4E9A12-3B5D-4F8E-9A1C-2D6E8F0A4B7C}"
SIGN_ID="${SIGN_ID:--}"

if [[ ! -d "$FCP_FW/ProExtensionHost.framework" ]]; then
  echo "Final Cut Pro frameworks not found at: $FCP_FW" >&2
  echo "Set FCP_APP to your Final Cut Pro .app path and retry." >&2
  exit 1
fi

mkdir -p "$LOCAL_FW/ProExtensionHost.framework/Headers" "$LOCAL_FW/ProExtensionHost.framework/Modules"
mkdir -p "$LOCAL_FW/ProExtension.framework/Headers" "$LOCAL_FW/ProExtension.framework/Modules"
cp "$ROOT/build/shims/ProExtensionHost/"*.h "$LOCAL_FW/ProExtensionHost.framework/Headers/"
cp "$ROOT/build/shims/ProExtensionHost/module.modulemap" "$LOCAL_FW/ProExtensionHost.framework/Modules/"
cp "$ROOT/build/shims/ProExtension/ProExtension.h" "$LOCAL_FW/ProExtension.framework/Headers/"
cp "$ROOT/build/shims/ProExtension/module.modulemap" "$LOCAL_FW/ProExtension.framework/Modules/"
ln -sf "$FCP_FW/ProExtensionHost.framework/ProExtensionHost" "$LOCAL_FW/ProExtensionHost.framework/ProExtensionHost"
ln -sf "$FCP_FW/ProExtension.framework/ProExtension" "$LOCAL_FW/ProExtension.framework/ProExtension"

mkdir -p "$BUILD" "$DIST/FCPAIHost.app/Contents/MacOS" \
  "$DIST/FCPAIHost.app/Contents/PlugIns/FCPWorkflowExtension.appex/Contents/MacOS" \
  "$DIST/FCPAIHost.app/Contents/Resources"

echo "==> Compiling FCPAIKit"
xcrun swiftc -emit-module -emit-library \
  "$ROOT/Sources/FCPAIKit/"*.swift \
  -module-name FCPAIKit \
  -o "$BUILD/libFCPAIKit.dylib" \
  -emit-module-path "$BUILD/FCPAIKit.swiftmodule"

SWIFT_COMMON=(
  -I "$BUILD"
  -L "$BUILD" -lFCPAIKit
  -F "$LOCAL_FW"
  -F "$FCP_FW"
)

echo "==> Compiling workflow extension"
xcrun swiftc -parse-as-library \
  "$ROOT/macOS/FCPWorkflowExtension/"*.swift \
  "${SWIFT_COMMON[@]}" \
  -framework Cocoa -framework SwiftUI -framework CoreMedia \
  -framework ProExtensionHost -framework ProExtension \
  -Xlinker -rpath -Xlinker "@executable_path/../../../../Frameworks" \
  -Xlinker -e -Xlinker _ProExtensionMain \
  -o "$DIST/FCPAIHost.app/Contents/PlugIns/FCPWorkflowExtension.appex/Contents/MacOS/FCPWorkflowExtension"

echo "==> Compiling host app"
xcrun swiftc -parse-as-library \
  "$ROOT/macOS/FCPAIHost/"*.swift \
  "${SWIFT_COMMON[@]}" \
  -framework SwiftUI -framework AppKit \
  -Xlinker -rpath -Xlinker "@executable_path/../Frameworks" \
  -o "$DIST/FCPAIHost.app/Contents/MacOS/FCPAIHost"

install_name_tool -change libFCPAIKit.dylib @executable_path/../Frameworks/libFCPAIKit.dylib \
  "$DIST/FCPAIHost.app/Contents/MacOS/FCPAIHost" 2>/dev/null || true
install_name_tool -change libFCPAIKit.dylib @executable_path/../../../../Frameworks/libFCPAIKit.dylib \
  "$DIST/FCPAIHost.app/Contents/PlugIns/FCPWorkflowExtension.appex/Contents/MacOS/FCPWorkflowExtension" 2>/dev/null || true

mkdir -p "$DIST/FCPAIHost.app/Contents/Frameworks"
cp "$BUILD/libFCPAIKit.dylib" "$DIST/FCPAIHost.app/Contents/Frameworks/"

cat > "$DIST/FCPAIHost.app/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key><string>en</string>
  <key>CFBundleExecutable</key><string>FCPAIHost</string>
  <key>CFBundleIdentifier</key><string>$HOST_ID</string>
  <key>CFBundleInfoDictionaryVersion</key><string>6.0</string>
  <key>CFBundleName</key><string>Valleytainment FCP AI</string>
  <key>CFBundleDisplayName</key><string>Valleytainment FCP AI</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>0.1.0</string>
  <key>CFBundleVersion</key><string>1</string>
  <key>LSMinimumSystemVersion</key><string>12.0</string>
  <key>NSAppleEventsUsageDescription</key>
  <string>Valleytainment FCP AI uses approved automation to execute editing commands you authorize in Final Cut Pro.</string>
  <key>NSHighResolutionCapable</key><true/>
</dict>
</plist>
PLIST

cat > "$DIST/FCPAIHost.app/Contents/PlugIns/FCPWorkflowExtension.appex/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key><string>en</string>
  <key>CFBundleExecutable</key><string>FCPWorkflowExtension</string>
  <key>CFBundleIdentifier</key><string>$EXT_ID</string>
  <key>CFBundleInfoDictionaryVersion</key><string>6.0</string>
  <key>CFBundleName</key><string>FCP AI Operator</string>
  <key>CFBundleDisplayName</key><string>FCP AI Operator</string>
  <key>CFBundlePackageType</key><string>XPC!</string>
  <key>CFBundleShortVersionString</key><string>0.1.0</string>
  <key>CFBundleVersion</key><string>1</string>
  <key>LSMinimumSystemVersion</key><string>12.0</string>
  <key>ProExtensionUUID</key><string>$PRO_EXT_UUID</string>
  <key>NSAppleEventsUsageDescription</key>
  <string>FCP AI Operator uses approved automation to carry out editing commands in Final Cut Pro.</string>
  <key>NSExtension</key>
  <dict>
    <key>NSExtensionPointIdentifier</key>
    <string>com.apple.FinalCut.WorkflowExtension</string>
    <key>ProExtensionPrincipalViewControllerClass</key>
    <string>FCPWorkflowExtension.ExtensionViewController</string>
    <key>NSExtensionAttributes</key>
    <dict>
      <key>ProExtensionMinWidth</key><integer>420</integer>
      <key>ProExtensionMinHeight</key><integer>560</integer>
    </dict>
  </dict>
</dict>
</plist>
PLIST

cp "$ROOT/macOS/FCPAIHost/FCPAIHost.entitlements" "$DIST/FCPAIHost.app/Contents/Resources/FCPAIHost.entitlements"
cp "$ROOT/macOS/FCPWorkflowExtension/FCPWorkflowExtension.entitlements" \
  "$DIST/FCPAIHost.app/Contents/PlugIns/FCPWorkflowExtension.appex/Contents/Resources/FCPWorkflowExtension.entitlements" 2>/dev/null || \
  mkdir -p "$DIST/FCPAIHost.app/Contents/PlugIns/FCPWorkflowExtension.appex/Contents/Resources" && \
  cp "$ROOT/macOS/FCPWorkflowExtension/FCPWorkflowExtension.entitlements" \
  "$DIST/FCPAIHost.app/Contents/PlugIns/FCPWorkflowExtension.appex/Contents/Resources/FCPWorkflowExtension.entitlements"

echo "==> Ad-hoc signing"
/usr/bin/codesign --force --sign "$SIGN_ID" "$DIST/FCPAIHost.app/Contents/Frameworks/libFCPAIKit.dylib"
/usr/bin/codesign --force --sign "$SIGN_ID" --entitlements "$ROOT/macOS/FCPWorkflowExtension/FCPWorkflowExtension.entitlements" \
  "$DIST/FCPAIHost.app/Contents/PlugIns/FCPWorkflowExtension.appex"
/usr/bin/codesign --force --sign "$SIGN_ID" --entitlements "$ROOT/macOS/FCPAIHost/FCPAIHost.entitlements" \
  "$DIST/FCPAIHost.app"

echo
echo "Built: $DIST/FCPAIHost.app"
