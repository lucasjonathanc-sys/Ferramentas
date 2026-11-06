import SwiftData
import SwiftUI

struct RootView: View {
    @State private var aba: Aba = .hoje
    @State private var estado = AppEstado()

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $aba) {
                HojeView()
                    .tag(Aba.hoje)
                    .toolbar(.hidden, for: .tabBar)
                TarefasView()
                    .tag(Aba.tarefas)
                    .toolbar(.hidden, for: .tabBar)
                AgendaView()
                    .tag(Aba.agenda)
                    .toolbar(.hidden, for: .tabBar)
                ClientesView()
                    .tag(Aba.clientes)
                    .toolbar(.hidden, for: .tabBar)
            }

            BarraAbas(aba: $aba) { estado.nova() }
        }
        .font(Fonte.texto(16))
        .background(Theme.fundo.ignoresSafeArea())
        .environment(estado)
        .tint(Theme.acento)
        .sheet(item: $estado.novaAtividade) { pedido in
            AtividadeEditor(pedido: pedido)
                .environment(estado)
        }
        .sheet(item: $estado.editando) { atividade in
            AtividadeEditor(atividade: atividade)
                .environment(estado)
        }
        .sheet(isPresented: $estado.mostrarAjustes) {
            AjustesView()
        }
        .sheet(isPresented: $estado.mostrarLembretes) {
            LembretesView()
        }
        .onAppear { Notificacoes.pedirPermissao() }
    }
}

#Preview {
    RootView()
        .modelContainer(for: [Atividade.self, Etapa.self, Cliente.self], inMemory: true)
}
