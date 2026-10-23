import SwiftUI

// The decoy shelf: textbooks, professional books, general reading and
// reports. Each one has its own cover (shown on the outer screen) and its own
// pages (shown inside when you tap the cover key). Titles, authors, publishers
// and companies are invented, except Kant's two works, which are in the public
// domain; their covers are original and their passages are our own
// translations. All text is original.

enum Shelf: String, CaseIterable, Identifiable {
    case textbook, professional, reading, report

    var id: String { rawValue }

    var name: String {
        switch self {
        case .textbook: tr("Textbooks", "教材")
        case .professional: tr("Professional", "专业书")
        case .reading: tr("General Reading", "人文社科")
        case .report: tr("Reports", "研报财报")
        }
    }

    var symbol: String {
        switch self {
        case .textbook: "graduationcap"
        case .professional: "books.vertical"
        case .reading: "book"
        case .report: "chart.bar.doc.horizontal"
        }
    }
}

/// One block of text on a page.
enum PageBlock: Hashable {
    case heading(String)
    case para(String)
    /// A displayed formula, set apart and centred.
    case formula(String)
    /// A boxed definition, theorem or key point.
    case box(title: String, text: String)
    case bullets([String])
    /// First row is the header.
    case table([[String]])
    /// A small note in the margin style (source, footnote).
    case note(String)
}

struct BookPage: Hashable {
    /// Running head: chapter or section.
    let section: String
    let blocks: [PageBlock]
}

/// How the cover is laid out.
enum CoverLayout {
    /// University textbook: colour field, big title, a motif, publisher at the foot.
    case textbook
    /// Professional book: paper jacket with a coloured band.
    case professional
    /// Broker research report: white page, brand bar, rating box.
    case research
    /// Annual or quarterly report: dark cover, thin rule, company name.
    case financial
    /// Popular non-fiction paperback: author on top, big centred title, an
    /// emblem, the English title, the publisher at the foot.
    case trade
    /// Classic in a scholarly series: series name across the top, a gilt
    /// frame, the title, and the series mark at the foot.
    case classic
}

/// The drawing on a cover.
enum CoverMotif {
    case curve, matrix, bell, orbit, network, ledger, columns, scales, bars, line, wafer, pie
    /// A low sun over the horizon.
    case horizon
    /// A small sailboat on a line of water.
    case sail
    /// Slow sleep waves under a crescent.
    case waves
    /// A single rule: for covers that are type only.
    case rule
    /// A round series mark.
    case crest
}

struct Book: Identifiable {
    let id: String
    let shelf: Shelf
    let title: String
    /// The English title or subtitle line on the cover.
    let english: String
    let subtitle: String
    let author: String
    let publisher: String
    let layout: CoverLayout
    let motif: CoverMotif
    /// Cover colours: field, text on the field, accent.
    let base: Color
    let ink: Color
    let accent: Color
    let pages: [BookPage]
}

private func c(_ hex: UInt32) -> Color {
    Color(red: Double((hex >> 16) & 0xFF) / 255, green: Double((hex >> 8) & 0xFF) / 255,
          blue: Double(hex & 0xFF) / 255)
}

enum Catalog {
    static func book(_ id: String) -> Book { all.first { $0.id == id } ?? all[0] }

    static func books(on shelf: Shelf) -> [Book] { all.filter { $0.shelf == shelf } }

    static let all: [Book] = textbooks + professional + reading + reports

    // MARK: Textbooks

    static let textbooks: [Book] = [
        Book(id: "calculus", shelf: .textbook, title: "高等数学", english: "Advanced Mathematics",
             subtitle: "第八版 · 上册", author: "华辰大学数学系 编", publisher: "华辰教育出版社",
             layout: .textbook, motif: .curve, base: c(0x1F4E8C), ink: .white, accent: c(0xF2C14E),
             pages: [
                BookPage(section: "第一章 函数与极限 · §1.3 函数的极限", blocks: [
                    .heading("一、自变量趋于有限值时函数的极限"),
                    .para("设函数 f(x) 在点 x₀ 的某一去心邻域内有定义。如果当 x 无限接近于 x₀ 时，对应的函数值 f(x) 无限接近于某个确定的常数 A，就称 A 是 f(x) 当 x→x₀ 时的极限。"),
                    .box(title: "定义 1", text: "设 f(x) 在 x₀ 的某去心邻域内有定义。若存在常数 A，对于任意给定的正数 ε，总存在正数 δ，使得当 0 < |x − x₀| < δ 时，恒有 |f(x) − A| < ε，则称常数 A 为函数 f(x) 当 x→x₀ 时的极限，记作"),
                    .formula("lim  f(x) = A   (x → x₀)"),
                    .para("定义中 0 < |x − x₀| 表示 x ≠ x₀，所以 x→x₀ 时 f(x) 有没有极限，与 f(x) 在点 x₀ 是否有定义并无关系。"),
                ]),
                BookPage(section: "第一章 函数与极限 · §1.6 两个重要极限", blocks: [
                    .heading("一、第一个重要极限"),
                    .formula("lim  sin x ⁄ x = 1   (x → 0)"),
                    .para("在单位圆中取圆心角 x（0 < x < π⁄2），比较三角形 AOB、扇形 AOB 与三角形 AOD 的面积，得 sin x < x < tan x。各式除以 sin x，取倒数，得 cos x < sin x ⁄ x < 1。"),
                    .para("当 x→0 时 cos x→1，由夹逼准则即得上式。x 换成 −x 时 sin x ⁄ x 不变，所以 x 从左侧趋于 0 时结论同样成立。"),
                    .box(title: "例 1", text: "求 lim (1 − cos x) ⁄ x²  (x→0)。"),
                    .formula("(1 − cos x) ⁄ x² = 2 sin²(x⁄2) ⁄ x² = ½ · [ sin(x⁄2) ⁄ (x⁄2) ]²  →  ½"),
                ]),
                BookPage(section: "第一章 函数与极限 · §1.6 两个重要极限", blocks: [
                    .heading("二、第二个重要极限"),
                    .formula("lim  (1 + 1⁄n)ⁿ = e   (n → ∞)"),
                    .para("先证数列 xₙ = (1 + 1⁄n)ⁿ 单调增加且有上界。按二项式定理展开，xₙ 的每一项都随 n 增大而增大，且项数也增加，故 xₙ < xₙ₊₁；又 xₙ < 1 + 1 + 1⁄2 + 1⁄2² + … < 3。由单调有界准则，极限存在，记为 e ≈ 2.71828。"),
                    .box(title: "例 2", text: "求 lim (1 − 2⁄x)ˣ  (x→∞)。"),
                    .formula("(1 − 2⁄x)ˣ = [ (1 + 1⁄(−x⁄2))^(−x⁄2) ]^(−2)  →  e⁻²"),
                    .note("习题 1-6：1.(1)(3)(5)  2.(2)(4)  4"),
                ]),
             ]),
        Book(id: "linear", shelf: .textbook, title: "线性代数", english: "Linear Algebra",
             subtitle: "第六版", author: "华辰大学数学系 编", publisher: "华辰教育出版社",
             layout: .textbook, motif: .matrix, base: c(0x2E6B4F), ink: .white, accent: c(0xE8D9A8),
             pages: [
                BookPage(section: "第三章 矩阵的初等变换与线性方程组 · §3.2 矩阵的秩", blocks: [
                    .box(title: "定义 4", text: "在 m×n 矩阵 A 中任取 k 行与 k 列（k ≤ m，k ≤ n），位于这些行列交叉处的 k² 个元素，不改变它们在 A 中所处的位置次序而得的 k 阶行列式，称为矩阵 A 的 k 阶子式。"),
                    .box(title: "定义 5", text: "设在矩阵 A 中有一个不等于 0 的 r 阶子式 D，且所有 r + 1 阶子式（如果存在的话）全等于 0，那么 D 称为矩阵 A 的最高阶非零子式，数 r 称为矩阵 A 的秩，记作 R(A)。"),
                    .para("由定义，零矩阵的秩等于 0；对 n 阶方阵 A，R(A) = n 当且仅当 |A| ≠ 0，此时称 A 为满秩矩阵。"),
                    .heading("定理 2  若 A ~ B，则 R(A) = R(B)。"),
                    .para("即初等变换不改变矩阵的秩。因此求秩时，只需把矩阵用初等行变换化为行阶梯形，行阶梯形中非零行的行数就是矩阵的秩。"),
                ]),
                BookPage(section: "第三章 · §3.3 线性方程组的解", blocks: [
                    .heading("定理 3  n 元线性方程组 Ax = b"),
                    .bullets(["无解的充分必要条件是 R(A) < R(A, b)；",
                              "有唯一解的充分必要条件是 R(A) = R(A, b) = n；",
                              "有无穷多解的充分必要条件是 R(A) = R(A, b) < n。"]),
                    .box(title: "例 9", text: "求解齐次线性方程组 x₁ + 2x₂ + 2x₃ + x₄ = 0，2x₁ + x₂ − 2x₃ − 2x₄ = 0，x₁ − x₂ − 4x₃ − 3x₄ = 0。"),
                    .para("对系数矩阵施行初等行变换化为行最简形，得 R(A) = 2 < 4，故方程组有非零解，自由未知数为 x₃, x₄。"),
                    .formula("x₁ = 2x₃ + (5⁄3)x₄，  x₂ = −2x₃ − (4⁄3)x₄"),
                    .note("习题三：9.(1)(3)  12  14"),
                ]),
             ]),
        Book(id: "probability", shelf: .textbook, title: "概率论与数理统计", english: "Probability and Statistics",
             subtitle: "第五版", author: "江城理工大学 编", publisher: "华辰教育出版社",
             layout: .textbook, motif: .bell, base: c(0x7A2E3A), ink: .white, accent: c(0xF0C9A0),
             pages: [
                BookPage(section: "第二章 随机变量及其分布 · §2.4 正态分布", blocks: [
                    .para("若连续型随机变量 X 的概率密度为"),
                    .formula("f(x) = 1 ⁄ (√(2π) σ) · e^(−(x−μ)² ⁄ 2σ²),  −∞ < x < +∞"),
                    .para("其中 μ，σ (σ > 0) 为常数，则称 X 服从参数为 μ，σ 的正态分布或高斯分布，记为 X ~ N(μ, σ²)。"),
                    .bullets(["曲线关于 x = μ 对称；",
                              "当 x = μ 时取到最大值 1 ⁄ (√(2π) σ)；",
                              "σ 越小，图形越陡峭，X 落在 μ 附近的概率越大。"]),
                    .box(title: "3σ 准则", text: "P{|X − μ| < σ} = 0.6827，P{|X − μ| < 2σ} = 0.9545，P{|X − μ| < 3σ} = 0.9973。"),
                ]),
                BookPage(section: "第五章 大数定律及中心极限定理", blocks: [
                    .box(title: "定理 4（独立同分布的中心极限定理）",
                         text: "设随机变量 X₁, X₂, …, Xₙ, … 相互独立，服从同一分布，且 E(Xₖ) = μ，D(Xₖ) = σ² > 0，则随机变量之和的标准化变量的分布函数对任意 x 满足"),
                    .formula("lim P{ (ΣXₖ − nμ) ⁄ (√n σ) ≤ x } = Φ(x)   (n → ∞)"),
                    .para("这就是说，当 n 充分大时，n 个独立同分布随机变量之和近似服从正态分布 N(nμ, nσ²)。在实际问题中，许多随机变量是由大量相互独立的随机因素综合影响形成的，因而往往近似服从正态分布。"),
                    .note("习题五：3  5  8"),
                ]),
             ]),
        Book(id: "physics", shelf: .textbook, title: "大学物理", english: "University Physics",
             subtitle: "力学 · 第四版", author: "北辰大学物理系 编", publisher: "华辰教育出版社",
             layout: .textbook, motif: .orbit, base: c(0x3C3A6E), ink: .white, accent: c(0x9FD3E6),
             pages: [
                BookPage(section: "第三章 动量守恒定律 · §3.2 动量定理", blocks: [
                    .para("牛顿第二定律可写成 F = dp ⁄ dt，其中 p = mv 为质点的动量。两边乘以 dt 并在 t₁ 到 t₂ 间积分，得"),
                    .formula("∫ F dt = p₂ − p₁"),
                    .para("左边称为力 F 在这段时间内的冲量 I。它表明：质点所受合外力的冲量等于质点动量的增量，这就是质点的动量定理。"),
                    .box(title: "例 3-2", text: "质量 m = 0.15 kg 的棒球以 v₀ = 40 m/s 水平飞来，被球棒击回，速度大小为 50 m/s，方向相反。若作用时间 Δt = 0.01 s，求球受到的平均冲力。"),
                    .formula("F̄ = m(v − v₀) ⁄ Δt = 0.15 × (50 + 40) ⁄ 0.01 = 1.35 × 10³ N"),
                ]),
                BookPage(section: "第三章 · §3.4 动量守恒定律", blocks: [
                    .para("对由 n 个质点组成的系统，内力总是成对出现、大小相等、方向相反，它们的矢量和为零。因此："),
                    .box(title: "动量守恒定律", text: "当系统所受合外力为零时，系统的总动量保持不变：Σ mᵢvᵢ = 常矢量。"),
                    .bullets(["合外力不为零，但某一方向上分量为零时，该方向上的动量守恒；",
                              "碰撞、爆炸等过程中内力远大于外力，可近似认为动量守恒；",
                              "动量守恒定律只适用于惯性系。"]),
                    .note("思考题 3-6  习题 3-9、3-12"),
                ]),
             ]),
        Book(id: "datastruct", shelf: .textbook, title: "数据结构", english: "Data Structures",
             subtitle: "C 语言版 · 第三版", author: "南岭大学计算机学院 编", publisher: "华辰教育出版社",
             layout: .textbook, motif: .network, base: c(0x22323F), ink: .white, accent: c(0x7FD1AE),
             pages: [
                BookPage(section: "第七章 图 · §7.4 最短路径", blocks: [
                    .heading("一、从某个源点到其余各顶点的最短路径"),
                    .para("迪杰斯特拉（Dijkstra）提出了按路径长度递增的次序产生最短路径的算法。设集合 S 存放已求出最短路径的顶点，初始时 S 中只有源点 v₀。"),
                    .bullets(["从 V − S 中选出 dist 值最小的顶点 vⱼ，把 vⱼ 加入 S；",
                              "对 V − S 中每个顶点 vₖ，若 dist[j] + w(j, k) < dist[k]，则更新 dist[k]；",
                              "重复上述步骤，直到 S = V。"]),
                    .para("算法的时间复杂度为 O(n²)。若用二叉堆实现优先队列，时间复杂度可降为 O((n + e) log n)。"),
                    .note("算法 7.15  ShortestPath_DIJ(G, v₀, P, D)"),
                ]),
             ]),
    ]

    // MARK: Professional

    static let professional: [Book] = [
        Book(id: "ml", shelf: .professional, title: "机器学习导论", english: "An Introduction to Machine Learning",
             subtitle: "原理、算法与实践", author: "林知远 著", publisher: "清岚科技出版社",
             layout: .professional, motif: .network, base: c(0xF3EFE6), ink: c(0x1E2A38), accent: c(0x2F6FDB),
             pages: [
                BookPage(section: "第 4 章 线性模型 · 4.3 梯度下降", blocks: [
                    .para("对于均方误差损失 L(w) = (1⁄2m) Σ (wᵀxᵢ − yᵢ)²，我们并不总是能求出闭式解。更一般的做法是从某个初始点出发，沿着损失下降最快的方向一步步移动参数："),
                    .formula("w ← w − η ∇L(w)"),
                    .para("其中 η 称为学习率。η 太小，收敛缓慢；η 太大，参数会在最优点附近来回震荡，甚至发散。实践中常用的办法是先取一个较大的学习率，再随训练轮数逐步衰减。"),
                    .box(title: "小批量梯度下降", text: "每一步只用 b 个样本估计梯度。它在计算量与梯度噪声之间取得了平衡：b 越大，估计越准，但每一步越慢。"),
                ]),
                BookPage(section: "第 5 章 模型评估 · 5.2 过拟合与正则化", blocks: [
                    .para("模型在训练集上表现很好、在新数据上表现很差，这种现象称为过拟合。其根源在于模型容量相对数据量过大，把训练数据中的噪声也当成了规律。"),
                    .bullets(["收集更多数据，或做数据增强；",
                              "降低模型复杂度，减少特征或参数；",
                              "加入正则项，如 L2 正则 λ‖w‖²；",
                              "提前停止：验证误差开始上升时停止训练。"]),
                    .table([["方法", "作用对象", "效果"],
                            ["L2 正则", "权重大小", "权重整体变小"],
                            ["L1 正则", "权重大小", "部分权重变为 0"],
                            ["Dropout", "隐藏单元", "相当于集成多个子网络"]]),
                ]),
             ]),
        Book(id: "finance", shelf: .professional, title: "公司金融", english: "Corporate Finance",
             subtitle: "第三版", author: "周以衡 著", publisher: "远桥经济出版社",
             layout: .professional, motif: .ledger, base: c(0xEFE9DC), ink: c(0x2B2118), accent: c(0x9C2B23),
             pages: [
                BookPage(section: "第 6 章 资本预算 · 6.1 净现值法则", blocks: [
                    .para("一个投资项目的净现值（NPV）等于它未来各期现金流按资本成本折现后的现值之和，减去初始投资："),
                    .formula("NPV = −C₀ + Σ Cₜ ⁄ (1 + r)ᵗ"),
                    .para("NPV 大于零的项目会增加股东财富，应当接受；NPV 小于零的项目应当拒绝。在资金不受限制时，按 NPV 选择项目总是正确的。"),
                    .box(title: "例 6.1", text: "某项目初始投资 1,000 万元，此后三年每年年末产生现金流 420 万元，资本成本 10%。"),
                    .formula("NPV = −1000 + 420 × (1⁄1.1 + 1⁄1.1² + 1⁄1.1³) ≈ 44.5 万元"),
                    .para("NPV 为正，项目可行。"),
                ]),
                BookPage(section: "第 9 章 资本成本 · 9.3 加权平均资本成本", blocks: [
                    .formula("WACC = E⁄V · r_E + D⁄V · r_D · (1 − T)"),
                    .para("其中 E、D 分别为股权与债务的市场价值，V = E + D，T 为公司所得税率。债务利息可在税前扣除，所以债务的实际成本是税后成本。"),
                    .bullets(["应使用市场价值而非账面价值作为权重；",
                              "股权成本通常用资本资产定价模型估计：r_E = r_f + β (r_m − r_f)；",
                              "当项目风险与公司整体风险不同时，不应直接使用公司的 WACC。"]),
                ]),
             ]),
        Book(id: "macro", shelf: .professional, title: "宏观经济学", english: "Macroeconomics",
             subtitle: "理论与中国实践", author: "沈启明 著", publisher: "远桥经济出版社",
             layout: .professional, motif: .line, base: c(0xE7ECEA), ink: c(0x17322B), accent: c(0x2E8B6E),
             pages: [
                BookPage(section: "第 10 章 总需求 · 10.2 IS–LM 模型", blocks: [
                    .para("IS 曲线描述产品市场均衡时利率 r 与收入 Y 的组合：利率下降刺激投资，总需求上升，均衡收入增加，所以 IS 曲线向右下方倾斜。"),
                    .para("LM 曲线描述货币市场均衡：收入增加使交易性货币需求上升，在货币供给不变时利率必须上升，所以 LM 曲线向右上方倾斜。"),
                    .box(title: "政策含义", text: "扩张性财政政策使 IS 右移，收入上升、利率上升；扩张性货币政策使 LM 右移，收入上升、利率下降。利率上升对私人投资的抑制称为挤出效应。"),
                ]),
             ]),
        Book(id: "civil", shelf: .professional, title: "民法总论", english: "General Principles of Civil Law",
             subtitle: "第二版", author: "韩松年 著", publisher: "正衡法律出版社",
             layout: .professional, motif: .scales, base: c(0xF1ECE1), ink: c(0x2A1F1A), accent: c(0x7B4A2B),
             pages: [
                BookPage(section: "第七章 民事法律行为 · 第三节 效力", blocks: [
                    .para("民事法律行为是民事主体通过意思表示设立、变更、终止民事法律关系的行为。其有效需同时满足三项要件："),
                    .bullets(["行为人具有相应的民事行为能力；",
                              "意思表示真实；",
                              "不违反法律、行政法规的强制性规定，不违背公序良俗。"]),
                    .para("欠缺上述要件的，依其情形分别为无效、可撤销或效力待定。可撤销的民事法律行为在被撤销之前是有效的，撤销权人应在法定期间内行使撤销权，逾期则撤销权消灭。"),
                    .note("参见本书第八章“代理”中关于无权代理的讨论。"),
                ]),
             ]),
    ]

    // MARK: General reading

    static let reading: [Book] = [
        Book(id: "bonfire", shelf: .reading, title: "从篝火到城市", english: "From Campfire to City",
             subtitle: "人类的十万年", author: "林远舟 著", publisher: "青川人文出版社",
             layout: .trade, motif: .horizon, base: c(0xF6F2EA), ink: c(0x1D1A16), accent: c(0xB0832F),
             pages: [
                BookPage(section: "第一部分 火 · 第 2 章 围着火的人", blocks: [
                    .heading("一堆火改变了什么"),
                    .para("在掌握用火之前，我们的祖先和其他大型动物没有太大区别：白天觅食，夜里躲避，吃下去的东西大多要靠一副长长的肠道慢慢消化。火让这一切悄悄改变了。"),
                    .para("烹煮让食物变软、变得更容易吸收。同样一块块茎，生吃需要咀嚼一个下午，烤熟之后几分钟就能吃完。省下来的时间和能量，流向了一个代价高昂的器官——大脑。"),
                    .box(title: "火边的夜晚", text: "火光把白天延长了几个小时。人们第一次有了一段既不觅食、也不睡觉的时间。故事、歌和计划，很可能就诞生在这几个小时里。"),
                    .para("火还是第一种被人类“驯服”的自然力量。会用火的群体可以清理灌木、驱赶猛兽，甚至改变一整片土地的植被。从这时起，人类不再只是适应环境，而是开始改造环境。"),
                ]),
                BookPage(section: "第二部分 种子 · 第 7 章 被小麦驯化的人", blocks: [
                    .heading("一场缓慢的交换"),
                    .para("农业常被描述为一次伟大的进步，但对最早的农人来说，它首先意味着更长的劳动时间、更单调的饮食和更多的疾病。一个采集者熟悉上百种植物，一个农人往往只依赖两三种。"),
                    .para("那么人们为什么还是留在了田里？答案或许是：每一代人只多走了一小步。多开一块地、多存一点粮，就能多养活一个孩子。等到人口增长、旧的生活方式再也养不活这么多人时，回头的路已经消失了。"),
                    .bullets(["定居让人口密度上升，村落变成了城镇；",
                              "储存的粮食需要看守，于是有了围墙和管理者；",
                              "记账的需要催生了最早的文字。"]),
                    .note("第 7 章注释见书末第 412 页。"),
                ]),
             ]),
        Book(id: "crew", shelf: .reading, title: "小团队，大航程", english: "Small Crew, Long Voyage",
             subtitle: "创业公司的前一百人", author: "陈牧野 著", publisher: "远桥经济出版社",
             layout: .trade, motif: .sail, base: c(0x23463F), ink: c(0xF4EFE3), accent: c(0xE9B949),
             pages: [
                BookPage(section: "第 3 章 第一批人", blocks: [
                    .heading("前十个人决定了公司的性格"),
                    .para("一家公司的文化并不写在墙上，而是写在最早那几个人的习惯里：他们怎么开会、怎么争论、怎么对待一个做砸了的项目。后来的人会照着这些习惯行事，哪怕没有人明说。"),
                    .box(title: "招聘的一条笨办法", text: "在发出录用通知之前，问自己：如果明天只剩下我们两个人，我还愿意和他一起把公司做下去吗？如果犹豫了，就再等一等。"),
                    .para("早期团队最怕的不是能力不够，而是方向不一致。一个人想做小而美的工具，另一个人想做改变行业的平台，两个人都很优秀，公司却会在拉扯中耗尽力气。"),
                ]),
                BookPage(section: "第 8 章 从 30 人到 100 人", blocks: [
                    .heading("当你不再认识每一个人"),
                    .para("大约在三十人前后，创始人会第一次发现：有些决定是在自己不知道的情况下做出的。这是好事，也是危险的信号。好事在于组织开始自己运转；危险在于，信息开始在层级之间走样。"),
                    .bullets(["把“为什么”写下来：每个重要决定附上一段背景；",
                              "每周固定一次全员同步，十五分钟，只讲变化；",
                              "让新人在第一个月里各跟一位老员工做一个完整项目。"]),
                    .table([["人数", "最常见的问题", "建议"],
                            ["1–10", "方向分歧", "先对齐目标，再分工"],
                            ["10–30", "职责重叠", "每件事只有一个负责人"],
                            ["30–100", "信息失真", "写下来，并定期复盘"]]),
                ]),
             ]),
        Book(id: "nightrepair", shelf: .reading, title: "夜间修复", english: "The Night Shift of the Brain",
             subtitle: "睡眠如何重塑大脑", author: "苏既白 著", publisher: "青川人文出版社",
             layout: .trade, motif: .waves, base: c(0x15233F), ink: c(0xEEF2F8), accent: c(0xF2D27A),
             pages: [
                BookPage(section: "第 2 章 一夜的四个阶段", blocks: [
                    .para("睡眠并不是一盏灯被关掉，而更像一部有固定段落的乐曲。一个晚上，大脑大约要把这部乐曲演奏四到六遍，每一遍约九十分钟。"),
                    .table([["阶段", "脑电特征", "主要作用"],
                            ["N1 入睡", "节律变慢", "从清醒过渡"],
                            ["N2 浅睡", "睡眠纺锤波", "巩固短时记忆"],
                            ["N3 深睡", "高幅慢波", "身体修复、清除代谢物"],
                            ["REM 快速眼动", "接近清醒", "情绪整理、做梦"]]),
                    .para("前半夜深睡比例高，后半夜快速眼动睡眠逐渐增加。所以只睡五六个小时，损失最多的往往是清晨那几段快速眼动睡眠。"),
                ]),
                BookPage(section: "第 5 章 熬夜的账单", blocks: [
                    .heading("缺觉的大脑在做什么"),
                    .para("连续几晚少睡两小时，人往往觉得自己“已经适应了”。但在注意力测试中，他们的表现会持续下滑，而且自己感觉不到。缺觉最狡猾的地方，正在于它会削弱我们判断自己有多缺觉的能力。"),
                    .box(title: "几条朴素的建议", text: "固定起床时间，比固定入睡时间更重要；睡前一小时调暗灯光；下午两点以后少喝含咖啡因的饮料；卧室保持凉爽、安静、黑暗。"),
                    .note("参见附录 B：睡眠日记模板。"),
                ]),
             ]),
        Book(id: "almanac", shelf: .reading, title: "慢慢变富的常识", english: "Common Sense for Getting Rich Slowly",
             subtitle: "关于财富、判断与幸福的笔记", author: "顾言 编", publisher: "远桥经济出版社",
             layout: .trade, motif: .rule, base: c(0xFAFAF7), ink: c(0x111111), accent: c(0x111111),
             pages: [
                BookPage(section: "第一辑 财富", blocks: [
                    .heading("1"),
                    .para("财富不是工资单上的数字，而是你在不工作的时候仍然在增长的东西：一项技能、一份产品、一笔被时间慢慢放大的投资。"),
                    .heading("2"),
                    .para("存钱的第一步不是记账，而是给自己定一个“够用”的数字。不知道多少才算够的人，赚得再多也会觉得不安。"),
                    .heading("3"),
                    .para("复利对金钱有效，对知识和人际关系同样有效。和值得信任的人长期合作，是回报最高、也最容易被低估的投资。"),
                ]),
                BookPage(section: "第二辑 判断", blocks: [
                    .heading("12"),
                    .para("大多数错误的决定，不是因为想得不够多，而是因为在情绪最强烈的时候做了决定。重要的事，隔一夜再说。"),
                    .heading("13"),
                    .para("如果一件事你需要不停说服自己去做，它多半不适合你。找到那些别人觉得是工作、你却觉得像玩的事情。"),
                    .heading("14"),
                    .para("每年挑一件小事认真做到底：学会做一道菜、跑完一次十公里、读完一套难啃的书。能力是这样一点点攒出来的。"),
                ]),
             ]),
        Book(id: "critique", shelf: .reading, title: "纯粹理性批判", english: "Kritik der reinen Vernunft",
             subtitle: "汉译学术经典 · 第一辑", author: "［德］康德 著", publisher: "远山书局",
             layout: .classic, motif: .crest, base: c(0xE6EDF2), ink: c(0x1C2A3A), accent: c(0xA9873E),
             pages: [
                BookPage(section: "导言 · 一 纯粹知识与经验性知识的区别", blocks: [
                    .para("我们的一切知识都从经验开始，这一点是毫无疑问的。因为，如果不是对象刺激我们的感官，一方面由它们自己产生出表象，另一方面推动我们的知性活动去比较、联结或分离这些表象，从而把感性印象的原始材料加工成关于对象的知识，那么我们的认识能力又靠什么被唤醒而活动起来呢？"),
                    .para("因此，就时间而言，我们没有任何知识先于经验，一切知识都从经验开始。"),
                    .para("然而，即使我们的一切知识都以经验开始，它们却并不因此全都源于经验。因为很可能，就连我们的经验知识，也是由我们通过印象所接受的东西，和我们自己的认识能力（感官印象仅仅是诱因）从自身中提供的东西组合而成的。"),
                    .note("译注：此处“先天的”（a priori）指不依赖于一切经验的知识，与“后天的”（a posteriori）即只有通过经验才可能的知识相对。"),
                ]),
                BookPage(section: "导言 · 四 分析判断与综合判断的区别", blocks: [
                    .para("在一切判断中，主词与谓词的关系有两种可能：要么谓词 B 属于主词 A，作为（隐蔽地）包含在 A 这个概念中的东西；要么 B 完全在 A 之外，虽然与它相联结。前一种情形我称之为分析判断，后一种称之为综合判断。"),
                    .box(title: "例", text: "“一切物体都有广延”是一个分析判断：广延本就包含在物体的概念之中。“一切物体都有重量”则是综合判断：重量这一谓词，是我在物体的一般概念之外附加上去的。"),
                    .para("于是，本书真正要回答的问题可以表述为：先天综合判断是如何可能的？"),
                    .note("译注：本书正文依据 1787 年第二版译出。"),
                ]),
             ]),
        Book(id: "prolegomena", shelf: .reading, title: "未来形而上学导论", english: "Prolegomena zu einer jeden künftigen Metaphysik",
             subtitle: "任何一种能够作为科学出现的未来形而上学", author: "［德］康德 著", publisher: "远山书局",
             layout: .classic, motif: .crest, base: c(0xF7F5EF), ink: c(0x1E1B17), accent: c(0x8E2F25),
             pages: [
                BookPage(section: "序言", blocks: [
                    .para("这部导论不是为学生准备的，而是为未来的教师准备的；即使对他们，它也不是用来整理一门现成科学的讲授，而是首先用来发现这门科学本身。"),
                    .para("我坦率地承认：正是对休谟的回忆，在多年以前首先打断了我的独断论迷梦，并给我在思辨哲学领域的研究指出了一个全新的方向。"),
                    .box(title: "本书的问题", text: "形而上学究竟是否可能？如果它是一门科学，为什么它不能像其他科学那样得到普遍而持久的赞同？如果它不是，为什么它又总是以科学的样子出现，用永远不能兑现的希望来吸引人类的理智？"),
                    .note("译注：本书初版于 1783 年，意在以较简明的方式阐述《纯粹理性批判》的要旨。"),
                ]),
                BookPage(section: "总问题 · 纯粹数学是如何可能的？", blocks: [
                    .para("数学知识有一个特点：它必须先在直观中，而且是在先天的直观中，表现出它的概念。因此，数学的判断总是直观的，而哲学只能满足于从单纯概念出发的推论性判断。"),
                    .para("几何学以空间的纯粹直观为基础，算术则在时间中通过单位的相继相加来形成它的数概念。如果从经验性的物体直观中去掉一切经验的东西，剩下的就只有空间和时间。"),
                    .note("参见本书 § 6 — § 13。"),
                ]),
             ]),
    ]

    // MARK: Reports

    static let reports: [Book] = [
        Book(id: "ev2026", shelf: .report, title: "新能源汽车行业深度报告", english: "New Energy Vehicles · Industry In-Depth",
             subtitle: "渗透率过半之后：从规模到利润", author: "启明证券研究所 · 汽车组", publisher: "2026 年 10 月",
             layout: .research, motif: .bars, base: .white, ink: c(0x1A2433), accent: c(0xC8102E),
             pages: [
                BookPage(section: "投资要点", blocks: [
                    .para("2026 年前三季度国内新能源乘用车零售渗透率首次稳定在 50% 以上，行业从“抢份额”转向“拼利润”。我们认为未来两年竞争焦点将从价格转向智能化与海外渠道。"),
                    .bullets(["价格战边际缓和：头部车企三季度单车均价环比降幅收窄至 1.2%；",
                              "智能驾驶成为第二增长曲线：城市领航功能搭载率预计 2027 年达 45%；",
                              "出海加速：海外销量占比有望从 18% 提升至 28%。"]),
                    .box(title: "评级", text: "维持行业“强于大市”评级。"),
                    .note("风险提示：需求不及预期；原材料价格大幅波动；海外贸易政策变化。"),
                ]),
                BookPage(section: "一、销量与渗透率", blocks: [
                    .table([["", "2024", "2025", "2026E", "2027E"],
                            ["销量（万辆）", "1,287", "1,566", "1,792", "1,950"],
                            ["同比", "35.5%", "21.7%", "14.4%", "8.8%"],
                            ["渗透率", "40.9%", "47.2%", "53.0%", "57.5%"]]),
                    .para("增速放缓的主要原因是基数抬高与换购周期拉长。分价格带看，10–20 万元区间占比最高，达 46%；30 万元以上区间增速最快。"),
                    .note("数据来源：启明证券研究所整理及预测。"),
                ]),
             ]),
        Book(id: "semis", shelf: .report, title: "半导体设备行业 2027 年度策略", english: "Semiconductor Equipment · 2027 Outlook",
             subtitle: "国产化率进入加速段", author: "衡远证券研究院 · 电子组", publisher: "2026 年 10 月",
             layout: .research, motif: .wafer, base: .white, ink: c(0x142033), accent: c(0x0B5FAE),
             pages: [
                BookPage(section: "核心观点", blocks: [
                    .para("我们预计 2027 年全球晶圆厂设备支出同比增长 8%，其中国内市场占比维持在 30% 以上。刻蚀、薄膜沉积环节的国产化率已超过 25%，量测与涂胶显影仍是主要短板。"),
                    .table([["环节", "2025 国产化率", "2027E"],
                            ["刻蚀", "24%", "33%"],
                            ["薄膜沉积", "21%", "30%"],
                            ["清洗", "35%", "42%"],
                            ["量测", "8%", "14%"]]),
                    .note("风险提示：下游扩产不及预期；技术验证周期拉长。"),
                ]),
             ]),
        Book(id: "annual2025", shelf: .report, title: "2025 年年度报告", english: "Annual Report 2025",
             subtitle: "星衡科技股份有限公司", author: "证券代码：688xxx", publisher: "2026 年 3 月",
             layout: .financial, motif: .columns, base: c(0x0F2B3D), ink: .white, accent: c(0xC9A55A),
             pages: [
                BookPage(section: "第二节 公司简介和主要财务指标", blocks: [
                    .heading("一、主要会计数据"),
                    .table([["项目（万元）", "2025 年", "2024 年", "增减"],
                            ["营业收入", "486,215", "402,733", "20.73%"],
                            ["归母净利润", "52,708", "41,960", "25.61%"],
                            ["扣非净利润", "47,391", "38,215", "24.01%"],
                            ["经营活动现金流", "61,054", "45,872", "33.10%"]]),
                    .heading("二、主要财务指标"),
                    .table([["指标", "2025 年", "2024 年"],
                            ["基本每股收益（元）", "1.32", "1.05"],
                            ["加权平均净资产收益率", "14.86%", "13.02%"],
                            ["研发投入占营收比例", "11.4%", "10.8%"]]),
                ]),
                BookPage(section: "第三节 管理层讨论与分析", blocks: [
                    .para("报告期内，公司围绕“平台化、国际化”战略，持续加大研发投入。工业控制产品线收入同比增长 27.4%，成为第一大收入来源；海外收入占比由 19.6% 提升至 24.3%。"),
                    .para("毛利率为 38.7%，同比提升 1.1 个百分点，主要得益于高附加值产品占比提升与规模效应。销售费用率下降 0.6 个百分点，管理费用率基本持平。"),
                    .box(title: "利润分配预案", text: "以总股本为基数，向全体股东每 10 股派发现金红利 3.50 元（含税），不送红股，不以资本公积转增股本。"),
                ]),
             ]),
        Book(id: "q3earnings", shelf: .report, title: "2026 年第三季度业绩报告", english: "Q3 2026 Earnings",
             subtitle: "衡远电子集团", author: "投资者关系部", publisher: "2026 年 10 月 16 日",
             layout: .financial, motif: .pie, base: c(0x1C1F26), ink: .white, accent: c(0x3FB8AF),
             pages: [
                BookPage(section: "业绩概览", blocks: [
                    .table([["（亿元）", "Q3 2026", "Q3 2025", "同比"],
                            ["营业收入", "128.6", "109.4", "+17.6%"],
                            ["毛利", "33.7", "27.3", "+23.4%"],
                            ["经营利润", "14.2", "10.9", "+30.3%"],
                            ["净利润", "11.5", "8.8", "+30.7%"]]),
                    .para("毛利率 26.2%，同比提升 1.2 个百分点；稀释每股收益 0.84 元。本季度汽车电子业务收入同比增长 41%，占总收入比重首次超过三分之一。"),
                ]),
                BookPage(section: "业务分部与指引", blocks: [
                    .table([["分部", "收入（亿元）", "同比", "占比"],
                            ["消费电子", "52.3", "+4.8%", "40.7%"],
                            ["汽车电子", "43.9", "+41.0%", "34.1%"],
                            ["工业与能源", "32.4", "+15.2%", "25.2%"]]),
                    .box(title: "第四季度指引", text: "预计营业收入 135–140 亿元，毛利率 25.5%–26.5%。"),
                    .note("本报告中的前瞻性陈述受多种风险及不确定因素影响，实际结果可能与之存在重大差异。"),
                ]),
             ]),
        Book(id: "macro202610", shelf: .report, title: "宏观经济月报", english: "Macro Monthly · October 2026",
             subtitle: "需求温和修复，政策靠前发力", author: "远桥研究院 · 宏观组", publisher: "2026 年 10 月",
             layout: .research, motif: .line, base: .white, ink: c(0x1D2A24), accent: c(0x1F7A57),
             pages: [
                BookPage(section: "本月要点", blocks: [
                    .table([["指标", "9 月", "8 月", "预期"],
                            ["工业增加值同比", "5.6%", "5.2%", "5.4%"],
                            ["社零总额同比", "4.1%", "3.7%", "3.9%"],
                            ["固定资产投资累计同比", "3.8%", "3.9%", "3.8%"],
                            ["CPI 同比", "0.6%", "0.4%", "0.5%"]]),
                    .para("9 月生产与消费双双回升，投资基本持平。地产链仍在筑底，但基建与设备更新投资对冲了部分拖累。我们预计四季度 GDP 同比增长 5.0% 左右。"),
                    .note("数据来源：远桥研究院整理。"),
                ]),
             ]),
    ]
}
