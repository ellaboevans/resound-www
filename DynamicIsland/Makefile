build:
	swift build

# Debug: LSUIElement (no dock icon) only applies in .app bundle — use `make release` for full effect
run: build
	.build/debug/DynamicIsland

release:
	swift build -c release
	mkdir -p DynamicIsland.app/Contents/MacOS
	cp .build/release/DynamicIsland DynamicIsland.app/Contents/MacOS/
	cp Sources/DynamicIsland/Info.plist DynamicIsland.app/Contents/

clean:
	rm -rf .build DynamicIsland.app
