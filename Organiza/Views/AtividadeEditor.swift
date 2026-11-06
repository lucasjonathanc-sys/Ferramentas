import SwiftData
import SwiftUI

/// Formulário "Nova atividade" (Tarefa | Compromisso), também usado para editar.
struct AtividadeEditor: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query(sort: \Cliente.nome) private var clientes: [Cliente]

    private let atividade: Atividade?
    private let pedido: NovaAtividadePedido?

    @State private var tipo: TipoAtividade = .tarefa
    @State private var titulo = ""
    @State private var temData = true
    @State private var dia = Date()
    @State private var temHorario = false
    @State private var hora = Date()
    @State private var horaFim = Date().addingTimeInterval(3600)
    @State private var contexto: Contexto = .chinaLink
    @State private var cliente: Cliente?
    @State private var maisOpcoes = false
    @State private var descricao = ""
    @State private var prioridade: Prioridade = .media
    @State private var repeticao: Repeticao = .nunca
    @State private var lembretes: [Int] = [15]
    @State private var local = ""
    @State private var link = ""
    @State private var trabalho: TipoTrabalho = .nenhum
    @State private var etapas: [EtapaRascunho] = []
    @State private var novaEtapa = ""
    @State private var carregado = false
    @State private var confirmarExclusao = false
    @FocusState private var focoTitulo: Bool

    init(atividade: Atividade? = nil, pedido: NovaAtividadePedido? = nil) {
        self.atividade = atividade
        self.pedido = pedido
    }

    private var editando: Bool { atividade != nil }
    private var ehCompromisso: Bool { tipo == .compromisso }
    private var clientesVisiveis: [Cliente] { clientes.filter { $0.ativo || $0 == cliente } }
    private var podeSalvar: Bool { !titulo.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    var body: some View {
        VStack(spacing: 0) {
            cabecalho
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    SegmentoPilula(opcoes: TipoAtividade.allCases, selecao: $tipo) { $0.rawValue }

                    rotulo("Título")
                    TextField(ehCompromisso ? "Ex.: Reunião de pauta" : "O que precisa ser feito?", text: $titulo, axis: .vertical)
                        .focused($focoTitulo)
                        .campo()
                        .padding(.top, -10)

                    datas

                    rotulo("Contexto")
                    FluxoLayout(espacamento: 8) {
                        ForEach(Contexto.allCases) { c in
                            ContextoChip(contexto: c, ativo: contexto == c) {
                                withAnimation(.snappy) { contexto = c }
                            }
                        }
                    }
                    .padding(.top, -10)

                    rotulo("Cliente", opcional: true)
                    clienteMenu
                        .padding(.top, -10)

                    maisOpcoesSecao

                    if editando, let a = atividade {
                        acoesDeStatus(a)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
            .scrollDismissesKeyboard(.interactively)

            rodape
        }
        .font(Fonte.texto(16))
        .background(Theme.fundo.ignoresSafeArea())
        .confirmationDialog("Apagar esta atividade?", isPresented: $confirmarExclusao, titleVisibility: .visible) {
            Button("Apagar", role: .destructive) {
                if let a = atividade {
                    Acoes.apagar(a, context: context)
                    try? context.save()
                }
                dismiss()
            }
        }
        .onAppear(perform: carregar)
        .onChange(of: tipo) { _, novo in
            if novo == .compromisso {
                temData = true
                if !temHorario {
                    temHorario = true
                    hora = Self.proximaHoraCheia(em: dia)
                    horaFim = hora.addingTimeInterval(3600)
                }
            }
        }
    }

    // MARK: Partes

    private var cabecalho: some View {
        HStack {
            Text(editando ? "Editar atividade" : "Nova atividade")
                .font(Fonte.titulo(21))
            Spacer()
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.primary)
                    .frame(width: 36, height: 36)
                    .overlay(Circle().stroke(Theme.borda, lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 12)
    }

    @ViewBuilder
    private var datas: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                rotulo(ehCompromisso ? "Data" : "Vencimento", opcional: !ehCompromisso)
                if temData || ehCompromisso {
                    HStack {
                        DatePicker("", selection: $dia, displayedComponents: .date)
                            .labelsHidden()
                        Spacer(minLength: 0)
                        if !ehCompromisso {
                            botaoLimpar { withAnimation { temData = false; temHorario = false } }
                        }
                    }
                    .campo()
                } else {
                    botaoAdicionar("Sem data") {
                        withAnimation { temData = true }
                    }
                }
            }
            VStack(alignment: .leading, spacing: 8) {
                rotulo(ehCompromisso ? "Início" : "Horário", opcional: !ehCompromisso)
                if temHorario {
                    HStack {
                        DatePicker("", selection: horaInicioBinding, displayedComponents: .hourAndMinute)
                            .labelsHidden()
                        Spacer(minLength: 0)
                        if !ehCompromisso {
                            botaoLimpar { withAnimation { temHorario = false } }
                        }
                    }
                    .campo()
                } else {
                    botaoAdicionar("Adicionar") {
                        withAnimation {
                            temData = true
                            temHorario = true
                            hora = Self.proximaHoraCheia(em: dia)
                        }
                    }
                }
            }
        }

        if ehCompromisso {
            VStack(alignment: .leading, spacing: 8) {
                rotulo("Fim")
                HStack {
                    DatePicker("", selection: $horaFim, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                    Spacer()
                    Text(duracaoTexto).font(Fonte.texto(12)).foregroundStyle(.secondary)
                }
                .campo()
            }
        }
    }

    /// Ao mudar o início, mantém a duração do compromisso.
    private var horaInicioBinding: Binding<Date> {
        Binding(
            get: { hora },
            set: { nova in
                let duracao = max(horaFim.timeIntervalSince(hora), 15 * 60)
                hora = nova
                horaFim = nova.addingTimeInterval(duracao)
            }
        )
    }

    private var duracaoTexto: String {
        var minutos = Int(horaFim.timeIntervalSince(hora) / 60)
        if minutos <= 0 { minutos += 24 * 60 }
        let h = minutos / 60, m = minutos % 60
        if h == 0 { return "\(m) min" }
        return m == 0 ? "\(h) h" : "\(h) h \(m) min"
    }

    private var clienteMenu: some View {
        Menu {
            Button("Nenhum") { cliente = nil }
            if !clientesVisiveis.isEmpty { Divider() }
            ForEach(clientesVisiveis) { c in
                Button(c.nome) {
                    cliente = c
                    contexto = .freela
                }
            }
        } label: {
            HStack {
                if let cliente {
                    Circle().fill(cliente.cor).frame(width: 8, height: 8)
                    Text(cliente.nome).foregroundStyle(Color.primary)
                } else {
                    Text(clientesVisiveis.isEmpty ? "Nenhum (cadastre na aba Clientes)" : "Nenhum")
                        .foregroundStyle(Color.primary)
                }
                Spacer()
                Image(systemName: "chevron.up.chevron.down").font(Fonte.texto(12)).foregroundStyle(.secondary)
            }
            .campo()
        }
    }

    private var maisOpcoesSecao: some View {
        VStack(alignment: .leading, spacing: 16) {
            Button {
                withAnimation(.snappy) { maisOpcoes.toggle() }
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Mais opções").font(Fonte.texto(15, .medio)).foregroundStyle(Color.primary)
                        Text(ehCompromisso
                             ? "Descrição, local, link, repetição e lembretes"
                             : "Descrição, prioridade, repetição e lembretes")
                            .font(Fonte.texto(12)).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: maisOpcoes ? "chevron.up" : "chevron.down")
                        .font(Fonte.texto(12)).foregroundStyle(.secondary)
                }
                .campo()
            }
            .buttonStyle(.plain)

            if maisOpcoes {
                if !ehCompromisso {
                    rotulo("Prioridade")
                    SegmentoPilula(opcoes: Prioridade.allCases, selecao: $prioridade) { $0.nome }
                        .padding(.top, -8)
                }

                rotulo("Repetição")
                Menu {
                    Picker("Repetição", selection: $repeticao) {
                        ForEach(Repeticao.allCases) { r in Text(r.rawValue).tag(r) }
                    }
                } label: {
                    HStack {
                        Text(repeticao.rawValue).foregroundStyle(Color.primary)
                        Spacer()
                        Image(systemName: "chevron.up.chevron.down").font(Fonte.texto(12)).foregroundStyle(.secondary)
                    }
                    .campo()
                }
                .padding(.top, -8)

                rotulo("Lembretes")
                lembretesEditor
                    .padding(.top, -8)

                if ehCompromisso {
                    rotulo("Local", opcional: true)
                    TextField("Sala, endereço...", text: $local).campo().padding(.top, -8)
                    rotulo("Link da reunião", opcional: true)
                    TextField("Meet, Zoom, Teams...", text: $link)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .campo()
                        .padding(.top, -8)
                }

                rotulo("Descrição")
                TextField("Briefing, pauta, links, observações...", text: $descricao, axis: .vertical)
                    .lineLimit(4...10)
                    .campo()
                    .padding(.top, -8)

                if !ehCompromisso {
                    trabalhoEEtapas
                }
            }
        }
    }

    private var lembretesEditor: some View {
        FluxoLayout(espacamento: 8) {
            ForEach(lembretes.sorted(), id: \.self) { minutos in
                HStack(spacing: 6) {
                    Text(OpcoesLembrete.nome(minutos))
                    Button {
                        withAnimation { lembretes.removeAll { $0 == minutos } }
                    } label: {
                        Image(systemName: "xmark").font(.caption2.weight(.bold))
                    }
                    .buttonStyle(.plain)
                }
                .font(Fonte.texto(15))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Theme.marcaSuave, in: Capsule())
            }
            Menu {
                ForEach(OpcoesLembrete.todas.filter { !lembretes.contains($0) }, id: \.self) { m in
                    Button(OpcoesLembrete.nome(m)) {
                        withAnimation { lembretes.append(m) }
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Text("Adicionar lembrete")
                    Image(systemName: "chevron.up.chevron.down").font(Fonte.texto(11))
                }
                .font(Fonte.texto(15))
                .foregroundStyle(Color.primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .overlay(Capsule().stroke(Theme.borda, lineWidth: 1))
            }
        }
    }

    @ViewBuilder
    private var trabalhoEEtapas: some View {
        rotulo("Tipo de trabalho", opcional: true)
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(TipoTrabalho.allCases) { t in
                    FiltroChip(titulo: t.rawValue, ativo: trabalho == t) {
                        withAnimation(.snappy) { trabalho = t }
                    }
                }
            }
        }
        .padding(.top, -8)

        rotulo("Etapas", opcional: true)
        VStack(alignment: .leading, spacing: 10) {
            ForEach($etapas) { $etapa in
                HStack(spacing: 10) {
                    Button { etapa.feita.toggle() } label: {
                        Image(systemName: etapa.feita ? "checkmark.square.fill" : "square")
                            .foregroundStyle(etapa.feita ? Theme.acento : Color.secondary)
                    }
                    .buttonStyle(.plain)
                    TextField("Etapa", text: $etapa.titulo)
                        .strikethrough(etapa.feita)
                    Button {
                        let id = etapa.id
                        withAnimation { etapas.removeAll { $0.id == id } }
                    } label: {
                        Image(systemName: "minus.circle").foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            HStack(spacing: 10) {
                Image(systemName: "plus").foregroundStyle(.secondary)
                TextField("Adicionar etapa", text: $novaEtapa)
                    .submitLabel(.done)
                    .onSubmit {
                        let texto = novaEtapa.trimmingCharacters(in: .whitespaces)
                        guard !texto.isEmpty else { return }
                        withAnimation { etapas.append(EtapaRascunho(titulo: texto)) }
                        novaEtapa = ""
                    }
            }
            if etapas.isEmpty && !trabalho.etapasSugeridas.isEmpty {
                Button {
                    withAnimation { etapas = trabalho.etapasSugeridas.map { EtapaRascunho(titulo: $0) } }
                } label: {
                    Label("Usar etapas sugeridas para \(trabalho.rawValue)", systemImage: "wand.and.stars")
                        .font(Fonte.texto(15))
                }
                .tint(Color.primary)
            }
        }
        .campo()
        .padding(.top, -8)
    }

    private func acoesDeStatus(_ a: Atividade) -> some View {
        VStack(spacing: 10) {
            if !a.ehCompromisso {
                HStack(spacing: 10) {
                    Button(a.status == .concluida ? "Reabrir" : "Concluir") {
                        salvar(fechar: false)
                        Acoes.alternarConclusao(a, context: context)
                        try? context.save()
                        dismiss()
                    }
                    .buttonStyle(PilulaStyle(principal: false))
                    Button(a.status == .cancelada ? "Reativar" : "Cancelar tarefa") {
                        salvar(fechar: false)
                        Acoes.cancelar(a)
                        try? context.save()
                        dismiss()
                    }
                    .buttonStyle(PilulaStyle(principal: false))
                }
            }
            Button(role: .destructive) {
                confirmarExclusao = true
            } label: {
                Label("Apagar", systemImage: "trash").font(Fonte.texto(15))
            }
            .tint(Theme.alerta)
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }

    private var rodape: some View {
        HStack(spacing: 12) {
            Spacer()
            Button("Cancelar") { dismiss() }
                .buttonStyle(PilulaStyle(principal: false))
            Button("Salvar") { salvar(fechar: true) }
                .buttonStyle(PilulaStyle())
                .disabled(!podeSalvar)
                .opacity(podeSalvar ? 1 : 0.4)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Theme.fundo.overlay(alignment: .top) { Theme.borda.frame(height: 0.5) })
    }

    // MARK: Auxiliares

    private func rotulo(_ texto: String, opcional: Bool = false) -> some View {
        HStack(spacing: 4) {
            Text(texto).font(Fonte.texto(15, .medio))
            if opcional {
                Text("(opcional)").font(Fonte.texto(15)).foregroundStyle(.secondary)
            }
        }
    }

    private func botaoLimpar(_ acao: @escaping () -> Void) -> some View {
        Button(action: acao) {
            Image(systemName: "xmark.circle.fill").foregroundStyle(.tertiary)
        }
        .buttonStyle(.plain)
    }

    private func botaoAdicionar(_ texto: String, acao: @escaping () -> Void) -> some View {
        Button(action: acao) {
            HStack {
                Text(texto).foregroundStyle(.secondary)
                Spacer()
                Image(systemName: "plus").font(Fonte.texto(12)).foregroundStyle(.secondary)
            }
            .campo()
        }
        .buttonStyle(.plain)
    }

    // MARK: Carregar / salvar

    private func carregar() {
        guard !carregado else { return }
        carregado = true

        if let a = atividade {
            tipo = a.tipo
            titulo = a.titulo
            temData = a.data != nil
            dia = a.data ?? Date()
            temHorario = a.temHorario
            hora = a.data ?? Self.proximaHoraCheia(em: Date())
            horaFim = a.fimEfetivo ?? hora.addingTimeInterval(3600)
            contexto = a.contexto
            cliente = a.cliente
            descricao = a.descricao
            prioridade = a.prioridade
            repeticao = a.repeticao
            lembretes = a.lembretes
            local = a.local
            link = a.link
            trabalho = a.trabalho
            etapas = a.etapasOrdenadas.map { EtapaRascunho(titulo: $0.titulo, feita: $0.feita) }
            // abre "Mais opções" se algo lá estiver preenchido
            maisOpcoes = !descricao.isEmpty || repeticao != .nunca || !etapas.isEmpty || !local.isEmpty || !link.isEmpty
        } else {
            let p = pedido ?? NovaAtividadePedido()
            tipo = p.tipo
            dia = p.data ?? Date()
            temData = true
            if p.tipo == .compromisso || p.temHorario {
                temHorario = true
                hora = p.temHorario ? (p.data ?? Self.proximaHoraCheia(em: dia)) : Self.proximaHoraCheia(em: dia)
                horaFim = hora.addingTimeInterval(3600)
            }
            if let c = p.cliente {
                cliente = c
                contexto = .freela
            }
            focoTitulo = true
        }
    }

    private func salvar(fechar: Bool) {
        guard podeSalvar else { return }
        let a: Atividade
        if let existente = atividade {
            a = existente
        } else {
            a = Atividade()
            context.insert(a)
        }

        let cal = Calendar.current
        a.tipo = tipo
        a.titulo = titulo.trimmingCharacters(in: .whitespacesAndNewlines)
        a.contexto = contexto
        a.cliente = cliente
        a.descricao = descricao
        a.prioridade = prioridade
        a.repeticao = repeticao
        a.lembretes = lembretes.sorted()
        a.local = ehCompromisso ? local : ""
        a.link = ehCompromisso ? link : ""
        a.trabalho = ehCompromisso ? .nenhum : trabalho

        if temData || ehCompromisso {
            if temHorario || ehCompromisso {
                let h = cal.dateComponents([.hour, .minute], from: hora)
                let inicio = cal.date(bySettingHour: h.hour ?? 9, minute: h.minute ?? 0, second: 0, of: dia) ?? dia
                a.data = inicio
                a.temHorario = true
                if ehCompromisso {
                    let f = cal.dateComponents([.hour, .minute], from: horaFim)
                    var fim = cal.date(bySettingHour: f.hour ?? 10, minute: f.minute ?? 0, second: 0, of: dia) ?? inicio
                    if fim <= inicio { fim = cal.date(byAdding: .day, value: 1, to: fim) ?? fim }
                    a.fim = fim
                } else {
                    a.fim = nil
                }
            } else {
                a.data = cal.startOfDay(for: dia)
                a.temHorario = false
                a.fim = nil
            }
        } else {
            a.data = nil
            a.temHorario = false
            a.fim = nil
        }

        // Recria as etapas a partir do rascunho
        for antiga in a.etapas ?? [] { context.delete(antiga) }
        a.etapas = []
        if !ehCompromisso {
            let validas = etapas.filter { !$0.titulo.trimmingCharacters(in: .whitespaces).isEmpty }
            for (i, r) in validas.enumerated() {
                let e = Etapa(titulo: r.titulo, feita: r.feita, ordem: i)
                context.insert(e)
                e.atividade = a
            }
        }

        try? context.save()
        Notificacoes.atualizar(a)
        if fechar { dismiss() }
    }

    private static func proximaHoraCheia(em dia: Date) -> Date {
        let cal = Calendar.current
        if cal.isDateInToday(dia) {
            let proxima = cal.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
            return cal.date(bySettingHour: cal.component(.hour, from: proxima), minute: 0, second: 0, of: proxima) ?? proxima
        }
        return cal.date(bySettingHour: 9, minute: 0, second: 0, of: dia) ?? dia
    }
}

struct EtapaRascunho: Identifiable {
    let id = UUID()
    var titulo: String
    var feita: Bool = false
}
