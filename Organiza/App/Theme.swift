import SwiftUI
import UIKit

enum Theme {
    // Paleta pastel, com variações para o modo escuro
    static let lilas = Color.dinamica("8B6CF0", "A994FF")
    static let rosa = Color.dinamica("EE7FA8", "F49DBE")
    static let pessego = Color.dinamica("F59A6B", "FFB08A")
    static let menta = Color.dinamica("3DBE98", "6FD8B6")
    static let azul = Color.dinamica("5A9BF0", "86B8FF")
    static let amarelo = Color.dinamica("E9AE2C", "FFD166")
    static let vermelho = Color.dinamica("E5484D", "FF6B6F")

    static let fundo = Color.dinamica("F6F2FC", "0F0D14")
    static let card = Color.dinamica("FFFFFF", "1C1924")

    static let gradiente = LinearGradient(
        colors: [Color(hex: "B49CFF"), Color(hex: "F49DBE"), Color(hex: "FFC59E")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Cores disponíveis para identificar clientes.
    static let paletaClientes = [
        "8B6CF0", "EE7FA8", "F59A6B", "3DBE98", "5A9BF0",
        "E9AE2C", "E5484D", "2CB1C9", "A0522D", "6B7280",
    ]
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

struct CardStyle: ViewModifier {
    var padding: CGFloat = 16

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .shadow(color: .black.opacity(0.05), radius: 12, y: 4)
    }
}

extension View {
    func card(padding: CGFloat = 16) -> some View {
        modifier(CardStyle(padding: padding))
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
    static let diaSemana = formatter("EEE")
    static let mesAno = formatter("MMMM yyyy")
    static let dataLonga = formatter("EEEE, d 'de' MMMM")

    static func dataPorExtenso(_ data: Date) -> String {
        dataLonga.string(from: data).capitalizadoPrimeira
    }

    static func diaCurto(_ data: Date) -> String {
        diaSemana.string(from: data).replacingOccurrences(of: ".", with: "").capitalizadoPrimeira
    }

    /// "Hoje 18:00", "Amanhã 09:30", "Ontem 14:00", "12 nov"...
    static func prazo(_ data: Date) -> String {
        let cal = Calendar.current
        let horaTexto = " " + hora.string(from: data)
        if cal.isDateInToday(data) { return "Hoje" + horaTexto }
        if cal.isDateInTomorrow(data) { return "Amanhã" + horaTexto }
        if cal.isDateInYesterday(data) { return "Ontem" + horaTexto }
        return diaMes.string(from: data).replacingOccurrences(of: ".", with: "")
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
