#!/bin/zsh
# Build script - updated for actual available devices

echo "=== Building Inches to Millimeters iOS App ==="

cd "$(dirname "$0")"

SCHEME="inch to millimeter conversion"
PROJECT="inch to millimeter conversion.xcodeproj"

echo "Project: $PROJECT"
echo "Scheme: $SCHEME"

# Use one of the available iOS simulators from xcrun simctl
# Available ones include: iPhone 16e, iPhone 17, iPhone 17 Pro, iPhone Air, various iPads

xcodebuild \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -destination 'platform=iOS Simulator,name=iPhone 16e' \
  -configuration Debug \
  build

echo ""
echo "=== If this fails on device name, try changing to another from the list like 'iPhone 17' ==="
echo "Then in Xcode: select the same destination in the toolbar and press ⌘R"
