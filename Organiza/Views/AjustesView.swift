import SwiftData
import SwiftUI
import UIKit
import UserNotifications

struct AjustesView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(\.openURL) private var openURL
    @AppStorage("nomeUsuaria") private var nome = "Hanna"

    @Query private var atividades: [Atividade]
    @State private var notificacoesAtivas: Bool?
    @State private var confirmarLimpeza = false

    private var antigas: [Atividade] {
        let limite = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        return atividades.filter { a in
            switch a.status {
            case .concluida: return (a.concluidaEm ?? a.criadaEm) < limite
            case .cancelada: return a.criadaEm < limite
            case .aberta: return a.jaPassou && (a.fimEfetivo ?? Date()) < limite
            }
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 14) {
                        LogoMarca(tamanho: 34)
                            .frame(width: 56, height: 56)
                            .background(Theme.fundo, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("DB. Organiza").font(Fonte.titulo(18))
                            Text("Feito com carinho para a \(nome.isEmpty ? "Hanna" : nome) 💜")
                                .font(Fonte.texto(12))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section {
                    TextField("Seu nome", text: $nome)
                        .textInputAutocapitalization(.words)
                } header: {
                    Text("Como te chamar")
                } footer: {
                    Text("Aparece na saudação da tela Hoje.")
                }

                Section("Lembretes") {
                    HStack {
                        Label("Notificações", systemImage: "bell")
                        Spacer()
                        switch notificacoesAtivas {
                        case .some(true):
                            Text("Ativas").foregroundStyle(.secondary)
                        case .some(false):
                            Button("Ativar") { abrirAjustesDoSistema() }
                        case .none:
                            ProgressView()
                        }
                    }
                }

                Section {
                    Button(role: .destructive) {
                        confirmarLimpeza = true
                    } label: {
                        Label("Limpar itens antigos (\(antigas.count))", systemImage: "sparkles")
                    }
                    .disabled(antigas.isEmpty)
                } header: {
                    Text("Organização")
                } footer: {
                    Text("Apaga tarefas concluídas ou canceladas e compromissos que já passaram há mais de 30 dias.")
                }
            }
            .font(Fonte.texto(16))
            .scrollContentBackground(.hidden)
            .background(Theme.fundo)
            .navigationTitle("Ajustes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("OK") { dismiss() }
                }
            }
            .confirmationDialog("Apagar \(antigas.count) itens antigos?",
                                isPresented: $confirmarLimpeza, titleVisibility: .visible) {
                Button("Apagar", role: .destructive) {
                    for a in antigas { Acoes.apagar(a, context: context) }
                    try? context.save()
                }
            }
            .task { await verificarNotificacoes() }
        }
    }

    private func verificarNotificacoes() async {
        let centro = UNUserNotificationCenter.current()
        let ajustes = await centro.notificationSettings()
        if ajustes.authorizationStatus == .notDetermined {
            let ok = (try? await centro.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
            notificacoesAtivas = ok
        } else {
            notificacoesAtivas = ajustes.authorizationStatus == .authorized
                || ajustes.authorizationStatus == .provisional
        }
    }

    private func abrirAjustesDoSistema() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            openURL(url)
        }
    }
}

/// Aberta pelo sininho: próximos lembretes agendados.
struct LembretesView: View {
    @Environment(\.dismiss) private var dismiss
    @Query private var atividades: [Atividade]

    private struct Item: Identifiable {
        let atividade: Atividade
        let quando: Date
        let minutos: Int
        var id: String { "\(atividade.uid.uuidString)-\(minutos)-\(quando.timeIntervalSince1970)" }
    }

    private var proximos: [Item] {
        let agora = Date()
        let limite = Calendar.current.date(byAdding: .day, value: 14, to: agora) ?? agora
        var lista: [Item] = []
        for a in atividades where a.aberta && !a.lembretes.isEmpty {
            guard let base = a.momentoLembrete else { continue }
            // para compromissos repetidos, usa a próxima ocorrência
            var referencia = base
            if a.ehCompromisso, a.repeticao != .nunca,
               let dia = a.proximaOcorrencia(), let inicio = a.inicio(em: dia) {
                referencia = inicio
            }
            for m in a.lembretes {
                let quando = referencia.addingTimeInterval(TimeInterval(-m * 60))
                if quando > agora && quando < limite {
                    lista.append(Item(atividade: a, quando: quando, minutos: m))
                }
            }
        }
        return lista.sorted { $0.quando < $1.quando }
    }

    var body: some View {
        NavigationStack {
            List {
                if proximos.isEmpty {
                    Text("Nenhum lembrete nos próximos 14 dias.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(proximos) { item in
                        HStack(alignment: .top, spacing: 12) {
                            Circle().fill(item.atividade.contexto.cor).frame(width: 8, height: 8).padding(.top, 6)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(item.atividade.titulo)
                                Text("\(Fmt.quando(item.quando, temHorario: true)) · \(OpcoesLembrete.nome(item.minutos))")
                                    .font(Fonte.texto(12))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .font(Fonte.texto(16))
            .scrollContentBackground(.hidden)
            .background(Theme.fundo)
            .navigationTitle("Próximos lembretes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("OK") { dismiss() }
                }
            }
        }
    }
}
