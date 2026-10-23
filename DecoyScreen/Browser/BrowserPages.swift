import DuoKit
import SwiftUI
import WebKit

// MARK: - New tab page

struct NewTabPage: View {
    let browser: Browser
    let tab: BrowserTab

    var body: some View {
        if tab.isPrivate {
            incognito
        } else {
            normal
        }
    }

    private var tiles: [(title: String, url: String)] {
        var out: [(String, String)] = browser.history.mostVisited(limit: 8).map { v in
            (Self.shortTitle(v.title, url: v.url), v.url)
        }
        // Fill the grid with bookmarks until there's enough history.
        for b in browser.bookmarks.items where out.count < 8 {
            let host = URL(string: b.url)?.host()
            if !out.contains(where: { URL(string: $0.1)?.host() == host }) { out.append((b.title, b.url)) }
        }
        return out
    }

    private var normal: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Duo.Space.xl) {
                if tiles.isEmpty {
                    Text("Search or type a web address to begin.")
                        .font(DuoType.callout)
                        .foregroundStyle(Duo.ink3)
                } else {
                    VStack(alignment: .leading, spacing: Duo.Space.m) {
                        SectionHeading("Frequently visited")
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 84), spacing: Duo.Space.l)],
                                  alignment: .leading, spacing: Duo.Space.xl) {
                            ForEach(tiles, id: \.url) { tile in
                                Button {
                                    if let u = URL(string: tile.url) { browser.load(u, in: tab) }
                                } label: {
                                    VStack(spacing: Duo.Space.s) {
                                        Favicon(url: URL(string: tile.url), size: 28)
                                            .frame(width: 60, height: 60)
                                            .background(Duo.raised, in: .rect(cornerRadius: 16))
                                        Text(tile.title)
                                            .font(DuoType.footnote)
                                            .foregroundStyle(Duo.ink)
                                            .lineLimit(1)
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
            .padding(Duo.Space.xl)
            .frame(maxWidth: 640, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Duo.paper)
    }

    private var incognito: some View {
        VStack(alignment: .leading, spacing: Duo.Space.m) {
            Text("You're Incognito")
                .font(DuoType.title2)
                .foregroundStyle(Duo.ink)
            Text("Pages you open in incognito tabs aren't saved to your history, and their cookies and site data are wiped when you close your last incognito tab.")
                .font(DuoType.callout)
                .foregroundStyle(Duo.ink2)
                .frame(maxWidth: 520, alignment: .leading)
        }
        .padding(Duo.Space.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Duo.paper)
        .environment(\.colorScheme, .dark)
    }

    static func shortTitle(_ title: String, url: String) -> String {
        let cut = title.split(whereSeparator: { "-|_–—·".contains($0) }).first.map(String.init)?
            .trimmingCharacters(in: .whitespaces) ?? ""
        if !cut.isEmpty, cut.count <= 14 { return cut }
        var host = URL(string: url)?.host() ?? url
        for p in ["www.", "m."] where host.hasPrefix(p) { host.removeFirst(p.count) }
        return host
    }
}

/// A site's icon, or its first letter.
struct Favicon: View {
    let url: URL?
    var size: CGFloat = 20

    var body: some View {
        let host = url?.host() ?? ""
        AsyncImage(url: URL(string: "https://\(host)/favicon.ico")) { phase in
            if let image = phase.image {
                image.resizable().interpolation(.high).scaledToFit()
            } else {
                Text(String(host.replacingOccurrences(of: "www.", with: "").replacingOccurrences(of: "m.", with: "").prefix(1)).uppercased())
                    .font(.system(size: size * 0.6, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(width: size, height: size)
                    .background(Self.color(for: host), in: .circle)
            }
        }
        .frame(width: size, height: size)
    }

    static func color(for host: String) -> Color {
        let hues: [Double] = [0.0, 0.08, 0.15, 0.33, 0.5, 0.58, 0.68, 0.8, 0.9]
        let h = host.unicodeScalars.reduce(0) { ($0 &* 31 &+ Int($1.value)) & 0xffff }
        return Color(hue: hues[h % hues.count], saturation: 0.55, brightness: 0.75)
    }
}

// MARK: - Tab grid

struct TabGrid: View {
    let browser: Browser
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorSchemeDefault
    @State private var incognito: Bool
    @State private var confirmCloseAll = false

    init(browser: Browser) {
        self.browser = browser
        _incognito = State(initialValue: browser.current?.isPrivate ?? false)
    }

    var body: some View {
        let tabs = incognito ? browser.privateTabs : browser.normalTabs
        NavigationStack {
            GeometryReader { geo in
                ScrollView {
                    if tabs.isEmpty {
                        ContentUnavailableView(incognito ? "No incognito tabs" : "No open tabs",
                                               systemImage: incognito ? "eyeglasses" : "square.on.square")
                            .padding(.top, 80)
                    } else {
                        LazyVGrid(columns: columns(for: geo.size.width), spacing: Duo.Space.xl) {
                            ForEach(tabs) { tab in
                                TabCard(tab: tab, selected: tab.id == browser.current?.id) {
                                    browser.select(tab)
                                    dismiss()
                                } onClose: {
                                    withAnimation { browser.close(tab) }
                                }
                            }
                        }
                        .padding(Duo.Space.l)
                    }
                }
            }
            .background(incognito ? Color(white: 0.1) : Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Picker("Tabs", selection: $incognito) {
                        Label("Incognito", systemImage: "eyeglasses").labelStyle(.iconOnly).tag(true)
                        Text(verbatim: "\(browser.normalTabs.count)").tag(false)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 140)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", systemImage: "checkmark") { dismiss() }
                }
                ToolbarItem(placement: .topBarPinnedTrailing) {
                    Button("New Tab", systemImage: "plus") {
                        browser.newTab(isPrivate: incognito)
                        dismiss()
                        browser.focusRequest += 1
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close All", systemImage: "xmark.square", role: .destructive) { confirmCloseAll = true }
                        .disabled(tabs.isEmpty)
                }
            }
            .confirmationDialog(incognito ? "Close all incognito tabs?" : "Close all tabs?",
                                isPresented: $confirmCloseAll, titleVisibility: .visible) {
                Button("Close All", role: .destructive) {
                    withAnimation { browser.closeAll(isPrivate: incognito) }
                }
            }
        }
        .environment(\.colorScheme, incognito ? .dark : colorSchemeDefault)
    }

    /// An even number of columns, so the fold falls between cards.
    private func columns(for width: CGFloat) -> [GridItem] {
        let fit = Int((width - Duo.Space.l * 2) / 200)
        let count = max(2, fit - fit % 2)
        return Array(repeating: GridItem(.flexible(), spacing: Duo.Space.l, alignment: .top), count: count)
    }
}

/// One tab: the page preview, then its title. Tap to open.
private struct TabCard: View {
    let tab: BrowserTab
    let selected: Bool
    let onOpen: () -> Void
    let onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Duo.Space.s) {
            // The preview's size is set by the card, never by the image: the
            // snapshot fills it from the top and is cropped to it.
            Color(.secondarySystemBackground)
                .aspectRatio(4 / 3, contentMode: .fit)
                .overlay(alignment: .top) {
                    if let image = tab.snapshot, !tab.onNewTabPage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    } else {
                        Favicon(url: tab.displayURL, size: 40)
                            .opacity(tab.onNewTabPage ? 0 : 1)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .clipShape(.rect(cornerRadius: 14))
                .overlay {
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(selected ? Color.accentColor : Color(.separator),
                                      lineWidth: selected ? 3 : 0.5)
                }
                .overlay(alignment: .topTrailing) {
                    Button("Close Tab", systemImage: "xmark", action: onClose)
                        .labelStyle(.iconOnly)
                        .font(.system(size: 12, weight: .bold))
                        .buttonStyle(.glass)
                        .buttonBorderShape(.circle)
                        .controlSize(.small)
                        .padding(Duo.Space.s)
                }

            HStack(spacing: 6) {
                if tab.onNewTabPage {
                    Image(systemName: tab.isPrivate ? "eyeglasses" : "globe")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Favicon(url: tab.displayURL, size: 16)
                }
                Text(tab.onNewTabPage ? String(localized: "New Tab") : tab.displayTitle)
                    .font(.footnote.weight(selected ? .semibold : .regular))
                    .lineLimit(1)
            }
            .padding(.horizontal, 2)
        }
        .contentShape(.rect)
        .onTapGesture(perform: onOpen)
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

// MARK: - Menu

// MARK: - History

struct HistoryList: View {
    let browser: Browser
    /// Set when shown as a tab: called after a visit is opened, and no Done.
    var onOpen: (() -> Void)?
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @State private var confirmClear = false

    var body: some View {
        let visits = query.isEmpty ? browser.history.visits
            : browser.history.visits.filter { $0.title.localizedCaseInsensitiveContains(query) || $0.url.localizedCaseInsensitiveContains(query) }
        let days = Dictionary(grouping: visits.prefix(600)) { Calendar.current.startOfDay(for: $0.date) }
            .sorted { $0.key > $1.key }
        NavigationStack {
            List {
                if visits.isEmpty {
                    Text("No history yet").foregroundStyle(.secondary)
                }
                ForEach(days, id: \.key) { day, items in
                    Section(Self.dayTitle(day)) {
                        ForEach(items) { v in
                            Button {
                                if let u = URL(string: v.url) { browser.load(u) }
                                if let onOpen { onOpen() } else { dismiss() }
                            } label: {
                                HStack(spacing: 12) {
                                    Favicon(url: URL(string: v.url), size: 22)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(v.title.isEmpty ? v.url : v.title).lineLimit(1).foregroundStyle(.primary)
                                        Text(v.url).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                                    }
                                    Spacer(minLength: 0)
                                    Text(v.date, style: .time).font(.caption2).foregroundStyle(.secondary)
                                }
                            }
                            .swipeActions { Button("Delete", role: .destructive) { browser.history.delete(v) } }
                        }
                    }
                }
            }
            .searchable(text: $query, prompt: "Search History")
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(onOpen == nil ? .inline : .automatic)
            .toolbar {
                if onOpen == nil {
                    ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Clear History", systemImage: "trash", role: .destructive) { confirmClear = true }
                        .disabled(browser.history.visits.isEmpty)
                }
            }
            .confirmationDialog("Clear all browsing history?", isPresented: $confirmClear, titleVisibility: .visible) {
                Button("Clear History", role: .destructive) { browser.history.clear() }
            }
        }
    }

    static func dayTitle(_ day: Date) -> String {
        if Calendar.current.isDateInToday(day) { return String(localized: "Today") }
        if Calendar.current.isDateInYesterday(day) { return String(localized: "Yesterday") }
        return day.formatted(date: .complete, time: .omitted)
    }
}

// MARK: - Bookmarks

struct BookmarkList: View {
    let browser: Browser
    /// Set when shown as a tab: called after a bookmark is opened, and no Done.
    var onOpen: (() -> Void)?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                if browser.bookmarks.items.isEmpty {
                    Text("No bookmarks yet. Tap ⋯ › Add to Bookmarks on any page.").foregroundStyle(.secondary)
                }
                ForEach(browser.bookmarks.items) { b in
                    Button {
                        if let u = URL(string: b.url) { browser.load(u) }
                        if let onOpen { onOpen() } else { dismiss() }
                    } label: {
                        HStack(spacing: 12) {
                            Favicon(url: URL(string: b.url), size: 22)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(b.title).lineLimit(1).foregroundStyle(.primary)
                                Text(b.url).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                            }
                        }
                    }
                    .swipeActions { Button("Delete", role: .destructive) { browser.bookmarks.delete(b) } }
                }
            }
            .navigationTitle("Bookmarks")
            .navigationBarTitleDisplayMode(onOpen == nil ? .inline : .automatic)
            .toolbar {
                if onOpen == nil {
                    ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
                }
            }
        }
    }
}

// MARK: - Settings

struct BrowserSettings: View {
    @Bindable var browser: Browser
    @Environment(\.dismiss) private var dismiss
    @State private var cleared = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Search Engine") {
                    Picker("Search Engine", selection: $browser.engine) {
                        ForEach(SearchEngine.allCases) { Text($0.name).tag($0) }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }
                Section {
                    Toggle("iPad Version of Websites", isOn: $browser.desktopByDefault)
                } footer: {
                    Text("Sends the iPad user agent so sites show their full pages, like Safari and Chrome on iPad. Applies to new tabs; change one page with ⋯ › Request Mobile Site.")
                }
                Section {
                    Button("Clear Cookies and Site Data", role: .destructive) {
                        WKWebsiteDataStoreHelper.clearAll()
                        cleared = true
                    }
                } footer: {
                    Text(cleared ? String(localized: "Done. You'll be signed out of websites.")
                                 : String(localized: "Signs you out of every website you've logged in to here."))
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
        }
    }
}

enum WKWebsiteDataStoreHelper {
    @MainActor
    static func clearAll() {
        let store = WKWebsiteDataStore.default()
        store.removeData(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(), modifiedSince: .distantPast) {}
    }
}
