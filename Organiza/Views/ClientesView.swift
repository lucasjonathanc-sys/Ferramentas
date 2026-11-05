import SwiftData
import SwiftUI

struct ClientesView: View {
    @Query(sort: \Cliente.nome) private var clientes: [Cliente]

    enum Grupo: Hashable { case ativos, arquivados }

    @State private var busca = ""
    @State private var grupo: Grupo = .ativos
    @State private var novoCliente = false

    private var ativos: [Cliente] { clientes.filter(\.ativo) }
    private var arquivados: [Cliente] { clientes.filter { !$0.ativo } }

    private var visiveis: [Cliente] {
        let base = grupo == .ativos ? ativos : arquivados
        guard !busca.isEmpty else { return base }
        return base.filter {
            $0.nome.localizedCaseInsensitiveContains(busca) || $0.nicho.localizedCaseInsensitiveContains(busca)
        }
    }

    private var receitaMensal: Double { ativos.reduce(0) { $0 + $1.valorMensal } }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    CabecalhoPagina("Clientes", busca: $busca, placeholderBusca: "Buscar cliente") {
                        BotaoCircular(icone: "plus") { novoCliente = true }
                    }

                    SegmentoPilula(opcoes: [Grupo.ativos, Grupo.arquivados], selecao: $grupo) { g in
                        g == .ativos ? "Ativos · \(ativos.count)" : "Arquivados"
                    }

                    if grupo == .ativos && receitaMensal > 0 {
                        HStack {
                            Text("Renda extra mensal")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(Fmt.dinheiro(receitaMensal))
                                .font(.system(.title3, design: .serif))
                        }
                        .card()
                    }

                    if visiveis.isEmpty {
                        if !busca.isEmpty {
                            EstadoVazio(titulo: "Nenhum cliente encontrado")
                        } else if grupo == .ativos {
                            EstadoVazio(titulo: "Nenhum cliente cadastrado", botao: "Novo cliente") {
                                novoCliente = true
                            }
                        } else {
                            EstadoVazio(titulo: "Nenhum cliente arquivado",
                                        texto: "Clientes que você pausar ou encerrar ficam guardados aqui.")
                        }
                    } else {
                        LazyVStack(spacing: 10) {
                            ForEach(visiveis) { cliente in
                                NavigationLink(value: cliente) {
                                    ClienteCard(cliente: cliente)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
            }
            .background(Theme.fundo.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: Cliente.self) { ClienteDetalheView(cliente: $0) }
            .sheet(isPresented: $novoCliente) { ClienteEditor() }
        }
    }
}

struct ClienteCard: View {
    let cliente: Cliente

    var body: some View {
        let abertas = cliente.abertas
        let proxima = abertas.first { $0.data != nil }

        HStack(spacing: 14) {
            AvatarCliente(cliente: cliente, tamanho: 46)
            VStack(alignment: .leading, spacing: 3) {
                Text(cliente.nome).font(.body.weight(.medium))
                if !cliente.nicho.isEmpty {
                    Text(cliente.nicho).font(.subheadline).foregroundStyle(.secondary)
                }
                HStack(spacing: 6) {
                    Text(abertas.isEmpty ? "Tudo em dia" : "\(abertas.count) em aberto")
                    if let proxima, let data = proxima.data {
                        Text("·")
                        Text(Fmt.quando(data, temHorario: proxima.temHorario))
                            .foregroundStyle(proxima.atrasada ? Theme.alerta : Color.secondary)
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.footnote)
                .foregroundStyle(.tertiary)
        }
        .card(padding: 14)
    }
}

struct ClienteDetalheView: View {
    @Environment(AppEstado.self) private var app
    let cliente: Cliente

    @State private var editar = false
    @State private var mostrarFeitas = false

    private var itens: [Atividade] {
        (cliente.atividades ?? [])
            .filter { mostrarFeitas || ($0.aberta && !$0.jaPassou) }
            .sorted(by: Atividade.ordenacao)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                cabecalho

                Button {
                    app.nova(NovaAtividadePedido(tipo: .tarefa, cliente: cliente))
                } label: {
                    Label("Nova atividade para \(cliente.nome)", systemImage: "plus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PilulaStyle())

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        TituloSecao(titulo: "Atividades")
                        Button(mostrarFeitas ? "Só em aberto" : "Ver todas") {
                            withAnimation { mostrarFeitas.toggle() }
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                    if itens.isEmpty {
                        Text("Nada em aberto para este cliente.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .card()
                    } else {
                        VStack(spacing: 0) {
                            ForEach(itens) { a in
                                AtividadeRow(atividade: a)
                                if a.id != itens.last?.id { Divider().padding(.leading, 38) }
                            }
                        }
                        .card(padding: 12)
                    }
                }

                if !cliente.observacoes.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        TituloSecao(titulo: "Observações")
                        Text(cliente.observacoes)
                            .font(.subheadline)
                            .card()
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .background(Theme.fundo.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Editar") { editar = true }
            }
        }
        .sheet(isPresented: $editar) { ClienteEditor(cliente: cliente) }
    }

    private var cabecalho: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 14) {
                AvatarCliente(cliente: cliente, tamanho: 60)
                VStack(alignment: .leading, spacing: 4) {
                    Text(cliente.nome)
                        .font(Theme.tituloSerifado(28))
                    if !cliente.nicho.isEmpty {
                        Text(cliente.nicho).foregroundStyle(.secondary)
                    }
                    if !cliente.ativo {
                        Text("Arquivado").font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            HStack(spacing: 8) {
                if let url = cliente.linkInstagram {
                    Link(destination: url) {
                        Chip(texto: "@" + cliente.instagram.replacingOccurrences(of: "@", with: ""), icone: "camera", cor: cliente.cor)
                    }
                }
                if let whats = linkContato {
                    Link(destination: whats) {
                        Chip(texto: "WhatsApp", icone: "message", cor: Theme.sucesso)
                    }
                }
                if cliente.valorMensal > 0 {
                    Chip(texto: Fmt.dinheiro(cliente.valorMensal) + "/mês", icone: "banknote")
                }
            }
        }
    }

    private var linkContato: URL? {
        let digitos = cliente.contato.filter(\.isNumber)
        guard digitos.count >= 10 else { return nil }
        let numero = digitos.count <= 11 ? "55" + digitos : digitos
        return URL(string: "https://wa.me/\(numero)")
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
    @State private var arquivado = false
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
                            .font(.system(size: 30, weight: .medium, design: .serif))
                            .foregroundStyle(Color(hex: corHex))
                            .frame(width: 80, height: 80)
                            .background(Color(hex: corHex).opacity(0.15), in: Circle())
                        Spacer()
                    }
                    .listRowBackground(Color.clear)

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                        ForEach(Theme.paletaClientes, id: \.self) { hex in
                            Circle()
                                .fill(Color(hex: hex))
                                .frame(width: 32, height: 32)
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
                    TextField("Nicho (ex.: confeitaria, salão)", text: $nicho)
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
                }

                Section("Observações") {
                    TextField("Identidade visual, tom de voz, dias de postagem...", text: $observacoes, axis: .vertical)
                        .lineLimit(3...10)
                }

                if cliente != nil {
                    Section {
                        Toggle("Arquivar cliente", isOn: $arquivado)
                        Button(role: .destructive) {
                            confirmarExclusao = true
                        } label: {
                            Label("Apagar cliente", systemImage: "trash")
                        }
                    } footer: {
                        Text("Arquivar tira o cliente da lista sem perder o histórico. Ao apagar, as atividades continuam, só que sem cliente.")
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.fundo)
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
            arquivado = !c.ativo
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
        c.ativo = !arquivado
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
