import Cocoa

// The root / catch-all content view of the main window.
class RootView: NSView {
    // Note: Using NSApp.sendAction() didn't work because of, I believe,
    // the responder chain not including the window when the app is not focused.
    override func mouseExited(with event: NSEvent) {
        (window?.windowController as? WindowController)?.phaseIn()
    }
    
    override func mouseEntered(with event: NSEvent) {
        (window?.windowController as? WindowController)?.phaseOut()
    }
    
    override func updateTrackingAreas() {
        for area in self.trackingAreas {
            self.removeTrackingArea(area)
        }
        let options: NSTrackingArea.Options = [
            .mouseEnteredAndExited,
            .activeAlways,
            .mouseMoved
        ]
        let trackingArea = NSTrackingArea(rect: self.bounds, options: options, owner: self, userInfo: nil)
        self.addTrackingArea(trackingArea)
    }
}
