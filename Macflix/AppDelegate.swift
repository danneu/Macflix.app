import Cocoa
import WebKit

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    var webView: DraggableWebView!
    var windowController = WindowController()

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        let styleMask = NSWindow.StyleMask(arrayLiteral: [.titled, .closable, .resizable, .miniaturizable, .fullSizeContentView])
        let frame = Store.getWindowFrame()
        window = NSWindow(contentRect: frame, styleMask: styleMask, backing: NSWindow.BackingStoreType.buffered, defer: true, screen: NSScreen.main)
        //window.setFrame(frame, display: true)
        window.windowController = windowController
        window.delegate = windowController
        windowController.window = window
        window.contentView = CatchallView()
        window.minSize = Util.minWindowSize
        
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.standardWindowButton(.closeButton)?.isHidden = true
        window.standardWindowButton(.miniaturizeButton)?.isHidden = true
        window.standardWindowButton(.zoomButton)?.isHidden = true

        window.isRestorable = false
        window.showsResizeIndicator = true
        window.isMovableByWindowBackground = true
        
        // WEBVIEW
        
        let driverJs: String = {
            let path = Bundle.main.path(forResource: "driver", ofType: "js")!
            let string = try! String(contentsOfFile: path, encoding: .utf8)
            return string
        }()
        let contentController = WKUserContentController()
        let script = WKUserScript(source: driverJs, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        contentController.addUserScript(script)

        let config = WKWebViewConfiguration()
        config.userContentController = contentController
        config.userContentController.add(self, name: "onPushState")
        config.userContentController.add(self, name: "onConsoleLog")
        config.userContentController.add(self, name: "requestFullscreen")
        config.userContentController.add(self, name: "onVideoDimensions")
        
        webView = DraggableWebView(frame: window.frame, configuration: config)
        webView.uiDelegate = self
        webView.navigationDelegate = self
        webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_13_3) AppleWebKit/604.5.6 (KHTML, like Gecko) Version/11.0.3 Safari/604.5.6"
        window.contentView?.addSubview(webView)
        
        webView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: webView.superview!.topAnchor),
            webView.trailingAnchor.constraint(equalTo: webView.superview!.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: webView.superview!.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: webView.superview!.leadingAnchor)
        ])
        
        window.makeKeyAndOrderFront(nil)
        
        let initUrl = URL(string: "https://www.netflix.com" + Store.getUrl())!
        webView.load(URLRequest(url: initUrl))
        
//        NotificationCenter.default.addObserver(self, selector: #selector(updateAlwaysTopMenuItem), name: .alwaysTopNotification, object: nil)
        updateAlwaysTopMenuItem()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
    
    @IBAction func refreshBrowser(_ sender: Any) {
        webView.reload()
    }
    
    @IBOutlet weak var alwaysTopMenuItem: NSMenuItem!
    
    @IBAction func toggleAlwaysTop(_ sender: Any) {
        Store.isAlwaysTop = !Store.isAlwaysTop
    }
    
    // Update the UI
    @objc func updateAlwaysTopMenuItem() {
        alwaysTopMenuItem.state = Store.isAlwaysTop ? .on : .off
    }
    
    @IBAction func fixWatchError(_ sender: Any) {
        let types = Set([
            WKWebsiteDataTypeIndexedDBDatabases,
            WKWebsiteDataTypeLocalStorage
        ])
        WKWebsiteDataStore.default().removeData(ofTypes: types, modifiedSince: Date(timeIntervalSince1970: 0), completionHandler: {
            self.webView.reloadFromOrigin()
        })
    }
    
    @IBOutlet weak var hideOnHoverMenuItem: NSMenuItem!
    @IBAction func toggleHideOnHover(_ sender: Any) {
    }
    func onUrlChange(path: String) {
        print("onUrlChange path=\"\(path)\"")
        Store.saveUrl(path)
    }
}




extension AppDelegate: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        print("got message from javascript: message.name=\"\(message.name)\" message.body=\(message.body)")
        // should be on url change sine more ways than pushstate
        if message.name == "onPushState", let dictionary = message.body as? [String: Any] {
            let path = (dictionary["url"] as? String) ?? "--"
            self.onUrlChange(path: path)
        } else if message.name == "onConsoleLog", let text = message.body as? String {
            print("onConsoleLog \"\(text)\"")
        } else if message.name == "requestFullscreen" {
            print("should be toggling fullscreen...")
            window.toggleFullScreen(nil)
        } else if message.name == "onVideoDimensions"  {
            let dict = message.body as? [String: Int] ?? nil
            var dims: NSSize? = nil
            if let width = dict?["width"], let height = dict?["height"] {
                dims = NSSize(width: width, height: height)
            }
            if window.aspectRatio != dims {
                print("-- VIDEO DIMS UPDATED", dims as Any)
                windowController.setAspectRatio(dims)
            }
        } else {
            print("unhandled js message: \(message.name) \(message.body)")
        }
    }
}

extension AppDelegate: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        print("started provisional navigation")
    }
    
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        print("didCommit")
        if let url = webView.url {
            self.onUrlChange(path: url.path)
        }
    }
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("didFinish")
    }
}

extension AppDelegate: WKUIDelegate {
    
}

func jsCompletion(obj: Any?, err: Error?) {
    if let err = err {
        print("javascript executed with error: \(err)")
    }
}



// A view that you can drag to move the underlying window around,
// but other mouse events are handled by the view.
class DraggableWebView: WKWebView {
    var dragStart: Date? = nil
    
    
    // This alone would be sufficient except that the final mouseUp
    // after a drag gets handled by the view instead of ignored,
    // so the user will accidentally click a button if they happened
    // to start (thus end) their drag on one.
    override var mouseDownCanMoveWindow: Bool {
        //return self.isHidden
        return true
    }
    
    // Timestamp the start of any drag.
    override func mouseDragged(with event: NSEvent) {
        if dragStart == nil {
            dragStart = Date()
        }
    }
    
    override func mouseDown(with event: NSEvent) {
        print("mouse down")
        // TODO: Look into why this happens and what it means.
        if dragStart != nil {
            print("[weird] mouseDown happened while dragStart was set.")
            dragStart = nil
        }
        super.mouseDown(with: event)
    }
    
    // Figure out if the mouseUp terminated a drag or not.
    // Also consider tiny drags be clicks.
    override func mouseUp(with event: NSEvent) {
        if let dragStart = dragStart {
            let milliseconds = (Date().timeIntervalSince1970 - dragStart.timeIntervalSince1970) * 1000
            // If this delta threshold is too inaccurate, it creates
            // awful UX of failed clicks.
            print("delta:", round(milliseconds), "ms")
            self.dragStart = nil
            if milliseconds > 200 {
                return
            }
        }
        
        super.mouseUp(with: event)
    }
    
//    open override func mouseEntered(with event: NSEvent) {
//        
//                print("[WebView] mouseEntered")
//        NSApp.sendAction(#selector(WindowController.phaseOut), to: nil, from: nil)
//    }
}
