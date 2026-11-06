import SwiftData
import SwiftUI

struct TarefasView: View {
    @Environment(\.modelContext) private var context
    @Environment(AppEstado.self) private var app
    @Query(sort: \Atividade.criadaEm, order: .reverse) private var atividades: [Atividade]

    enum FiltroStatus: Hashable { case abertas, concluidas, canceladas }
    enum FiltroTipo: Hashable { case todas, soTarefas, soCompromissos }

    @State private var busca = ""
    @State private var status: FiltroStatus = .abertas
    @State private var tipo: FiltroTipo = .todas
    @State private var contexto: Contexto?

    private let cal = Calendar.current

    private var filtradas: [Atividade] {
        atividades.filter { a in
            let passaStatus: Bool
            switch status {
            case .abertas: passaStatus = a.aberta && !a.jaPassou
            case .concluidas: passaStatus = a.status == .concluida || (a.aberta && a.jaPassou)
            case .canceladas: passaStatus = a.status == .cancelada
            }
            let passaTipo: Bool
            switch tipo {
            case .todas: passaTipo = true
            case .soTarefas: passaTipo = !a.ehCompromisso
            case .soCompromissos: passaTipo = a.ehCompromisso
            }
            let passaContexto = contexto == nil || a.contexto == contexto
            let passaBusca = busca.isEmpty
                || a.titulo.localizedCaseInsensitiveContains(busca)
                || a.descricao.localizedCaseInsensitiveContains(busca)
                || (a.cliente?.nome.localizedCaseInsensitiveContains(busca) ?? false)
            return passaStatus && passaTipo && passaContexto && passaBusca
        }
    }

    /// Data usada para agrupar (compromissos repetidos usam a próxima ocorrência).
    private func referencia(_ a: Atividade) -> Date? {
        a.ehCompromisso ? a.proximaOcorrencia() : a.data
    }

    private var grupos: [(String, [Atividade])] {
        let itens = filtradas
        guard status == .abertas else {
            let ordenadas = itens.sorted { ($0.concluidaEm ?? $0.data ?? $0.criadaEm) > ($1.concluidaEm ?? $1.data ?? $1.criadaEm) }
            return ordenadas.isEmpty ? [] : [("", ordenadas)]
        }

        let hoje = cal.startOfDay(for: Date())
        let amanha = cal.date(byAdding: .day, value: 1, to: hoje) ?? hoje
        let depoisDeAmanha = cal.date(byAdding: .day, value: 2, to: hoje) ?? hoje
        let semana = cal.date(byAdding: .day, value: 8, to: hoje) ?? hoje

        var atrasadas: [Atividade] = [], deHoje: [Atividade] = [], deAmanha: [Atividade] = []
        var proximos: [Atividade] = [], depois: [Atividade] = [], semData: [Atividade] = []

        for a in itens {
            guard let d = referencia(a) else { semData.append(a); continue }
            if a.atrasada && d < hoje { atrasadas.append(a) }
            else if d < amanha { deHoje.append(a) }
            else if d < depoisDeAmanha { deAmanha.append(a) }
            else if d < semana { proximos.append(a) }
            else { depois.append(a) }
        }

        let ordenar: ([Atividade]) -> [Atividade] = { lista in
            lista.sorted { a, b in
                let da = referencia(a).flatMap { a.inicio(em: $0) } ?? .distantFuture
                let db = referencia(b).flatMap { b.inicio(em: $0) } ?? .distantFuture
                if cal.isDate(da, inSameDayAs: db) && a.temHorario != b.temHorario { return a.temHorario }
                if da != db { return da < db }
                return a.prioridadeRaw > b.prioridadeRaw
            }
        }

        return [
            ("Atrasadas", ordenar(atrasadas)),
            ("Hoje", ordenar(deHoje)),
            ("Amanhã", ordenar(deAmanha)),
            ("Próximos 7 dias", ordenar(proximos)),
            ("Mais adiante", ordenar(depois)),
            ("Sem data", semData.sorted { $0.prioridadeRaw > $1.prioridadeRaw }),
        ].filter { !$0.1.isEmpty }
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                CabecalhoPagina("Tarefas", busca: $busca, placeholderBusca: "Buscar por título")
                    .padding(.horizontal, 20)
                    .padding(.top, 12)

                filtros

                if grupos.isEmpty {
                    ScrollView {
                        EstadoVazio(titulo: textoVazio.0, texto: textoVazio.1)
                    }
                } else {
                    lista
                }
            }
            .background(Theme.fundo.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var textoVazio: (String, String) {
        if !busca.isEmpty { return ("Nada encontrado", "Tente buscar outro título.") }
        switch status {
        case .abertas: return ("Nenhuma tarefa em aberto", "Use o botão + para criar uma tarefa.")
        case .concluidas: return ("Nenhuma tarefa concluída", "O que você concluir aparece aqui.")
        case .canceladas: return ("Nenhuma tarefa cancelada", "Tarefas canceladas ficam guardadas aqui.")
        }
    }

    private var filtros: some View {
        VStack(alignment: .leading, spacing: 10) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    FiltroChip(titulo: "Abertas", ativo: status == .abertas) { status = .abertas }
                    FiltroChip(titulo: "Concluídas", ativo: status == .concluidas) { status = .concluidas }
                    FiltroChip(titulo: "Canceladas", ativo: status == .canceladas) { status = .canceladas }
                    FiltroChip(titulo: "Só tarefas", ativo: tipo == .soTarefas) {
                        tipo = tipo == .soTarefas ? .todas : .soTarefas
                    }
                    FiltroChip(titulo: "Só compromissos", ativo: tipo == .soCompromissos) {
                        tipo = tipo == .soCompromissos ? .todas : .soCompromissos
                    }
                }
                .padding(.horizontal, 20)
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Contexto.allCases) { c in
                        ContextoChip(contexto: c, ativo: contexto == c) {
                            withAnimation(.snappy) { contexto = contexto == c ? nil : c }
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .animation(.snappy, value: status)
        .animation(.snappy, value: tipo)
    }

    private var lista: some View {
        List {
            ForEach(grupos, id: \.0) { grupo in
                Section {
                    ForEach(grupo.1) { a in
                        AtividadeRow(atividade: a)
                            .listRowBackground(Theme.card)
                            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                if !a.ehCompromisso && a.status != .cancelada {
                                    Button {
                                        withAnimation { Acoes.alternarConclusao(a, context: context) }
                                    } label: {
                                        Label(a.status == .concluida ? "Reabrir" : "Concluir",
                                              systemImage: a.status == .concluida ? "arrow.uturn.backward" : "checkmark")
                                    }
                                    .tint(Theme.sucesso)
                                }
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    withAnimation { Acoes.apagar(a, context: context) }
                                } label: {
                                    Label("Apagar", systemImage: "trash")
                                }
                                Button {
                                    withAnimation { Acoes.cancelar(a) }
                                } label: {
                                    Label(a.status == .cancelada ? "Reativar" : "Cancelar",
                                          systemImage: a.status == .cancelada ? "arrow.uturn.backward" : "xmark")
                                }
                                .tint(.gray)
                            }
                    }
                } header: {
                    if !grupo.0.isEmpty {
                        Text(grupo.0)
                            .font(Fonte.titulo(16))
                            .foregroundStyle(grupo.0 == "Atrasadas" ? Theme.alerta : Color.secondary)
                            .textCase(nil)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .contentMargins(.top, 0, for: .scrollContent)
    }
}
