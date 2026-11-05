import SwiftData
import SwiftUI

/// Cria ou edita uma tarefa.
struct TarefaEditor: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query(sort: \Cliente.nome) private var clientes: [Cliente]

    private let tarefa: Tarefa?
    private let clienteInicial: Cliente?
    private let prazoInicial: Date?
    private let frenteInicial: Frente?

    @State private var titulo = ""
    @State private var notas = ""
    @State private var frente: Frente = .chinaLink
    @State private var tipo: TipoTarefa = .copy
    @State private var status: StatusTarefa = .aFazer
    @State private var prioridade: Prioridade = .media
    @State private var temPrazo = true
    @State private var prazo = Date()
    @State private var lembrete = true
    @State private var cliente: Cliente?
    @State private var etapas: [EtapaRascunho] = []
    @State private var novaEtapa = ""
    @State private var carregado = false
    @State private var confirmarExclusao = false
    @FocusState private var focoTitulo: Bool

    init(tarefa: Tarefa? = nil, cliente: Cliente? = nil, prazo: Date? = nil, frente: Frente? = nil) {
        self.tarefa = tarefa
        self.clienteInicial = cliente
        self.prazoInicial = prazo
        self.frenteInicial = frente
    }

    private var editando: Bool { tarefa != nil }

    private var clientesAtivos: [Cliente] {
        clientes.filter { $0.ativo || $0 == cliente }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("O que precisa ser feito?", text: $titulo, axis: .vertical)
                        .font(.title3.weight(.medium))
                        .focused($focoTitulo)

                    Picker("Frente", selection: $frente) {
                        ForEach(Frente.allCases) { f in
                            Text(f.rawValue).tag(f)
                        }
                    }
                    .pickerStyle(.segmented)
                    .listRowSeparator(.hidden)
                }

                Section("Tipo") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(TipoTarefa.allCases) { t in
                                Button {
                                    withAnimation(.snappy) { tipo = t }
                                } label: {
                                    VStack(spacing: 6) {
                                        Image(systemName: t.icone).font(.title3)
                                        Text(t.rawValue).font(.caption2.weight(.semibold))
                                    }
                                    .frame(width: 74, height: 62)
                                    .foregroundStyle(tipo == t ? Color.white : t.cor)
                                    .background(tipo == t ? t.cor : t.cor.opacity(0.12),
                                                in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .listRowInsets(EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12))
                }

                if frente == .freela || !clientesAtivos.isEmpty {
                    Section {
                        if clientesAtivos.isEmpty {
                            Label("Cadastre seus clientes na aba Clientes", systemImage: "person.crop.circle.badge.plus")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        } else {
                            Picker("Cliente", selection: $cliente) {
                                Text("Nenhum").tag(Cliente?.none)
                                ForEach(clientesAtivos) { c in
                                    Text(c.nome).tag(Optional(c))
                                }
                            }
                        }
                    }
                }

                Section {
                    Picker("Status", selection: $status) {
                        ForEach(StatusTarefa.allCases) { s in
                            Label(s.rawValue, systemImage: s.icone).tag(s)
                        }
                    }
                    Picker("Prioridade", selection: $prioridade) {
                        ForEach(Prioridade.allCases) { p in
                            Text(p.nome).tag(p)
                        }
                    }
                }

                Section {
                    Toggle(isOn: $temPrazo.animation()) {
                        Label("Prazo", systemImage: "calendar")
                    }
                    if temPrazo {
                        DatePicker("Entrega", selection: $prazo, displayedComponents: [.date, .hourAndMinute])
                        HStack(spacing: 8) {
                            atalhoPrazo("Hoje", dias: 0)
                            atalhoPrazo("Amanhã", dias: 1)
                            atalhoPrazo("+1 semana", dias: 7)
                        }
                        Toggle(isOn: $lembrete) {
                            Label("Lembrar no horário", systemImage: "bell.badge")
                        }
                    }
                }

                Section {
                    ForEach($etapas) { $etapa in
                        HStack {
                            Button {
                                etapa.feita.toggle()
                            } label: {
                                Image(systemName: etapa.feita ? "checkmark.square.fill" : "square")
                                    .foregroundStyle(etapa.feita ? Theme.menta : Color.secondary)
                            }
                            .buttonStyle(.plain)
                            TextField("Etapa", text: $etapa.titulo)
                                .strikethrough(etapa.feita)
                        }
                    }
                    .onDelete { etapas.remove(atOffsets: $0) }
                    .onMove { etapas.move(fromOffsets: $0, toOffset: $1) }

                    HStack {
                        Image(systemName: "plus")
                            .foregroundStyle(Theme.lilas)
                        TextField("Adicionar etapa", text: $novaEtapa)
                            .onSubmit(adicionarEtapa)
                            .submitLabel(.done)
                    }

                    if etapas.isEmpty && !tipo.etapasSugeridas.isEmpty {
                        Button {
                            withAnimation {
                                etapas = tipo.etapasSugeridas.map { EtapaRascunho(titulo: $0) }
                            }
                        } label: {
                            Label("Usar etapas sugeridas para \(tipo.rawValue)", systemImage: "wand.and.stars")
                        }
                    }
                } header: {
                    Text("Etapas")
                } footer: {
                    if !etapas.isEmpty {
                        Text("\(etapas.filter(\.feita).count) de \(etapas.count) concluídas")
                    }
                }

                Section("Notas, briefing, links") {
                    TextField("Ex.: tom de voz, referências, link do Drive...", text: $notas, axis: .vertical)
                        .lineLimit(3...10)
                }

                if editando {
                    Section {
                        Button(role: .destructive) {
                            confirmarExclusao = true
                        } label: {
                            Label("Apagar tarefa", systemImage: "trash")
                        }
                    }
                }
            }
            .navigationTitle(editando ? "Editar tarefa" : "Nova tarefa")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salvar", action: salvar)
                        .fontWeight(.semibold)
                        .disabled(titulo.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .confirmationDialog("Apagar esta tarefa?", isPresented: $confirmarExclusao, titleVisibility: .visible) {
                Button("Apagar", role: .destructive, action: apagar)
            }
            .onAppear(perform: carregar)
        }
    }

    private func atalhoPrazo(_ texto: String, dias: Int) -> some View {
        Button(texto) {
            let cal = Calendar.current
            let base = cal.date(byAdding: .day, value: dias, to: Date()) ?? Date()
            let hora = cal.component(.hour, from: prazo)
            let minuto = cal.component(.minute, from: prazo)
            prazo = cal.date(bySettingHour: hora, minute: minuto, second: 0, of: base) ?? base
        }
        .font(.caption.weight(.semibold))
        .buttonStyle(.bordered)
        .tint(Theme.lilas)
    }

    private func adicionarEtapa() {
        let texto = novaEtapa.trimmingCharacters(in: .whitespaces)
        guard !texto.isEmpty else { return }
        withAnimation { etapas.append(EtapaRascunho(titulo: texto)) }
        novaEtapa = ""
    }

    private func carregar() {
        guard !carregado else { return }
        carregado = true

        if let t = tarefa {
            titulo = t.titulo
            notas = t.notas
            frente = t.frente
            tipo = t.tipo
            status = t.status
            prioridade = t.prioridade
            temPrazo = t.prazo != nil
            prazo = t.prazo ?? Self.prazoPadrao()
            lembrete = t.lembrete
            cliente = t.cliente
            etapas = t.etapasOrdenadas.map { EtapaRascunho(titulo: $0.titulo, feita: $0.feita) }
        } else {
            cliente = clienteInicial
            frente = frenteInicial ?? (clienteInicial != nil ? .freela : .chinaLink)
            prazo = prazoInicial.map(Self.ajustarHora) ?? Self.prazoPadrao()
            focoTitulo = true
        }
    }

    private func salvar() {
        let t: Tarefa
        if let existente = tarefa {
            t = existente
        } else {
            t = Tarefa()
            context.insert(t)
        }

        t.titulo = titulo.trimmingCharacters(in: .whitespacesAndNewlines)
        t.notas = notas
        t.frente = frente
        t.tipo = tipo
        if t.status != status {
            t.concluidaEm = status == .concluida ? Date() : nil
        }
        t.status = status
        t.prioridade = prioridade
        t.prazo = temPrazo ? prazo : nil
        t.lembrete = temPrazo && lembrete
        t.cliente = cliente

        // Recria as etapas a partir do rascunho
        for antiga in t.etapas ?? [] {
            context.delete(antiga)
        }
        t.etapas = []
        let validas = etapas.filter { !$0.titulo.trimmingCharacters(in: .whitespaces).isEmpty }
        for (indice, rascunho) in validas.enumerated() {
            let etapa = Etapa(titulo: rascunho.titulo, feita: rascunho.feita, ordem: indice)
            context.insert(etapa)
            etapa.tarefa = t
        }

        try? context.save()
        Notificacoes.atualizar(t)
        dismiss()
    }

    private func apagar() {
        guard let t = tarefa else { return }
        Notificacoes.cancelar(t)
        context.delete(t)
        try? context.save()
        dismiss()
    }

    /// Hoje às 18h (ou daqui a 1h, se já passou das 18h).
    private static func prazoPadrao() -> Date {
        let cal = Calendar.current
        let hoje18 = cal.date(bySettingHour: 18, minute: 0, second: 0, of: Date()) ?? Date()
        if hoje18 > Date() { return hoje18 }
        return cal.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
    }

    /// Mantém o dia escolhido e define 18h.
    private static func ajustarHora(_ dia: Date) -> Date {
        Calendar.current.date(bySettingHour: 18, minute: 0, second: 0, of: dia) ?? dia
    }
}

struct EtapaRascunho: Identifiable {
    let id = UUID()
    var titulo: String
    var feita: Bool = false
}
