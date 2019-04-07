import Cocoa
import Foundation

class WindowController: NSWindowController, NSWindowDelegate {

    override func windowDidLoad() {
        super.windowDidLoad()

        if let window = window {
            window.setFrame(Store.getWindowFrame(), display: true)
            window.minSize = Util.minWindowSize
            window.isMovableByWindowBackground = true
            
            // Removing unchecking the titlebar from storyboard ruins my
            // hover/dragging system. So this hack lets me keep the titlebar
            // but render nothing on it.
            window.standardWindowButton(.closeButton)?.isHidden = true
            window.standardWindowButton(.miniaturizeButton)?.isHidden = true
            window.standardWindowButton(.zoomButton)?.isHidden = true
            
            // window.restorable=true will not only remember frame, but
            // also the fullscreen status. Since a window launching to
            // fullscreen is awful UX, we disable it and manually save the frame.
            window.isRestorable = false

            alwaysTopChanged()
            NotificationCenter.default.addObserver(self, selector: #selector(alwaysTopChanged), name: .alwaysTopNotificationId, object: nil)
        }
    }

    @objc func alwaysTopChanged() {
        if let window = window {
            window.level = Store.alwaysTop ? .floating : .normal
        }
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

    @objc func resetWindow() {
        let frame = Util.defaultWindowFrame
        guard let window = window else { return }
        window.setFrame(frame, display: true)
        Store.saveWindowFrame(frame)
    }

}
