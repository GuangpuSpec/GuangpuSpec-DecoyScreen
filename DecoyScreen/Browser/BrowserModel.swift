import Observation
import SwiftUI
import UIKit
import WebKit

/// One tab: a web view plus the state the UI shows for it.
@MainActor
@Observable
final class BrowserTab: Identifiable {
    let id = UUID()
    let isPrivate: Bool
    @ObservationIgnored let webView: WKWebView

    private(set) var title = ""
    private(set) var url: URL?
    private(set) var isLoading = false
    private(set) var progress = 0.0
    private(set) var canGoBack = false
    private(set) var canGoForward = false
    /// Showing the new-tab page instead of a web page.
    var onNewTabPage = true
    var snapshot: UIImage?
    /// iPad (desktop-class) pages instead of phone pages.
    var isDesktop = false {
        didSet { webView.customUserAgent = isDesktop ? Browser.iPadUserAgent : nil }
    }
    /// A restored tab that hasn't loaded yet (loads when you open it).
    var pendingURL: URL?

    @ObservationIgnored private var observations: [NSKeyValueObservation] = []
    @ObservationIgnored var onScroll: ((CGFloat, Bool) -> Void)?
    @ObservationIgnored private var lastOffset: CGFloat = 0

    init(configuration: WKWebViewConfiguration, isPrivate: Bool) {
        self.isPrivate = isPrivate
        webView = WKWebView(frame: .zero, configuration: configuration)
        webView.allowsBackForwardNavigationGestures = true
        webView.allowsLinkPreview = true
        webView.isFindInteractionEnabled = true
        webView.isOpaque = false
        webView.backgroundColor = .systemBackground
        webView.scrollView.contentInsetAdjustmentBehavior = .automatic
        #if DEBUG
        webView.isInspectable = true
        #endif

        let refresh = UIRefreshControl()
        refresh.addAction(UIAction { [weak webView] action in
            webView?.reload()
            (action.sender as? UIRefreshControl)?.endRefreshing()
        }, for: .valueChanged)
        webView.scrollView.refreshControl = refresh

        let sync: @Sendable () -> Void = { [weak self] in
            MainActor.assumeIsolated { self?.sync() }
        }
        let scroll: @Sendable () -> Void = { [weak self] in
            MainActor.assumeIsolated { self?.scrolled() }
        }
        observations = [
            webView.observe(\.canGoBack) { _, _ in sync() },
            webView.observe(\.canGoForward) { _, _ in sync() },
            webView.observe(\.isLoading) { _, _ in sync() },
            webView.observe(\.estimatedProgress) { _, _ in sync() },
            webView.observe(\.url) { _, _ in sync() },
            webView.observe(\.title) { _, _ in sync() },
            webView.scrollView.observe(\.contentOffset) { _, _ in scroll() },
        ]
    }

    private func sync() {
        canGoBack = webView.canGoBack
        canGoForward = webView.canGoForward
        isLoading = webView.isLoading
        progress = webView.estimatedProgress
        title = webView.title ?? ""
        if let u = webView.url, u.absoluteString != "about:blank" {
            url = u
            onNewTabPage = false
        }
    }

    private func scrolled() {
        let sv = webView.scrollView
        let y = sv.contentOffset.y + sv.adjustedContentInset.top
        defer { lastOffset = y }
        guard sv.isDragging || sv.isDecelerating else { return }
        onScroll?(y - lastOffset, y <= 4)
    }

    /// The address to show and edit.
    var displayURL: URL? { url ?? pendingURL }

    var displayTitle: String {
        if !title.isEmpty { return title }
        if let host = displayURL?.host() { return host }
        return String(localized: "New Tab")
    }

    func refreshSnapshot() async {
        guard !onNewTabPage, webView.window != nil else { return }
        let config = WKSnapshotConfiguration()
        config.snapshotWidth = 360
        if let image = try? await webView.takeSnapshot(configuration: config) {
            snapshot = image
        }
    }
}

/// A JavaScript alert, confirm or prompt waiting for an answer.
struct JSDialog: Identifiable {
    enum Kind { case alert, confirm, prompt(String) }
    let id = UUID()
    let kind: Kind
    let message: String
    let host: String
    let respond: (Bool, String?) -> Void
}

/// All tabs, plus history, bookmarks and settings.
@MainActor
@Observable
final class Browser {
    private(set) var tabs: [BrowserTab] = []
    private(set) var currentID: UUID?
    /// Toolbars tucked away while you scroll down a page.
    var chromeHidden = false
    var dialog: JSDialog?
    /// Ask the address bar to take focus (e.g. from the new-tab page).
    var focusRequest = 0
    /// What's in the address bar while you type (drives suggestions).
    var typed = ""
    /// Ask the address bar to take `typed` (the ↖ fill-in button).
    var fillRequest = 0
    var engine: SearchEngine {
        didSet { UserDefaults.standard.set(engine.rawValue, forKey: "engine") }
    }
    /// New tabs ask for iPad pages (like Safari and Chrome on iPad do).
    var desktopByDefault: Bool {
        didSet { UserDefaults.standard.set(desktopByDefault, forKey: "desktopByDefault") }
    }

    /// What Safari on iPad sends: iPad Safari presents itself as a Mac so
    /// sites serve their full desktop pages.
    nonisolated static let iPadUserAgent =
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/26.0 Safari/605.1.15"

    let history = HistoryStore()
    let bookmarks = BookmarkStore()

    @ObservationIgnored private let delegate = WebDelegate()
    @ObservationIgnored private var privateStore = WKWebsiteDataStore.nonPersistent()
    @ObservationIgnored private var scrollDistance: CGFloat = 0

    var current: BrowserTab? { tabs.first { $0.id == currentID } ?? tabs.last }
    var normalTabs: [BrowserTab] { tabs.filter { !$0.isPrivate } }
    var privateTabs: [BrowserTab] { tabs.filter(\.isPrivate) }

    init() {
        engine = SearchEngine(rawValue: UserDefaults.standard.string(forKey: "engine") ?? "") ?? .localDefault
        desktopByDefault = UserDefaults.standard.object(forKey: "desktopByDefault") as? Bool ?? true
        delegate.browser = self
        restore()
        if tabs.isEmpty { newTab() }
    }

    // MARK: Tabs

    private func makeConfiguration(isPrivate: Bool) -> WKWebViewConfiguration {
        let c = WKWebViewConfiguration()
        c.websiteDataStore = isPrivate ? privateStore : .default()
        c.allowsInlineMediaPlayback = true
        c.allowsPictureInPictureMediaPlayback = true
        c.mediaTypesRequiringUserActionForPlayback = []
        // Full screen goes to the system video player (the page's full-screen
        // button falls back to it, as on iPhone Safari). WebKit's element full
        // screen moves the whole web view into a separate window, which on
        // iPhone showed a black screen and left a blank page behind on exit.
        c.preferences.isElementFullscreenEnabled = false
        c.preferences.javaScriptCanOpenWindowsAutomatically = true
        c.defaultWebpagePreferences.allowsContentJavaScript = true
        // Identify as Mobile Safari, like Chrome on iPhone does, so sites serve their full pages.
        c.applicationNameForUserAgent = "Version/26.0 Mobile/15E148 Safari/604.1"
        c.userContentController.addUserScript(WKUserScript(
            source: Self.tabletScript, injectionTime: .atDocumentStart, forMainFrameOnly: false))
        return c
    }

    /// Makes a page behave as it does in Safari on iPad.
    ///
    /// - Device: with the iPad user agent, the page still reads
    ///   `navigator.platform` as "iPhone", and many sites (Bilibili, Zhihu…)
    ///   check that and fall back to their phone layout. iPad Safari reports
    ///   "MacIntel" with touch points, so the page gets the same here.
    /// - Video: on an iPhone, WebKit plays a video inline only when the page
    ///   marks it `playsinline`. iPad and desktop pages never do (they don't
    ///   need to), so their videos jumped to the full-screen player. Every
    ///   video gets the mark before it plays.
    /// - Full screen: the page's own full-screen button opens the system
    ///   video player.
    nonisolated static let tabletScript = """
    (function () {
      if (navigator.userAgent.indexOf('Macintosh') !== -1) {
        try {
          Object.defineProperty(Navigator.prototype, 'platform', { get: function () { return 'MacIntel'; }, configurable: true });
          Object.defineProperty(Navigator.prototype, 'maxTouchPoints', { get: function () { return 5; }, configurable: true });
        } catch (e) {}
      }
      function inline(v) {
        if (!v || v.nodeName !== 'VIDEO') return;
        if (!v.hasAttribute('playsinline')) v.setAttribute('playsinline', '');
        if (!v.hasAttribute('webkit-playsinline')) v.setAttribute('webkit-playsinline', '');
        v.playsInline = true;
      }
      // A page asking for full screen (on its player or a wrapper around
      // it) gets the system video player instead.
      if (!('requestFullscreen' in Element.prototype) || !document.fullscreenEnabled) {
        var enter = function () {
          var v = this && this.nodeName === 'VIDEO' ? this
            : (this && this.querySelector && this.querySelector('video')) || document.querySelector('video');
          if (v && v.webkitEnterFullscreen) { try { v.webkitEnterFullscreen(); } catch (e) {} }
          return Promise.resolve();
        };
        Element.prototype.requestFullscreen = enter;
        Element.prototype.webkitRequestFullscreen = enter;
        Element.prototype.webkitRequestFullScreen = enter;
        try {
          Object.defineProperty(Document.prototype, 'fullscreenEnabled', { get: function () { return true; }, configurable: true });
          Object.defineProperty(Document.prototype, 'webkitFullscreenEnabled', { get: function () { return true; }, configurable: true });
        } catch (e) {}
        if (!document.exitFullscreen) { document.exitFullscreen = function () { return Promise.resolve(); }; }
      }
      var play = HTMLMediaElement.prototype.play;
      HTMLMediaElement.prototype.play = function () { inline(this); return play.apply(this, arguments); };
      var create = Document.prototype.createElement;
      Document.prototype.createElement = function () {
        var el = create.apply(this, arguments);
        if (el && el.nodeName === 'VIDEO') inline(el);
        return el;
      };
      function scan(root) {
        if (!root || !root.querySelectorAll) return;
        if (root.nodeName === 'VIDEO') inline(root);
        root.querySelectorAll('video').forEach(inline);
      }
      new MutationObserver(function (records) {
        records.forEach(function (r) { r.addedNodes.forEach(scan); });
      }).observe(document, { childList: true, subtree: true });
      document.addEventListener('DOMContentLoaded', function () { scan(document); });
    })();
    """

    @discardableResult
    func newTab(url: URL? = nil, isPrivate: Bool = false, select: Bool = true,
                configuration: WKWebViewConfiguration? = nil, after parent: BrowserTab? = nil) -> BrowserTab {
        let tab = BrowserTab(configuration: configuration ?? makeConfiguration(isPrivate: isPrivate), isPrivate: isPrivate)
        tab.webView.navigationDelegate = delegate
        tab.webView.uiDelegate = delegate
        tab.onScroll = { [weak self] delta, atTop in self?.scrolled(delta, atTop: atTop) }
        tab.isDesktop = parent?.isDesktop ?? desktopByDefault
        if let parent, let i = tabs.firstIndex(where: { $0.id == parent.id }) {
            tabs.insert(tab, at: i + 1)
        } else {
            tabs.append(tab)
        }
        if configuration != nil { tab.onNewTabPage = false }
        if let url {
            tab.onNewTabPage = false
            tab.webView.load(URLRequest(url: url))
        }
        if select { self.select(tab) }
        save()
        return tab
    }

    func select(_ tab: BrowserTab) {
        // Keep a fresh preview of the tab you're leaving for the tab overview.
        if let leaving = current, leaving.id != tab.id {
            Task { await leaving.refreshSnapshot() }
        }
        currentID = tab.id
        chromeHidden = false
        if let pending = tab.pendingURL {
            tab.pendingURL = nil
            tab.onNewTabPage = false
            tab.webView.load(URLRequest(url: pending))
        }
        save()
    }

    func close(_ tab: BrowserTab) {
        tab.webView.stopLoading()
        tab.webView.pauseAllMediaPlayback(completionHandler: nil)
        let wasCurrent = tab.id == current?.id
        let index = tabs.firstIndex { $0.id == tab.id } ?? 0
        tabs.removeAll { $0.id == tab.id }
        if privateTabs.isEmpty, tab.isPrivate {
            // Last incognito tab gone: forget its cookies and storage.
            privateStore = .nonPersistent()
        }
        if wasCurrent {
            // Prefer the neighbour of the same kind (normal or incognito).
            let before = tabs.prefix(index).last { $0.isPrivate == tab.isPrivate }
            let after = tabs.dropFirst(index).first { $0.isPrivate == tab.isPrivate }
            if let next = before ?? after ?? tabs.last {
                select(next)
            }
        }
        if tabs.isEmpty { newTab() }
        save()
    }

    func closeAll(isPrivate: Bool) {
        for tab in tabs where tab.isPrivate == isPrivate { close(tab) }
    }

    // MARK: Navigation

    /// Go to what was typed: an address, or a search.
    func go(_ text: String, in tab: BrowserTab? = nil) {
        guard let url = Self.url(from: text, engine: engine), let tab = tab ?? current else { return }
        load(url, in: tab)
    }

    func load(_ url: URL, in tab: BrowserTab? = nil) {
        guard let tab = tab ?? current else { return }
        tab.pendingURL = nil
        tab.onNewTabPage = false
        tab.webView.load(URLRequest(url: url))
        chromeHidden = false
    }

    static func url(from text: String, engine: SearchEngine) -> URL? {
        let raw = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !raw.isEmpty else { return nil }
        if raw.contains("://"), let u = URL(string: raw) { return u }
        let looksLikeHost = !raw.contains(" ") && (raw.contains(".") || raw.hasPrefix("localhost"))
            && raw.rangeOfCharacter(from: .init(charactersIn: "。，")) == nil
        if looksLikeHost, let u = URL(string: "https://" + raw), u.host() != nil { return u }
        return engine.searchURL(raw)
    }

    func home() {
        guard let tab = current else { return }
        tab.webView.pauseAllMediaPlayback(completionHandler: nil)
        tab.onNewTabPage = true
        chromeHidden = false
    }

    func toggleDesktop() {
        guard let tab = current else { return }
        tab.isDesktop.toggle()
        tab.webView.reload()
    }

    func findInPage() {
        current?.webView.findInteraction?.presentFindNavigator(showingReplace: false)
    }

    // MARK: Media

    func pauseAll() {
        for tab in tabs { tab.webView.pauseAllMediaPlayback(completionHandler: nil) }
    }

    func setHidden(_ hidden: Bool) {
        if hidden { pauseAll() }
        for tab in tabs { tab.webView.setAllMediaPlaybackSuspended(hidden, completionHandler: nil) }
    }

    // MARK: Toolbars

    private func scrolled(_ delta: CGFloat, atTop: Bool) {
        if atTop {
            if chromeHidden { chromeHidden = false }
            scrollDistance = 0
            return
        }
        if (delta > 0) != (scrollDistance > 0) { scrollDistance = 0 }
        scrollDistance += delta
        if scrollDistance > 40, !chromeHidden { chromeHidden = true }
        if scrollDistance < -40, chromeHidden { chromeHidden = false }
    }

    // MARK: Saving open tabs

    func save() {
        let urls = normalTabs.compactMap { $0.displayURL?.absoluteString ?? "" }
        UserDefaults.standard.set(urls, forKey: "openTabs")
        let index = normalTabs.firstIndex { $0.id == current?.id } ?? max(0, urls.count - 1)
        UserDefaults.standard.set(index, forKey: "openTabIndex")
    }

    private func restore() {
        let urls = UserDefaults.standard.stringArray(forKey: "openTabs") ?? []
        let index = UserDefaults.standard.integer(forKey: "openTabIndex")
        for (i, s) in urls.enumerated() {
            let tab = newTab(select: false)
            if let u = URL(string: s), !s.isEmpty {
                tab.pendingURL = u
                tab.onNewTabPage = false
            }
            if i == index { select(tab) }
        }
        if currentID == nil, let last = tabs.last { select(last) }
        save()
    }

    // MARK: Delegate callbacks

    fileprivate func tab(for webView: WKWebView) -> BrowserTab? {
        tabs.first { $0.webView === webView }
    }

    fileprivate func didFinish(_ tab: BrowserTab) {
        if !tab.isPrivate, let url = tab.webView.url {
            history.record(url: url, title: tab.webView.title ?? "")
        }
        save()
        Task { await tab.refreshSnapshot() }
    }
}

/// Navigation and UI callbacks for every tab.
@MainActor
private final class WebDelegate: NSObject, WKNavigationDelegate, WKUIDelegate {
    weak var browser: Browser?

    private static let webSchemes: Set<String> = ["http", "https", "about", "data", "blob", "file", "javascript"]

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction,
                 preferences: WKWebpagePreferences) async -> (WKNavigationActionPolicy, WKWebpagePreferences) {
        let scheme = navigationAction.request.url?.scheme?.lowercased() ?? "about"
        if Self.webSchemes.contains(scheme) {
            // Pages come in iPad form through the user agent alone. WebKit's desktop
            // content mode (simulated mouse input) misbehaves on an iPhone and can
            // leave touches stuck, so it stays on the phone setting.
            preferences.preferredContentMode = .mobile
            // Open https links here, never in an installed app (Xiaohongshu,
            // Bilibili…). This is the "allow without trying app link" policy,
            // the same one Firefox for iOS uses.
            let stayInBrowser = WKNavigationActionPolicy(rawValue: WKNavigationActionPolicy.allow.rawValue + 2) ?? .allow
            return (scheme.hasPrefix("http") ? stayInBrowser : .allow, preferences)
        }
        // Phone, mail and messages go to their apps. Other app links ("open in the
        // Bilibili app" and friends) are dropped so you stay on the web page.
        if ["tel", "mailto", "sms", "facetime"].contains(scheme), let url = navigationAction.request.url,
           navigationAction.navigationType == .linkActivated {
            _ = await UIApplication.shared.open(url)
        }
        return (.cancel, preferences)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        guard let browser, let tab = browser.tab(for: webView) else { return }
        browser.didFinish(tab)
    }

    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        webView.reload()
    }

    // Links that open a new window (target="_blank", window.open) become a new tab.
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration,
                 for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        guard let browser else { return nil }
        let parent = browser.tab(for: webView)
        let tab = browser.newTab(isPrivate: parent?.isPrivate ?? false, configuration: configuration, after: parent)
        return tab.webView
    }

    func webViewDidClose(_ webView: WKWebView) {
        guard let browser, let tab = browser.tab(for: webView) else { return }
        browser.close(tab)
    }

    // MARK: JavaScript dialogs

    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String,
                 initiatedByFrame frame: WKFrameInfo) async {
        await withCheckedContinuation { (c: CheckedContinuation<Void, Never>) in
            show(.alert, message, frame) { _, _ in c.resume() }
        }
    }

    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String,
                 initiatedByFrame frame: WKFrameInfo) async -> Bool {
        await withCheckedContinuation { (c: CheckedContinuation<Bool, Never>) in
            show(.confirm, message, frame) { ok, _ in c.resume(returning: ok) }
        }
    }

    func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String,
                 defaultText: String?, initiatedByFrame frame: WKFrameInfo) async -> String? {
        await withCheckedContinuation { (c: CheckedContinuation<String?, Never>) in
            show(.prompt(defaultText ?? ""), prompt, frame) { ok, text in c.resume(returning: ok ? text : nil) }
        }
    }

    /// Shown with UIKit on top of whatever is on screen (even a sheet), so a
    /// page is never left waiting on a dialog nobody can see.
    private func show(_ kind: JSDialog.Kind, _ message: String, _ frame: WKFrameInfo,
                      respond: @escaping (Bool, String?) -> Void) {
        guard let top = Share.topViewController() else { respond(false, nil); return }
        let alert = UIAlertController(title: frame.request.url?.host(), message: message, preferredStyle: .alert)
        let answer = DialogAnswer(respond)
        let finish: (Bool, String?) -> Void = { ok, text in answer.finish(ok, text) }
        switch kind {
        case .alert:
            alert.addAction(UIAlertAction(title: String(localized: "OK"), style: .default) { _ in finish(true, nil) })
        case .confirm:
            alert.addAction(UIAlertAction(title: String(localized: "Cancel"), style: .cancel) { _ in finish(false, nil) })
            alert.addAction(UIAlertAction(title: String(localized: "OK"), style: .default) { _ in finish(true, nil) })
        case .prompt(let text):
            alert.addTextField { $0.text = text }
            alert.addAction(UIAlertAction(title: String(localized: "Cancel"), style: .cancel) { _ in finish(false, nil) })
            alert.addAction(UIAlertAction(title: String(localized: "OK"), style: .default) { [weak alert] _ in
                finish(true, alert?.textFields?.first?.text)
            })
        }
        top.present(alert, animated: true)
        // A dialog that can't be shown (e.g. mid-transition) must not freeze the page.
        let shown = WeakBox(alert)
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1))
            if shown.value?.presentingViewController == nil { answer.finish(false, nil) }
        }
    }

    // MARK: Long-press on links

    func webView(_ webView: WKWebView, contextMenuConfigurationFor elementInfo: WKContextMenuElementInfo) async -> UIContextMenuConfiguration? {
        guard let url = elementInfo.linkURL, let browser else { return nil }
        let parent = browser.tab(for: webView)
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
            UIMenu(children: [
                UIAction(title: String(localized: "Open in New Tab"), image: UIImage(systemName: "plus.square.on.square")) { _ in
                    browser.newTab(url: url, isPrivate: parent?.isPrivate ?? false, select: false, after: parent)
                },
                UIAction(title: String(localized: "Open in Incognito Tab"), image: UIImage(systemName: "eyeglasses")) { _ in
                    browser.newTab(url: url, isPrivate: true, select: false, after: parent)
                },
                UIAction(title: String(localized: "Copy Link"), image: UIImage(systemName: "doc.on.doc")) { _ in
                    UIPasteboard.general.url = url
                },
                UIAction(title: String(localized: "Share…"), image: UIImage(systemName: "square.and.arrow.up")) { _ in
                    Share.present([url])
                },
            ])
        }
    }
}

/// Answers a page's dialog exactly once.
@MainActor
private final class DialogAnswer {
    private var respond: ((Bool, String?) -> Void)?
    init(_ respond: @escaping (Bool, String?) -> Void) { self.respond = respond }
    func finish(_ ok: Bool, _ text: String?) {
        respond?(ok, text)
        respond = nil
    }
}

@MainActor
private final class WeakBox<T: AnyObject> {
    weak var value: T?
    init(_ value: T) { self.value = value }
}

/// Shows the system share sheet from anywhere.
enum Share {
    /// The view controller on top of the app's main window.
    @MainActor
    static func topViewController() -> UIViewController? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let main = scenes.first { $0.session.role == .windowApplication && $0.activationState == .foregroundActive }
            ?? scenes.first { $0.session.role == .windowApplication }
        guard var top = main?.keyWindow?.rootViewController ?? main?.windows.first?.rootViewController else { return nil }
        while let next = top.presentedViewController, !next.isBeingDismissed { top = next }
        return top
    }

    @MainActor
    static func present(_ items: [Any]) {
        guard let top = topViewController() else { return }
        let sheet = UIActivityViewController(activityItems: items, applicationActivities: nil)
        sheet.popoverPresentationController?.sourceView = top.view
        top.present(sheet, animated: true)
    }
}
