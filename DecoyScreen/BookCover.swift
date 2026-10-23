import SwiftUI

/// A book or report cover, drawn to fill whatever size it is given (the
/// outer screen, or a thumbnail on the shelf). Everything scales from width.
struct BookCover: View {
    let book: Book

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            ZStack {
                switch book.layout {
                case .textbook: textbook(w)
                case .professional: professional(w)
                case .research: research(w)
                case .financial: financial(w)
                case .trade: trade(w)
                case .classic: classic(w)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .overlay { PrintFinish(layout: book.layout) }
            .clipped()
        }
        .accessibilityElement()
        .accessibilityLabel(book.title)
    }

    // MARK: Layouts

    private func textbook(_ w: CGFloat) -> some View {
        ZStack(alignment: .topLeading) {
            book.base
            // The soft light across a printed textbook cover.
            LinearGradient(colors: [.white.opacity(0.14), .clear, .black.opacity(0.12)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
            VStack(alignment: .leading, spacing: 0) {
                Text(tr("Undergraduate Textbook Series", "普通高等教育本科教材"))
                    .font(.system(size: w * 0.03, weight: .medium))
                    .tracking(w * 0.004)
                    .opacity(0.75)
                    .padding(.bottom, w * 0.06)
                Rectangle().fill(book.accent).frame(width: w * 0.16, height: w * 0.012)
                    .padding(.bottom, w * 0.05)
                Text(book.title)
                    .font(.system(size: w * 0.135, weight: .heavy))
                    .tracking(w * 0.004)
                    .lineLimit(2)
                    .minimumScaleFactor(0.5)
                Text(book.english)
                    .font(.system(size: w * 0.042, weight: .medium))
                    .opacity(0.8)
                    .padding(.top, w * 0.02)
                Text(book.subtitle)
                    .font(.system(size: w * 0.046, weight: .semibold))
                    .padding(.top, w * 0.04)
                Spacer(minLength: 0)
                Motif(kind: book.motif, color: book.accent)
                    .frame(height: w * 0.62)
                Spacer(minLength: 0)
                Text(book.author)
                    .font(.system(size: w * 0.038, weight: .medium))
                    .opacity(0.85)
                Rectangle().fill(book.ink.opacity(0.3)).frame(height: 0.5).padding(.vertical, w * 0.025)
                Text(book.publisher)
                    .font(.system(size: w * 0.04, weight: .semibold))
            }
            .foregroundStyle(book.ink)
            .padding(w * 0.09)
        }
    }

    private func professional(_ w: CGFloat) -> some View {
        ZStack(alignment: .topLeading) {
            book.base
            VStack(spacing: 0) {
                book.accent.frame(height: w * 0.05)
                Spacer()
            }
            VStack(alignment: .leading, spacing: 0) {
                Spacer(minLength: w * 0.14)
                Text(book.title)
                    .font(.system(size: w * 0.12, weight: .bold, design: .serif))
                    .lineLimit(2)
                    .minimumScaleFactor(0.5)
                Text(book.english)
                    .font(.system(size: w * 0.04, design: .serif).italic())
                    .foregroundStyle(book.ink.opacity(0.7))
                    .padding(.top, w * 0.025)
                Text(book.subtitle)
                    .font(.system(size: w * 0.045, weight: .medium))
                    .foregroundStyle(book.accent)
                    .padding(.top, w * 0.05)
                Spacer(minLength: 0)
                Motif(kind: book.motif, color: book.accent)
                    .frame(height: w * 0.5)
                    .padding(.horizontal, w * 0.06)
                Spacer(minLength: 0)
                Text(book.author)
                    .font(.system(size: w * 0.045, weight: .semibold))
                Text(book.publisher)
                    .font(.system(size: w * 0.036))
                    .foregroundStyle(book.ink.opacity(0.65))
                    .padding(.top, w * 0.02)
            }
            .foregroundStyle(book.ink)
            .padding(w * 0.09)
        }
    }

    private func research(_ w: CGFloat) -> some View {
        ZStack(alignment: .topLeading) {
            Color.white
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text(book.author.components(separatedBy: " · ").first ?? book.author)
                        .font(.system(size: w * 0.04, weight: .bold))
                    Spacer()
                    Text(tr("Industry Research", "行业研究"))
                        .font(.system(size: w * 0.034, weight: .medium))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, w * 0.07)
                .frame(height: w * 0.12)
                .background(book.accent)

                VStack(alignment: .leading, spacing: 0) {
                    Text(tr("In-depth report", "深度报告"))
                        .font(.system(size: w * 0.034, weight: .semibold))
                        .foregroundStyle(book.accent)
                        .padding(.top, w * 0.1)
                    Text(book.title)
                        .font(.system(size: w * 0.095, weight: .bold))
                        .lineLimit(3)
                        .minimumScaleFactor(0.5)
                        .padding(.top, w * 0.03)
                    Text(book.subtitle)
                        .font(.system(size: w * 0.048, weight: .medium))
                        .foregroundStyle(book.ink.opacity(0.75))
                        .padding(.top, w * 0.035)
                    Text(book.english)
                        .font(.system(size: w * 0.032))
                        .foregroundStyle(book.ink.opacity(0.5))
                        .padding(.top, w * 0.02)
                    Spacer(minLength: 0)
                    Motif(kind: book.motif, color: book.accent)
                        .frame(height: w * 0.42)
                    Spacer(minLength: 0)
                    Rectangle().fill(book.ink.opacity(0.15)).frame(height: 0.5)
                    HStack {
                        Text(book.author)
                        Spacer()
                        Text(book.publisher)
                    }
                    .font(.system(size: w * 0.032))
                    .foregroundStyle(book.ink.opacity(0.6))
                    .padding(.top, w * 0.025)
                }
                .foregroundStyle(book.ink)
                .padding(.horizontal, w * 0.07)
                .padding(.bottom, w * 0.08)
            }
        }
    }

    private func financial(_ w: CGFloat) -> some View {
        ZStack(alignment: .topLeading) {
            book.base
            VStack(alignment: .leading, spacing: 0) {
                Text(book.subtitle)
                    .font(.system(size: w * 0.055, weight: .semibold))
                Rectangle().fill(book.accent).frame(height: w * 0.006).padding(.vertical, w * 0.05)
                Spacer(minLength: 0)
                Text(book.title)
                    .font(.system(size: w * 0.1, weight: .bold))
                    .lineLimit(2)
                    .minimumScaleFactor(0.5)
                Text(book.english)
                    .font(.system(size: w * 0.042, weight: .medium))
                    .foregroundStyle(book.accent)
                    .padding(.top, w * 0.025)
                Motif(kind: book.motif, color: book.accent)
                    .frame(height: w * 0.4)
                    .padding(.vertical, w * 0.08)
                Spacer(minLength: 0)
                HStack {
                    Text(book.author)
                    Spacer()
                    Text(book.publisher)
                }
                .font(.system(size: w * 0.034))
                .opacity(0.75)
            }
            .foregroundStyle(book.ink)
            .padding(w * 0.09)
        }
    }
}

extension BookCover {
    /// Popular non-fiction: author on top, a big centred title, an emblem,
    /// then the English title and the publisher.
    fileprivate func trade(_ w: CGFloat) -> some View {
        ZStack {
            book.base
            VStack(spacing: 0) {
                Text(book.author)
                    .font(.system(size: w * 0.04, weight: .medium))
                    .tracking(w * 0.006)
                    .opacity(0.8)
                    .padding(.top, w * 0.12)
                Text(book.title)
                    .font(.system(size: w * 0.15, weight: .heavy, design: .serif))
                    .foregroundStyle(book.motif == .rule ? book.ink : book.accent)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.45)
                    .padding(.top, w * 0.07)
                Text(book.subtitle)
                    .font(.system(size: w * 0.048, weight: .medium))
                    .multilineTextAlignment(.center)
                    .padding(.top, w * 0.035)
                Spacer(minLength: w * 0.04)
                Motif(kind: book.motif, color: book.accent)
                    .frame(width: w * 0.62, height: w * 0.42)
                Spacer(minLength: w * 0.04)
                Text(book.english)
                    .font(.system(size: w * 0.058, weight: .semibold, design: .serif))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.6)
                    .padding(.horizontal, w * 0.08)
                Text(book.publisher)
                    .font(.system(size: w * 0.034, weight: .medium))
                    .opacity(0.7)
                    .padding(.top, w * 0.07)
                    .padding(.bottom, w * 0.08)
            }
            .foregroundStyle(book.ink)
            .padding(.horizontal, w * 0.07)
        }
    }

    /// A classic in a scholarly series: series name, a gilt frame, the title,
    /// the original title, the author, and the series mark at the foot.
    fileprivate func classic(_ w: CGFloat) -> some View {
        ZStack {
            book.base
            // Gilt frame.
            RoundedRectangle(cornerRadius: w * 0.01)
                .strokeBorder(book.accent.opacity(0.85), lineWidth: max(1, w * 0.006))
                .padding(w * 0.06)
            RoundedRectangle(cornerRadius: w * 0.006)
                .strokeBorder(book.accent.opacity(0.5), lineWidth: max(0.5, w * 0.002))
                .padding(w * 0.078)
            VStack(spacing: 0) {
                Text(tr("Classics of World Scholarship in Translation", "汉 译 学 术 经 典"))
                    .font(.system(size: w * 0.042, weight: .semibold, design: .serif))
                    .tracking(w * 0.01)
                    .foregroundStyle(book.accent)
                    .padding(.top, w * 0.15)
                Rectangle().fill(book.accent.opacity(0.7)).frame(width: w * 0.3, height: max(0.5, w * 0.003))
                    .padding(.top, w * 0.04)
                Spacer(minLength: 0)
                Text(book.title)
                    .font(.system(size: w * 0.115, weight: .bold, design: .serif))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.5)
                Text(book.english)
                    .font(.system(size: w * 0.038, design: .serif).italic())
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.6)
                    .opacity(0.75)
                    .padding(.top, w * 0.035)
                Text(book.author)
                    .font(.system(size: w * 0.042, weight: .medium, design: .serif))
                    .padding(.top, w * 0.07)
                Spacer(minLength: 0)
                Motif(kind: .crest, color: book.accent)
                    .frame(width: w * 0.16, height: w * 0.16)
                Text(book.publisher)
                    .font(.system(size: w * 0.036, weight: .semibold, design: .serif))
                    .tracking(w * 0.006)
                    .padding(.top, w * 0.03)
                    .padding(.bottom, w * 0.14)
            }
            .foregroundStyle(book.ink)
            .padding(.horizontal, w * 0.14)
        }
    }
}

/// What makes a flat drawing read as a printed cover: the hinge crease
/// beside the spine, a soft sheen on the laminate, and slightly darker edges.
private struct PrintFinish: View {
    let layout: CoverLayout

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            // Reports are stapled sheets: no hinge, just the sheen.
            let bound = layout != .research
            ZStack(alignment: .leading) {
                LinearGradient(stops: [.init(color: .white.opacity(0.0), location: 0),
                                       .init(color: .white.opacity(0.10), location: 0.35),
                                       .init(color: .white.opacity(0.0), location: 0.6)],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
                if bound {
                    HStack(spacing: 0) {
                        LinearGradient(colors: [.black.opacity(0.28), .black.opacity(0.06)],
                                       startPoint: .leading, endPoint: .trailing)
                            .frame(width: w * 0.035)
                        LinearGradient(colors: [.white.opacity(0.18), .clear],
                                       startPoint: .leading, endPoint: .trailing)
                            .frame(width: w * 0.02)
                        LinearGradient(colors: [.black.opacity(0.10), .clear],
                                       startPoint: .leading, endPoint: .trailing)
                            .frame(width: w * 0.04)
                        Spacer(minLength: 0)
                    }
                }
                RoundedRectangle(cornerRadius: 0)
                    .strokeBorder(.black.opacity(0.08), lineWidth: max(0.5, w * 0.004))
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// The line drawing on a cover.
private struct Motif: View {
    let kind: CoverMotif
    let color: Color

    var body: some View {
        Canvas { gc, size in
            let w = size.width, h = size.height
            let stroke = StrokeStyle(lineWidth: max(1, w * 0.008), lineCap: .round, lineJoin: .round)
            let thin = StrokeStyle(lineWidth: max(0.5, w * 0.003))
            let faint = GraphicsContext.Shading.color(color.opacity(0.35))
            let full = GraphicsContext.Shading.color(color)
            switch kind {
            case .curve:
                axes(gc, w, h, faint, thin)
                var p = Path()
                for i in 0...80 {
                    let x = CGFloat(i) / 80
                    let y = 0.5 - 0.32 * sin(x * .pi * 2.2) * exp(-x * 0.9)
                    let pt = CGPoint(x: x * w, y: y * h)
                    if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
                }
                gc.stroke(p, with: full, style: stroke)
            case .matrix:
                let cols = 4, rows = 4
                let cell = min(w / CGFloat(cols + 2), h / CGFloat(rows + 1))
                let ox = (w - cell * CGFloat(cols)) / 2, oy = (h - cell * CGFloat(rows)) / 2
                var b = Path()
                b.move(to: CGPoint(x: ox - 6, y: oy)); b.addLine(to: CGPoint(x: ox - 12, y: oy))
                b.addLine(to: CGPoint(x: ox - 12, y: oy + cell * CGFloat(rows)))
                b.addLine(to: CGPoint(x: ox - 6, y: oy + cell * CGFloat(rows)))
                let rx = ox + cell * CGFloat(cols)
                b.move(to: CGPoint(x: rx + 6, y: oy)); b.addLine(to: CGPoint(x: rx + 12, y: oy))
                b.addLine(to: CGPoint(x: rx + 12, y: oy + cell * CGFloat(rows)))
                b.addLine(to: CGPoint(x: rx + 6, y: oy + cell * CGFloat(rows)))
                gc.stroke(b, with: full, style: stroke)
                for r in 0..<rows {
                    for col in 0..<cols {
                        let rect = CGRect(x: ox + CGFloat(col) * cell + cell * 0.3, y: oy + CGFloat(r) * cell + cell * 0.3,
                                          width: cell * 0.4, height: cell * 0.4)
                        gc.fill(Path(ellipseIn: rect), with: r == col ? full : faint)
                    }
                }
            case .bell:
                axes(gc, w, h, faint, thin)
                var p = Path()
                for i in 0...80 {
                    let x = CGFloat(i) / 80
                    let z = (x - 0.5) / 0.15
                    let y = 0.88 - 0.72 * exp(-z * z / 2)
                    let pt = CGPoint(x: x * w, y: y * h)
                    if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
                }
                gc.stroke(p, with: full, style: stroke)
                for k in [-1.0, 1.0] {
                    var l = Path()
                    let x = (0.5 + 0.15 * k) * w
                    l.move(to: CGPoint(x: x, y: h * 0.88)); l.addLine(to: CGPoint(x: x, y: h * 0.45))
                    gc.stroke(l, with: faint, style: thin)
                }
            case .orbit:
                let c = CGPoint(x: w / 2, y: h / 2)
                for (i, a) in [0.0, 1.05, 2.1].enumerated() {
                    var e = Path(ellipseIn: CGRect(x: -w * 0.42, y: -h * 0.16, width: w * 0.84, height: h * 0.32))
                    e = e.applying(CGAffineTransform(rotationAngle: a)).applying(CGAffineTransform(translationX: c.x, y: c.y))
                    gc.stroke(e, with: i == 0 ? full : faint, style: stroke)
                }
                gc.fill(Path(ellipseIn: CGRect(x: c.x - w * 0.04, y: c.y - w * 0.04, width: w * 0.08, height: w * 0.08)), with: full)
            case .network:
                let pts: [CGPoint] = [(0.12, 0.3), (0.35, 0.15), (0.6, 0.35), (0.85, 0.2), (0.25, 0.7),
                                      (0.5, 0.62), (0.78, 0.75), (0.92, 0.5)].map { CGPoint(x: $0.0 * w, y: $0.1 * h) }
                let edges = [(0, 1), (1, 2), (2, 3), (0, 4), (4, 5), (5, 2), (5, 6), (6, 7), (3, 7), (1, 5)]
                for (a, b) in edges {
                    var p = Path(); p.move(to: pts[a]); p.addLine(to: pts[b])
                    gc.stroke(p, with: faint, style: stroke)
                }
                for (i, p) in pts.enumerated() {
                    let r = w * (i == 5 ? 0.04 : 0.025)
                    gc.fill(Path(ellipseIn: CGRect(x: p.x - r, y: p.y - r, width: r * 2, height: r * 2)), with: full)
                }
            case .ledger:
                for i in 0..<6 {
                    let y = h * (0.15 + CGFloat(i) * 0.14)
                    var l = Path(); l.move(to: CGPoint(x: 0, y: y)); l.addLine(to: CGPoint(x: w, y: y))
                    gc.stroke(l, with: faint, style: thin)
                }
                var p = Path()
                let ys: [CGFloat] = [0.8, 0.72, 0.75, 0.55, 0.5, 0.32, 0.22]
                for (i, y) in ys.enumerated() {
                    let pt = CGPoint(x: w * CGFloat(i) / CGFloat(ys.count - 1), y: h * y)
                    if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
                }
                gc.stroke(p, with: full, style: stroke)
            case .columns:
                let n = 5
                let gap = w * 0.05
                let bw = (w - gap * CGFloat(n - 1)) / CGFloat(n)
                for i in 0..<n {
                    let bh = h * (0.3 + 0.13 * CGFloat(i))
                    let r = CGRect(x: CGFloat(i) * (bw + gap), y: h - bh, width: bw, height: bh)
                    gc.stroke(Path(r), with: i == n - 1 ? full : faint, style: stroke)
                }
            case .scales:
                var p = Path()
                p.move(to: CGPoint(x: w / 2, y: h * 0.1)); p.addLine(to: CGPoint(x: w / 2, y: h * 0.85))
                p.move(to: CGPoint(x: w * 0.3, y: h * 0.85)); p.addLine(to: CGPoint(x: w * 0.7, y: h * 0.85))
                p.move(to: CGPoint(x: w * 0.15, y: h * 0.25)); p.addLine(to: CGPoint(x: w * 0.85, y: h * 0.25))
                gc.stroke(p, with: full, style: stroke)
                for x in [0.15, 0.85] {
                    var pan = Path()
                    pan.move(to: CGPoint(x: w * (x - 0.12), y: h * 0.55))
                    pan.addLine(to: CGPoint(x: w * x, y: h * 0.25))
                    pan.addLine(to: CGPoint(x: w * (x + 0.12), y: h * 0.55))
                    pan.addQuadCurve(to: CGPoint(x: w * (x - 0.12), y: h * 0.55), control: CGPoint(x: w * x, y: h * 0.68))
                    gc.stroke(pan, with: faint, style: stroke)
                }
            case .bars:
                let vals: [CGFloat] = [0.35, 0.42, 0.5, 0.58, 0.66, 0.78]
                let gap = w * 0.04
                let bw = (w - gap * CGFloat(vals.count - 1)) / CGFloat(vals.count)
                for (i, v) in vals.enumerated() {
                    let r = CGRect(x: CGFloat(i) * (bw + gap), y: h * (1 - v), width: bw, height: h * v)
                    gc.fill(Path(r), with: i >= vals.count - 2 ? full : faint)
                }
            case .line:
                axes(gc, w, h, faint, thin)
                var p = Path()
                let ys: [CGFloat] = [0.7, 0.62, 0.66, 0.5, 0.55, 0.42, 0.38, 0.3]
                for (i, y) in ys.enumerated() {
                    let pt = CGPoint(x: w * CGFloat(i) / CGFloat(ys.count - 1), y: h * y)
                    if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
                }
                gc.stroke(p, with: full, style: stroke)
            case .wafer:
                let d = min(w, h) * 0.9
                let rect = CGRect(x: (w - d) / 2, y: (h - d) / 2, width: d, height: d)
                gc.stroke(Path(ellipseIn: rect), with: full, style: stroke)
                var grid = Path()
                let n = 7
                for i in 1..<n {
                    let t = CGFloat(i) / CGFloat(n)
                    grid.move(to: CGPoint(x: rect.minX + d * t, y: rect.minY)); grid.addLine(to: CGPoint(x: rect.minX + d * t, y: rect.maxY))
                    grid.move(to: CGPoint(x: rect.minX, y: rect.minY + d * t)); grid.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + d * t))
                }
                gc.drawLayer { layer in
                    layer.clip(to: Path(ellipseIn: rect.insetBy(dx: 2, dy: 2)))
                    layer.stroke(grid, with: faint, style: thin)
                }
            case .horizon:
                let d = min(w, h) * 0.62
                let sun = CGRect(x: (w - d) / 2, y: h * 0.62 - d / 2, width: d, height: d)
                gc.drawLayer { layer in
                    layer.clip(to: Path(CGRect(x: 0, y: 0, width: w, height: h * 0.62)))
                    layer.fill(Path(ellipseIn: sun), with: full)
                }
                for i in 0..<4 {
                    let y = h * (0.7 + CGFloat(i) * 0.08)
                    let inset = w * (0.08 + CGFloat(i) * 0.08)
                    var l = Path(); l.move(to: CGPoint(x: inset, y: y)); l.addLine(to: CGPoint(x: w - inset, y: y))
                    gc.stroke(l, with: i == 0 ? full : faint, style: stroke)
                }
            case .sail:
                var hull = Path()
                hull.move(to: CGPoint(x: w * 0.22, y: h * 0.72))
                hull.addLine(to: CGPoint(x: w * 0.78, y: h * 0.72))
                hull.addLine(to: CGPoint(x: w * 0.68, y: h * 0.84))
                hull.addLine(to: CGPoint(x: w * 0.32, y: h * 0.84))
                hull.closeSubpath()
                gc.fill(hull, with: full)
                var main = Path()
                main.move(to: CGPoint(x: w * 0.5, y: h * 0.08))
                main.addLine(to: CGPoint(x: w * 0.5, y: h * 0.66))
                main.addLine(to: CGPoint(x: w * 0.74, y: h * 0.66))
                main.closeSubpath()
                gc.fill(main, with: full)
                var jib = Path()
                jib.move(to: CGPoint(x: w * 0.46, y: h * 0.2))
                jib.addLine(to: CGPoint(x: w * 0.46, y: h * 0.66))
                jib.addLine(to: CGPoint(x: w * 0.28, y: h * 0.66))
                jib.closeSubpath()
                gc.fill(jib, with: faint)
                var sea = Path()
                for i in 0...40 {
                    let x = CGFloat(i) / 40
                    let pt = CGPoint(x: x * w, y: h * 0.92 + sin(x * .pi * 6) * h * 0.02)
                    if i == 0 { sea.move(to: pt) } else { sea.addLine(to: pt) }
                }
                gc.stroke(sea, with: faint, style: stroke)
            case .waves:
                // A crescent: a full disc minus an offset disc.
                let d = min(w, h) * 0.34
                let moon = CGRect(x: w * 0.5 - d / 2, y: h * 0.04, width: d, height: d)
                gc.drawLayer { layer in
                    layer.fill(Path(ellipseIn: moon), with: full)
                    layer.blendMode = .destinationOut
                    layer.fill(Path(ellipseIn: moon.offsetBy(dx: d * 0.3, dy: -d * 0.12)), with: .color(.black))
                }
                for (i, amp) in [0.05, 0.09, 0.13].enumerated() {
                    var p = Path()
                    let base = h * (0.58 + CGFloat(i) * 0.14)
                    for k in 0...60 {
                        let x = CGFloat(k) / 60
                        let pt = CGPoint(x: x * w, y: base + sin(x * .pi * (3 - Double(i) * 0.7)) * h * amp)
                        if k == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
                    }
                    gc.stroke(p, with: i == 2 ? full : faint, style: stroke)
                }
                for (x, y) in [(0.12, 0.12), (0.86, 0.2), (0.2, 0.36), (0.78, 0.4), (0.95, 0.06)] {
                    let r = w * 0.008
                    gc.fill(Path(ellipseIn: CGRect(x: w * x - r, y: h * y - r, width: r * 2, height: r * 2)), with: full)
                }
            case .rule:
                var l = Path()
                l.move(to: CGPoint(x: w * 0.3, y: h / 2)); l.addLine(to: CGPoint(x: w * 0.7, y: h / 2))
                gc.stroke(l, with: full, style: StrokeStyle(lineWidth: max(1, w * 0.006)))
            case .crest:
                let d = min(w, h)
                let rect = CGRect(x: (w - d) / 2, y: (h - d) / 2, width: d, height: d)
                gc.stroke(Path(ellipseIn: rect.insetBy(dx: d * 0.04, dy: d * 0.04)), with: full,
                          style: StrokeStyle(lineWidth: max(1, d * 0.05)))
                gc.stroke(Path(ellipseIn: rect.insetBy(dx: d * 0.16, dy: d * 0.16)), with: full,
                          style: StrokeStyle(lineWidth: max(0.5, d * 0.025)))
                // An open book in the middle.
                let c = CGPoint(x: rect.midX, y: rect.midY)
                var pages = Path()
                pages.move(to: CGPoint(x: c.x, y: c.y + d * 0.12))
                pages.addQuadCurve(to: CGPoint(x: c.x - d * 0.2, y: c.y + d * 0.08), control: CGPoint(x: c.x - d * 0.1, y: c.y + d * 0.04))
                pages.addLine(to: CGPoint(x: c.x - d * 0.2, y: c.y - d * 0.1))
                pages.addQuadCurve(to: CGPoint(x: c.x, y: c.y - d * 0.06), control: CGPoint(x: c.x - d * 0.1, y: c.y - d * 0.14))
                pages.addQuadCurve(to: CGPoint(x: c.x + d * 0.2, y: c.y - d * 0.1), control: CGPoint(x: c.x + d * 0.1, y: c.y - d * 0.14))
                pages.addLine(to: CGPoint(x: c.x + d * 0.2, y: c.y + d * 0.08))
                pages.addQuadCurve(to: CGPoint(x: c.x, y: c.y + d * 0.12), control: CGPoint(x: c.x + d * 0.1, y: c.y + d * 0.04))
                pages.move(to: CGPoint(x: c.x, y: c.y - d * 0.06)); pages.addLine(to: CGPoint(x: c.x, y: c.y + d * 0.12))
                gc.stroke(pages, with: full, style: StrokeStyle(lineWidth: max(0.5, d * 0.03), lineJoin: .round))
            case .pie:
                let d = min(w, h) * 0.9
                let c = CGPoint(x: w / 2, y: h / 2)
                let parts: [Double] = [0.407, 0.341, 0.252]
                var start = -Double.pi / 2
                for (i, f) in parts.enumerated() {
                    var p = Path()
                    p.move(to: c)
                    p.addArc(center: c, radius: d / 2, startAngle: .radians(start), endAngle: .radians(start + f * 2 * .pi), clockwise: false)
                    p.closeSubpath()
                    gc.fill(p, with: .color(color.opacity([1, 0.6, 0.3][i])))
                    start += f * 2 * .pi
                }
            }
        }
        .accessibilityHidden(true)
    }

    private func axes(_ gc: GraphicsContext, _ w: CGFloat, _ h: CGFloat,
                      _ shading: GraphicsContext.Shading, _ style: StrokeStyle) {
        var a = Path()
        a.move(to: CGPoint(x: 0, y: h * 0.9)); a.addLine(to: CGPoint(x: w, y: h * 0.9))
        a.move(to: CGPoint(x: w * 0.04, y: 0)); a.addLine(to: CGPoint(x: w * 0.04, y: h))
        gc.stroke(a, with: shading, style: style)
    }
}
