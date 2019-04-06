import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    var mediaKeyTap: MediaKeyTap?
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        mediaKeyTap = MediaKeyTap(delegate: self)
        mediaKeyTap?.start()
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
    
    @IBAction func toggleVideoPlayback(_ sender: Any) {
        NSApp.sendAction(#selector(ViewController.toggleVideoPlayback), to: nil, from: nil)
    }
    
    @IBAction func clearData(_ sender: Any) {
        NSApp.sendAction(#selector(ViewController.clearData), to: nil, from: nil)
    }
    
    @IBAction func enlargeSubs(_ sender: Any) {
        NSApp.sendAction(#selector(ViewController.enlargeSubs), to: nil, from: nil)
    }
    
    @IBAction func shrinkSubs(_ sender: Any) {
        NSApp.sendAction(#selector(ViewController.shrinkSubs), to: nil, from: nil)

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

extension NSResponder {
    func printChain() {
        let next = self.nextResponder
        print(next ?? "no next responder, dead end")
        next?.printChain()
    }
}
