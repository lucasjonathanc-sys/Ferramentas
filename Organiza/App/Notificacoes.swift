import Foundation
import UserNotifications

/// Agenda e cancela os lembretes locais das atividades.
enum Notificacoes {
    static func pedirPermissao() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    /// Reagenda todos os lembretes de uma atividade.
    static func atualizar(_ a: Atividade) {
        let prefixo = a.uid.uuidString
        let titulo = a.titulo
        let corpo = Self.corpo(a)
        let deveAgendar = a.aberta && !a.lembretes.isEmpty && a.momentoLembrete != nil
        let base = a.momentoLembrete
        // Tarefas que se repetem geram a próxima ao concluir, então o lembrete é único.
        let repeticao = a.ehCompromisso ? a.repeticao : .nunca
        let lembretes = a.lembretes
        let ehCompromisso = a.ehCompromisso

        cancelar(prefixo: prefixo) {
            guard deveAgendar, let base else { return }
            for minutos in lembretes {
                let quando = base.addingTimeInterval(TimeInterval(-minutos * 60))
                let texto = minutos == 0
                    ? (ehCompromisso ? "Começando agora" : "Vence agora")
                    : "\(OpcoesLembrete.nome(minutos).capitalizadoPrimeira) · \(corpo)"
                agendar(
                    id: "\(prefixo)-\(minutos)",
                    titulo: titulo,
                    corpo: minutos == 0 ? "\(texto) · \(corpo)" : texto,
                    data: quando,
                    repeticao: repeticao
                )
            }
        }
    }

    static func cancelar(_ a: Atividade) {
        cancelar(prefixo: a.uid.uuidString) {}
    }

    // MARK: - Privado

    private static func corpo(_ a: Atividade) -> String {
        var partes = [a.contexto.rawValue]
        if let cliente = a.cliente { partes.append(cliente.nome) }
        if let data = a.data, a.temHorario { partes.append(Fmt.hora.string(from: data)) }
        if !a.local.isEmpty { partes.append(a.local) }
        return partes.joined(separator: " · ")
    }

    private static func agendar(id: String, titulo: String, corpo: String, data: Date, repeticao: Repeticao) {
        let conteudo = UNMutableNotificationContent()
        conteudo.title = titulo
        conteudo.body = corpo
        conteudo.sound = .default

        let cal = Calendar.current
        let centro = UNUserNotificationCenter.current()

        func adicionar(_ sufixo: String, _ componentes: DateComponents, repete: Bool) {
            let gatilho = UNCalendarNotificationTrigger(dateMatching: componentes, repeats: repete)
            centro.add(UNNotificationRequest(identifier: id + sufixo, content: conteudo, trigger: gatilho))
        }

        switch repeticao {
        case .nunca:
            guard data > Date() else { return }
            adicionar("", cal.dateComponents([.year, .month, .day, .hour, .minute], from: data), repete: false)
        case .diaria:
            adicionar("", cal.dateComponents([.hour, .minute], from: data), repete: true)
        case .diasUteis:
            var c = cal.dateComponents([.hour, .minute], from: data)
            for dia in 2...6 { // segunda (2) a sexta (6)
                c.weekday = dia
                adicionar("-d\(dia)", c, repete: true)
            }
        case .semanal:
            adicionar("", cal.dateComponents([.weekday, .hour, .minute], from: data), repete: true)
        case .mensal:
            adicionar("", cal.dateComponents([.day, .hour, .minute], from: data), repete: true)
        case .anual:
            adicionar("", cal.dateComponents([.month, .day, .hour, .minute], from: data), repete: true)
        }
    }

    /// Remove todos os pedidos pendentes cujo id começa com o prefixo e depois executa `depois`.
    private static func cancelar(prefixo: String, depois: @escaping () -> Void) {
        let centro = UNUserNotificationCenter.current()
        centro.getPendingNotificationRequests { pedidos in
            let ids = pedidos.map(\.identifier).filter { $0.hasPrefix(prefixo) }
            centro.removePendingNotificationRequests(withIdentifiers: ids)
            depois()
        }
    }
}
