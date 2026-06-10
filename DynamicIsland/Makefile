build:
	swift build

# Debug: LSUIElement (no dock icon) only applies in .app bundle — use `make release` for full effect
run: build
	.build/debug/Resound

release:
	swift build -c release
	mkdir -p Resound.app/Contents/MacOS
	cp .build/release/Resound Resound.app/Contents/MacOS/
	cp Sources/Resound/Info.plist Resound.app/Contents/

clean:
	rm -rf .build Resound.app
