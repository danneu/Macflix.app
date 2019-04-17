import Cocoa

class MainWindow: NSWindow {
    // Catches the build-in menuitems.
    // Use AppDelegate.validateMenuItem to catch custom menuitems.
    override func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        if menuItem.action == #selector(NSWindow.toggleFullScreen(_:)) {
            return true
        } else {
            return super.validateMenuItem(menuItem)
        }
    }
    
    // Always ensure avoidance is off for fullscreen transition.
    override func toggleFullScreen(_ sender: Any?) {
        (windowController as? WindowController)?.avoidance = .off
        
        let isFullScreening = !self.styleMask.contains(.fullScreen)
        
        // Always reset level to .normal so that super method will work.
        // .floating prevents super method from transitioning.
        self.level = .normal
    
        super.toggleFullScreen(sender)
        
        // After fullscreen transition, reset level based on store.
        if !isFullScreening {
            self.level = Store.isAlwaysTop ? .floating : .normal
        }
    }
}
