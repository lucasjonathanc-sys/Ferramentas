import SwiftData
import SwiftUI

struct HojeView: View {
    @Query private var tarefas: [Tarefa]
    @Query(sort: \Compromisso.inicio) private var compromissos: [Compromisso]
    @AppStorage("nomeUsuaria") private var nome = ""

    @State private var novaTarefa = false
    @State private var novoCompromisso = false
    @State private var tarefaEditada: Tarefa?
    @State private var compromissoEditado: Compromisso?
    @State private var mostrarAjustes = false

    private let cal = Calendar.current

    // MARK: Dados

    private var compromissosHoje: [Compromisso] {
        compromissos.filter { cal.isDateInToday($0.inicio) }
    }

    private var tarefasHoje: [Tarefa] {
        tarefas
            .filter { t in
                if let p = t.prazo, cal.isDateInToday(p) { return true }
                // concluída hoje também conta para o progresso do dia
                if let c = t.concluidaEm, cal.isDateInToday(c) { return true }
                return false
            }
            .sorted(by: Tarefa.ordenacao)
    }

    private var atrasadas: [Tarefa] {
        tarefas
            .filter { t in
                guard t.atrasada, let p = t.prazo else { return false }
                return !cal.isDateInToday(p)
            }
            .sorted(by: Tarefa.ordenacao)
    }

    private var proximosDias: [Tarefa] {
        let amanha = cal.startOfDay(for: cal.date(byAdding: .day, value: 1, to: Date())!)
        let limite = cal.date(byAdding: .day, value: 7, to: amanha)!
        return tarefas
            .filter { t in
                guard !t.concluida, let p = t.prazo else { return false }
                return p >= amanha && p < limite
            }
            .sorted(by: Tarefa.ordenacao)
    }

    private var emAprovacao: [Tarefa] {
        tarefas.filter { $0.status == .aprovacao }.sorted(by: Tarefa.ordenacao)
    }

    private var saudacao: String {
        let hora = cal.component(.hour, from: Date())
        let base: String
        switch hora {
        case 5..<12: base = "Bom dia"
        case 12..<18: base = "Boa tarde"
        default: base = "Boa noite"
        }
        let emoji = hora >= 5 && hora < 18 ? "☀️" : "🌙"
        return nome.isEmpty ? "\(base) \(emoji)" : "\(base), \(nome) \(emoji)"
    }

    // MARK: Corpo

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    cabecalho
                    resumoDoDia
                    acoesRapidas

                    VStack(alignment: .leading, spacing: 10) {
                        TituloSecao(titulo: "Agenda de hoje", icone: "calendar", cor: Theme.azul,
                                    detalhe: compromissosHoje.isEmpty ? nil : "\(compromissosHoje.count)")
                        if compromissosHoje.isEmpty {
                            CartaoVazio(texto: "Nenhuma reunião hoje. Dia livre pra criar! ✨", icone: "cup.and.saucer.fill")
                        } else {
                            VStack(spacing: 8) {
                                ForEach(compromissosHoje) { c in
                                    CompromissoRow(compromisso: c) { compromissoEditado = c }
                                }
                            }
                            .card()
                        }
                    }

                    if !atrasadas.isEmpty {
                        listaTarefas("Atrasadas", icone: "exclamationmark.triangle.fill", cor: Theme.vermelho, itens: atrasadas)
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        TituloSecao(titulo: "Entregas de hoje", icone: "target", cor: Theme.rosa,
                                    detalhe: tarefasHoje.isEmpty ? nil : "\(tarefasHoje.filter(\.concluida).count)/\(tarefasHoje.count)")
                        if tarefasHoje.isEmpty {
                            CartaoVazio(texto: "Nada com prazo pra hoje.", icone: "checkmark.seal.fill")
                        } else {
                            blocoTarefas(tarefasHoje)
                        }
                    }

                    if !emAprovacao.isEmpty {
                        listaTarefas("Aguardando aprovação", icone: "hourglass", cor: Theme.amarelo, itens: emAprovacao)
                    }

                    if !proximosDias.isEmpty {
                        listaTarefas("Próximos 7 dias", icone: "calendar.badge.clock", cor: Theme.lilas, itens: proximosDias)
                    }
                }
                .padding()
            }
            .background(Theme.fundo.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { mostrarAjustes = true } label: {
                        Image(systemName: "gearshape.fill")
                    }
                }
            }
            .sheet(isPresented: $novaTarefa) { TarefaEditor() }
            .sheet(isPresented: $novoCompromisso) { CompromissoEditor() }
            .sheet(item: $tarefaEditada) { TarefaEditor(tarefa: $0) }
            .sheet(item: $compromissoEditado) { CompromissoEditor(compromisso: $0) }
            .sheet(isPresented: $mostrarAjustes) { AjustesView() }
        }
    }

    private var cabecalho: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(Fmt.dataPorExtenso(Date()))
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
            Text(saudacao)
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
        }
    }

    private var resumoDoDia: some View {
        let total = tarefasHoje.count
        let feitas = tarefasHoje.filter(\.concluida).count
        let progresso = total == 0 ? 0 : Double(feitas) / Double(total)
        let pendentesChina = tarefas.filter { !$0.concluida && $0.frente == .chinaLink }.count
        let pendentesFreela = tarefas.filter { !$0.concluida && $0.frente == .freela }.count

        return HStack(spacing: 18) {
            ZStack {
                AnelProgresso(progresso: progresso, cor: .white, espessura: 9)
                VStack(spacing: 0) {
                    Text("\(Int(progresso * 100))%")
                        .font(.system(.title3, design: .rounded, weight: .bold))
                    Text("do dia")
                        .font(.caption2)
                        .opacity(0.85)
                }
            }
            .frame(width: 86, height: 86)

            VStack(alignment: .leading, spacing: 8) {
                Text(mensagemMotivacional(feitas: feitas, total: total))
                    .font(.headline)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 8) {
                    resumoPill("\(pendentesChina)", Frente.chinaLink.rawValue)
                    resumoPill("\(pendentesFreela)", Frente.freela.rawValue)
                }
            }
            Spacer(minLength: 0)
        }
        .foregroundStyle(.white)
        .padding(18)
        .background(Theme.gradiente, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
        .shadow(color: Theme.lilas.opacity(0.35), radius: 16, y: 8)
    }

    private func resumoPill(_ numero: String, _ texto: String) -> some View {
        HStack(spacing: 4) {
            Text(numero).fontWeight(.bold)
            Text(texto)
        }
        .font(.caption)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Color.white.opacity(0.25), in: Capsule())
    }

    private func mensagemMotivacional(feitas: Int, total: Int) -> String {
        if total == 0 { return "Sem entregas hoje. Que tal adiantar algo?" }
        if feitas == total { return "Tudo entregue! Arrasou 💜" }
        let faltam = total - feitas
        return faltam == 1 ? "Falta só 1 entrega hoje!" : "Faltam \(faltam) entregas hoje"
    }

    private var acoesRapidas: some View {
        HStack(spacing: 12) {
            botaoAcao("Nova tarefa", icone: "plus.circle.fill", cor: Theme.lilas) { novaTarefa = true }
            botaoAcao("Compromisso", icone: "calendar.badge.plus", cor: Theme.azul) { novoCompromisso = true }
        }
    }

    private func botaoAcao(_ texto: String, icone: String, cor: Color, acao: @escaping () -> Void) -> some View {
        Button(action: acao) {
            Label(texto, systemImage: icone)
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .foregroundStyle(cor)
                .background(Theme.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .shadow(color: .black.opacity(0.04), radius: 8, y: 3)
        }
        .buttonStyle(.plain)
    }

    private func listaTarefas(_ titulo: String, icone: String, cor: Color, itens: [Tarefa]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            TituloSecao(titulo: titulo, icone: icone, cor: cor, detalhe: "\(itens.count)")
            blocoTarefas(itens)
        }
    }

    private func blocoTarefas(_ itens: [Tarefa]) -> some View {
        VStack(spacing: 6) {
            ForEach(itens) { t in
                TarefaRow(tarefa: t) { tarefaEditada = t }
                if t.id != itens.last?.id {
                    Divider().padding(.leading, 40)
                }
            }
        }
        .card()
    }
}

#Preview {
    HojeView()
        .modelContainer(for: [Tarefa.self, Etapa.self, Compromisso.self, Cliente.self], inMemory: true)
}
