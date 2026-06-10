import AppKit

struct HotkeyBinding: Codable, Equatable {
    var keyCode: UInt16
    var flags: UInt

    var displayString: String {
        var parts: [String] = []
        if flags & NSEvent.ModifierFlags.command.rawValue != 0 { parts.append("⌘") }
        if flags & NSEvent.ModifierFlags.option.rawValue != 0 { parts.append("⌥") }
        if flags & NSEvent.ModifierFlags.shift.rawValue != 0 { parts.append("⇧") }
        if flags & NSEvent.ModifierFlags.control.rawValue != 0 { parts.append("⌃") }
        parts.append(keyChar ?? "?")
        return parts.joined()
    }

    private var keyChar: String? {
        let chars: [UInt16: String] = [
            0: "a", 1: "s", 2: "d", 3: "f", 4: "h", 5: "g", 6: "z", 7: "x",
            8: "c", 9: "v", 11: "b", 12: "q", 13: "w", 14: "e", 15: "r",
            16: "y", 17: "t", 18: "1", 19: "2", 20: "3", 21: "4", 22: "5",
            23: "6", 24: "7", 25: "8", 26: "9", 27: "0", 30: "⌫", 32: "space",
            33: "-", 34: "=", 35: "[", 36: "]", 37: "\\", 38: ";", 39: "'",
            40: "`", 41: ",", 42: ".", 43: "/", 123: "←", 124: "→", 125: "↓", 126: "↑"
        ]
        return chars[keyCode]
    }
}
