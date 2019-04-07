import Cocoa
import WebKit

extension ViewController: WKNavigationDelegate {
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

class ViewController: NSViewController, WKUIDelegate {
    var webView: WKWebView!
    // Netflix default is 14px
    var subSize = 14
    var subsVisible = true

    func onUrlChange(path: String) {
        print("onUrlChange path=\"\(path)\"")
        Store.saveUrl(path)
    }

    override func loadView() {
        super.loadView()

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

        //webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView = WKWebView(frame: view.frame, configuration: config)
        webView.allowsBackForwardNavigationGestures = true

        webView.uiDelegate = self
        webView.navigationDelegate = self
        webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_13_3) AppleWebKit/604.5.6 (KHTML, like Gecko) Version/11.0.3 Safari/604.5.6"

        self.view = webView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let initUrl = URL(string: "https://www.netflix.com" + Store.getUrl())
        let myRequest = URLRequest(url: initUrl!)
        webView.load(myRequest)
    }

    @objc func bumpBackward() {
        self.webView.evaluateJavaScript("window.netflix.bumpBackward()", completionHandler: jsCompletion)
    }

    @objc func bumpForward() {
        self.webView.evaluateJavaScript("window.netflix.bumpForward()", completionHandler: jsCompletion)
    }

    @objc func speedUp() {
        self.webView.evaluateJavaScript("window.netflix.adjustPlaybackSpeed(0.25)", completionHandler: jsCompletion)
    }

    @objc func speedDown() {
        self.webView.evaluateJavaScript("window.netflix.adjustPlaybackSpeed(-0.25)", completionHandler: jsCompletion)
    }

    @objc func reloadBrowser() {
        self.webView.reloadFromOrigin()
    }

    func nextEpisode() {
        self.webView.evaluateJavaScript("window.netflix.nextEpisode()", completionHandler: jsCompletion)
    }

    func pauseVideo() {
        self.webView.evaluateJavaScript("window.netflix.pauseVideo()", completionHandler: jsCompletion)
    }

    func playVideo() {
        self.webView.evaluateJavaScript("window.netflix.playVideo()", completionHandler: jsCompletion)
    }

    @objc func toggleVideoPlayback() {
        self.webView.evaluateJavaScript("window.netflix.toggleVideoPlayback()", completionHandler: jsCompletion)
    }

    @objc func enlargeSubs() {
        self.adjustSubSize(delta: 2)
    }

    @objc func shrinkSubs() {
        self.adjustSubSize(delta: -2)
    }

    func adjustSubSize(delta: Int) {
        // in pixels
        let minSize = 14
        let newSize = max(minSize, self.subSize + delta)
        self.subSize = newSize
        self.webView.evaluateJavaScript("window.netflix.setSubSize(\(newSize))", completionHandler: jsCompletion)
    }

    @objc func toggleSubtitleVisibility() {
        subsVisible = !subsVisible
        self.webView.evaluateJavaScript("window.netflix.toggleSubtitleVisibility(\(subsVisible))", completionHandler: jsCompletion)
    }

    @objc func clearData() {
        let store = WKWebsiteDataStore.default()
        let types = WKWebsiteDataStore.allWebsiteDataTypes()
        let epoch = Date(timeIntervalSince1970: 0)
        store.removeData(ofTypes: types, modifiedSince: epoch, completionHandler: {
            self.webView.reload()
        })
    }

}

func jsCompletion(obj: Any?, err: Error?) {
    if let err = err {
        print("javascript executed with error: \(String(describing: err))")
    }
}

extension ViewController: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        print("got message from javascript: message.name=\"\(message.name)\"")
        if message.name == "onPushState", let dictionary = message.body as? [String: Any] {
            let path = (dictionary["url"] as? String) ?? "--"
            self.onUrlChange(path: path)
        } else if message.name == "onConsoleLog", let text = message.body as? String {
            print("onConsoleLog \"\(text)\"")
        } else if message.name == "requestFullscreen" {
            self.view.window?.toggleFullScreen(nil)
        } else {
            print("unhandled js message: \(message.name) \(message.body)")
        }
    }
}

class ViewControllerView: NSView {
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        return true
    }
}
