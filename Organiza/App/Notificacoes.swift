import Foundation
import UserNotifications

/// Agenda e cancela os lembretes locais de tarefas e compromissos.
enum Notificacoes {
    static func pedirPermissao() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    static func atualizar(_ tarefa: Tarefa) {
        let id = "tarefa-\(tarefa.uid.uuidString)"
        guard tarefa.lembrete, let prazo = tarefa.prazo, !tarefa.concluida else {
            cancelar(id: id)
            return
        }
        var corpo = tarefa.frente.rawValue
        if let cliente = tarefa.cliente { corpo += " · \(cliente.nome)" }
        corpo += " · \(tarefa.tipo.rawValue)"
        agendar(id: id, titulo: "⏰ Prazo: \(tarefa.titulo)", corpo: corpo, data: prazo)
    }

    static func cancelar(_ tarefa: Tarefa) {
        cancelar(id: "tarefa-\(tarefa.uid.uuidString)")
    }

    static func atualizar(_ compromisso: Compromisso) {
        let id = "compromisso-\(compromisso.uid.uuidString)"
        guard compromisso.lembreteMinutos >= 0 else {
            cancelar(id: id)
            return
        }
        let data = compromisso.inicio.addingTimeInterval(TimeInterval(-compromisso.lembreteMinutos * 60))
        let quando = compromisso.lembreteMinutos == 0
            ? "Começando agora"
            : "Começa às \(Fmt.hora.string(from: compromisso.inicio))"
        var corpo = quando
        if !compromisso.local.isEmpty { corpo += " · \(compromisso.local)" }
        agendar(id: id, titulo: "📅 \(compromisso.titulo)", corpo: corpo, data: data)
    }

    static func cancelar(_ compromisso: Compromisso) {
        cancelar(id: "compromisso-\(compromisso.uid.uuidString)")
    }

    // MARK: - Privado

    private static func agendar(id: String, titulo: String, corpo: String, data: Date) {
        cancelar(id: id)
        guard data > Date() else { return }

        let conteudo = UNMutableNotificationContent()
        conteudo.title = titulo
        conteudo.body = corpo
        conteudo.sound = .default

        let componentes = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: data)
        let gatilho = UNCalendarNotificationTrigger(dateMatching: componentes, repeats: false)
        UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: id, content: conteudo, trigger: gatilho))
    }

    private static func cancelar(id: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
    }
}
