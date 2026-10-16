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
    @Environment(\.isEnabled) private var enabled
    var prominent = false
    @Environment(\.colorScheme) private var scheme
    func makeBody(configuration: Configuration) -> some View {
        let t = PassportTheme(dark: scheme == .dark, game: "")
        configuration.label.font(PixelFont.font(16)).padding(.horizontal, 12).padding(.vertical, 11)
            .frame(minHeight: 44).background(prominent ? t.ink : t.panel)
            .foregroundStyle(prominent ? t.paper : t.ink)
            .overlay(Rectangle().stroke(t.border, lineWidth: 1)).opacity(!enabled ? 0.4 : configuration.isPressed ? 0.65 : 1)
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

/// Small, original bitmap glyphs for the app's navigation controls.
struct TerminalGlyph: View {
    enum Kind { case back, ribbons, competitive, settings }
    var kind: Kind
    private var pixels: [String] {
        switch kind {
        case .back: return ["00010000", "00110000", "01111111", "11111111", "01111111", "00110000", "00010000", "00000000"]
        case .ribbons: return ["00111100", "01100110", "11011011", "11011011", "01100110", "00111100", "00100100", "01100110"]
        case .competitive: return ["00011000", "00110000", "01100000", "11111110", "00011100", "00111000", "01110000", "01100000"]
        case .settings: return ["00111100", "10111101", "11100111", "11000011", "11000011", "11100111", "10111101", "00111100"]
        }
    }
    var body: some View {
        Canvas { context, size in
            let unit = floor(min(size.width, size.height) / 8)
            let origin = CGPoint(x: (size.width - unit * 8) / 2, y: (size.height - unit * 8) / 2)
            for (y, row) in pixels.enumerated() {
                for (x, pixel) in row.enumerated() where pixel == "1" {
                    context.fill(Path(CGRect(x: origin.x + CGFloat(x) * unit, y: origin.y + CGFloat(y) * unit, width: unit, height: unit)), with: .foreground)
                }
            }
        }.accessibilityHidden(true)
    }
}

struct TerminalBackControl: ViewModifier {
    @Environment(\.dismiss) private var dismiss
    var title = "Back"
    private var button: some View {
        Button { dismiss() } label: {
            HStack(spacing: 6) {
                TerminalGlyph(kind: .back).frame(width: 16, height: 16)
                Text(title).font(PixelFont.font(14))
            }
        }.buttonStyle(RetroAction()).accessibilityLabel(title).accessibilityIdentifier("navigation.back")
    }
    func body(content: Content) -> some View {
        content.navigationBarBackButtonHidden(true).toolbar {
            if #available(iOS 26.0, *) {
                ToolbarItem(placement: .topBarLeading) { button }.sharedBackgroundVisibility(.hidden)
            } else {
                ToolbarItem(placement: .topBarLeading) { button }
            }
        }
    }
}
extension View {
    func terminalBackControl(_ title: String = "Back") -> some View { modifier(TerminalBackControl(title: title)) }
}

struct TerminalToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button { configuration.isOn.toggle() } label: {
            HStack(spacing: 8) {
                configuration.label
                Spacer(minLength: 4)
                Text(configuration.isOn ? "ON" : "OFF").font(PixelFont.font(12))
                    .frame(width: 44, height: 28).background(configuration.isOn ? Color(hex: "718F4E") : Color.secondary.opacity(0.15))
                    .foregroundStyle(configuration.isOn ? Color.white : Color.primary)
                    .overlay(Rectangle().stroke(Color.secondary, lineWidth: 1))
            }.frame(minHeight: 36).contentShape(Rectangle())
        }.buttonStyle(.plain).accessibilityRepresentation {
            Toggle(isOn: configuration.$isOn) { configuration.label }.toggleStyle(.switch)
        }
    }
}

struct TerminalSelector<Value: Hashable>: View {
    var title: String
    @Binding var selection: Value
    var values: [Value]
    var name: (Value) -> String
    var inline = false
    var identifier = ""
    @State private var presented = false
    @Environment(\.colorScheme) private var scheme
    var body: some View {
        let theme = PassportTheme(dark: scheme == .dark, game: "")
        Group {
            if inline {
                HStack(spacing: 5) {
                    ForEach(values, id: \.self) { value in
                        Button { selection = value } label: {
                            Text(name(value)).font(PixelFont.font(14)).lineLimit(1).minimumScaleFactor(0.7)
                                .frame(maxWidth: .infinity, minHeight: 40)
                                .foregroundStyle(selection == value ? theme.paper : theme.ink)
                                .background(selection == value ? theme.accent : theme.panel)
                                .overlay(Rectangle().stroke(theme.border))
                        }.buttonStyle(.plain).accessibilityAddTraits(selection == value ? .isSelected : [])
                            .accessibilityIdentifier(identifier + "." + String(describing: value))
                    }
                }
            } else {
                Button { presented = true } label: {
                    HStack { Text(title); Spacer(minLength: 4); Text(name(selection)).foregroundStyle(theme.accent); Text("▾") }
                        .font(PixelFont.font(15)).frame(minHeight: 40).padding(.horizontal, 8)
                        .background(theme.panel).overlay(Rectangle().stroke(theme.border))
                }.buttonStyle(.plain).accessibilityLabel(title + ": " + name(selection))
            }
        }.accessibilityElement(children: .contain).accessibilityIdentifier(identifier)
        .sheet(isPresented: $presented) {
            TerminalPanel(title: title, onClose: { presented = false }) {
                ForEach(values, id: \.self) { value in
                    Button { selection = value; presented = false } label: {
                        HStack { Text(name(value)); Spacer(); if selection == value { Text("✓") } }.frame(maxWidth: .infinity, minHeight: 44)
                    }.buttonStyle(RetroAction()).accessibilityAddTraits(selection == value ? .isSelected : [])
                }
            }
        }
    }
}

struct TerminalPanel<Content: View>: View {
    var title: String
    var onClose: () -> Void
    @ViewBuilder var content: () -> Content
    @Environment(\.colorScheme) private var scheme
    var body: some View {
        let theme = PassportTheme(dark: scheme == .dark, game: "")
        VStack(spacing: 0) {
            HStack { Text(title.uppercased()).font(PixelFont.font(20)); Spacer(); Button("Close", action: onClose).buttonStyle(RetroAction()) }.padding(12)
            Rectangle().fill(theme.border).frame(height: 1)
            ScrollView { VStack(alignment: .leading, spacing: 8, content: content).frame(maxWidth: .infinity).padding(12) }
        }.background(theme.paper).foregroundStyle(theme.ink).font(PixelFont.font(16)).toggleStyle(TerminalToggleStyle())
    }
}

private struct TerminalMenuRow: PrimitiveButtonStyle {
    var close: () -> Void
    func makeBody(configuration: Configuration) -> some View {
        Button {
            close()
            // Wait for this action board to close before presenting another sheet.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { configuration.trigger() }
        } label: { configuration.label.frame(maxWidth: .infinity, minHeight: 44, alignment: .leading) }
            .buttonStyle(RetroAction())
    }
}
struct TerminalMenu<Content: View, Label: View>: View {
    @ViewBuilder var content: () -> Content
    @ViewBuilder var label: () -> Label
    @State private var presented = false
    var body: some View {
        Button { presented = true } label: { label() }.buttonStyle(RetroAction())
            .sheet(isPresented: $presented) {
                NavigationStack {
                    TerminalPanel(title: "Options", onClose: { presented = false }) {
                        content().buttonStyle(TerminalMenuRow(close: { presented = false }))
                    }.toolbar(.hidden, for: .navigationBar)
                }
            }
    }
}

struct TerminalToolbarItem<Content: View>: ToolbarContent {
    var placement: ToolbarItemPlacement = .automatic
    @ViewBuilder var content: () -> Content
    var body: some ToolbarContent {
        if #available(iOS 26.0, *) {
            ToolbarItem(placement: placement) { content().buttonStyle(RetroAction()) }.sharedBackgroundVisibility(.hidden)
        } else {
            ToolbarItem(placement: placement) { content().buttonStyle(RetroAction()) }
        }
    }
}

struct TerminalSlider: View {
    @Binding var value: Double
    var bounds: ClosedRange<Double>
    var step: Double
    init(value: Binding<Double>, in bounds: ClosedRange<Double>, step: Double = 0.01) { _value = value; self.bounds = bounds; self.step = step }
    private func set(_ raw: Double) { value = min(bounds.upperBound, max(bounds.lowerBound, bounds.lowerBound + ((raw - bounds.lowerBound) / step).rounded() * step)) }
    var body: some View {
        HStack(spacing: 8) {
            Button("−") { set(value - step) }.accessibilityLabel("Decrease")
            GeometryReader { g in
                let fraction = (value - bounds.lowerBound) / (bounds.upperBound - bounds.lowerBound)
                ZStack(alignment: .leading) {
                    Rectangle().fill(Color.secondary.opacity(0.25)).frame(height: 6)
                    Rectangle().fill(Color(hex: "718F4E")).frame(width: max(0, g.size.width * fraction), height: 6)
                    Rectangle().fill(Color.primary).frame(width: 12, height: 24).offset(x: max(0, (g.size.width - 12) * fraction))
                }.frame(height: 40).contentShape(Rectangle())
                    .gesture(DragGesture(minimumDistance: 0).onChanged { set(bounds.lowerBound + ($0.location.x / max(1, g.size.width)) * (bounds.upperBound - bounds.lowerBound)) })
            }.frame(height: 40)
            Button("+") { set(value + step) }.accessibilityLabel("Increase")
        }.buttonStyle(RetroAction()).accessibilityElement(children: .ignore)
            .accessibilityValue("\(Int((value * 100).rounded())) percent")
            .accessibilityAdjustableAction { direction in set(value + (direction == .increment ? step : -step)) }
    }
}

struct TerminalColorPicker: View {
    var title: String
    @Binding var selection: Color
    var supportsOpacity = false
    @State private var hex = ""
    init(_ title: String, selection: Binding<Color>, supportsOpacity: Bool = false) { self.title = title; _selection = selection; self.supportsOpacity = supportsOpacity }
    private var currentHex: String {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 1
        UIColor(selection).getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(format: "%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
    }
    private let colors = ["719957", "254C3B", "317A9A", "263959", "8065A8", "BC668B", "C94C46", "D6A142", "D5CDB8", "565D63", "171B22", "F4F1E6"]
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title).font(PixelFont.font(15)); Spacer()
                TextField("Hex colour", text: $hex).font(PixelFont.font(14)).frame(width: 90)
                    .textInputAutocapitalization(.characters).autocorrectionDisabled()
                    .padding(8).overlay(Rectangle().stroke(Color.secondary))
                    .onChange(of: hex) { _, value in
                        let clean = value.replacingOccurrences(of: "#", with: "")
                        if clean.count == 6, UInt32(clean, radix: 16) != nil { selection = Color(hex: clean) }
                    }
            }.onAppear { hex = currentHex }.onChange(of: selection) { _, _ in hex = currentHex }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6)) {
                ForEach(colors, id: \.self) { hex in
                    Button { selection = Color(hex: hex) } label: { Rectangle().fill(Color(hex: hex)).frame(height: 32).overlay(Rectangle().stroke(Color.primary, lineWidth: 1)) }.buttonStyle(.plain).accessibilityLabel("Tint " + hex)
                }
            }
        }
    }
}

struct TerminalDisclosureGroup<Content: View>: View {
    var title: String
    @ViewBuilder var content: () -> Content
    @State private var expanded = false
    init(_ title: String, @ViewBuilder content: @escaping () -> Content) { self.title = title; self.content = content }
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button { expanded.toggle() } label: { HStack { Text(title); Spacer(); Text(expanded ? "−" : "+") }.frame(maxWidth: .infinity, minHeight: 40) }.buttonStyle(RetroAction()).accessibilityValue(expanded ? "Expanded" : "Collapsed")
            if expanded { content() }
        }
    }
}

struct TerminalStepper: View {
    var title: String
    @Binding var value: Int
    var bounds: ClosedRange<Int>
    init(_ title: String, value: Binding<Int>, in bounds: ClosedRange<Int>) { self.title = title; _value = value; self.bounds = bounds }
    var body: some View {
        HStack { Text(title).font(PixelFont.font(15)); Spacer(); Button("−") { value -= 1 }.disabled(value <= bounds.lowerBound); Button("+") { value += 1 }.disabled(value >= bounds.upperBound) }.buttonStyle(RetroAction())
            .accessibilityElement(children: .ignore).accessibilityLabel(title)
            .accessibilityAdjustableAction { direction in value = min(bounds.upperBound, max(bounds.lowerBound, value + (direction == .increment ? 1 : -1))) }
    }
}
struct TerminalMenuLink<Destination: View>: View {
    var title: String
    @ViewBuilder var destination: () -> Destination
    init(_ title: String, @ViewBuilder destination: @escaping () -> Destination) { self.title = title; self.destination = destination }
    var body: some View { NavigationLink(destination: destination) { HStack { Text(title); Spacer(); Text("›") }.frame(maxWidth: .infinity, minHeight: 44) }.buttonStyle(RetroAction()) }
}

struct TerminalFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration.font(PixelFont.font(16)).padding(10)
            .background(Color.secondary.opacity(0.08)).overlay(Rectangle().stroke(Color.secondary.opacity(0.5)))
    }
}
private struct TerminalSearch: ViewModifier {
    @Binding var text: String
    var prompt: String
    func body(content: Content) -> some View {
        content.safeAreaInset(edge: .top, spacing: 0) {
            HStack(spacing: 8) {
                Text("⌕").font(PixelFont.font(24))
                TextField(prompt, text: $text).textFieldStyle(TerminalFieldStyle()).autocorrectionDisabled()
                if !text.isEmpty { Button("×") { text = "" }.buttonStyle(RetroAction()).accessibilityLabel("Clear search") }
            }.padding(10).background(.background)
        }
    }
}
private struct TerminalDialogAction: PrimitiveButtonStyle {
    var close: () -> Void
    func makeBody(configuration: Configuration) -> some View {
        Button { configuration.trigger(); close() } label: { configuration.label.frame(maxWidth: .infinity, minHeight: 44) }.buttonStyle(RetroAction())
    }
}
private struct TerminalDialog<Actions: View, Message: View>: ViewModifier {
    var title: String
    @Binding var presented: Bool
    @ViewBuilder var actions: () -> Actions
    @ViewBuilder var message: () -> Message
    func body(content: Content) -> some View {
        content.sheet(isPresented: $presented) {
            TerminalPanel(title: title, onClose: { presented = false }) {
                message()
                actions().buttonStyle(TerminalDialogAction(close: { presented = false }))
            }.presentationDetents([.medium, .large])
        }
    }
}
extension View {
    func terminalSearchable(text: Binding<String>, prompt: String = "Search") -> some View { modifier(TerminalSearch(text: text, prompt: prompt)) }
    func terminalAlert<A: View, M: View>(_ title: String, isPresented: Binding<Bool>, @ViewBuilder actions: @escaping () -> A, @ViewBuilder message: @escaping () -> M) -> some View {
        modifier(TerminalDialog(title: title, presented: isPresented, actions: actions, message: message))
    }
    func terminalAlert<A: View>(_ title: String, isPresented: Binding<Bool>, @ViewBuilder actions: @escaping () -> A) -> some View {
        terminalAlert(title, isPresented: isPresented, actions: actions, message: { EmptyView() })
    }
    func terminalConfirmationDialog<A: View>(_ title: String, isPresented: Binding<Bool>, titleVisibility: Visibility = .visible, @ViewBuilder actions: @escaping () -> A) -> some View {
        terminalAlert(title, isPresented: isPresented, actions: actions)
    }
}
