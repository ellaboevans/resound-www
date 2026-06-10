build:
	swift build

# Debug: LSUIElement (no dock icon) only applies in .app bundle — use `make release` for full effect
run: build
	.build/debug/Resound

release:
	swift build -c release
	mkdir -p Resound.app/Contents/MacOS Resound.app/Contents/Resources
	cp .build/release/Resound Resound.app/Contents/MacOS/
	cp Sources/Resound/Info.plist Resound.app/Contents/
	cp Sources/Resound/Resources/Resound.icns Resound.app/Contents/Resources/
	codesign --force --deep --sign - Resound.app

dmg: icon release
	scripts/create-dmg.sh

icon:
	swift scripts/generate-icon.swift /tmp/Resound.iconset
	cp /tmp/Resound.icns Sources/Resound/Resources/Resound.icns

clean:
	rm -rf .build Resound.app dmg_staging Resound.dmg

www: dmg
	cp Resound.dmg ../resound-www/public/resound/Resound.dmg
	@echo "→ Copied Resound.dmg to ../resound-www/public/resound/"
