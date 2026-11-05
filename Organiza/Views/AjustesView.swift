import SwiftData
import SwiftUI
import UIKit
import UserNotifications

struct AjustesView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(\.openURL) private var openURL
    @AppStorage("nomeUsuaria") private var nome = ""

    @Query private var tarefas: [Tarefa]
    @State private var notificacoesAtivas: Bool?
    @State private var confirmarLimpeza = false

    private var concluidasAntigas: [Tarefa] {
        let limite = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        return tarefas.filter { t in
            guard t.concluida, let data = t.concluidaEm else { return false }
            return data < limite
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Seu nome", text: $nome)
                        .textInputAutocapitalization(.words)
                } header: {
                    Text("Como posso te chamar?")
                } footer: {
                    Text("Aparece na saudação da tela Hoje.")
                }

                Section("Lembretes") {
                    HStack {
                        Label("Notificações", systemImage: "bell.badge.fill")
                        Spacer()
                        switch notificacoesAtivas {
                        case .some(true):
                            Text("Ativas").foregroundStyle(Theme.menta)
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
                        Label("Limpar concluídas há mais de 30 dias (\(concluidasAntigas.count))", systemImage: "sparkles")
                    }
                    .disabled(concluidasAntigas.isEmpty)
                } header: {
                    Text("Organização")
                }

                Section {
                    Text("Feito com 💜 para organizar a rotina entre a China Link e os clientes de social media.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Ajustes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("OK") { dismiss() }
                }
            }
            .confirmationDialog("Apagar \(concluidasAntigas.count) tarefas antigas?",
                                isPresented: $confirmarLimpeza, titleVisibility: .visible) {
                Button("Apagar", role: .destructive) {
                    for t in concluidasAntigas { context.delete(t) }
                    try? context.save()
                }
            }
            .task { await verificarNotificacoes() }
        }
    }

    private func verificarNotificacoes() async {
        let ajustes = await UNUserNotificationCenter.current().notificationSettings()
        if ajustes.authorizationStatus == .notDetermined {
            let ok = (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])) ?? false
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
