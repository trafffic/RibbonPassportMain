import SwiftUI
import CoreText

enum PixelFont {
    private static let registered: Void = {
        if let url = Bundle.main.url(forResource: "PixelifySans", withExtension: "ttf", subdirectory: "RibbonAssets/Fonts") {
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }()
    static func font(_ size: CGFloat, style: WidgetStyle = WidgetStyle()) -> Font {
        _ = registered
        let scaled = size * min(1.15, max(0.85, style.textScale))
        return style.typeface == .pixel ? .custom("PixelifySans-Regular", size: scaled, relativeTo: .body) : .system(size: scaled)
    }
}

struct RetroPanel: ViewModifier {
    var padding: CGFloat = 12
    @Environment(\.colorScheme) private var scheme
    func body(content: Content) -> some View {
        let t = PassportTheme(dark: scheme == .dark, game: "")
        content.padding(padding).background(t.panel).overlay(Rectangle().stroke(t.border, lineWidth: 1))
    }
}
extension View {
    func retroPanel(padding: CGFloat = 12) -> some View { modifier(RetroPanel(padding: padding)) }
}
struct RetroAction: ButtonStyle {
    var prominent = false
    @Environment(\.colorScheme) private var scheme
    func makeBody(configuration: Configuration) -> some View {
        let t = PassportTheme(dark: scheme == .dark, game: "")
        configuration.label.font(PixelFont.font(16)).padding(.horizontal, 12).padding(.vertical, 11)
            .frame(minHeight: 44).background(prominent ? t.ink : t.panel)
            .foregroundStyle(prominent ? t.paper : t.ink)
            .overlay(Rectangle().stroke(t.border, lineWidth: 1)).opacity(configuration.isPressed ? 0.65 : 1)
    }
}
struct RetroHeading: View {
    var title: String
    var value: String = ""
    var body: some View {
        HStack { Text(title).font(PixelFont.font(20)); Spacer(); Text(value).font(PixelFont.font(13)).foregroundStyle(.secondary) }
    }
}
struct GameMascot: View {
    var game: String
    var size: CGFloat = 24
    @Environment(\.colorScheme) private var scheme
    var body: some View {
        AssetImage(key: "game-\(game)-\(scheme == .dark ? "dark" : "light")")
            .frame(width: game == "scar" ? min(size, 64) : size, height: game == "scar" ? min(size, 64) : size)
            .frame(width: size, height: size)
            .accessibilityLabel(RibbonCatalog.shared.gameName(game))
    }
}

/// Original pixel scenery shared by PC boxes and widget packs.
struct PixelWallpaperView: View {
    var settings: WallpaperSettings
    var dark: Bool
    var base: Color
    var body: some View {
        let tint = Color(hex: settings.colorHex)
        let strength = min(1, max(0, settings.strength))
        ZStack {
            base
            tint.opacity(0.08 + strength * 0.19)
            Canvas { context, size in
                let sx = size.width / 160, sy = size.height / 120
                func rect(_ x: Double, _ y: Double, _ w: Double, _ h: Double, _ opacity: Double = 1) {
                    context.fill(Path(CGRect(x: x * sx, y: y * sy, width: w * sx, height: h * sy)), with: .color(tint.opacity(opacity * strength)))
                }
                func steps(_ points: [CGPoint], opacity: Double) {
                    var p = Path(); p.addLines(points.map { CGPoint(x: $0.x * sx, y: $0.y * sy) }); p.closeSubpath()
                    context.fill(p, with: .color(tint.opacity(opacity * strength)))
                }
                switch settings.design {
                case .classic:
                    for x in stride(from: 0, to: 160, by: 8) { rect(Double(x), 0, 0.4, 120, 0.3) }
                    for y in stride(from: 0, to: 120, by: 8) { rect(0, Double(y), 160, 0.4, 0.3) }
                    rect(0, 0, 160, 3, 0.4); rect(0, 117, 160, 3, 0.4)
                case .meadow:
                    steps([CGPoint(x: 0, y: 84), CGPoint(x: 20, y: 84), CGPoint(x: 20, y: 76), CGPoint(x: 46, y: 76), CGPoint(x: 46, y: 88), CGPoint(x: 82, y: 88), CGPoint(x: 82, y: 80), CGPoint(x: 116, y: 80), CGPoint(x: 116, y: 72), CGPoint(x: 142, y: 72), CGPoint(x: 142, y: 84), CGPoint(x: 160, y: 84), CGPoint(x: 160, y: 120), CGPoint(x: 0, y: 120)], opacity: 0.35)
                    for i in 0..<18 { let x = Double((i * 37 + 9) % 157), y = Double(93 + (i * 13) % 25); rect(x, y, 1, 3, 0.65); rect(x + 2, y - 1, 1, 4, 0.65) }
                    rect(13, 17, 17, 3, 0.25); rect(18, 14, 8, 3, 0.25); rect(106, 28, 22, 3, 0.25)
                case .woodland:
                    rect(0, 100, 160, 20, 0.25)
                    for i in 0..<8 {
                        let x = Double(i * 24 - 12), y = Double(54 + (i % 3) * 12)
                        rect(x + 9, y + 24, 4, 25, 0.6); rect(x, y + 14, 24, 13, 0.4)
                        rect(x + 4, y + 6, 16, 10, 0.4); rect(x + 8, y, 8, 6, 0.4)
                    }
                case .seaside:
                    rect(0, 83, 160, 37, 0.24)
                    for row in 0..<4 { for i in 0..<7 { rect(Double(i * 29 + (row % 2) * 12 - 8), Double(86 + row * 9), 17, 2, 0.65) } }
                    rect(119, 16, 12, 12, 0.35); rect(116, 19, 18, 6, 0.35)
                case .dunes:
                    steps([CGPoint(x: 0, y: 90), CGPoint(x: 18, y: 90), CGPoint(x: 18, y: 82), CGPoint(x: 40, y: 82), CGPoint(x: 40, y: 74), CGPoint(x: 62, y: 74), CGPoint(x: 62, y: 82), CGPoint(x: 99, y: 82), CGPoint(x: 99, y: 94), CGPoint(x: 130, y: 94), CGPoint(x: 130, y: 86), CGPoint(x: 160, y: 86), CGPoint(x: 160, y: 120), CGPoint(x: 0, y: 120)], opacity: 0.3)
                    rect(126, 83, 4, 20, 0.7); rect(120, 88, 6, 4, 0.7); rect(120, 83, 3, 7, 0.7); rect(130, 94, 6, 3, 0.7); rect(133, 88, 3, 9, 0.7)
                    for i in 0..<15 { rect(Double((i * 37) % 160), Double(102 + (i * 7) % 16), 2, 1, 0.7) }
                case .starfield:
                    for i in 0..<35 {
                        let x = Double((i * 47 + 13) % 158), y = Double((i * 31 + 7) % 118)
                        rect(x, y, 1, 1, 0.8)
                        if i % 9 == 0 { rect(x - 1, y, 3, 1, 0.7); rect(x, y - 1, 1, 3, 0.7) }
                    }
                    rect(125, 19, 12, 12, 0.3); rect(122, 22, 18, 6, 0.3)
                }
            }
        }.clipped().allowsHitTesting(false).accessibilityHidden(true)
    }
}

private enum SunMoonArtwork {
    static let images: [SunMoonWallpaper: UIImage] = Dictionary(uniqueKeysWithValues: SunMoonWallpaper.allCases.compactMap { wallpaper in
        guard let url = Bundle.main.url(forResource: wallpaper.filename, withExtension: "png", subdirectory: "RibbonAssets/Wallpapers"),
              let image = UIImage(contentsOfFile: url.path) else { return nil }
        return (wallpaper, image)
    })
}
struct BoxWallpaperView: View {
    var settings: WallpaperSettings
    var fullArtwork = false
    static func image(for wallpaper: SunMoonWallpaper) -> UIImage? { SunMoonArtwork.images[wallpaper] }
    var body: some View {
        GeometryReader { geometry in
            if let artwork = Self.image(for: settings.sunMoon ?? .forest) {
                if fullArtwork {
                    Image(uiImage: artwork).resizable().interpolation(.none)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                } else {
                    Image(uiImage: artwork).resizable().interpolation(.none)
                        .frame(width: geometry.size.width * PCGridMetrics.artworkWidth / PCGridMetrics.gridWidth, height: geometry.size.height * PCGridMetrics.artworkHeight / PCGridMetrics.gridHeight)
                        .offset(x: -geometry.size.width * PCGridMetrics.originX / PCGridMetrics.gridWidth, y: -geometry.size.height * PCGridMetrics.originY / PCGridMetrics.gridHeight)
                }
                if let tint = settings.tint { Color(hex: tint).opacity(min(1, max(0, settings.strength)) * 0.5) }
            }
        }.clipped().allowsHitTesting(false).accessibilityHidden(true)
    }
}
