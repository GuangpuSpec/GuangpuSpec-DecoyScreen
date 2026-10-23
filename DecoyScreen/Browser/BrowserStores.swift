import Foundation
import Observation

// MARK: - Search engine

enum SearchEngine: String, CaseIterable, Identifiable, Codable {
    case google, baidu, bing

    var id: String { rawValue }

    var name: String {
        switch self {
        case .google: "Google"
        case .baidu: String(localized: "Baidu")
        case .bing: "Bing"
        }
    }

    func searchURL(_ query: String) -> URL? {
        let q = query.addingPercentEncoding(withAllowedCharacters: .urlQueryValueAllowed) ?? query
        return switch self {
        case .google: URL(string: "https://www.google.com/search?q=\(q)")
        case .baidu: URL(string: "https://www.baidu.com/s?wd=\(q)")
        case .bing: URL(string: "https://www.bing.com/search?q=\(q)")
        }
    }

    /// OpenSearch suggestion endpoints: they all answer `[query, [suggestions…]]`.
    func suggestURL(_ query: String) -> URL? {
        let q = query.addingPercentEncoding(withAllowedCharacters: .urlQueryValueAllowed) ?? query
        return switch self {
        case .google: URL(string: "https://suggestqueries.google.com/complete/search?client=firefox&q=\(q)")
        case .baidu: URL(string: "https://suggestion.baidu.com/su?action=opensearch&ie=utf-8&wd=\(q)")
        case .bing: URL(string: "https://api.bing.com/osjson.aspx?query=\(q)")
        }
    }

    static var localDefault: SearchEngine {
        Locale.current.language.languageCode == .chinese ? .baidu : .google
    }
}

extension CharacterSet {
    static let urlQueryValueAllowed: CharacterSet = {
        var set = CharacterSet.urlQueryAllowed
        set.remove(charactersIn: "&=+?#")
        return set
    }()
}

enum Suggestions {
    /// Search suggestions from the engine; empty on any failure.
    static func fetch(_ query: String, engine: SearchEngine) async -> [String] {
        guard let url = engine.suggestURL(query) else { return [] }
        var request = URLRequest(url: url, timeoutInterval: 3)
        request.setValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")
        guard let (data, _) = try? await URLSession.shared.data(for: request) else { return [] }
        // Baidu may answer in GBK despite ie=utf-8; try both.
        let text = String(data: data, encoding: .utf8)
            ?? String(data: data, encoding: String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(CFStringEncodings.GB_18030_2000.rawValue))))
        guard let text, let json = try? JSONSerialization.jsonObject(with: Data(text.utf8)) as? [Any],
              json.count > 1, let list = json[1] as? [String] else { return [] }
        return Array(list.prefix(6))
    }
}

// MARK: - History

struct Visit: Codable, Identifiable, Hashable {
    var id = UUID()
    var url: String
    var title: String
    var date: Date
}

@MainActor
@Observable
final class HistoryStore {
    private(set) var visits: [Visit] = []
    @ObservationIgnored private let file: URL

    init() {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        file = dir.appendingPathComponent("history.json")
        if let data = try? Data(contentsOf: file),
           let saved = try? JSONDecoder().decode([Visit].self, from: data) {
            visits = saved
        }
    }

    func record(url: URL, title: String) {
        guard let scheme = url.scheme, scheme.hasPrefix("http") else { return }
        let s = url.absoluteString
        if let first = visits.first, first.url == s {
            visits[0].title = title.isEmpty ? first.title : title
            visits[0].date = .now
        } else {
            visits.insert(Visit(url: s, title: title, date: .now), at: 0)
            if visits.count > 3000 { visits.removeLast(visits.count - 3000) }
        }
        save()
    }

    func updateTitle(url: URL, title: String) {
        guard !title.isEmpty, let i = visits.firstIndex(where: { $0.url == url.absoluteString }), i < 5 else { return }
        visits[i].title = title
        save()
    }

    func delete(_ visit: Visit) {
        visits.removeAll { $0.id == visit.id }
        save()
    }

    func clear() {
        visits = []
        save()
    }

    /// Visits whose title or address contains the text.
    func matches(_ text: String, limit: Int = 3) -> [Visit] {
        guard !text.isEmpty else { return [] }
        var seen = Set<String>()
        var out: [Visit] = []
        for v in visits where v.url.localizedCaseInsensitiveContains(text) || v.title.localizedCaseInsensitiveContains(text) {
            if seen.insert(v.url).inserted { out.append(v) }
            if out.count == limit { break }
        }
        return out
    }

    /// The sites you go to most, one tile per site.
    func mostVisited(limit: Int = 8) -> [Visit] {
        var counts: [String: Int] = [:]
        var latest: [String: Visit] = [:]
        for v in visits {
            guard let host = URL(string: v.url)?.host() else { continue }
            counts[host, default: 0] += 1
            if latest[host] == nil { latest[host] = v }
        }
        return counts.sorted { $0.value > $1.value }
            .prefix(limit)
            .compactMap { latest[$0.key] }
    }

    private func save() {
        let snapshot = visits
        let file = file
        Task.detached(priority: .utility) {
            if let data = try? JSONEncoder().encode(snapshot) { try? data.write(to: file, options: .atomic) }
        }
    }
}

// MARK: - Bookmarks

struct Bookmark: Codable, Identifiable, Hashable {
    var id = UUID()
    var title: String
    var url: String
}

@MainActor
@Observable
final class BookmarkStore {
    private(set) var items: [Bookmark] {
        didSet {
            if let data = try? JSONEncoder().encode(items) { UserDefaults.standard.set(data, forKey: "bookmarks") }
        }
    }

    static let starters: [Bookmark] = [
        Bookmark(title: String(localized: "Bilibili"), url: "https://www.bilibili.com/"),
        Bookmark(title: "YouTube", url: "https://www.youtube.com/"),
        Bookmark(title: String(localized: "Xiaohongshu"), url: "https://www.xiaohongshu.com/explore"),
        Bookmark(title: String(localized: "Douyin"), url: "https://www.douyin.com/"),
        Bookmark(title: String(localized: "Weibo"), url: "https://weibo.com/"),
        Bookmark(title: String(localized: "Zhihu"), url: "https://www.zhihu.com/"),
    ]

    init() {
        if let data = UserDefaults.standard.data(forKey: "bookmarks"),
           let saved = try? JSONDecoder().decode([Bookmark].self, from: data) {
            items = saved
        } else {
            items = Self.starters
        }
    }

    func contains(_ url: URL?) -> Bool {
        guard let url else { return false }
        return items.contains { $0.url == url.absoluteString }
    }

    func toggle(url: URL, title: String) {
        if contains(url) {
            items.removeAll { $0.url == url.absoluteString }
        } else {
            items.insert(Bookmark(title: title.isEmpty ? (url.host() ?? url.absoluteString) : title,
                                  url: url.absoluteString), at: 0)
        }
    }

    func delete(_ b: Bookmark) { items.removeAll { $0.id == b.id } }

    func matches(_ text: String, limit: Int = 2) -> [Bookmark] {
        guard !text.isEmpty else { return [] }
        return Array(items.filter { $0.url.localizedCaseInsensitiveContains(text) || $0.title.localizedCaseInsensitiveContains(text) }.prefix(limit))
    }
}
