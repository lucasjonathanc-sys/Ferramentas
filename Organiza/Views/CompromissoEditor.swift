import SwiftData
import SwiftUI

struct CompromissoEditor: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query(sort: \Cliente.nome) private var clientes: [Cliente]

    private let compromisso: Compromisso?
    private let diaInicial: Date?
    private let clienteInicial: Cliente?

    @State private var titulo = ""
    @State private var tipo: TipoCompromisso = .reuniao
    @State private var frente: Frente = .chinaLink
    @State private var inicio = Date()
    @State private var fim = Date().addingTimeInterval(3600)
    @State private var local = ""
    @State private var link = ""
    @State private var notas = ""
    @State private var lembreteMinutos = 15
    @State private var cliente: Cliente?
    @State private var carregado = false
    @State private var confirmarExclusao = false

    private let opcoesLembrete: [(Int, String)] = [
        (-1, "Sem lembrete"), (0, "Na hora"), (5, "5 min antes"), (15, "15 min antes"),
        (30, "30 min antes"), (60, "1 hora antes"), (1440, "1 dia antes"),
    ]

    init(compromisso: Compromisso? = nil, dia: Date? = nil, cliente: Cliente? = nil) {
        self.compromisso = compromisso
        self.diaInicial = dia
        self.clienteInicial = cliente
    }

    private var editando: Bool { compromisso != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Ex.: Reunião de pauta, gravação...", text: $titulo, axis: .vertical)
                        .font(.title3.weight(.medium))

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
                            ForEach(TipoCompromisso.allCases) { t in
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

                Section {
                    DatePicker("Início", selection: $inicio)
                        .onChange(of: inicio) { _, novo in
                            // garante que o fim nunca fique antes do início
                            if fim <= novo { fim = novo.addingTimeInterval(3600) }
                        }
                    DatePicker("Fim", selection: $fim, in: inicio...)
                    Picker(selection: $lembreteMinutos) {
                        ForEach(opcoesLembrete, id: \.0) { opcao in
                            Text(opcao.1).tag(opcao.0)
                        }
                    } label: {
                        Label("Lembrete", systemImage: "bell.badge")
                    }
                }

                if !clientes.isEmpty {
                    Section {
                        Picker("Cliente", selection: $cliente) {
                            Text("Nenhum").tag(Cliente?.none)
                            ForEach(clientes.filter { $0.ativo || $0 == cliente }) { c in
                                Text(c.nome).tag(Optional(c))
                            }
                        }
                    }
                }

                Section("Onde") {
                    TextField("Local (sala, endereço...)", text: $local)
                    TextField("Link (Meet, Zoom, Teams...)", text: $link)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }

                Section("Pauta / notas") {
                    TextField("O que levar, o que discutir...", text: $notas, axis: .vertical)
                        .lineLimit(3...10)
                }

                if editando {
                    Section {
                        Button(role: .destructive) {
                            confirmarExclusao = true
                        } label: {
                            Label("Apagar compromisso", systemImage: "trash")
                        }
                    }
                }
            }
            .navigationTitle(editando ? "Editar compromisso" : "Novo compromisso")
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
            .confirmationDialog("Apagar este compromisso?", isPresented: $confirmarExclusao, titleVisibility: .visible) {
                Button("Apagar", role: .destructive, action: apagar)
            }
            .onAppear(perform: carregar)
        }
    }

    private func carregar() {
        guard !carregado else { return }
        carregado = true

        if let c = compromisso {
            titulo = c.titulo
            tipo = c.tipo
            frente = c.frente
            inicio = c.inicio
            fim = c.fim
            local = c.local
            link = c.link
            notas = c.notas
            lembreteMinutos = c.lembreteMinutos
            cliente = c.cliente
        } else {
            let base = Self.proximoHorario(no: diaInicial ?? Date())
            inicio = base
            fim = base.addingTimeInterval(3600)
            cliente = clienteInicial
            if clienteInicial != nil { frente = .freela }
        }
    }

    private func salvar() {
        let c: Compromisso
        if let existente = compromisso {
            c = existente
        } else {
            c = Compromisso()
            context.insert(c)
        }
        c.titulo = titulo.trimmingCharacters(in: .whitespacesAndNewlines)
        c.tipo = tipo
        c.frente = frente
        c.inicio = inicio
        c.fim = max(fim, inicio)
        c.local = local
        c.link = link
        c.notas = notas
        c.lembreteMinutos = lembreteMinutos
        c.cliente = cliente

        try? context.save()
        Notificacoes.atualizar(c)
        dismiss()
    }

    private func apagar() {
        guard let c = compromisso else { return }
        Notificacoes.cancelar(c)
        context.delete(c)
        try? context.save()
        dismiss()
    }

    /// Próxima hora cheia no dia escolhido (ou 10h, se for outro dia).
    private static func proximoHorario(no dia: Date) -> Date {
        let cal = Calendar.current
        if cal.isDateInToday(dia) {
            let agora = Date()
            let proxima = cal.date(byAdding: .hour, value: 1, to: agora) ?? agora
            return cal.date(bySettingHour: cal.component(.hour, from: proxima), minute: 0, second: 0, of: proxima) ?? proxima
        }
        return cal.date(bySettingHour: 10, minute: 0, second: 0, of: dia) ?? dia
    }
}
