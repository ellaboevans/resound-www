build:
	swift build

# Debug: LSUIElement (no dock icon) only applies in .app bundle — use `make release` for full effect
run: build
	.build/debug/Resound

release:
	mkdir -p Resound.app/Contents/MacOS Resound.app/Contents/Resources
	# Build for arm64 (Apple Silicon)
	swift build -c release --build-path .build/arm64
	cp .build/arm64/release/Resound .build/Resound.arm64
	# Build for x86_64 (Intel)
	swift build -c release --build-path .build/x86_64 \
		--triple x86_64-apple-macosx$(shell sw_vers -productVersion | cut -d. -f1).0
	cp .build/x86_64/release/Resound .build/Resound.x86_64
	# Merge into universal binary
	lipo -create -output Resound.app/Contents/MacOS/Resound \
		.build/Resound.arm64 .build/Resound.x86_64
	cp Sources/Resound/Info.plist Resound.app/Contents/
	cp Sources/Resound/Resources/Resound.icns Resound.app/Contents/Resources/
	codesign --force --deep --sign - Resound.app
	# Clean per-arch build artifacts
	rm -rf .build/arm64 .build/x86_64 .build/Resound.arm64 .build/Resound.x86_64

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
