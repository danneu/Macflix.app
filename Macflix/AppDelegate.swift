import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    var mediaKeyTap: MediaKeyTap?
    @IBOutlet weak var alwaysTopItem: NSMenuItem!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        mediaKeyTap = MediaKeyTap(delegate: self)
        mediaKeyTap?.start()
        NotificationCenter.default.addObserver(self, selector: #selector(updateAlwaysTopItem), name: .alwaysTopNotificationId, object: nil)
        updateAlwaysTopItem()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }

    @IBAction func fixPlaybackError(_ sender: Any) {
        NSApp.sendAction(#selector(ViewController.fixPlaybackError), to: nil, from: nil)
    }
    
    @objc func updateAlwaysTopItem() {
        alwaysTopItem.state = Store.alwaysTop ? .on : .off
    }

    @IBAction func toggleAlwaysTop(_ sender: Any) {
        Store.alwaysTop = !Store.alwaysTop
    }

    @IBAction func toggleVideoPlayback(_ sender: Any) {
        NSApp.sendAction(#selector(ViewController.toggleVideoPlayback), to: nil, from: nil)
    }

    @IBAction func clearData(_ sender: Any) {
        NSApp.sendAction(#selector(ViewController.clearAllData), to: nil, from: nil)
    }

    @IBAction func enlargeSubs(_ sender: Any) {
        NSApp.sendAction(#selector(ViewController.enlargeSubs), to: nil, from: nil)
    }

    @IBAction func shrinkSubs(_ sender: Any) {
        NSApp.sendAction(#selector(ViewController.shrinkSubs), to: nil, from: nil)

    }
    @IBAction func speedUp(_ sender: Any) {
        NSApp.sendAction(#selector(ViewController.speedUp), to: nil, from: nil)

    }
    @IBAction func speedDown(_ sender: Any) {
        NSApp.sendAction(#selector(ViewController.speedDown), to: nil, from: nil)

    }
    @IBAction func reloadBrowser(_ sender: Any) {
        NSApp.sendAction(#selector(ViewController.reloadBrowser), to: nil, from: nil)

    }

    @IBAction func toggleSubtitleVisibility(_ sender: Any) {
        NSApp.sendAction(#selector(ViewController.toggleSubtitleVisibility), to: nil, from: nil)
    }

    @IBAction func resetWindow(_ sender: Any) {
        NSApp.sendAction(#selector(WindowController.resetWindow), to: nil, from: nil)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
}

extension AppDelegate: MediaKeyTapDelegate {
    func handle(mediaKey: MediaKey, event: KeyEvent) {
        switch mediaKey {
        case .playPause:
            NSApp.sendAction(#selector(ViewController.toggleVideoPlayback), to: nil, from: nil)
        case .previous, .rewind:
            NSApp.sendAction(#selector(ViewController.bumpBackward), to: nil, from: nil)
        case .next, .fastForward:
            NSApp.sendAction(#selector(ViewController.bumpForward), to: nil, from: nil)
        }
    }
}
