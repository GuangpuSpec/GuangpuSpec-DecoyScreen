import DuoKit
import SwiftUI

/// How the app works:
/// - Phone open: the inner screen is a browser; the outer screen faces the
///   people across from you and shows the cover of the chosen book.
/// - Tap Cover in the toolbar: the inner screen shows that book's pages.
///   Close returns to the browser.
/// - Phone closed (or in tent mode): the outer screen shows the cover and
///   any video stops.
struct RootView: View {
    @State private var store = DecoyStore.shared
    @State private var browser = Browser()
    @State private var camera = CameraKeeper()
    @State private var monitor = HingeMonitor()
    @State private var outerAvailable = false
    @State private var hidden = false
    @State private var section = DecoyTab.browser
    @Environment(\.scenePhase) private var phase

    /// The system has put the app on the outer screen.
    private var onOuterDisplay: Bool {
        monitor.pose == .closed || monitor.pose == .tent
    }

    var body: some View {
        ZStack {
            if onOuterDisplay {
                OuterFace(store: store)
                    .transition(.opacity)
            } else {
                inner
                    .sceneAccessory {
                        CameraCaptureAccessory(isEnabled: $store.showOnOuter) {
                            OuterFace(store: store)
                        }
                        .onAvailabilityChange { available in
                            outerAvailable = available
                        }
                    }
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: onOuterDisplay)
        .readsHinge(into: monitor)
        .onChange(of: onOuterDisplay) { _, outer in
            if outer { browser.pauseAll() }
            updateCamera()
        }
        .onChange(of: phase) { _, newPhase in
            if newPhase != .active { browser.pauseAll() }
            updateCamera()
        }
        .onChange(of: store.showOnOuter) { updateCamera() }
        .onChange(of: hidden) { _, isHidden in browser.setHidden(isHidden) }
        .task { updateCamera() }
    }

    private var inner: some View {
        let status = outerStatus(store: store, camera: camera, outerAvailable: outerAvailable)
        return ZStack {
            // System tabs: a floating bar at the bottom in portrait, the lower
            // half of the vertical bar on the side.
            TabView(selection: $section) {
                Tab("Browser", systemImage: "safari", value: DecoyTab.browser) {
                    NavigationStack {
                        BrowserScreen(browser: browser, store: store, outerStatus: status,
                                      onCamera: { camera.openSettings() }, hidden: $hidden)
                    }
                }
                Tab("Covers", systemImage: "books.vertical", value: DecoyTab.covers) {
                    ShelfPicker(store: store, camera: camera, status: status, inTab: true)
                }
                Tab("Bookmarks", systemImage: "star", value: DecoyTab.bookmarks) {
                    BookmarkList(browser: browser) { section = .browser }
                }
                Tab("History", systemImage: "clock", value: DecoyTab.history) {
                    HistoryList(browser: browser) { section = .browser }
                }
            }
            // Instant, no slide: the book must be there the moment you tap.
            if hidden {
                BookReader(book: store.book, page: pageBinding) { hidden = false }
                    .transition(.opacity)
            }
        }
        .animation(.easeOut(duration: 0.12), value: hidden)
    }

    private var pageBinding: Binding<Int> {
        Binding(get: { store.pageIndex[store.bookID] ?? 0 },
                set: { store.pageIndex[store.bookID] = $0 })
    }

    /// Keep the camera running only while it can do its job: phone open, app
    /// in front, cover switched on.
    private func updateCamera() {
        let needed = !onOuterDisplay && phase == .active && store.showOnOuter
        if needed {
            Task { await camera.start() }
        } else {
            camera.stop()
        }
        // A closed-phone cover shouldn't fall asleep in your hand.
        UIApplication.shared.isIdleTimerDisabled = onOuterDisplay && phase == .active
    }
}

enum DecoyTab: Hashable {
    case browser, covers, bookmarks, history
}

/// The outer screen: your text, or the chosen book's cover.
struct OuterFace: View {
    let store: DecoyStore

    var body: some View {
        Group {
            switch store.outerSource {
            case .text:
                OuterSign(text: store.signText, style: store.signStyle)
            case .book:
                OuterCover(book: store.book)
            }
        }
        // The whole outer screen, edge to edge: no safe-area strip beside the
        // camera, no status bar, no home indicator.
        .ignoresSafeArea()
        .statusBarHidden()
        .persistentSystemOverlays(.hidden)
    }
}

/// The cover on the outer screen, filling it edge to edge like a real cover.
struct OuterCover: View {
    let book: Book

    var body: some View {
        BookCover(book: book)
            .ignoresSafeArea()
            .background((book.layout == .research ? Color.white : book.base).ignoresSafeArea())
    }
}

/// One line saying what the outer screen is doing.
@MainActor
func outerStatus(store: DecoyStore, camera: CameraKeeper, outerAvailable: Bool) -> OuterStatusInfo {
    let title = store.outerSource == .text ? "“\(store.signText)”" : store.book.title
    if !store.showOnOuter {
        return OuterStatusInfo(color: Duo.ink3, message: String(localized: "Outer screen cover is off"), needsAction: false)
    }
    if outerAvailable {
        return OuterStatusInfo(color: Duo.approve, message: String(localized: "Outer screen shows: \(title)"), needsAction: false)
    }
    let message: String = switch camera.state {
    case .denied: String(localized: "The outer screen needs camera access")
    case .noCamera: String(localized: "No camera here (simulator), so the outer screen can't show it. Close the phone to see the decoy.")
    case .failed: String(localized: "The camera couldn't start, so the outer screen is off")
    case .idle, .starting: String(localized: "Starting the outer screen…")
    case .running: String(localized: "Outer screen not available right now (use the app full screen with the phone open)")
    }
    return OuterStatusInfo(color: Duo.waiting, message: message, needsAction: camera.state == .denied)
}
