import DuoKit
import SwiftUI

/// What the inner screen turns into when you tap Cover: the pages of the book
/// on the outer screen. Swipe to turn pages (content interaction); Close and
/// the page keys are system toolbar items.
struct BookReader: View {
    let book: Book
    @Binding var page: Int
    let onDone: () -> Void

    var body: some View {
        let pages = book.pages
        let index = min(max(0, page), pages.count - 1)
        NavigationStack {
            TabView(selection: Binding(get: { index }, set: { page = $0 })) {
                ForEach(Array(pages.enumerated()), id: \.offset) { i, p in
                    PageView(book: book, page: p, number: i + 1)
                        .padding(.horizontal, Duo.Space.xl)
                        .tag(i)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .background(Self.paper)
            .navigationTitle(book.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close", systemImage: "xmark", action: onDone)
                }
                ToolbarItemGroup(placement: .bottomBar) {
                    Button("Previous Page", systemImage: "chevron.up") { turn(-1) }
                        .disabled(index == 0)
                    Button("Next Page", systemImage: "chevron.down") { turn(1) }
                        .disabled(index >= pages.count - 1)
                }
            }
        }
        .environment(\.colorScheme, .light)
    }

    /// Book paper, slightly warmer than the app's.
    static let paper = Color(red: 0.97, green: 0.96, blue: 0.93)

    private func turn(_ delta: Int) {
        withAnimation(.easeOut(duration: 0.2)) {
            page = min(max(0, page + delta), book.pages.count - 1)
        }
    }
}

/// One printed page.
private struct PageView: View {
    let book: Book
    let page: BookPage
    let number: Int

    private let ink = Color(red: 0.13, green: 0.12, blue: 0.11)
    private let muted = Color(red: 0.42, green: 0.4, blue: 0.37)

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Running head
            HStack {
                Text(page.section)
                Spacer(minLength: 16)
                Text(book.title)
            }
            .font(.system(size: 12))
            .foregroundStyle(muted)
            .lineLimit(1)
            .padding(.bottom, 10)
            Rectangle().fill(muted.opacity(0.35)).frame(height: 0.5)
                .accessibilityHidden(true)

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(Array(page.blocks.enumerated()), id: \.offset) { _, block in
                        blockView(block)
                    }
                }
                .frame(maxWidth: 640, alignment: .leading)
                .padding(.vertical, 24)
            }
            .scrollIndicators(.hidden)

            Text(verbatim: "— \(number) —")
                .font(.system(size: 12))
                .foregroundStyle(muted)
                .frame(maxWidth: .infinity)
        }
        .foregroundStyle(ink)
        .padding(.top, 8)
    }

    @ViewBuilder
    private func blockView(_ block: PageBlock) -> some View {
        switch block {
        case .heading(let s):
            Text(s)
                .font(.system(size: 18, weight: .semibold, design: .serif))
                .padding(.top, 4)
        case .para(let s):
            Text(s)
                .font(.system(size: 17, design: .serif))
                .lineSpacing(7)
                .fixedSize(horizontal: false, vertical: true)
        case .formula(let s):
            Text(s)
                .font(.system(size: 18, design: .serif).italic())
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
        case .box(let title, let text):
            VStack(alignment: .leading, spacing: 6) {
                Text(title).font(.system(size: 15, weight: .bold))
                Text(text).font(.system(size: 16, design: .serif)).lineSpacing(6)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 14)
            .overlay(alignment: .leading) {
                Rectangle().fill(book.accent == .white ? ink : accentOnPaper).frame(width: 2)
            }
        case .bullets(let items):
            VStack(alignment: .leading, spacing: 8) {
                ForEach(items, id: \.self) { item in
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        Text(verbatim: "•")
                        Text(item).fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .font(.system(size: 17, design: .serif))
            .lineSpacing(5)
        case .table(let rows):
            TableBlock(rows: rows, ink: ink, rule: muted)
        case .note(let s):
            Text(s)
                .font(.system(size: 13))
                .foregroundStyle(muted)
        }
    }

    /// A cover colour that reads on paper: the cover field when the cover is
    /// dark (light type on it), the accent otherwise.
    private var accentOnPaper: Color {
        var white: CGFloat = 0
        UIColor(book.ink).getWhite(&white, alpha: nil)
        return white > 0.6 ? book.base : book.accent
    }
}

private struct TableBlock: View {
    let rows: [[String]]
    let ink: Color
    let rule: Color

    var body: some View {
        let cols = rows.map(\.count).max() ?? 0
        Grid(alignment: .leading, horizontalSpacing: 20, verticalSpacing: 0) {
            ForEach(Array(rows.enumerated()), id: \.offset) { r, row in
                GridRow {
                    ForEach(0..<cols, id: \.self) { col in
                        Text(col < row.count ? row[col] : "")
                            .font(.system(size: 15, weight: r == 0 ? .semibold : .regular).monospacedDigit())
                            .gridColumnAlignment(col == 0 ? .leading : .trailing)
                            .padding(.vertical, 8)
                    }
                }
                if r == 0 || r == rows.count - 1 {
                    Rectangle().fill(rule.opacity(r == 0 ? 0.6 : 0.3)).frame(height: r == 0 ? 1 : 0.5)
                        .gridCellUnsizedAxes(.horizontal)
                }
            }
        }
        .foregroundStyle(ink)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
