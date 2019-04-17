import Cocoa

func parsePath(_ input: String) -> String {
    return URL(string: input)?.path ?? Util.defaultPath
}

struct Store {
    static let common = UserDefaults.standard
    
    // Only saving /browser and /watch/:num
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
        print("saving window frame \(frame)")
        
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
    
    static var isAlwaysTop: Bool {
        get {
            return common.object(forKey: "is_always_top") as? Bool ?? true
        }
        set {
            common.set(newValue, forKey: "is_always_top")
            NSApp.sendAction(#selector(WindowController.alwaysTopChanged), to: nil, from: nil)
            NSApp.sendAction(#selector(AppDelegate.updateAlwaysTopMenuItem), to: nil, from: nil)


//            NotificationCenter.default.post(name: .alwaysTopNotification, object: nil)
        }
    }
//    static var isHideOnHover: Bool {
//        get {
//            return common.bool(forKey: "is_hide_on_hover")
//        }
//        set {
//            common.set(newValue, forKey: "is_hide_on_hover")
//            //  NSApp.sendAction(#selector(WindowController.alwaysTopChanged), to: nil, from: nil)
//            
//            //            NotificationCenter.default.post(name: .alwaysTopNotification, object: nil)
//        }
//    }
    
}


extension Notification.Name {
    static let alwaysTopNotification = Notification.Name("AlwaysTopNotificationId")
}
