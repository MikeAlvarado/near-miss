#!/bin/sh
# Builds the App Store archive and the .ipa to upload. Nothing is uploaded here.
#   TEAM_ID=XXXXXXXXXX tools/archive.sh
# TEAM_ID is your Apple Developer team (Xcode > Settings > Accounts). It is not kept in the repo.
set -eu
: "${TEAM_ID:?Set TEAM_ID to your Apple Developer team id}"
cd "$(dirname "$0")/.."
xcodegen generate
rm -rf build/Casi.xcarchive build/export
xcodebuild -project NearMiss.xcodeproj -scheme NearMiss -configuration Release \
  -destination 'generic/platform=iOS' -archivePath build/Casi.xcarchive \
  DEVELOPMENT_TEAM="$TEAM_ID" -allowProvisioningUpdates archive
cat > build/ExportOptions.plist <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>method</key><string>app-store-connect</string>
	<key>destination</key><string>export</string>
	<key>teamID</key><string>$TEAM_ID</string>
	<key>signingStyle</key><string>automatic</string>
</dict>
</plist>
PLIST
xcodebuild -exportArchive -archivePath build/Casi.xcarchive -exportPath build/export \
  -exportOptionsPlist build/ExportOptions.plist -allowProvisioningUpdates
echo "Ready: build/export/NearMiss.ipa"
