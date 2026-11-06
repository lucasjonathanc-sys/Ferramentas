import CoreText
import SwiftUI
import UIKit

/// Cores e estilos do app, seguindo a identidade visual da marca (Dulce Berdulles):
/// preto #0B0B0B, bege #D6CDC2, off-white #F6F4EF, vinho #7A0E15 e taupe #82766B.
enum Theme {
    static let preto = Color(hex: "0B0B0B")
    static let bege = Color(hex: "D6CDC2")
    static let offWhite = Color(hex: "F6F4EF")
    static let taupe = Color(hex: "82766B")

    static let fundo = Color.dinamica("F6F4EF", "0B0B0B")
    static let card = Color.dinamica("FCFBF8", "161413")
    static let campo = Color.dinamica("FFFFFF", "1B1918")
    static let borda = Color.dinamica("E2DAD0", "2E2A27")
    static let suave = Color.dinamica("ECE6DE", "221F1D")
    static let textoSecundario = Color.dinamica("82766B", "A79C92")

    /// Botões principais (pílula preta).
    static let acento = Color.dinamica("0B0B0B", "F6F4EF")
    static let textoNoAcento = Color.dinamica("F6F4EF", "0B0B0B")

    /// Vinho da marca: botão +, seleção, hora atual, ponto da logo.
    static let marca = Color.dinamica("7A0E15", "B8323B")
    static let marcaSuave = Color.dinamica("F0E2E0", "2B1517")

    static let alerta = Color.dinamica("A3262C", "E0676C")
    static let sucesso = Color.dinamica("5E7556", "8FAA86")

    /// Cores disponíveis para identificar clientes (tons da paleta).
    static let paletaClientes = [
        "7A0E15", "82766B", "B08968", "4F5D75", "C2A878",
        "5E7556", "A85C5C", "3E3A39", "9C8A7A", "6D4C5C",
    ]

    static func tituloSerifado(_ tamanho: CGFloat = 34) -> Font {
        Fonte.titulo(tamanho)
    }
}

// MARK: - Fontes da marca

/// Playfair Display (títulos), Montserrat (chamadas) e Inter (textos).
enum Fonte {
    enum Peso { case regular, medio, semibold }

    static func titulo(_ tamanho: CGFloat, italico: Bool = false) -> Font {
        .custom(italico ? "PlayfairDisplay-Italic" : "PlayfairDisplay-Regular", size: tamanho, relativeTo: .title)
    }

    static func chamada(_ tamanho: CGFloat, _ peso: Peso = .medio) -> Font {
        .custom(peso == .semibold ? "Montserrat-SemiBold" : "Montserrat-Medium", size: tamanho, relativeTo: .subheadline)
    }

    static func texto(_ tamanho: CGFloat, _ peso: Peso = .regular) -> Font {
        let nome: String
        switch peso {
        case .regular: nome = "Inter-Regular"
        case .medio: nome = "Inter-Medium"
        case .semibold: nome = "Inter-SemiBold"
        }
        return .custom(nome, size: tamanho, relativeTo: tamanho >= 17 ? .body : (tamanho >= 14 ? .subheadline : .caption))
    }

    /// Registra os arquivos .ttf do app (não precisa de Info.plist).
    static func registrar() {
        var urls = Bundle.main.urls(forResourcesWithExtension: "ttf", subdirectory: nil) ?? []
        urls += Bundle.main.urls(forResourcesWithExtension: "ttf", subdirectory: "Fonts") ?? []
        for url in urls {
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }

    /// Aplica as fontes da marca nas barras de navegação (telas em Form/sheets).
    static func configurarAparencia() {
        let barra = UINavigationBarAppearance()
        barra.configureWithTransparentBackground()
        barra.backgroundColor = UIColor { $0.userInterfaceStyle == .dark ? UIColor(hex: "0B0B0B") : UIColor(hex: "F6F4EF") }
        if let f = UIFont(name: "PlayfairDisplay-Regular", size: 19) {
            barra.titleTextAttributes = [.font: f]
        }
        if let f = UIFont(name: "PlayfairDisplay-Regular", size: 34) {
            barra.largeTitleTextAttributes = [.font: f]
        }
        if let f = UIFont(name: "Inter-Medium", size: 17) {
            let botao = UIBarButtonItemAppearance()
            botao.normal.titleTextAttributes = [.font: f]
            barra.buttonAppearance = botao
            barra.doneButtonAppearance = botao
        }
        UINavigationBar.appearance().standardAppearance = barra
        UINavigationBar.appearance().scrollEdgeAppearance = barra
        UINavigationBar.appearance().compactAppearance = barra
    }
}

// MARK: - Elementos de apoio da marca

/// Traço de pincel vinho (como o da identidade, embaixo do título).
struct TracoPincel: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.midY + r.height * 0.25))
        p.addCurve(
            to: CGPoint(x: r.maxX, y: r.midY - r.height * 0.15),
            control1: CGPoint(x: r.minX + r.width * 0.35, y: r.minY - r.height * 0.1),
            control2: CGPoint(x: r.minX + r.width * 0.6, y: r.maxY + r.height * 0.2)
        )
        return p
    }
}

struct PincelMarca: View {
    var largura: CGFloat = 120

    var body: some View {
        TracoPincel()
            .stroke(Theme.marca, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
            .frame(width: largura, height: 10)
    }
}

/// Asterisco fino de 8 pontas (elemento de apoio da marca).
struct Asterisco: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        let c = CGPoint(x: r.midX, y: r.midY)
        let raio = min(r.width, r.height) / 2
        for i in 0..<4 {
            let angulo = Double(i) * .pi / 4
            let dx = CGFloat(cos(angulo)) * raio
            let dy = CGFloat(sin(angulo)) * raio
            p.move(to: CGPoint(x: c.x - dx, y: c.y - dy))
            p.addLine(to: CGPoint(x: c.x + dx, y: c.y + dy))
        }
        return p
    }
}

struct AsteriscoMarca: View {
    var tamanho: CGFloat = 18

    var body: some View {
        Asterisco()
            .stroke(Theme.marca, style: StrokeStyle(lineWidth: max(1, tamanho / 14), lineCap: .round))
            .frame(width: tamanho, height: tamanho)
    }
}

/// Logo "DB." com o ponto vinho.
struct LogoMarca: View {
    var tamanho: CGFloat = 28
    var cor: Color = .primary

    var body: some View {
        HStack(alignment: .lastTextBaseline, spacing: 0) {
            Text("DB").foregroundStyle(cor)
            Text(".").foregroundStyle(Theme.marca)
        }
        .font(Fonte.titulo(tamanho))
    }
}

extension UIColor {
    convenience init(hex: String) {
        let limpo = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var valor: UInt64 = 0
        Scanner(string: limpo).scanHexInt64(&valor)
        self.init(
            red: CGFloat((valor >> 16) & 0xFF) / 255,
            green: CGFloat((valor >> 8) & 0xFF) / 255,
            blue: CGFloat(valor & 0xFF) / 255,
            alpha: 1
        )
    }
}

extension Color {
    init(hex: String) {
        self.init(uiColor: UIColor(hex: hex))
    }

    static func dinamica(_ claro: String, _ escuro: String) -> Color {
        let c = UIColor(hex: claro)
        let e = UIColor(hex: escuro)
        return Color(uiColor: UIColor { $0.userInterfaceStyle == .dark ? e : c })
    }
}

// MARK: - Estilos reutilizáveis

struct CardStyle: ViewModifier {
    var padding: CGFloat = 16

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(Theme.borda.opacity(0.6), lineWidth: 0.5))
    }
}

/// Campo com borda arredondada, como no formulário do vídeo.
struct CampoStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.campo, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Theme.borda, lineWidth: 1))
    }
}

/// Botão em pílula preta (principal) ou contornada (secundário).
struct PilulaStyle: ButtonStyle {
    var principal = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Fonte.chamada(14))
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .foregroundStyle(principal ? Theme.textoNoAcento : Color.primary)
            .background {
                Capsule().fill(principal ? Theme.acento : Color.clear)
            }
            .overlay {
                Capsule().stroke(principal ? Color.clear : Theme.borda, lineWidth: 1)
            }
            .opacity(configuration.isPressed ? 0.75 : 1)
    }
}

extension View {
    func card(padding: CGFloat = 16) -> some View {
        modifier(CardStyle(padding: padding))
    }

    func campo() -> some View {
        modifier(CampoStyle())
    }
}

// MARK: - Datas em português

enum Fmt {
    static let locale = Locale(identifier: "pt_BR")

    private static func formatter(_ formato: String) -> DateFormatter {
        let f = DateFormatter()
        f.locale = locale
        f.dateFormat = formato
        return f
    }

    static let hora = formatter("HH:mm")
    static let diaMes = formatter("d MMM")
    static let diaMesLongo = formatter("d 'de' MMMM")
    static let diaSemana = formatter("EEE")
    static let mes = formatter("MMMM")
    static let mesAno = formatter("MMMM 'de' yyyy")
    static let dataLonga = formatter("EEEE, d 'de' MMMM")
    static let dataCampo = formatter("d 'de' MMM 'de' yyyy")

    static func dataPorExtenso(_ data: Date) -> String {
        dataLonga.string(from: data).capitalizadoPrimeira
    }

    static func diaCurto(_ data: Date) -> String {
        diaSemana.string(from: data).replacingOccurrences(of: ".", with: "").capitalizadoPrimeira
    }

    /// "Hoje 18:00", "Amanhã", "Ontem", "12 nov 14:00"...
    static func quando(_ data: Date, temHorario: Bool) -> String {
        let cal = Calendar.current
        let horaTexto = temHorario ? " · " + hora.string(from: data) : ""
        if cal.isDateInToday(data) { return "Hoje" + horaTexto }
        if cal.isDateInTomorrow(data) { return "Amanhã" + horaTexto }
        if cal.isDateInYesterday(data) { return "Ontem" + horaTexto }
        return diaMes.string(from: data).replacingOccurrences(of: ".", with: "") + horaTexto
    }

    /// "5 a 7 de novembro", "30 de out. a 1 de nov."
    static func intervalo(_ inicio: Date, _ fim: Date) -> String {
        let cal = Calendar.current
        if cal.isDate(inicio, inSameDayAs: fim) { return diaMesLongo.string(from: inicio) }
        if cal.component(.month, from: inicio) == cal.component(.month, from: fim) {
            return "\(cal.component(.day, from: inicio)) a \(diaMesLongo.string(from: fim))"
        }
        return "\(diaMes.string(from: inicio)) a \(diaMes.string(from: fim))"
    }

    static func dinheiro(_ valor: Double) -> String {
        valor.formatted(.currency(code: "BRL").locale(locale))
    }
}

extension String {
    var capitalizadoPrimeira: String {
        guard let primeira = first else { return self }
        return primeira.uppercased() + dropFirst()
    }
}
