import Foundation

func parsePath(_ input: String) -> String {
    return URL(string: input)?.path ?? Util.defaultPath
}

// Only saving /browser and /watch/:num
struct Store {
    static let common = UserDefaults.standard

    static func saveUrl(_ input: String) {
        var path = parsePath(input)
        path = path.hasPrefix("/browse") || path.hasPrefix("/watch/") ? path : Util.defaultPath
        //print("Store.saveurl input=\(input) path=\(path)")
        common.set(path, forKey: "latestUrl")
    }

    static func getUrl() -> String {
        return common.string(forKey: "latestUrl") ?? Util.defaultPath
    }

    static func saveWindowFrame(_ frame: NSRect) {
        //print("saving window frame \(frame)")
        let dict = frame.dictionaryRepresentation
        common.set(dict, forKey: "windowFrame")
    }

    static func getWindowFrame() -> NSRect {
        print("getting window frame")
        guard let dict = common.dictionary(forKey: "windowFrame") as CFDictionary? else {
            print("got frame default")
            return Util.defaultWindowFrame
        }
        let frame = NSRect(dictionaryRepresentation: dict) ?? Util.defaultWindowFrame
        print("got fram \(frame)")
        return frame
    }

    static func getAlwaysTop() -> Bool {
        return common.object(forKey: "always_top") as? Bool ?? true
    }

    static var alwaysTop: Bool {
        get {
            return common.object(forKey: "always_top") as? Bool ?? true
        }
        set {
            common.set(newValue, forKey: "always_top")
            NotificationCenter.default.post(name: .alwaysTopNotificationId, object: nil)
        }
    }
}

extension Notification.Name {
    static let alwaysTopNotificationId = Notification.Name("AlwaysTopNotificationId")
}
