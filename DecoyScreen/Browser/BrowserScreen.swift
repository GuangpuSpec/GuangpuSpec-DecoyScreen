import DuoKit
import SwiftUI
import WebKit

/// The inner screen: a browser. The page fills the content area and keeps its
/// own taps and scrolling; navigation and actions are system toolbar items,
/// and the address field is the system search field.
struct BrowserScreen: View {
    let browser: Browser
    let store: DecoyStore
    let outerStatus: OuterStatusInfo
    let onCamera: () -> Void
    @Binding var hidden: Bool

    @State private var query = ""
    @State private var searching = false
    @State private var remote: [String] = []
    @State private var showingTabs = false
    @State private var sheet: BrowserSheet?

    var body: some View {
        let tab = browser.current
        ZStack(alignment: .top) {
            TabHost(tabs: browser.tabs, current: tab)
            if let tab, tab.onNewTabPage {
                NewTabPage(browser: browser, tab: tab)
            }
            if let tab, tab.isLoading, !tab.onNewTabPage {
                ProgressView(value: max(0.05, tab.progress))
                    .progressViewStyle(.linear)
                    .tint(Duo.sun)
            }
        }
        .background(Duo.paper)
        .navigationTitle(tab?.onNewTabPage == false ? (tab?.displayTitle ?? "") : String(localized: "New Tab"))
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $query, isPresented: $searching, prompt: Text("Search or type URL"))
        .searchSuggestions { suggestions }
        .onSubmit(of: .search) {
            browser.go(query)
            searching = false
        }
        .task(id: query) { await fetchRemote() }
        .onChange(of: searching) { _, isSearching in
            if isSearching {
                let current = browser.current
                query = current?.onNewTabPage == false ? (current?.displayURL?.absoluteString ?? "") : ""
            }
        }
        .onChange(of: browser.focusRequest) { searching = true }
        .toolbar {
            ToolbarItemGroup(placement: .navigation) {
                Button("Back", systemImage: "chevron.backward") { goBack() }
                    .disabled(!canGoBack)
                Button("Forward", systemImage: "chevron.forward") { tab?.webView.goForward() }
                    .disabled(!(tab?.canGoForward ?? false))
            }
            ToolbarItem(placement: .topBarPinnedTrailing) {
                Button("Cover", systemImage: "eye.slash") { hidden = true }
                    .accessibilityHint(Text("Shows the pages of the book on the outer screen"))
            }
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button("Tabs", systemImage: "square.on.square") {
                    Task {
                        await browser.current?.refreshSnapshot()
                        showingTabs = true
                    }
                }
                .badge(tabCount)
                if let tab, !tab.onNewTabPage {
                    Button(tab.isLoading ? "Stop" : "Reload",
                           systemImage: tab.isLoading ? "xmark" : "arrow.clockwise") {
                        if tab.isLoading { tab.webView.stopLoading() } else { tab.webView.reload() }
                    }
                }
                if outerStatus.needsAction {
                    Button("Allow Camera", systemImage: "camera", action: onCamera)
                }
            }
            ToolbarOverflowMenu {
                Button("New Tab", systemImage: "plus.square") {
                    browser.newTab()
                    browser.focusRequest += 1
                }
                Button("New Incognito Tab", systemImage: "eyeglasses") {
                    browser.newTab(isPrivate: true)
                    browser.focusRequest += 1
                }
                if let tab, !tab.onNewTabPage, let url = tab.displayURL {
                    Button(browser.bookmarks.contains(url) ? "Remove Bookmark" : "Add to Bookmarks",
                           systemImage: browser.bookmarks.contains(url) ? "star.slash" : "star") {
                        browser.bookmarks.toggle(url: url, title: tab.title)
                    }
                    Button("Find in Page", systemImage: "doc.text.magnifyingglass") { browser.findInPage() }
                    Button(tab.isDesktop ? "Request Mobile Site" : "Request Desktop Site",
                           systemImage: tab.isDesktop ? "iphone" : "desktopcomputer") { browser.toggleDesktop() }
                    Button("Copy Link", systemImage: "doc.on.doc") { UIPasteboard.general.url = url }
                    Button("Share…", systemImage: "square.and.arrow.up") { Share.present([url]) }
                }
                Button("Settings", systemImage: "gearshape") { sheet = .settings }
            }
        }
        .fullScreenCover(isPresented: $showingTabs) {
            TabGrid(browser: browser)
        }
        .sheet(item: $sheet) { which in
            switch which {
            case .history: HistoryList(browser: browser)
            case .bookmarks: BookmarkList(browser: browser)
            case .settings: BrowserSettings(browser: browser)
            }
        }
    }

    // MARK: Search suggestions

    @ViewBuilder
    private var suggestions: some View {
        let typed = query.trimmingCharacters(in: .whitespaces)
        if typed.isEmpty || typed == browser.current?.displayURL?.absoluteString {
            ForEach(Array(browser.history.visits.prefix(8))) { v in
                Button { open(v.url) } label: {
                    Label(v.title.isEmpty ? v.url : v.title, systemImage: "clock")
                }
            }
        } else {
            if let url = Browser.url(from: typed, engine: browser.engine), url.host() != nil,
               !(url.absoluteString.contains("search?") || url.absoluteString.contains("/s?wd=")) {
                Button { open(url.absoluteString) } label: { Label(url.absoluteString, systemImage: "globe") }
            }
            ForEach(browser.bookmarks.matches(typed)) { b in
                Button { open(b.url) } label: { Label(b.title, systemImage: "star") }
            }
            ForEach(browser.history.matches(typed)) { v in
                Button { open(v.url) } label: { Label(v.title.isEmpty ? v.url : v.title, systemImage: "clock") }
            }
            ForEach(remote.filter { $0 != typed }, id: \.self) { s in
                Button { search(s) } label: { Label(s, systemImage: "magnifyingglass") }
            }
        }
    }

    private func fetchRemote() async {
        let typed = query.trimmingCharacters(in: .whitespaces)
        guard searching, !typed.isEmpty else { remote = []; return }
        try? await Task.sleep(for: .milliseconds(160))
        guard !Task.isCancelled else { return }
        let found = await Suggestions.fetch(typed, engine: browser.engine)
        if !Task.isCancelled { remote = found }
    }

    private func open(_ s: String) {
        if let url = URL(string: s) { browser.load(url) }
        searching = false
    }

    private func search(_ q: String) {
        if let url = browser.engine.searchURL(q) { browser.load(url) }
        searching = false
    }

    // MARK: Navigation

    private var tabCount: Int {
        browser.current?.isPrivate == true ? browser.privateTabs.count : browser.normalTabs.count
    }

    private var canGoBack: Bool {
        guard let tab = browser.current else { return false }
        return tab.canGoBack || (tab.onNewTabPage && tab.url != nil)
    }

    private func goBack() {
        guard let tab = browser.current else { return }
        if tab.onNewTabPage, tab.url != nil { tab.onNewTabPage = false } else { tab.webView.goBack() }
    }
}

enum BrowserSheet: String, Identifiable {
    case history, bookmarks, settings
    var id: String { rawValue }
}

/// What the outer screen is doing, for the status line in the shelf.
struct OuterStatusInfo {
    let color: Color
    let message: String
    /// Something you can fix (camera permission).
    let needsAction: Bool
}

struct TabCount: View {
    let count: Int

    var body: some View {
        Text(count > 99 ? ":D" : "\(count)")
            .font(.system(size: 12, weight: .bold).monospacedDigit())
            .frame(width: 22, height: 22)
            .overlay(RoundedRectangle(cornerRadius: 5).stroke(lineWidth: 1.5))
    }
}

// MARK: - Web view host

/// Holds every tab's web view and shows only the current one. Web views stay
/// in the window the whole time: pulling one out mid-touch can leave WebKit
/// waiting for a touch that never ends, which blocks every tap in the app.
struct TabHost: UIViewRepresentable {
    let tabs: [BrowserTab]
    let current: BrowserTab?

    /// Sizes every web view it holds to fill it, on every layout pass, so a
    /// web view the system took away and handed back is never left at the
    /// wrong size.
    final class Container: UIView {
        override func layoutSubviews() {
            super.layoutSubviews()
            for view in subviews where view.frame != bounds { view.frame = bounds }
        }
    }

    func makeUIView(context: Context) -> UIView {
        let container = Container()
        container.clipsToBounds = true
        return container
    }

    func updateUIView(_ container: UIView, context: Context) {
        let wanted = Set(tabs.map { ObjectIdentifier($0.webView) })
        for view in container.subviews where !wanted.contains(ObjectIdentifier(view)) {
            view.removeFromSuperview()
        }
        // Leave a web view alone while it is in full screen; it comes back
        // on exit.
        for tab in tabs where tab.webView.superview !== container
            && tab.webView.fullscreenState == .notInFullscreen {
            let web = tab.webView
            web.removeFromSuperview()
            web.translatesAutoresizingMaskIntoConstraints = true
            web.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            web.frame = container.bounds
            container.addSubview(web)
        }
        for tab in tabs where tab.webView.superview === container {
            let visible = tab.id == current?.id && !tab.onNewTabPage
            tab.webView.isHidden = !visible
            if visible { container.bringSubviewToFront(tab.webView) }
        }
        container.setNeedsLayout()
    }
}
