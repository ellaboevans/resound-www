build:
	swift build

run: build
	.build/debug/DynamicIsland

release:
	swift build -c release
	mkdir -p DynamicIsland.app/Contents/MacOS
	cp -r .build/release/DynamicIsland DynamicIsland.app/Contents/MacOS/
	cp Sources/DynamicIsland/Info.plist DynamicIsland.app/Contents/

clean:
	rm -rf .build DynamicIsland.app
