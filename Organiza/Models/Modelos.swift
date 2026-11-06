import Foundation
import SwiftData
import SwiftUI

// MARK: - Enums

/// Área da vida a que a atividade pertence (os chips com bolinha colorida).
enum Contexto: String, CaseIterable, Identifiable {
    case chinaLink = "China Link"
    case freela = "Clientes"
    case pessoal = "Pessoal"
    case faculdade = "Faculdade"
    case igreja = "Igreja"

    var id: String { rawValue }

    var cor: Color {
        switch self {
        case .chinaLink: return Theme.marca
        case .freela: return Color(hex: "B08968")
        case .pessoal: return Color(hex: "5E7556")
        case .faculdade: return Color(hex: "4F5D75")
        case .igreja: return Color(hex: "B8975A")
        }
    }

    var icone: String {
        switch self {
        case .chinaLink: return "building.2"
        case .freela: return "camera.aperture"
        case .pessoal: return "heart"
        case .faculdade: return "graduationcap"
        case .igreja: return "sparkles"
        }
    }
}

enum TipoAtividade: String, CaseIterable, Identifiable {
    case tarefa = "Tarefa"
    case compromisso = "Compromisso"

    var id: String { rawValue }
}

enum StatusAtividade: String, CaseIterable, Identifiable {
    case aberta = "Aberta"
    case concluida = "Concluída"
    case cancelada = "Cancelada"

    var id: String { rawValue }
}

enum Prioridade: Int, CaseIterable, Identifiable {
    case baixa = 0
    case media = 1
    case alta = 2

    var id: Int { rawValue }

    var nome: String {
        switch self {
        case .baixa: return "Baixa"
        case .media: return "Média"
        case .alta: return "Alta"
        }
    }
}

enum Repeticao: String, CaseIterable, Identifiable {
    case nunca = "Não se repete"
    case diaria = "Todo dia"
    case diasUteis = "Dias úteis (seg a sex)"
    case semanal = "Toda semana"
    case mensal = "Todo mês"
    case anual = "Todo ano"

    var id: String { rawValue }

    var curto: String {
        switch self {
        case .nunca: return ""
        case .diaria: return "Diária"
        case .diasUteis: return "Dias úteis"
        case .semanal: return "Semanal"
        case .mensal: return "Mensal"
        case .anual: return "Anual"
        }
    }

    /// Próxima data depois de `data` seguindo a regra.
    func proxima(depois data: Date) -> Date? {
        let cal = Calendar.current
        switch self {
        case .nunca: return nil
        case .diaria: return cal.date(byAdding: .day, value: 1, to: data)
        case .diasUteis:
            var d = cal.date(byAdding: .day, value: 1, to: data) ?? data
            while cal.isDateInWeekend(d) {
                d = cal.date(byAdding: .day, value: 1, to: d) ?? d
            }
            return d
        case .semanal: return cal.date(byAdding: .weekOfYear, value: 1, to: data)
        case .mensal: return cal.date(byAdding: .month, value: 1, to: data)
        case .anual: return cal.date(byAdding: .year, value: 1, to: data)
        }
    }

    /// Se uma atividade que começa em `inicio` acontece também em `dia`.
    func ocorre(inicio: Date, em dia: Date) -> Bool {
        let cal = Calendar.current
        let diaInicio = cal.startOfDay(for: inicio)
        let alvo = cal.startOfDay(for: dia)
        if alvo == diaInicio { return true }
        guard alvo > diaInicio else { return false }
        switch self {
        case .nunca: return false
        case .diaria: return true
        case .diasUteis: return !cal.isDateInWeekend(alvo)
        case .semanal: return cal.component(.weekday, from: alvo) == cal.component(.weekday, from: diaInicio)
        case .mensal: return cal.component(.day, from: alvo) == cal.component(.day, from: diaInicio)
        case .anual:
            return cal.component(.day, from: alvo) == cal.component(.day, from: diaInicio)
                && cal.component(.month, from: alvo) == cal.component(.month, from: diaInicio)
        }
    }
}

/// Opções de lembrete (minutos antes).
enum OpcoesLembrete {
    static let todas: [Int] = [0, 5, 15, 30, 60, 120, 1440, 2880]

    static func nome(_ minutos: Int) -> String {
        switch minutos {
        case 0: return "Na hora"
        case 1440: return "1 dia antes"
        case 2880: return "2 dias antes"
        case let m where m >= 60 && m % 60 == 0: return "\(m / 60) h antes"
        default: return "\(minutos) min antes"
        }
    }
}

// MARK: - Modelos (SwiftData)

@Model
final class Cliente {
    var uid: UUID = UUID()
    var nome: String = ""
    var nicho: String = ""
    var instagram: String = ""
    var contato: String = ""
    var valorMensal: Double = 0
    var corHex: String = "82766B"
    var observacoes: String = ""
    var ativo: Bool = true
    var criadoEm: Date = Date()

    @Relationship(deleteRule: .nullify, inverse: \Atividade.cliente)
    var atividades: [Atividade]? = []

    init(nome: String = "") {
        self.nome = nome
    }

    var cor: Color { Color(hex: corHex) }

    var iniciais: String {
        let letras = nome.split(separator: " ").prefix(2).compactMap { $0.first }.map { String($0) }.joined()
        return letras.isEmpty ? "?" : letras.uppercased()
    }

    var abertas: [Atividade] {
        (atividades ?? []).filter { $0.status == .aberta }.sorted(by: Atividade.ordenacao)
    }

    var linkInstagram: URL? {
        let user = instagram.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "@", with: "")
        guard !user.isEmpty else { return nil }
        return URL(string: "https://instagram.com/\(user)")
    }
}

/// Uma tarefa ou um compromisso (como em "Nova atividade").
@Model
final class Atividade {
    var uid: UUID = UUID()
    var tipoRaw: String = TipoAtividade.tarefa.rawValue
    var titulo: String = ""
    var descricao: String = ""
    var contextoRaw: String = Contexto.chinaLink.rawValue
    var statusRaw: String = StatusAtividade.aberta.rawValue
    var prioridadeRaw: Int = Prioridade.media.rawValue
    /// Vencimento (tarefa) ou início (compromisso). Tarefa pode não ter data.
    var data: Date?
    /// Se `false`, a atividade é "sem hora" (só o dia importa).
    var temHorario: Bool = false
    /// Fim do compromisso.
    var fim: Date?
    var repeticaoRaw: String = Repeticao.nunca.rawValue
    /// Minutos antes para cada lembrete.
    var lembretes: [Int] = []
    var local: String = ""
    var link: String = ""
    var criadaEm: Date = Date()
    var concluidaEm: Date?
    var cliente: Cliente?

    init(tipo: TipoAtividade = .tarefa, titulo: String = "") {
        self.tipoRaw = tipo.rawValue
        self.titulo = titulo
    }

    var tipo: TipoAtividade {
        get { TipoAtividade(rawValue: tipoRaw) ?? .tarefa }
        set { tipoRaw = newValue.rawValue }
    }

    var contexto: Contexto {
        get { Contexto(rawValue: contextoRaw) ?? .pessoal }
        set { contextoRaw = newValue.rawValue }
    }

    var status: StatusAtividade {
        get { StatusAtividade(rawValue: statusRaw) ?? .aberta }
        set { statusRaw = newValue.rawValue }
    }

    var prioridade: Prioridade {
        get { Prioridade(rawValue: prioridadeRaw) ?? .media }
        set { prioridadeRaw = newValue.rawValue }
    }

    var repeticao: Repeticao {
        get { Repeticao(rawValue: repeticaoRaw) ?? .nunca }
        set { repeticaoRaw = newValue.rawValue }
    }

    var ehCompromisso: Bool { tipo == .compromisso }
    var aberta: Bool { status == .aberta }

    /// Momento usado como referência para atraso e lembretes
    /// (sem horário: 9h do dia para lembretes, fim do dia para atraso).
    var momentoLembrete: Date? {
        guard let data else { return nil }
        if temHorario { return data }
        return Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: data)
    }

    var atrasada: Bool {
        guard aberta, !ehCompromisso, let data else { return false }
        if temHorario { return data < Date() }
        return Calendar.current.startOfDay(for: data) < Calendar.current.startOfDay(for: Date())
    }

    var fimEfetivo: Date? {
        guard let data else { return nil }
        if let fim, fim > data { return fim }
        return data.addingTimeInterval(ehCompromisso ? 3600 : 1800)
    }

    var jaPassou: Bool {
        guard ehCompromisso, repeticao == .nunca, let fim = fimEfetivo else { return false }
        return fim < Date()
    }

    /// Se a atividade aparece no dia (considerando repetição de compromissos).
    func aparece(em dia: Date) -> Bool {
        guard let data else { return false }
        if ehCompromisso { return repeticao.ocorre(inicio: data, em: dia) }
        return Calendar.current.isDate(data, inSameDayAs: dia)
    }

    /// Horário de início dessa atividade num dia específico (para repetições).
    func inicio(em dia: Date) -> Date? {
        guard let data else { return nil }
        let cal = Calendar.current
        let c = cal.dateComponents([.hour, .minute], from: data)
        return cal.date(bySettingHour: c.hour ?? 0, minute: c.minute ?? 0, second: 0, of: dia)
    }

    /// Próximo dia (a partir de hoje) em que um compromisso repetido acontece.
    func proximaOcorrencia(aPartirDe hoje: Date = Date()) -> Date? {
        guard let data else { return nil }
        guard ehCompromisso, repeticao != .nunca else { return data }
        let cal = Calendar.current
        var dia = max(cal.startOfDay(for: hoje), cal.startOfDay(for: data))
        for _ in 0..<400 {
            if repeticao.ocorre(inicio: data, em: dia) { return dia }
            dia = cal.date(byAdding: .day, value: 1, to: dia) ?? dia
        }
        return data
    }

    static func ordenacao(_ a: Atividade, _ b: Atividade) -> Bool {
        if a.aberta != b.aberta { return a.aberta }
        switch (a.data, b.data) {
        case let (da?, db?) where da != db:
            let ca = Calendar.current.startOfDay(for: da)
            let cb = Calendar.current.startOfDay(for: db)
            if ca != cb { return ca < cb }
            // no mesmo dia: com horário primeiro, por hora
            if a.temHorario != b.temHorario { return a.temHorario }
            if da != db { return da < db }
        case (.some, .none): return true
        case (.none, .some): return false
        default: break
        }
        if a.prioridadeRaw != b.prioridadeRaw { return a.prioridadeRaw > b.prioridadeRaw }
        return a.criadaEm > b.criadaEm
    }
}

// MARK: - Ações

enum Acoes {
    /// Conclui (ou reabre) uma tarefa. Se ela se repete, cria a próxima.
    static func alternarConclusao(_ a: Atividade, context: ModelContext) {
        if a.status == .concluida {
            a.status = .aberta
            a.concluidaEm = nil
            Notificacoes.atualizar(a)
            return
        }
        a.status = .concluida
        a.concluidaEm = Date()
        Notificacoes.atualizar(a)

        if !a.ehCompromisso, a.repeticao != .nunca, let data = a.data,
           let proxima = a.repeticao.proxima(depois: data) {
            let nova = Atividade(tipo: a.tipo, titulo: a.titulo)
            nova.descricao = a.descricao
            nova.contexto = a.contexto
            nova.prioridade = a.prioridade
            nova.data = proxima
            nova.temHorario = a.temHorario
            nova.repeticao = a.repeticao
            nova.lembretes = a.lembretes
            nova.local = a.local
            nova.link = a.link
            nova.cliente = a.cliente
            context.insert(nova)
            // a concluída deixa de repetir; quem repete agora é a nova
            a.repeticao = .nunca
            Notificacoes.atualizar(nova)
        }
    }

    static func cancelar(_ a: Atividade) {
        a.status = a.status == .cancelada ? .aberta : .cancelada
        a.concluidaEm = nil
        Notificacoes.atualizar(a)
    }

    static func apagar(_ a: Atividade, context: ModelContext) {
        Notificacoes.cancelar(a)
        context.delete(a)
    }
}
