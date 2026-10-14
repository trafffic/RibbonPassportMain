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
