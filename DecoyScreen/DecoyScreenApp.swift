import CoreText
import DuoKit
import SwiftUI

@main
struct DecoyScreenApp: App {
    init() {
        // The title-card typeface, bundled with the app: Noto Serif SC Black,
        // a heavy Song (Songti-style) face under the SIL Open Font License
        // (Fonts/NotoSerifSC-OFL.txt).
        if let url = Bundle.main.url(forResource: "NotoSerifSC-Black", withExtension: "otf") {
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .tint(Duo.ink)
        }
    }
}
