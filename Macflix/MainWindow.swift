import Cocoa

class MainWindow: NSWindow {
    var fullScr = false
    
    // Catches the build-in menuitems.
    // Use AppDelegate.validateMenuItem to catch custom menuitems.
//    override func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
//        if menuItem.action == #selector(NSWindow.toggleFullScreen(_:)) {
//            return true
//        } else {
//            return super.validateMenuItem(menuItem)
//        }
//    }
    
    // Always ensure avoidance is off for fullscreen transition.
    override func toggleFullScreen(_ sender: Any?) {
        (windowController as? WindowController)?.avoidance = .off
        super.toggleFullScreen(sender)
        
        if fullScr == true
        {
            // disable title bar in window mode
            fullScr = false
            titleVisibility = .hidden
            titlebarAppearsTransparent = true
            standardWindowButton(.closeButton)?.isHidden = true
            standardWindowButton(.miniaturizeButton)?.isHidden = true
            standardWindowButton(.zoomButton)?.isHidden = true
        }
        else
        {
            // enable title bar in full screen to avoid this white bar that pops in when moving mouse to the top of screen
            fullScr = true
            titleVisibility = .visible
            titlebarAppearsTransparent = false
            standardWindowButton(.closeButton)?.isHidden = false
            standardWindowButton(.miniaturizeButton)?.isHidden = false
            standardWindowButton(.zoomButton)?.isHidden = false
        }
    }
}
