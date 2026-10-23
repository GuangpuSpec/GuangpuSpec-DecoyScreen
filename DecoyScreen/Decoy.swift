import Foundation
import Observation
import SwiftUI

/// Picks the English or Chinese text, following the app's language.
func tr(_ en: String, _ zh: String) -> String {
    (Bundle.main.preferredLocalizations.first ?? "en").hasPrefix("zh") ? zh : en
}

/// The chosen cover, saved between launches.
@MainActor
@Observable
final class DecoyStore {
    static let shared = DecoyStore()

    var bookID: String {
        didSet { defaults.set(bookID, forKey: "book") }
    }

    /// The page you were on in each book, so the cover reopens where you left it.
    var pageIndex: [String: Int] {
        didSet { defaults.set(pageIndex, forKey: "pages") }
    }

    /// Whether the outer screen shows the cover while you use the inner one.
    var showOnOuter: Bool {
        didSet { defaults.set(showOnOuter, forKey: "showOnOuter") }
    }

    /// What the outer screen shows: a book cover, or your own text.
    var outerSource: OuterSource {
        didSet { defaults.set(outerSource.rawValue, forKey: "outerSource") }
    }

    /// Your text for the outer screen, e.g. "In a meeting".
    var signText: String {
        didSet { defaults.set(signText, forKey: "signText") }
    }

    var signStyle: SignStyle {
        didSet { defaults.set(signStyle.rawValue, forKey: "signStyle") }
    }

    var book: Book { Catalog.book(bookID) }

    @ObservationIgnored private let defaults = UserDefaults.standard

    private init() {
        bookID = defaults.string(forKey: "book") ?? Catalog.all[0].id
        pageIndex = defaults.dictionary(forKey: "pages") as? [String: Int] ?? [:]
        showOnOuter = defaults.object(forKey: "showOnOuter") as? Bool ?? true
        outerSource = OuterSource(rawValue: defaults.string(forKey: "outerSource") ?? "") ?? .book
        signText = defaults.string(forKey: "signText") ?? tr("In a meeting", "会议中")
        signStyle = SignStyle(rawValue: defaults.string(forKey: "signStyle") ?? "") ?? .titleCard
    }
}

enum OuterSource: String {
    case book, text
}

/// Looks for the outer-screen text: dramatic title cards. Heavy Songti type,
/// squeezed narrow and set flush left, lines in mixed sizes, thin rules and
/// small labels, on black.
enum SignStyle: String, CaseIterable, Identifiable {
    /// White type on black, like a film title card.
    case titleCard
    /// Black type on white.
    case daylight
    /// Orange type between hazard stripes, over a hex grid.
    case warning
    /// White type on deep red, flashing frame.
    case emergency
    /// Green type on a scan-line monitor.
    case monitor

    var id: String { rawValue }

    var name: String {
        switch self {
        case .titleCard: tr("Title card", "标题卡")
        case .daylight: tr("Daylight", "白昼")
        case .warning: tr("Warning", "警报")
        case .emergency: tr("Emergency", "紧急")
        case .monitor: tr("Monitor", "监视")
        }
    }

    /// The small label above the text.
    var label: String {
        switch self {
        case .titleCard, .daylight: "现在状态"
        case .warning: "警告"
        case .emergency: "紧急通告"
        case .monitor: "状态监视中"
        }
    }

    var background: Color {
        switch self {
        case .titleCard: Color(red: 0.02, green: 0.02, blue: 0.02)
        case .daylight: Color(red: 0.96, green: 0.95, blue: 0.93)
        case .warning: Color(red: 0.05, green: 0.04, blue: 0.03)
        case .emergency: Color(red: 0.55, green: 0.02, blue: 0.04)
        case .monitor: Color(red: 0.01, green: 0.05, blue: 0.03)
        }
    }

    var foreground: Color {
        switch self {
        case .titleCard, .emergency: Color(red: 0.97, green: 0.96, blue: 0.94)
        case .daylight: Color(red: 0.05, green: 0.05, blue: 0.05)
        case .warning: Color(red: 1.0, green: 0.42, blue: 0.0)
        case .monitor: Color(red: 0.36, green: 1.0, blue: 0.55)
        }
    }

    /// Rules, labels and patterns.
    var detail: Color {
        switch self {
        case .titleCard: Color(red: 0.86, green: 0.1, blue: 0.12)
        case .daylight: Color(red: 0.75, green: 0.06, blue: 0.08)
        case .warning: Color(red: 1.0, green: 0.42, blue: 0.0)
        case .emergency: Color(red: 1.0, green: 0.86, blue: 0.0)
        case .monitor: Color(red: 0.36, green: 1.0, blue: 0.55)
        }
    }
}

/// Text that fills the outer screen as a title card. The colour runs edge to
/// edge; the type stays inside the safe area, clear of the camera.
///
/// Type: the first line is the headline, as big as it can be while fitting,
/// squeezed to 80% width the way film title cards are; further lines (after
/// a line break or a space) are set smaller beneath it.
struct OuterSign: View {
    let text: String
    let style: SignStyle

    /// Heavy Song (Songti-style) type, the classic title-card face: the
    /// bundled Noto Serif SC Black.
    private func type(_ size: CGFloat) -> Font {
        .custom(OuterSign.typeface, size: size)
    }

    static let typeface = "NotoSerifSC-Black"

    private var parts: (head: String, rest: String) {
        let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
        // A typed line break always splits. A space splits only in Chinese
        // ("专注中 请勿打扰"), never inside an English phrase.
        let chinese = t.unicodeScalars.contains { $0.value >= 0x2E80 }
        let space = chinese ? (t.range(of: " ") ?? t.range(of: "　")) : nil
        if let r = t.rangeOfCharacter(from: .newlines) ?? space {
            return (String(t[..<r.lowerBound]),
                    t[r.upperBound...].trimmingCharacters(in: .whitespacesAndNewlines))
        }
        return (t, "")
    }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            let size = min(w, h)
            let pad = size * 0.09
            // Drawn edge to edge; the lettering keeps clear of the camera and
            // any other system area.
            let inset = geo.safeAreaInsets
            ZStack(alignment: .topLeading) {
                style.background
                Decoration(style: style)
                VStack(alignment: .leading, spacing: 0) {
                    // Label and rule.
                    HStack(spacing: size * 0.025) {
                        Rectangle().fill(style.detail).frame(width: size * 0.018, height: size * 0.06)
                        Text(verbatim: style.label)
                            .font(type(size * 0.05))
                            .tracking(size * 0.012)
                            .foregroundStyle(style.detail)
                    }
                    Rectangle().fill(style.foreground.opacity(0.85))
                        .frame(width: size * 0.42, height: max(1, size * 0.004))
                        .padding(.top, size * 0.03)
                    Spacer(minLength: size * 0.04)
                    squeezed(parts.head, size: size * 0.42, width: w - pad * 2 - inset.leading - inset.trailing,
                             lines: OuterSign.lines(for: parts.head))
                    if !parts.rest.isEmpty {
                        squeezed(parts.rest, size: size * 0.16, width: w - pad * 2 - inset.leading - inset.trailing,
                                 lines: OuterSign.lines(for: parts.rest) + 1)
                            .padding(.top, size * 0.03)
                    }
                    Spacer(minLength: size * 0.04)
                    // Foot: a thin rule, then the time, small.
                    HStack(alignment: .lastTextBaseline) {
                        Rectangle().fill(style.foreground.opacity(0.5))
                            .frame(height: max(0.5, size * 0.002))
                        TimelineView(.periodic(from: .now, by: 30)) { context in
                            Text(context.date, format: .dateTime.month(.twoDigits).day(.twoDigits).hour().minute())
                                .font(.system(size: size * 0.04, weight: .semibold, design: .serif).monospacedDigit())
                                .foregroundStyle(style.foreground.opacity(0.7))
                        }
                        .fixedSize()
                    }
                }
                .padding(EdgeInsets(top: pad + inset.top, leading: pad + inset.leading,
                                    bottom: pad + inset.bottom, trailing: pad + inset.trailing))
                .padding(.vertical, style == .warning ? size * 0.07 : 0)
            }
            .frame(width: w, height: h)
        }
        .accessibilityElement()
        .accessibilityLabel(text)
    }

    /// Type laid out at 125% width, then squeezed to 80%: narrow, tall letters.
    private func squeezed(_ s: String, size: CGFloat, width: CGFloat, lines: Int) -> some View {
        let squeeze: CGFloat = 0.8
        return Text(s.isEmpty ? " " : s)
            .font(type(size))
            .foregroundStyle(style.foreground)
            .lineLimit(lines)
            .minimumScaleFactor(0.08)
            .lineSpacing(-size * 0.05)
            .frame(width: width / squeeze, alignment: .leading)
            .scaleEffect(x: squeeze, y: 1, anchor: .leading)
            .frame(width: width, alignment: .leading)
            .shadow(color: style == .monitor ? style.foreground.opacity(0.6) : .clear, radius: size * 0.02)
    }

    /// How many lines the text may use. Short text stays on one line and
    /// shrinks to fit, so "会议中" never breaks as "会议 / 中"; longer text
    /// wraps. Lines you typed yourself are always kept.
    static func lines(for text: String) -> Int {
        let typed = text.split(separator: "\n", omittingEmptySubsequences: false).count
        // A Chinese character is about as wide as two Latin letters.
        let width = text.unicodeScalars.reduce(0.0) { sum, c in
            sum + (c.value >= 0x2E80 ? 1.0 : 0.55)
        }
        let wanted = width <= 6 ? 1 : width <= 14 ? 2 : width <= 26 ? 3 : 4
        return max(typed, wanted)
    }
}

/// The pattern behind the type for each look.
private struct Decoration: View {
    let style: SignStyle

    var body: some View {
        switch style {
        case .titleCard, .daylight:
            // A single red bar down the trailing edge.
            GeometryReader { geo in
                let s = min(geo.size.width, geo.size.height)
                style.detail.frame(width: s * 0.025)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
                    .padding(.vertical, s * 0.09)
                    .padding(.trailing, s * 0.04)
            }
        case .warning:
            ZStack {
                HexGrid(color: style.detail.opacity(0.12))
                VStack {
                    HazardStripes(color: style.detail)
                    Spacer()
                    HazardStripes(color: style.detail)
                }
            }
        case .emergency:
            GeometryReader { geo in
                let s = min(geo.size.width, geo.size.height)
                TimelineView(.periodic(from: .now, by: 0.8)) { context in
                    let on = Int(context.date.timeIntervalSinceReferenceDate / 0.8) % 2 == 0
                    Rectangle()
                        .strokeBorder(style.detail.opacity(on ? 1 : 0.25), lineWidth: s * 0.02)
                        .padding(s * 0.035)
                }
            }
        case .monitor:
            ZStack {
                HexGrid(color: style.detail.opacity(0.06))
                ScanLines(color: .black.opacity(0.35))
            }
        }
    }
}

/// Diagonal black-and-colour hazard band.
private struct HazardStripes: View {
    let color: Color

    var body: some View {
        GeometryReader { geo in
            let h = geo.size.height
            Canvas { gc, size in
                gc.fill(Path(CGRect(origin: .zero, size: size)), with: .color(color))
                let step = h * 1.1
                var x = -h
                while x < size.width + h {
                    var p = Path()
                    p.move(to: CGPoint(x: x, y: size.height))
                    p.addLine(to: CGPoint(x: x + h, y: 0))
                    p.addLine(to: CGPoint(x: x + h + step / 2, y: 0))
                    p.addLine(to: CGPoint(x: x + step / 2, y: size.height))
                    p.closeSubpath()
                    gc.fill(p, with: .color(.black))
                    x += step
                }
            }
        }
        .frame(height: 22)
        .accessibilityHidden(true)
    }
}

/// A faint grid of hexagons.
private struct HexGrid: View {
    let color: Color

    var body: some View {
        Canvas { gc, size in
            let r: CGFloat = max(14, min(size.width, size.height) * 0.05)
            let dx = r * 1.732, dy = r * 1.5
            var row = 0
            var y: CGFloat = 0
            while y < size.height + r {
                var x: CGFloat = row % 2 == 0 ? 0 : dx / 2
                while x < size.width + r {
                    var p = Path()
                    for i in 0..<6 {
                        let a = CGFloat(i) * .pi / 3 + .pi / 6
                        let pt = CGPoint(x: x + r * cos(a), y: y + r * sin(a))
                        if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
                    }
                    p.closeSubpath()
                    gc.stroke(p, with: .color(color), lineWidth: 1)
                    x += dx
                }
                y += dy
                row += 1
            }
        }
        .accessibilityHidden(true)
    }
}

/// Thin horizontal lines, like an old monitor.
private struct ScanLines: View {
    let color: Color

    var body: some View {
        Canvas { gc, size in
            var y: CGFloat = 0
            while y < size.height {
                gc.fill(Path(CGRect(x: 0, y: y, width: size.width, height: 1)), with: .color(color))
                y += 3
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
