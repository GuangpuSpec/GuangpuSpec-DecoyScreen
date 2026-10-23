import DuoKit
import SwiftUI

/// Choose the cover the outer screen shows. Tap a cover to use it (content
/// interaction); Done and the outer-screen switch are system toolbar items.
struct ShelfPicker: View {
    let store: DecoyStore
    let camera: CameraKeeper
    let status: OuterStatusInfo
    /// Shown as a tab: large title, no Done.
    var inTab = false
    @Environment(\.dismiss) private var dismiss
    @State private var editingText = false

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                ScrollView {
                    VStack(alignment: .leading, spacing: Duo.Space.xxl) {
                        HStack(spacing: Duo.Space.s) {
                            Circle().fill(status.color).frame(width: 8, height: 8)
                                .accessibilityHidden(true)
                            Text(status.message)
                                .font(DuoType.footnote)
                                .foregroundStyle(Duo.ink3)
                        }
                        VStack(alignment: .leading, spacing: Duo.Space.m) {
                            SectionHeading(verbatim: tr("My Text", "自定义文字"))
                            LazyVGrid(columns: columns(for: geo.size.width), alignment: .leading,
                                      spacing: Duo.Space.xl) {
                                signTile
                            }
                        }
                        ForEach(Shelf.allCases) { shelf in
                            VStack(alignment: .leading, spacing: Duo.Space.m) {
                                SectionHeading(verbatim: shelf.name)
                                LazyVGrid(columns: columns(for: geo.size.width), alignment: .leading,
                                          spacing: Duo.Space.xl) {
                                    ForEach(Catalog.books(on: shelf)) { book in
                                        cover(book)
                                    }
                                }
                            }
                        }
                    }
                    .padding(Duo.Space.xl)
                }
            }
            .background(Duo.paper)
            .sheet(isPresented: $editingText) {
                SignTextEditor(store: store)
            }
            .navigationTitle("Covers")
            .navigationBarTitleDisplayMode(inTab ? .automatic : .inline)
            .toolbar {
                if !inTab {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done", systemImage: "checkmark") { dismiss() }
                    }
                }
                ToolbarItem(placement: .topBarPinnedTrailing) {
                    Button(tr("Edit Text", "编辑文字"), systemImage: "character.cursor.ibeam") { editingText = true }
                }
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button(store.showOnOuter ? "Hide Cover Outside" : "Show Cover Outside",
                           systemImage: store.showOnOuter ? "rectangle.portrait.fill" : "rectangle.portrait.slash") {
                        store.showOnOuter.toggle()
                    }
                    if status.needsAction {
                        Button("Allow Camera", systemImage: "camera") { camera.openSettings() }
                    }
                }
            }
        }
    }

    /// The custom-text "cover": tap to show it outside; the first time (or
    /// with no text yet) the editor opens.
    private var signTile: some View {
        let selected = store.outerSource == .text
        return Button {
            if store.signText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                editingText = true
            } else {
                store.outerSource = .text
            }
        } label: {
            VStack(alignment: .leading, spacing: Duo.Space.s) {
                OuterSign(text: store.signText, style: store.signStyle)
                    .aspectRatio(3 / 4, contentMode: .fit)
                    .clipShape(.rect(cornerRadius: 6))
                    .overlay {
                        RoundedRectangle(cornerRadius: 6)
                            .strokeBorder(selected ? Duo.ink : Duo.line, lineWidth: selected ? 3 : 0.5)
                    }
                Text(tr("Show my text", "显示我的文字"))
                    .font(selected ? DuoType.callout.weight(.semibold) : DuoType.callout)
                    .foregroundStyle(Duo.ink)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tr("My text: \(store.signText)", "自定义文字：\(store.signText)"))
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    /// An even number of columns, so the fold never cuts through a cover.
    private func columns(for width: CGFloat) -> [GridItem] {
        let fit = Int((width - Duo.Space.xl * 2) / 150)
        let count = max(2, fit - fit % 2)
        return Array(repeating: GridItem(.flexible(), spacing: Duo.Space.xl, alignment: .top), count: count)
    }

    private func cover(_ book: Book) -> some View {
        let selected = store.outerSource == .book && book.id == store.bookID
        return Button {
            store.bookID = book.id
            store.outerSource = .book
        } label: {
            VStack(alignment: .leading, spacing: Duo.Space.s) {
                BookCover(book: book)
                    .aspectRatio(3 / 4, contentMode: .fit)
                    .clipShape(.rect(cornerRadius: 6))
                    .overlay {
                        RoundedRectangle(cornerRadius: 6)
                            .strokeBorder(selected ? Duo.ink : Duo.line, lineWidth: selected ? 3 : 0.5)
                    }
                Text(book.title)
                    .font(selected ? DuoType.callout.weight(.semibold) : DuoType.callout)
                    .foregroundStyle(Duo.ink)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(book.title)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

/// Write the text for the outer screen and pick its colours. Save shows it
/// outside straight away.
struct SignTextEditor: View {
    let store: DecoyStore
    @Environment(\.dismiss) private var dismiss
    @State private var text: String
    @State private var style: SignStyle

    init(store: DecoyStore) {
        self.store = store
        _text = State(initialValue: store.signText)
        _style = State(initialValue: store.signStyle)
    }

    private let presets: [String] = [
        tr("In a meeting", "会议中"),
        tr("Focusing · please don't disturb", "专注中 请勿打扰"),
        tr("Back in 5 minutes", "五分钟后回来"),
        tr("On a call", "通话中"),
        tr("Lunch break", "午休中"),
        tr("Come in", "欢迎打扰"),
    ]

    private var trimmed: String { text.trimmingCharacters(in: .whitespacesAndNewlines) }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    OuterSign(text: trimmed, style: style)
                        .aspectRatio(3 / 4, contentMode: .fit)
                        .frame(maxHeight: 280)
                        .clipShape(.rect(cornerRadius: 12))
                        .frame(maxWidth: .infinity)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets())
                } footer: {
                    Text(tr("This fills the outer screen while you use the phone open, and when you close it.",
                            "打开手机使用时，或合上手机后，外屏都会显示这段文字。"))
                }
                Section(tr("Text", "文字")) {
                    TextField(tr("What should the outer screen say?", "外屏要显示什么？"),
                              text: $text, axis: .vertical)
                        .lineLimit(1...4)
                }
                Section(tr("Quick picks", "常用")) {
                    ScrollView(.horizontal) {
                        HStack(spacing: Duo.Space.s) {
                            ForEach(presets, id: \.self) { preset in
                                Button(preset) { text = preset }
                                    .buttonStyle(.bordered)
                            }
                        }
                    }
                    .scrollIndicators(.hidden)
                    .listRowInsets(EdgeInsets(top: Duo.Space.s, leading: Duo.Space.l,
                                              bottom: Duo.Space.s, trailing: Duo.Space.l))
                }
                Section(tr("Colours", "配色")) {
                    Picker(tr("Colours", "配色"), selection: $style) {
                        ForEach(SignStyle.allCases) { s in
                            Label {
                                Text(s.name)
                            } icon: {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(s.background)
                                    .overlay(RoundedRectangle(cornerRadius: 4).strokeBorder(Duo.line, lineWidth: 0.5))
                                    .overlay(Text(verbatim: "字").font(.custom(OuterSign.typeface, size: 12)).foregroundStyle(s.foreground))
                                    .frame(width: 22, height: 22)
                            }
                            .tag(s)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }
            }
            .navigationTitle(tr("Outer Screen Text", "外屏文字"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(tr("Cancel", "取消"), systemImage: "xmark") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(tr("Show", "显示"), systemImage: "checkmark") {
                        store.signText = trimmed
                        store.signStyle = style
                        store.outerSource = .text
                        dismiss()
                    }
                    .disabled(trimmed.isEmpty)
                }
            }
        }
    }
}
