#!/bin/sh

# This script is used to generate the control file for the Debian package.
if [ $# -ne 1 ]; then
    echo "Usage: $0 <version>"
    exit 1
fi

VERSION=$1

# Strip leading "v" from version if present
VERSION=${VERSION#v}

# Create the layout directory
mkdir -p layout/DEBIAN

# Write the control file
cat > layout/DEBIAN/control << __EOF__
Package: a0.sapphire.external.jb
Name: Sapphire JB
Version: $VERSION
Section: Tweaks
Depends: firmware (>= 14.0)
Architecture: iphoneos-arm
Author: AlexZero
Maintainer: AlexZero
Description: 8 Ball Pool External Drawning Aim Assist
__EOF__

# Set permissions
chmod 0644 layout/DEBIAN/control

RAND_BUILD_STR=$(openssl rand -hex 4)

# Write the Info.plist file
defaults write $PWD/Resources/Info.plist CFBundleShortVersionString $VERSION
defaults write $PWD/Resources/Info.plist CFBundleVersion $RAND_BUILD_STR
plutil -convert xml1 $PWD/Resources/Info.plist
chmod 0644 $PWD/Resources/Info.plist

XCODE_PROJ_PBXPROJ=$PWD/Sapphire.xcodeproj/project.pbxproj
sed -i '' "s/MARKETING_VERSION = .*;/MARKETING_VERSION = $VERSION;/g" $XCODE_PROJ_PBXPROJ