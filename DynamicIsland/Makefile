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

dmg: release
	mkdir -p dmg_staging
	cp -R Resound.app dmg_staging/
	ln -s /Applications dmg_staging/Applications
	hdiutil create -volname "Resound" -srcfolder dmg_staging -ov -format UDZO Resound.dmg
	rm -rf dmg_staging
	@echo "Created Resound.dmg"

clean:
	rm -rf .build Resound.app dmg_staging Resound.dmg
