import Cocoa
import Foundation

class WindowController: NSWindowController, NSWindowDelegate {

    override func windowDidLoad() {
        super.windowDidLoad()

        if let window = window {
            window.setFrame(Store.getWindowFrame(), display: true)
            window.minSize = Util.minWindowSize
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
