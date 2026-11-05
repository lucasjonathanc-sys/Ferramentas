import SwiftData
import SwiftUI

struct ClientesView: View {
    @Query(sort: \Cliente.nome) private var clientes: [Cliente]
    @State private var novoCliente = false
    @State private var mostrarInativos = false

    private var ativos: [Cliente] { clientes.filter(\.ativo) }
    private var inativos: [Cliente] { clientes.filter { !$0.ativo } }
    private var receitaMensal: Double { ativos.reduce(0) { $0 + $1.valorMensal } }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    resumo

                    if clientes.isEmpty {
                        ContentUnavailableView {
                            Label("Nenhum cliente ainda", systemImage: "person.2.badge.plus")
                        } description: {
                            Text("Cadastre as empresas que você atende como social media para organizar entregas por cliente.")
                        } actions: {
                            Button("Adicionar cliente") { novoCliente = true }
                                .buttonStyle(.borderedProminent)
                                .tint(Theme.lilas)
                        }
                        .padding(.top, 30)
                    }

                    LazyVStack(spacing: 12) {
                        ForEach(ativos) { cliente in
                            NavigationLink(value: cliente) {
                                ClienteCard(cliente: cliente)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    if !inativos.isEmpty {
                        DisclosureGroup(isExpanded: $mostrarInativos) {
                            LazyVStack(spacing: 12) {
                                ForEach(inativos) { cliente in
                                    NavigationLink(value: cliente) {
                                        ClienteCard(cliente: cliente).opacity(0.6)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.top, 8)
                        } label: {
                            Text("Clientes pausados (\(inativos.count))")
                                .font(.subheadline.weight(.semibold))
                        }
                        .tint(Theme.lilas)
                    }
                }
                .padding()
            }
            .background(Theme.fundo.ignoresSafeArea())
            .navigationTitle("Clientes")
            .navigationDestination(for: Cliente.self) { ClienteDetalheView(cliente: $0) }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { novoCliente = true } label: {
                        Image(systemName: "plus.circle.fill").font(.title3)
                    }
                }
            }
            .sheet(isPresented: $novoCliente) { ClienteEditor() }
        }
    }

    @ViewBuilder
    private var resumo: some View {
        if !ativos.isEmpty {
            let pendentes = ativos.reduce(0) { $0 + $1.tarefasPendentes.count }
            HStack(spacing: 12) {
                metrica(valor: "\(ativos.count)", titulo: "clientes ativos", icone: "person.2.fill", cor: Theme.lilas)
                metrica(valor: "\(pendentes)", titulo: "entregas pendentes", icone: "tray.full.fill", cor: Theme.rosa)
            }
            if receitaMensal > 0 {
                HStack {
                    Image(systemName: "banknote.fill")
                    Text("Renda extra mensal")
                    Spacer()
                    Text(Fmt.dinheiro(receitaMensal)).fontWeight(.bold)
                }
                .font(.subheadline)
                .foregroundStyle(.white)
                .padding(16)
                .background(Theme.gradiente, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            }
        }
    }

    private func metrica(valor: String, titulo: String, icone: String, cor: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: icone).foregroundStyle(cor)
            Text(valor).font(.system(.title, design: .rounded, weight: .bold))
            Text(titulo).font(.caption).foregroundStyle(.secondary)
        }
        .card()
    }
}

struct ClienteCard: View {
    let cliente: Cliente

    var body: some View {
        let pendentes = cliente.tarefasPendentes
        let proxima = pendentes.first { $0.prazo != nil }

        HStack(spacing: 14) {
            AvatarCliente(cliente: cliente, tamanho: 48)
            VStack(alignment: .leading, spacing: 4) {
                Text(cliente.nome).font(.headline)
                if !cliente.nicho.isEmpty {
                    Text(cliente.nicho).font(.subheadline).foregroundStyle(.secondary)
                }
                HStack(spacing: 6) {
                    Chip(texto: pendentes.isEmpty ? "Tudo em dia" : "\(pendentes.count) pendente\(pendentes.count == 1 ? "" : "s")",
                         icone: pendentes.isEmpty ? "checkmark" : "tray.full",
                         cor: pendentes.isEmpty ? Theme.menta : cliente.cor)
                    if let proxima, let prazo = proxima.prazo {
                        Chip(texto: Fmt.prazo(prazo), icone: "clock",
                             cor: proxima.atrasada ? Theme.vermelho : Color.secondary)
                    }
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .card()
    }
}

struct ClienteDetalheView: View {
    let cliente: Cliente

    @State private var editar = false
    @State private var novaTarefa = false
    @State private var novoCompromisso = false
    @State private var tarefaEditada: Tarefa?
    @State private var compromissoEditado: Compromisso?
    @State private var mostrarConcluidas = false

    private var tarefas: [Tarefa] {
        (cliente.tarefas ?? [])
            .filter { mostrarConcluidas || !$0.concluida }
            .sorted(by: Tarefa.ordenacao)
    }

    private var proximosCompromissos: [Compromisso] {
        (cliente.compromissos ?? [])
            .filter { !$0.jaPassou }
            .sorted { $0.inicio < $1.inicio }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                cabecalho

                HStack(spacing: 12) {
                    botao("Tarefa", icone: "plus.circle.fill") { novaTarefa = true }
                    botao("Compromisso", icone: "calendar.badge.plus") { novoCompromisso = true }
                }

                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        TituloSecao(titulo: "Entregas", icone: "tray.full.fill", cor: cliente.cor)
                        Button(mostrarConcluidas ? "Ocultar feitas" : "Ver feitas") {
                            withAnimation { mostrarConcluidas.toggle() }
                        }
                        .font(.caption.weight(.semibold))
                        .tint(cliente.cor)
                    }
                    if tarefas.isEmpty {
                        CartaoVazio(texto: "Nenhuma entrega pendente.", icone: "checkmark.seal.fill")
                    } else {
                        VStack(spacing: 6) {
                            ForEach(tarefas) { t in
                                TarefaRow(tarefa: t, mostrarFrente: false) { tarefaEditada = t }
                                if t.id != tarefas.last?.id { Divider().padding(.leading, 40) }
                            }
                        }
                        .card()
                    }
                }

                if !proximosCompromissos.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        TituloSecao(titulo: "Próximos compromissos", icone: "calendar", cor: Theme.azul)
                        VStack(spacing: 8) {
                            ForEach(proximosCompromissos) { c in
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(Fmt.prazo(c.inicio))
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(.secondary)
                                    CompromissoRow(compromisso: c) { compromissoEditado = c }
                                }
                            }
                        }
                        .card()
                    }
                }

                if !cliente.observacoes.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        TituloSecao(titulo: "Observações", icone: "note.text", cor: Theme.amarelo)
                        Text(cliente.observacoes)
                            .font(.subheadline)
                            .card()
                    }
                }
            }
            .padding()
        }
        .background(Theme.fundo.ignoresSafeArea())
        .navigationTitle(cliente.nome)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Editar") { editar = true }
            }
        }
        .sheet(isPresented: $editar) { ClienteEditor(cliente: cliente) }
        .sheet(isPresented: $novaTarefa) { TarefaEditor(cliente: cliente) }
        .sheet(isPresented: $novoCompromisso) { CompromissoEditor(cliente: cliente) }
        .sheet(item: $tarefaEditada) { TarefaEditor(tarefa: $0) }
        .sheet(item: $compromissoEditado) { CompromissoEditor(compromisso: $0) }
    }

    private var cabecalho: some View {
        HStack(spacing: 16) {
            AvatarCliente(cliente: cliente, tamanho: 64)
            VStack(alignment: .leading, spacing: 6) {
                Text(cliente.nome).font(.title2.weight(.bold))
                if !cliente.nicho.isEmpty {
                    Text(cliente.nicho).foregroundStyle(.secondary)
                }
                HStack(spacing: 8) {
                    if let url = cliente.linkInstagram {
                        Link(destination: url) {
                            Chip(texto: "@\(cliente.instagram.replacingOccurrences(of: "@", with: ""))",
                                 icone: "camera", cor: cliente.cor)
                        }
                    }
                    if let whats = linkContato {
                        Link(destination: whats) {
                            Chip(texto: "Contato", icone: "message.fill", cor: Theme.menta)
                        }
                    }
                    if cliente.valorMensal > 0 {
                        Chip(texto: Fmt.dinheiro(cliente.valorMensal) + "/mês", icone: "banknote", cor: Theme.amarelo)
                    }
                }
            }
            Spacer(minLength: 0)
        }
        .card()
    }

    /// Abre o WhatsApp se o contato for um número de telefone.
    private var linkContato: URL? {
        let digitos = cliente.contato.filter(\.isNumber)
        guard digitos.count >= 10 else { return nil }
        let numero = digitos.count <= 11 ? "55" + digitos : digitos
        return URL(string: "https://wa.me/\(numero)")
    }

    private func botao(_ texto: String, icone: String, acao: @escaping () -> Void) -> some View {
        Button(action: acao) {
            Label(texto, systemImage: icone)
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .foregroundStyle(cliente.cor)
                .background(cliente.cor.opacity(0.12), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

struct ClienteEditor: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    private let cliente: Cliente?

    @State private var nome = ""
    @State private var nicho = ""
    @State private var instagram = ""
    @State private var contato = ""
    @State private var valorMensal: Double = 0
    @State private var corHex = Theme.paletaClientes[0]
    @State private var observacoes = ""
    @State private var ativo = true
    @State private var carregado = false
    @State private var confirmarExclusao = false

    init(cliente: Cliente? = nil) {
        self.cliente = cliente
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Spacer()
                        Text(iniciaisPrevia)
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(width: 80, height: 80)
                            .background(Color(hex: corHex).gradient, in: Circle())
                        Spacer()
                    }
                    .listRowBackground(Color.clear)

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                        ForEach(Theme.paletaClientes, id: \.self) { hex in
                            Circle()
                                .fill(Color(hex: hex))
                                .frame(width: 34, height: 34)
                                .overlay {
                                    if hex == corHex {
                                        Image(systemName: "checkmark").font(.caption.weight(.bold)).foregroundStyle(.white)
                                    }
                                }
                                .onTapGesture { withAnimation(.snappy) { corHex = hex } }
                        }
                    }
                    .padding(.vertical, 6)
                }

                Section("Dados") {
                    TextField("Nome da empresa", text: $nome)
                    TextField("Nicho (ex.: confeitaria, salão, pet shop)", text: $nicho)
                    TextField("@instagram", text: $instagram)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    TextField("WhatsApp / contato", text: $contato)
                        .keyboardType(.phonePad)
                }

                Section("Financeiro") {
                    HStack {
                        Text("Valor mensal")
                        Spacer()
                        TextField("R$ 0,00", value: $valorMensal, format: .currency(code: "BRL").locale(Fmt.locale))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    Toggle("Cliente ativo", isOn: $ativo)
                }

                Section("Observações") {
                    TextField("Identidade visual, tom de voz, dias de postagem...", text: $observacoes, axis: .vertical)
                        .lineLimit(3...10)
                }

                if cliente != nil {
                    Section {
                        Button(role: .destructive) {
                            confirmarExclusao = true
                        } label: {
                            Label("Apagar cliente", systemImage: "trash")
                        }
                    } footer: {
                        Text("As tarefas desse cliente não são apagadas, apenas ficam sem cliente.")
                    }
                }
            }
            .navigationTitle(cliente == nil ? "Novo cliente" : "Editar cliente")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salvar", action: salvar)
                        .fontWeight(.semibold)
                        .disabled(nome.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .confirmationDialog("Apagar este cliente?", isPresented: $confirmarExclusao, titleVisibility: .visible) {
                Button("Apagar", role: .destructive, action: apagar)
            }
            .onAppear(perform: carregar)
        }
    }

    private var iniciaisPrevia: String {
        let letras = nome.split(separator: " ").prefix(2).compactMap { $0.first }.map { String($0) }.joined()
        return letras.isEmpty ? "?" : letras.uppercased()
    }

    private func carregar() {
        guard !carregado else { return }
        carregado = true
        if let c = cliente {
            nome = c.nome
            nicho = c.nicho
            instagram = c.instagram
            contato = c.contato
            valorMensal = c.valorMensal
            corHex = c.corHex
            observacoes = c.observacoes
            ativo = c.ativo
        } else {
            corHex = Theme.paletaClientes.randomElement() ?? Theme.paletaClientes[0]
        }
    }

    private func salvar() {
        let c: Cliente
        if let existente = cliente {
            c = existente
        } else {
            c = Cliente()
            context.insert(c)
        }
        c.nome = nome.trimmingCharacters(in: .whitespacesAndNewlines)
        c.nicho = nicho
        c.instagram = instagram.trimmingCharacters(in: .whitespacesAndNewlines)
        c.contato = contato
        c.valorMensal = valorMensal
        c.corHex = corHex
        c.observacoes = observacoes
        c.ativo = ativo
        try? context.save()
        dismiss()
    }

    private func apagar() {
        guard let c = cliente else { return }
        context.delete(c)
        try? context.save()
        dismiss()
    }
}
