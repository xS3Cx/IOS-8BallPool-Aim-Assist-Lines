#!/bin/sh

# This script is used to build the Sapphire app and create a tipa file with Xcode.
if [ $# -ne 1 ]; then
    echo "Usage: $0 <version>"
    exit 1
fi

VERSION=$1

# Strip leading "v" from version if present
VERSION=${VERSION#v}

# Build using Xcode
xcodebuild clean build archive \
-scheme Sapphire \
-project Sapphire.xcodeproj \
-sdk iphoneos \
-destination 'generic/platform=iOS' \
-archivePath Sapphire \
CODE_SIGNING_ALLOWED=NO | xcpretty

chmod 0644 Resources/Info.plist
cp supports/entitlements.plist Sapphire.xcarchive/Products
cd Sapphire.xcarchive/Products/Applications
codesign --remove-signature Sapphire.app
cd -
cd Sapphire.xcarchive/Products
mv Applications Payload
ldid -Sentitlements.plist Payload/Sapphire.app
chmod 0644 Payload/Sapphire.app/Info.plist
zip -qr Sapphire.tipa Payload
cd -
mkdir -p packages
mv Sapphire.xcarchive/Products/Sapphire.tipa packages/Sapphire+AppIntents16_$VERSION.tipa
