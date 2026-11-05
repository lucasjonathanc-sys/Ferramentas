import SwiftUI
import UIKit

/// Cores e estilos do app.
/// Por enquanto neutro (off-white + preto). `marca` vai virar o vinho da identidade visual da Hanna.
enum Theme {
    static let fundo = Color.dinamica("F7F4F2", "111012")
    static let card = Color.dinamica("FFFFFF", "1C1A1D")
    static let campo = Color.dinamica("FFFFFF", "232026")
    static let borda = Color.dinamica("E6E0DE", "34303A")
    static let suave = Color.dinamica("EFEAE8", "2A262D")

    /// Botões principais (pílula preta).
    static let acento = Color.dinamica("1B1A1C", "F4F1EF")
    static let textoNoAcento = Color.dinamica("FFFFFF", "111012")

    /// Cor da marca (provisória, neutra).
    static let marca = Color.dinamica("6E6470", "B9AFBA")
    static let marcaSuave = Color.dinamica("ECE6EC", "2E2930")

    static let alerta = Color.dinamica("C2454B", "E8777B")
    static let sucesso = Color.dinamica("5E9A6E", "86C496")

    /// Cores disponíveis para identificar clientes.
    static let paletaClientes = [
        "C97B8E", "8E7CC3", "6F93C9", "7FA37A", "C9A15B",
        "D48A6A", "5FA8A8", "9A6B5A", "6B6470", "B5677A",
    ]

    static func tituloSerifado(_ tamanho: CGFloat = 34) -> Font {
        .system(size: tamanho, weight: .regular, design: .serif)
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
            .font(.subheadline.weight(.semibold))
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
