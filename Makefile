SHELL := /bin/bash

.DEFAULT_GOAL := help

.PHONY: help doctor purge-image-cache generate build build-release run run-release clean app-path dmg

help:
	@echo "StoryJuicer commands:"
	@echo "  make doctor        Check local toolchain and SDK readiness"
	@echo "  make purge-image-cache  Remove local Diffusers runtime/model cache data"
	@echo "  make build         Generate project and build Debug app"
	@echo "  make run           Build and open Debug app"
	@echo "  make build-release Build Release app"
	@echo "  make run-release   Build and open Release app"
	@echo "  make dmg           Build, sign, notarize, and package a distributable DMG"
	@echo "  make clean         Clean Xcode build artifacts"
	@echo "  make app-path      Print built Debug .app bundle path"
	@echo ""
	@echo "Note: this is an Xcode project app target, so use make/xcodebuild (not swift run)."

doctor:
	./scripts/doctor.sh

purge-image-cache:
	bash ./scripts/purge_diffusers_cache.sh

generate:
	./scripts/generate.sh

build:
	./scripts/build.sh

build-release:
	./scripts/build.sh --release

run:
	./scripts/run.sh

run-release:
	./scripts/run.sh --release

clean:
	xcodebuild -project StoryJuicer.xcodeproj -scheme StoryJuicer -destination 'platform=macOS' clean

app-path:
	@xcodebuild \
		-project StoryJuicer.xcodeproj \
		-scheme StoryJuicer \
		-configuration Debug \
		-destination 'platform=macOS' \
		-showBuildSettings | awk -F' = ' '\
			/TARGET_BUILD_DIR = / { target=$$2 } \
			/WRAPPER_NAME = / { wrapper=$$2 } \
			END { if (target != "" && wrapper != "") print target "/" wrapper }'

# ── Distributable DMG ────────────────────────────────────────────────
# Signs with Developer ID, notarizes with Apple, staples the ticket,
# and packages into a DMG ready for distribution.
#
# Prerequisites (one-time):
#   xcrun notarytool store-credentials "StoryJuicer-Notarize" \
#     --apple-id <email> --team-id <team> --password <app-specific-pw>

SIGN_IDENTITY := "Developer ID Application: Jacob RAINS (47347VQHQV)"
TEAM_ID       := 47347VQHQV
NOTARY_PROFILE := StoryJuicer-Notarize
DMG_DIR       := dist
APP_NAME      := StoryJuicer

dmg:
	@echo "──── 1/7  Preparing output directory ────"
	@mkdir -p $(DMG_DIR)/export
	@rm -rf $(DMG_DIR)/$(APP_NAME).xcarchive $(DMG_DIR)/export/$(APP_NAME).app
	@echo ""
	@echo "──── 2/7  Regenerating Xcode project ────"
	xcodegen generate
	@# Restore entitlements (xcodegen overwrites them to empty <dict/>)
	@# PlistBuddy handles dotted keys; plutil treats dots as path separators
	@rm -f Resources/StoryJuicer.entitlements
	@/usr/libexec/PlistBuddy -c "Add :com.apple.security.network.client bool true" Resources/StoryJuicer.entitlements
	@/usr/libexec/PlistBuddy -c "Add :com.apple.security.cs.allow-jit bool true" Resources/StoryJuicer.entitlements
	@/usr/libexec/PlistBuddy -c "Add :com.apple.security.cs.allow-unsigned-executable-memory bool true" Resources/StoryJuicer.entitlements
	@echo "    Entitlements restored."
	@echo ""
	@echo "──── 3/7  Building Release archive ────"
	@echo "       (This may take several minutes for a full Release build)"
	xcodebuild archive \
		-project $(APP_NAME).xcodeproj \
		-scheme $(APP_NAME) \
		-destination 'generic/platform=macOS' \
		-archivePath $(DMG_DIR)/$(APP_NAME).xcarchive \
		DEVELOPMENT_TEAM=$(TEAM_ID) \
		CODE_SIGN_IDENTITY=$(SIGN_IDENTITY) \
		CODE_SIGN_STYLE=Manual \
		OTHER_CODE_SIGN_FLAGS="--timestamp --options runtime"
	@echo ""
	@echo "──── 4/7  Exporting signed app ────"
	@# Create ExportOptions plist using plutil (no fragile PlistBuddy/heredocs)
	@plutil -create xml1 $(DMG_DIR)/ExportOptions.plist
	@plutil -insert method -string developer-id $(DMG_DIR)/ExportOptions.plist
	@plutil -insert teamID -string $(TEAM_ID) $(DMG_DIR)/ExportOptions.plist
	@plutil -insert signingStyle -string manual $(DMG_DIR)/ExportOptions.plist
	@plutil -insert signingCertificate -string "Developer ID Application" $(DMG_DIR)/ExportOptions.plist
	xcodebuild -exportArchive \
		-archivePath $(DMG_DIR)/$(APP_NAME).xcarchive \
		-exportPath $(DMG_DIR)/export \
		-exportOptionsPlist $(DMG_DIR)/ExportOptions.plist
	@echo ""
	@echo "──── 5/7  Notarizing app with Apple ────"
	ditto -c -k --keepParent "$(DMG_DIR)/export/$(APP_NAME).app" "$(DMG_DIR)/$(APP_NAME).zip"
	xcrun notarytool submit "$(DMG_DIR)/$(APP_NAME).zip" \
		--keychain-profile "$(NOTARY_PROFILE)" \
		--wait
	@echo ""
	@echo "──── 6/7  Stapling notarization ticket ────"
	xcrun stapler staple "$(DMG_DIR)/export/$(APP_NAME).app"
	@echo ""
	@echo "──── 7/7  Creating DMG with drag-to-Applications ────"
	@rm -f "$(DMG_DIR)/$(APP_NAME).dmg"
	create-dmg \
		--volname "$(APP_NAME)" \
		--volicon "Resources/Assets.xcassets/AppIcon.appiconset/icon_512x512.png" \
		--window-pos 200 120 \
		--window-size 660 400 \
		--icon-size 128 \
		--icon "$(APP_NAME).app" 160 190 \
		--app-drop-link 500 190 \
		--hide-extension "$(APP_NAME).app" \
		--no-internet-enable \
		"$(DMG_DIR)/$(APP_NAME).dmg" \
		"$(DMG_DIR)/export/$(APP_NAME).app"
	xcrun notarytool submit "$(DMG_DIR)/$(APP_NAME).dmg" \
		--keychain-profile "$(NOTARY_PROFILE)" \
		--wait
	xcrun stapler staple "$(DMG_DIR)/$(APP_NAME).dmg"
	@echo ""
	@echo "✅ Done! Distributable DMG: $(DMG_DIR)/$(APP_NAME).dmg"
	@rm -f "$(DMG_DIR)/$(APP_NAME).zip" "$(DMG_DIR)/ExportOptions.plist"
