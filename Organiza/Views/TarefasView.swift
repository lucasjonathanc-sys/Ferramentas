import SwiftData
import SwiftUI

struct TarefasView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Tarefa.criadaEm, order: .reverse) private var tarefas: [Tarefa]

    @State private var filtro: Frente?
    @State private var busca = ""
    @State private var mostrarConcluidas = false
    @State private var novaTarefa = false
    @State private var tarefaEditada: Tarefa?

    private var filtradas: [Tarefa] {
        tarefas.filter { t in
            let passaFrente = filtro == nil || t.frente == filtro
            let passaBusca = busca.isEmpty
                || t.titulo.localizedCaseInsensitiveContains(busca)
                || t.notas.localizedCaseInsensitiveContains(busca)
                || (t.cliente?.nome.localizedCaseInsensitiveContains(busca) ?? false)
            return passaFrente && passaBusca
        }
    }

    private var statusVisiveis: [StatusTarefa] {
        StatusTarefa.allCases.filter { $0 != .concluida || mostrarConcluidas }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    FiltroFrente(selecao: $filtro)
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))

                ForEach(statusVisiveis) { status in
                    let itens = filtradas.filter { $0.status == status }.sorted(by: Tarefa.ordenacao)
                    if !itens.isEmpty {
                        Section {
                            ForEach(itens) { t in
                                TarefaRow(tarefa: t, mostrarFrente: filtro == nil) { tarefaEditada = t }
                                    .swipeActions(edge: .leading) {
                                        Button {
                                            withAnimation {
                                                t.alternarConclusao()
                                                Notificacoes.atualizar(t)
                                            }
                                        } label: {
                                            Label(t.concluida ? "Reabrir" : "Concluir",
                                                  systemImage: t.concluida ? "arrow.uturn.backward" : "checkmark")
                                        }
                                        .tint(Theme.menta)
                                    }
                                    .swipeActions(edge: .trailing) {
                                        Button(role: .destructive) {
                                            Notificacoes.cancelar(t)
                                            withAnimation { context.delete(t) }
                                        } label: {
                                            Label("Apagar", systemImage: "trash")
                                        }
                                    }
                                    .contextMenu {
                                        ForEach(StatusTarefa.allCases) { s in
                                            Button {
                                                withAnimation { mover(t, para: s) }
                                            } label: {
                                                Label("Mover para \(s.rawValue)", systemImage: s.icone)
                                            }
                                            .disabled(s == t.status)
                                        }
                                    }
                            }
                        } header: {
                            Label("\(status.rawValue) · \(itens.count)", systemImage: status.icone)
                                .foregroundStyle(status.cor)
                                .font(.subheadline.weight(.semibold))
                                .textCase(nil)
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.fundo.ignoresSafeArea())
            .overlay {
                if filtradas.filter({ !$0.concluida || mostrarConcluidas }).isEmpty {
                    ContentUnavailableView {
                        Label(busca.isEmpty ? "Nenhuma tarefa" : "Nada encontrado",
                              systemImage: busca.isEmpty ? "checklist" : "magnifyingglass")
                    } description: {
                        Text(busca.isEmpty ? "Toque em + para adicionar uma copy, vídeo, arte..." : "Tente outra busca.")
                    }
                }
            }
            .searchable(text: $busca, prompt: "Buscar tarefa ou cliente")
            .navigationTitle("Tarefas")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        withAnimation { mostrarConcluidas.toggle() }
                    } label: {
                        Image(systemName: mostrarConcluidas ? "eye.fill" : "eye.slash")
                    }
                    .accessibilityLabel(mostrarConcluidas ? "Ocultar concluídas" : "Mostrar concluídas")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { novaTarefa = true } label: {
                        Image(systemName: "plus.circle.fill").font(.title3)
                    }
                }
            }
            .sheet(isPresented: $novaTarefa) { TarefaEditor(frente: filtro) }
            .sheet(item: $tarefaEditada) { TarefaEditor(tarefa: $0) }
        }
    }

    private func mover(_ t: Tarefa, para status: StatusTarefa) {
        t.status = status
        t.concluidaEm = status == .concluida ? Date() : nil
        Notificacoes.atualizar(t)
    }
}

#Preview {
    TarefasView()
        .modelContainer(for: [Tarefa.self, Etapa.self, Compromisso.self, Cliente.self], inMemory: true)
}
