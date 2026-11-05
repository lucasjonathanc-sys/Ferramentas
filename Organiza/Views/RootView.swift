import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            HojeView()
                .tabItem { Label("Hoje", systemImage: "sun.max.fill") }
            TarefasView()
                .tabItem { Label("Tarefas", systemImage: "checklist") }
            AgendaView()
                .tabItem { Label("Agenda", systemImage: "calendar") }
            ClientesView()
                .tabItem { Label("Clientes", systemImage: "person.2.fill") }
        }
        .tint(Theme.lilas)
        .onAppear { Notificacoes.pedirPermissao() }
    }
}

#Preview {
    RootView()
        .modelContainer(for: [Tarefa.self, Etapa.self, Compromisso.self, Cliente.self], inMemory: true)
}
