import SwiftData
import SwiftUI

struct HojeView: View {
    @Environment(AppEstado.self) private var app
    @Query private var atividades: [Atividade]
    @AppStorage("nomeUsuaria") private var nome = "Hanna"

    private let cal = Calendar.current

    private var saudacao: String {
        let hora = cal.component(.hour, from: Date())
        let base: String
        switch hora {
        case 5..<12: base = "Bom dia"
        case 12..<18: base = "Boa tarde"
        default: base = "Boa noite"
        }
        let primeiro = nome.split(separator: " ").first.map(String.init) ?? ""
        return primeiro.isEmpty ? base : "\(base), \(primeiro)"
    }

    private var compromissosHoje: [Atividade] {
        atividades
            .filter { $0.ehCompromisso && $0.status != .cancelada && $0.aparece(em: Date()) }
            .sorted { ($0.inicio(em: Date()) ?? .distantPast) < ($1.inicio(em: Date()) ?? .distantPast) }
    }

    private var tarefasHoje: [Atividade] {
        atividades
            .filter { a in
                guard !a.ehCompromisso, a.status != .cancelada else { return false }
                if let d = a.data, cal.isDateInToday(d) { return true }
                if let c = a.concluidaEm, cal.isDateInToday(c), a.status == .concluida { return true }
                return false
            }
            .sorted(by: Atividade.ordenacao)
    }

    private var atrasadas: [Atividade] {
        atividades
            .filter { a in
                guard a.atrasada, let d = a.data else { return false }
                return !cal.isDateInToday(d)
            }
            .sorted(by: Atividade.ordenacao)
    }

    private var proximosDias: [Atividade] {
        let amanha = cal.startOfDay(for: cal.date(byAdding: .day, value: 1, to: Date()) ?? Date())
        let limite = cal.date(byAdding: .day, value: 7, to: amanha) ?? amanha
        return atividades
            .filter { a in
                guard a.aberta, let d = a.ehCompromisso ? a.proximaOcorrencia(aPartirDe: amanha) : a.data else { return false }
                return d >= amanha && d < limite
            }
            .sorted { a, b in
                let da = a.ehCompromisso ? (a.proximaOcorrencia(aPartirDe: amanha) ?? .distantFuture) : (a.data ?? .distantFuture)
                let db = b.ehCompromisso ? (b.proximaOcorrencia(aPartirDe: amanha) ?? .distantFuture) : (b.data ?? .distantFuture)
                return da < db
            }
    }

    private var semPrazo: Int {
        atividades.filter { $0.aberta && $0.data == nil }.count
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    CabecalhoPagina(saudacao, subtitulo: Fmt.dataPorExtenso(Date()), pincel: true)

                    if atividades.isEmpty {
                        EstadoVazio(
                            titulo: "Comece pela primeira atividade",
                            texto: "Tarefas e compromissos que você criar aparecem aqui, organizados por dia.",
                            botao: "Nova atividade"
                        ) { app.nova() }
                    } else {
                        resumo

                        secao("Agenda de hoje", itens: compromissosHoje, dia: Date(), vazio: "Nenhum compromisso hoje.")
                        if !atrasadas.isEmpty {
                            secao("Atrasadas", itens: atrasadas, cor: Theme.alerta)
                        }
                        secao("Para hoje", itens: tarefasHoje, vazio: "Nada com vencimento hoje.")
                        if !proximosDias.isEmpty {
                            secao("Próximos dias", itens: proximosDias)
                        }
                        if semPrazo > 0 {
                            Text("\(semPrazo) tarefa\(semPrazo == 1 ? "" : "s") sem data na aba Tarefas")
                                .font(Fonte.texto(13))
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
            }
            .background(Theme.fundo.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var resumo: some View {
        let total = tarefasHoje.count
        let feitas = tarefasHoje.filter { $0.status == .concluida }.count
        let progresso = total == 0 ? 0 : Double(feitas) / Double(total)

        return VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(total == 0 ? "Sem tarefas para hoje" : "\(feitas) de \(total) feitas hoje")
                    .font(Fonte.texto(15, .medio))
                Spacer()
                Text("\(compromissosHoje.count) compromisso\(compromissosHoje.count == 1 ? "" : "s")")
                    .font(Fonte.texto(15))
                    .foregroundStyle(.secondary)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Theme.suave)
                    Capsule().fill(Theme.acento)
                        .frame(width: max(0, geo.size.width * progresso))
                }
            }
            .frame(height: 6)
            .animation(.snappy, value: progresso)
        }
        .card()
    }

    private func secao(_ titulo: String, itens: [Atividade], dia: Date? = nil, cor: Color = .primary, vazio: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            TituloSecao(titulo: titulo, detalhe: itens.isEmpty ? nil : "\(itens.count)", cor: cor)
            if itens.isEmpty {
                if let vazio {
                    Text(vazio)
                        .font(Fonte.texto(15))
                        .foregroundStyle(.secondary)
                        .card()
                }
            } else {
                VStack(spacing: 0) {
                    ForEach(itens) { a in
                        AtividadeRow(atividade: a, dia: dia, mostrarData: dia == nil)
                        if a.id != itens.last?.id {
                            Divider().padding(.leading, 38)
                        }
                    }
                }
                .card(padding: 12)
            }
        }
    }
}
