VERSION               := 1.0.0

ARCHS                 := arm64
TARGET                := iphone:clang:16.5:14.0

APPLICATION_NAME      := Sapphire
INSTALL_TARGET_PROCESSES := Sapphire

# Project paths
THEOS_PROJECT_DIR     := $(shell pwd)
ENT_PLIST             := $(THEOS_PROJECT_DIR)/supports/entitlements.plist
LAUNCHD_PLIST_PATH    := $(THEOS_PROJECT_DIR)/layout/Library/LaunchDaemons/a0.sapphire.external.plist

PLUTIL              ?= $(THEOS)/toolchain/linux/host/bin/plutil


define LAUNCHD_PLIST_CONTENT
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>a0.sapphire.external.hudservices</string>
    <key>ProgramArguments</key>
    <array>
        <string>$(THEOS_PACKAGE_INSTALL_PREFIX)/Applications/Sapphire.app/Sapphire</string>
        <string>-hud</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
</dict>
</plist>
endef
export LAUNCHD_PLIST_CONTENT


include $(THEOS)/makefiles/common.mk

Sapphire_USE_MODULES  := 0


Sapphire_FILES        := $(wildcard sources/*.m sources/*.mm)
# Sapphire_FILES       += $(wildcard sources/*.swift)
Sapphire_FILES       += $(wildcard sources/KIF/*.m sources/KIF/*.mm)
Sapphire_FILES       += $(wildcard sources/AimAssist/*.m sources/AimAssist/*.mm)

# Sapphire_FILES       += $(wildcard sources/SPLarkController/*.swift)
# Sapphire_FILES       += $(wildcard sources/SnapshotSafeView/*.swift)

ifeq ($(THEOS_PACKAGE_SCHEME),roothide)
    Sapphire_FILES   += libroot/dyn.c
    Sapphire_LIBRARIES += roothide
endif


Sapphire_CFLAGS       := \
    -fobjc-arc \
    -Iheaders \
    -Isources \
    -Isources/KIF \
    -Isources/AimAssist \
    -include supports/hudapp-prefix.pch

MainApplication.mm_CCFLAGS += -std=c++14

# Sapphire_SWIFT_BRIDGING_HEADER := supports/hudapp-bridging-header.h
# Sapphire_SWIFT_BRIDGING_HEADER := supports/hudapp-bridging-header.h
Sapphire_LDFLAGS      := -Flibraries -lobjc -lSystem

Sapphire_FRAMEWORKS   := CoreGraphics CoreServices QuartzCore IOKit UIKit WebKit UIKit Foundation CoreFoundation AVFoundation
Sapphire_PRIVATE_FRAMEWORKS := BackBoardServices GraphicsServices SpringBoardServices

Sapphire_CODESIGN_FLAGS := -S$(ENT_PLIST)



include $(THEOS_MAKE_PATH)/application.mk


include $(THEOS_MAKE_PATH)/aggregate.mk


before-all::
	@echo "Generating LaunchDaemon Plist..."
	$(ECHO_NOTHING) echo "$$LAUNCHD_PLIST_CONTENT" > $(LAUNCHD_PLIST_PATH) $(ECHO_END)

# Staging / packaging paths
STAGING_PAYLOAD_DIR     := $(THEOS_STAGING_DIR)/Payload
STAGING_APP_PATH        := $(STAGING_PAYLOAD_DIR)/Sapphire.app
FINAL_TIPA_PATH         := packages/Sapphire_$(VERSION).tipa

after-package::
	@echo "Creating .tipa package for TrollStore..."

	# Ensure directories exist and copy app bundle
	$(ECHO_NOTHING) mkdir -p packages "$(STAGING_PAYLOAD_DIR)" $(ECHO_END)
	$(ECHO_NOTHING) cp -R "$(THEOS_STAGING_DIR)$(THEOS_PACKAGE_INSTALL_PREFIX)/Applications/$(APPLICATION_NAME).app" "$(STAGING_PAYLOAD_DIR)" $(ECHO_END)

	# Update Info.plist
	# Remove CFBundleIconName entry (two-line key/value) if present
	$(ECHO_NOTHING) sed -i '/<key>CFBundleIconName<\/key>/{N;d;}' $(STAGING_APP_PATH)/Info.plist $(ECHO_END)
	# Update CFBundleVersion value (replace the following <string> line)
	$(ECHO_NOTHING) sed -i "/<key>CFBundleVersion<\/key>/{n;s/<string>.*<\/string>/<string>$(VERSION)<\/string>/;}" $(STAGING_APP_PATH)/Info.plist $(ECHO_END)

	# Create .tipa archive
	$(ECHO_NOTHING) (cd $(THEOS_STAGING_DIR) && zip -qr $(abspath $(FINAL_TIPA_PATH)) Payload) $(ECHO_END)

