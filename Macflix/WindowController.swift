import Cocoa
import WebKit

enum Avoidance {
    case off
    case ghost
    //case teleport
}

//protocol AvoidanceDelegate: class {
//    var avoidance: Avoidance? { get set }
//    func mouseEnteredGlobally()
//    func mouseExitedGlobally()
//}

protocol Avoider {
    func phaseOut()
    func phaseIn()
}

class WindowController: NSWindowController, NSWindowDelegate, Avoider {
//    var avoidanceDelegate: AvoidanceDelegate?
    var avoidance: Avoidance = .off {
        didSet {
            // Update AppDelegate menu state whenever avoidance is updated.
            if let appDelegate = NSApplication.shared.delegate as? AppDelegate {
                appDelegate.hideOnHoverMenuItem.state = self.avoidance == .ghost ? .on : .off
            }
        }
    }
    
    override var window: NSWindow? {
        didSet {
            // Whenever window is set, sync its always-on-top property
            // with the value in Store.
            self.alwaysTopChanged()
        }
    }
    
    @objc func phaseOut() {
        if (avoidance != .ghost) { return }
        guard let window = window else { return }
        window.isOpaque = false
        window.backgroundColor = NSColor(red: 0, green: 0, blue: 0, alpha: 0.10)
        window.hasShadow = false
        window.ignoresMouseEvents = true
        guard let webView = window.contentView?.subviews.first(where: { view in view is WKWebView }) else { return }
        webView.isHidden = true
    }
    
    @objc func phaseIn() {
        if (avoidance != .ghost) { return }
        guard let window = window else { return }
        window.isOpaque = true
        window.backgroundColor = NSColor.windowBackgroundColor
        window.hasShadow = true
        window.ignoresMouseEvents = false
        guard let webView = window.contentView?.subviews.first(where: { $0 is WKWebView }) else { return }
        webView.isHidden = false
    }
    
    func setAspectRatio(_ ratio: NSSize?) {
        guard let window = window else { return }
        if let ratio = ratio {
            window.aspectRatio = ratio
            let newFrame = Util.scaleFrameToAspectRatio(aspect: ratio, frame: window.frame)
            window.setFrame(newFrame, display: true, animate: true)
        } else {
            // On non-/watch pages, user can resize to whatever dims they want.
            window.resizeIncrements = NSSize(width: 1.0, height: 1.0)
        }
    }
    
    // When user manually resizes window, store the frame for next launch.
    func windowDidEndLiveResize(_ notification: Notification) {
        guard let windowFrame = window?.frame,
            let screenFrame =  window?.screen?.frame else {
                return
        }
        
        // save window dimensions if it's not fullscreen
        if windowFrame.width < screenFrame.width || windowFrame.height < screenFrame.height {
            Store.saveWindowFrame(windowFrame)
        }
    }
    
    // When user moves window, store the frame for next launch.
    func windowDidMove(_ notification: Notification) {
        guard let windowFrame = window?.frame,
            let screenFrame =  window?.screen?.frame else {
                return
        }
        
        // only save if window is 100% in bounds
        if screenFrame.contains(windowFrame) {
            Store.saveWindowFrame(windowFrame)
        }
    }
    
    @objc func alwaysTopChanged() {
        if let window = window {
            window.level = Store.isAlwaysTop ? .floating : .normal
        }
    }
}
