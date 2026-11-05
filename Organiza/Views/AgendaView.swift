import SwiftData
import SwiftUI

struct AgendaView: View {
    @Query(sort: \Compromisso.inicio) private var compromissos: [Compromisso]
    @Query private var tarefas: [Tarefa]

    @State private var selecionado = Calendar.current.startOfDay(for: Date())
    @State private var mostrarMes = false
    @State private var novoCompromisso = false
    @State private var novaTarefa = false
    @State private var compromissoEditado: Compromisso?
    @State private var tarefaEditada: Tarefa?

    private let cal = Calendar.current

    private var semana: [Date] {
        let inicio = cal.dateInterval(of: .weekOfYear, for: selecionado)?.start ?? selecionado
        return (0..<7).compactMap { cal.date(byAdding: .day, value: $0, to: inicio) }
    }

    private func compromissosDo(_ dia: Date) -> [Compromisso] {
        compromissos.filter { cal.isDate($0.inicio, inSameDayAs: dia) }
    }

    private func tarefasDo(_ dia: Date) -> [Tarefa] {
        tarefas
            .filter { t in
                guard let p = t.prazo else { return false }
                return cal.isDate(p, inSameDayAs: dia)
            }
            .sorted(by: Tarefa.ordenacao)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    seletorSemana

                    if mostrarMes {
                        DatePicker("Data", selection: $selecionado, displayedComponents: .date)
                            .datePickerStyle(.graphical)
                            .tint(Theme.lilas)
                            .card(padding: 8)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    conteudoDoDia
                }
                .padding()
            }
            .background(Theme.fundo.ignoresSafeArea())
            .navigationTitle(Fmt.mesAno.string(from: selecionado).capitalizadoPrimeira)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Hoje") {
                        withAnimation(.snappy) { selecionado = cal.startOfDay(for: Date()) }
                    }
                    .disabled(cal.isDateInToday(selecionado))
                }
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        withAnimation(.snappy) { mostrarMes.toggle() }
                    } label: {
                        Image(systemName: mostrarMes ? "calendar.circle.fill" : "calendar.circle")
                    }
                    Menu {
                        Button { novoCompromisso = true } label: {
                            Label("Compromisso / reunião", systemImage: "calendar.badge.plus")
                        }
                        Button { novaTarefa = true } label: {
                            Label("Tarefa com prazo neste dia", systemImage: "checklist")
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill").font(.title3)
                    }
                }
            }
            .sheet(isPresented: $novoCompromisso) { CompromissoEditor(dia: selecionado) }
            .sheet(isPresented: $novaTarefa) { TarefaEditor(prazo: selecionado) }
            .sheet(item: $compromissoEditado) { CompromissoEditor(compromisso: $0) }
            .sheet(item: $tarefaEditada) { TarefaEditor(tarefa: $0) }
        }
    }

    private var seletorSemana: some View {
        VStack(spacing: 10) {
            HStack {
                Button { mudarSemana(-1) } label: { Image(systemName: "chevron.left") }
                Spacer()
                Text(Fmt.dataPorExtenso(selecionado))
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Button { mudarSemana(1) } label: { Image(systemName: "chevron.right") }
            }
            .foregroundStyle(Theme.lilas)

            HStack(spacing: 4) {
                ForEach(semana, id: \.self) { dia in
                    diaBotao(dia)
                }
            }
        }
        .card(padding: 12)
        .gesture(
            DragGesture(minimumDistance: 30).onEnded { valor in
                if valor.translation.width < -40 { mudarSemana(1) }
                if valor.translation.width > 40 { mudarSemana(-1) }
            }
        )
    }

    private func diaBotao(_ dia: Date) -> some View {
        let ativo = cal.isDate(dia, inSameDayAs: selecionado)
        let hoje = cal.isDateInToday(dia)
        let temCompromisso = !compromissosDo(dia).isEmpty
        let temTarefa = tarefasDo(dia).contains { !$0.concluida }

        return Button {
            withAnimation(.snappy) { selecionado = dia }
        } label: {
            VStack(spacing: 6) {
                Text(Fmt.diaCurto(dia))
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(ativo ? Color.white.opacity(0.9) : Color.secondary)
                Text("\(cal.component(.day, from: dia))")
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(ativo ? Color.white : (hoje ? Theme.lilas : Color.primary))
                HStack(spacing: 3) {
                    Circle().fill(ativo ? Color.white : Theme.azul)
                        .frame(width: 5, height: 5)
                        .opacity(temCompromisso ? 1 : 0)
                    Circle().fill(ativo ? Color.white : Theme.rosa)
                        .frame(width: 5, height: 5)
                        .opacity(temTarefa ? 1 : 0)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(ativo ? AnyShapeStyle(Theme.gradiente) : AnyShapeStyle(Color.clear))
            }
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var conteudoDoDia: some View {
        let lista = compromissosDo(selecionado)
        let entregas = tarefasDo(selecionado)

        VStack(alignment: .leading, spacing: 10) {
            TituloSecao(titulo: "Compromissos", icone: "person.3.fill", cor: Theme.azul,
                        detalhe: lista.isEmpty ? nil : "\(lista.count)")
            if lista.isEmpty {
                CartaoVazio(texto: "Nenhum compromisso neste dia.", icone: "calendar")
            } else {
                VStack(spacing: 8) {
                    ForEach(lista) { c in
                        CompromissoRow(compromisso: c) { compromissoEditado = c }
                        if c.id != lista.last?.id { Divider() }
                    }
                }
                .card()
            }
        }

        VStack(alignment: .leading, spacing: 10) {
            TituloSecao(titulo: "Entregas", icone: "target", cor: Theme.rosa,
                        detalhe: entregas.isEmpty ? nil : "\(entregas.filter(\.concluida).count)/\(entregas.count)")
            if entregas.isEmpty {
                CartaoVazio(texto: "Nenhuma entrega com prazo neste dia.", icone: "checkmark.seal")
            } else {
                VStack(spacing: 6) {
                    ForEach(entregas) { t in
                        TarefaRow(tarefa: t) { tarefaEditada = t }
                        if t.id != entregas.last?.id { Divider().padding(.leading, 40) }
                    }
                }
                .card()
            }
        }
    }

    private func mudarSemana(_ delta: Int) {
        withAnimation(.snappy) {
            selecionado = cal.date(byAdding: .weekOfYear, value: delta, to: selecionado) ?? selecionado
        }
    }
}

#Preview {
    AgendaView()
        .modelContainer(for: [Tarefa.self, Etapa.self, Compromisso.self, Cliente.self], inMemory: true)
}
