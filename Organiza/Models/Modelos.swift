import Foundation
import SwiftData
import SwiftUI

// MARK: - Enums

/// Em qual "frente" de trabalho a tarefa/compromisso se encaixa.
enum Frente: String, CaseIterable, Identifiable {
    case chinaLink = "China Link"
    case freela = "Freela"
    case pessoal = "Pessoal"

    var id: String { rawValue }

    var icone: String {
        switch self {
        case .chinaLink: return "building.2.fill"
        case .freela: return "camera.aperture"
        case .pessoal: return "heart.fill"
        }
    }

    var cor: Color {
        switch self {
        case .chinaLink: return Theme.vermelho
        case .freela: return Theme.lilas
        case .pessoal: return Theme.rosa
        }
    }

    var descricao: String {
        switch self {
        case .chinaLink: return "Copywriting na empresa"
        case .freela: return "Social media para clientes"
        case .pessoal: return "Vida pessoal"
        }
    }
}

enum TipoTarefa: String, CaseIterable, Identifiable {
    case copy = "Copy"
    case roteiro = "Roteiro"
    case video = "Vídeo"
    case design = "Design"
    case post = "Post"
    case stories = "Stories"
    case planejamento = "Planejamento"
    case outro = "Outro"

    var id: String { rawValue }

    var icone: String {
        switch self {
        case .copy: return "text.quote"
        case .roteiro: return "doc.text.fill"
        case .video: return "video.fill"
        case .design: return "paintpalette.fill"
        case .post: return "square.grid.3x3.fill"
        case .stories: return "circle.dashed"
        case .planejamento: return "calendar.badge.clock"
        case .outro: return "sparkle"
        }
    }

    var cor: Color {
        switch self {
        case .copy: return Theme.azul
        case .roteiro: return Theme.azul
        case .video: return Theme.pessego
        case .design: return Theme.rosa
        case .post: return Theme.lilas
        case .stories: return Theme.amarelo
        case .planejamento: return Theme.menta
        case .outro: return .gray
        }
    }

    /// Etapas sugeridas de acordo com o tipo de trabalho.
    var etapasSugeridas: [String] {
        switch self {
        case .copy: return ["Ler briefing", "Pesquisa", "Rascunho", "Revisão", "Enviar p/ aprovação"]
        case .roteiro: return ["Ideia / gancho", "Estrutura", "Escrever roteiro", "Aprovação"]
        case .video: return ["Roteiro", "Gravação", "Edição", "Legenda + capa", "Aprovação", "Postar"]
        case .design: return ["Briefing", "Referências", "Criação", "Ajustes", "Aprovação", "Exportar"]
        case .post: return ["Arte", "Legenda", "Hashtags", "Aprovação", "Agendar / postar"]
        case .stories: return ["Captar conteúdo", "Montar sequência", "Postar"]
        case .planejamento: return ["Levantar datas", "Definir pautas", "Montar calendário", "Apresentar"]
        case .outro: return []
        }
    }
}

enum StatusTarefa: String, CaseIterable, Identifiable {
    case aFazer = "A fazer"
    case fazendo = "Fazendo"
    case aprovacao = "Em aprovação"
    case concluida = "Concluída"

    var id: String { rawValue }

    var icone: String {
        switch self {
        case .aFazer: return "circle"
        case .fazendo: return "circle.lefthalf.filled"
        case .aprovacao: return "hourglass"
        case .concluida: return "checkmark.circle.fill"
        }
    }

    var cor: Color {
        switch self {
        case .aFazer: return .gray
        case .fazendo: return Theme.azul
        case .aprovacao: return Theme.amarelo
        case .concluida: return Theme.menta
        }
    }
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

enum TipoCompromisso: String, CaseIterable, Identifiable {
    case reuniao = "Reunião"
    case call = "Call"
    case gravacao = "Gravação"
    case entrega = "Entrega"
    case evento = "Evento"
    case pessoal = "Pessoal"

    var id: String { rawValue }

    var icone: String {
        switch self {
        case .reuniao: return "person.3.fill"
        case .call: return "video.bubble.fill"
        case .gravacao: return "camera.fill"
        case .entrega: return "shippingbox.fill"
        case .evento: return "star.fill"
        case .pessoal: return "heart.fill"
        }
    }

    var cor: Color {
        switch self {
        case .reuniao: return Theme.azul
        case .call: return Theme.lilas
        case .gravacao: return Theme.pessego
        case .entrega: return Theme.vermelho
        case .evento: return Theme.amarelo
        case .pessoal: return Theme.rosa
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
    var corHex: String = "9B7BF7"
    var observacoes: String = ""
    var ativo: Bool = true
    var criadoEm: Date = Date()

    @Relationship(deleteRule: .nullify, inverse: \Tarefa.cliente)
    var tarefas: [Tarefa]? = []

    @Relationship(deleteRule: .nullify, inverse: \Compromisso.cliente)
    var compromissos: [Compromisso]? = []

    init(nome: String = "") {
        self.nome = nome
    }

    var cor: Color { Color(hex: corHex) }

    var iniciais: String {
        let partes = nome.split(separator: " ").prefix(2)
        let letras = partes.compactMap { $0.first }.map { String($0) }.joined()
        return letras.isEmpty ? "?" : letras.uppercased()
    }

    var tarefasPendentes: [Tarefa] {
        (tarefas ?? []).filter { !$0.concluida }.sorted(by: Tarefa.ordenacao)
    }

    var linkInstagram: URL? {
        let user = instagram
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "@", with: "")
        guard !user.isEmpty else { return nil }
        return URL(string: "https://instagram.com/\(user)")
    }
}

@Model
final class Tarefa {
    var uid: UUID = UUID()
    var titulo: String = ""
    var notas: String = ""
    var frenteRaw: String = Frente.chinaLink.rawValue
    var tipoRaw: String = TipoTarefa.copy.rawValue
    var statusRaw: String = StatusTarefa.aFazer.rawValue
    var prioridadeRaw: Int = Prioridade.media.rawValue
    var prazo: Date?
    var lembrete: Bool = false
    var criadaEm: Date = Date()
    var concluidaEm: Date?
    var cliente: Cliente?

    @Relationship(deleteRule: .cascade, inverse: \Etapa.tarefa)
    var etapas: [Etapa]? = []

    init(titulo: String = "") {
        self.titulo = titulo
    }

    var frente: Frente {
        get { Frente(rawValue: frenteRaw) ?? .chinaLink }
        set { frenteRaw = newValue.rawValue }
    }

    var tipo: TipoTarefa {
        get { TipoTarefa(rawValue: tipoRaw) ?? .outro }
        set { tipoRaw = newValue.rawValue }
    }

    var status: StatusTarefa {
        get { StatusTarefa(rawValue: statusRaw) ?? .aFazer }
        set { statusRaw = newValue.rawValue }
    }

    var prioridade: Prioridade {
        get { Prioridade(rawValue: prioridadeRaw) ?? .media }
        set { prioridadeRaw = newValue.rawValue }
    }

    var concluida: Bool { status == .concluida }

    var atrasada: Bool {
        guard let prazo, !concluida else { return false }
        return prazo < Date()
    }

    var etapasOrdenadas: [Etapa] {
        (etapas ?? []).sorted { $0.ordem < $1.ordem }
    }

    var progressoEtapas: Double? {
        let todas = etapas ?? []
        guard !todas.isEmpty else { return nil }
        return Double(todas.filter(\.feita).count) / Double(todas.count)
    }

    func alternarConclusao() {
        if concluida {
            status = .aFazer
            concluidaEm = nil
        } else {
            status = .concluida
            concluidaEm = Date()
        }
    }

    /// Pendentes primeiro, depois por prazo (sem prazo por último) e prioridade.
    static func ordenacao(_ a: Tarefa, _ b: Tarefa) -> Bool {
        if a.concluida != b.concluida { return !a.concluida }
        switch (a.prazo, b.prazo) {
        case let (pa?, pb?) where pa != pb: return pa < pb
        case (.some, .none): return true
        case (.none, .some): return false
        default: break
        }
        if a.prioridadeRaw != b.prioridadeRaw { return a.prioridadeRaw > b.prioridadeRaw }
        return a.criadaEm > b.criadaEm
    }
}

@Model
final class Etapa {
    var titulo: String = ""
    var feita: Bool = false
    var ordem: Int = 0
    var tarefa: Tarefa?

    init(titulo: String, feita: Bool = false, ordem: Int = 0) {
        self.titulo = titulo
        self.feita = feita
        self.ordem = ordem
    }
}

@Model
final class Compromisso {
    var uid: UUID = UUID()
    var titulo: String = ""
    var inicio: Date = Date()
    var fim: Date = Date().addingTimeInterval(3600)
    var tipoRaw: String = TipoCompromisso.reuniao.rawValue
    var frenteRaw: String = Frente.chinaLink.rawValue
    var local: String = ""
    var link: String = ""
    var notas: String = ""
    /// Minutos antes do início para lembrar. -1 = sem lembrete.
    var lembreteMinutos: Int = 15
    var cliente: Cliente?

    init(titulo: String = "", inicio: Date = Date()) {
        self.titulo = titulo
        self.inicio = inicio
        self.fim = inicio.addingTimeInterval(3600)
    }

    var tipo: TipoCompromisso {
        get { TipoCompromisso(rawValue: tipoRaw) ?? .reuniao }
        set { tipoRaw = newValue.rawValue }
    }

    var frente: Frente {
        get { Frente(rawValue: frenteRaw) ?? .chinaLink }
        set { frenteRaw = newValue.rawValue }
    }

    var url: URL? {
        let texto = link.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !texto.isEmpty else { return nil }
        if texto.lowercased().hasPrefix("http") { return URL(string: texto) }
        return URL(string: "https://\(texto)")
    }

    var jaPassou: Bool { fim < Date() }
    var acontecendoAgora: Bool { inicio <= Date() && fim >= Date() }
}
