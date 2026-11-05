import SwiftData
import SwiftUI

struct AgendaView: View {
    @Environment(AppEstado.self) private var app
    @Query private var atividades: [Atividade]

    enum Modo: String, CaseIterable, Hashable {
        case dia = "Dia"
        case semana = "Semana"
        case mes = "Mês"
    }

    @State private var modo: Modo = .semana
    @State private var referencia = Calendar.current.startOfDay(for: Date())

    private let cal = Calendar.current
    /// Quantos dias aparecem na visão "Semana" (3, como no vídeo, para caber no iPhone).
    private let diasNaSemana = 3

    private var dias: [Date] {
        let quantidade = modo == .dia ? 1 : diasNaSemana
        return (0..<quantidade).compactMap { cal.date(byAdding: .day, value: $0, to: referencia) }
    }

    private var tituloPeriodo: String {
        switch modo {
        case .dia:
            return Fmt.dataPorExtenso(referencia)
        case .semana:
            return Fmt.intervalo(dias.first ?? referencia, dias.last ?? referencia)
        case .mes:
            return Fmt.mesAno.string(from: referencia).capitalizadoPrimeira
        }
    }

    private var mostrandoHoje: Bool {
        switch modo {
        case .dia, .semana: return dias.contains { cal.isDateInToday($0) }
        case .mes: return cal.isDate(referencia, equalTo: Date(), toGranularity: .month) && cal.isDateInToday(referencia)
        }
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 14) {
                    CabecalhoPagina("Agenda")
                    SegmentoPilula(opcoes: Modo.allCases, selecao: $modo) { $0.rawValue }
                    navegacao
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)

                switch modo {
                case .dia, .semana:
                    LinhaDoTempo(dias: dias, atividades: atividades)
                case .mes:
                    MesView(referencia: $referencia, atividades: atividades)
                }
            }
            .background(Theme.fundo.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var navegacao: some View {
        HStack(spacing: 12) {
            Button { avancar(-1) } label: { Image(systemName: "chevron.left") }
            Text(tituloPeriodo)
                .font(.subheadline.weight(.medium))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Button { avancar(1) } label: { Image(systemName: "chevron.right") }
            Spacer()
            Button("Hoje") {
                withAnimation(.snappy) { referencia = cal.startOfDay(for: Date()) }
            }
            .font(.subheadline)
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .overlay(Capsule().stroke(Theme.borda, lineWidth: 1))
            .opacity(mostrandoHoje ? 0.4 : 1)
            .disabled(mostrandoHoje)
        }
        .foregroundStyle(Color.primary)
        .buttonStyle(.plain)
    }

    private func avancar(_ direcao: Int) {
        withAnimation(.snappy) {
            switch modo {
            case .dia:
                referencia = cal.date(byAdding: .day, value: direcao, to: referencia) ?? referencia
            case .semana:
                referencia = cal.date(byAdding: .day, value: direcao * diasNaSemana, to: referencia) ?? referencia
            case .mes:
                let mes = cal.date(byAdding: .month, value: direcao, to: referencia) ?? referencia
                referencia = cal.date(from: cal.dateComponents([.year, .month], from: mes)) ?? mes
            }
        }
    }
}

// MARK: - Linha do tempo (Dia / Semana)

private struct EventoPosicionado: Identifiable {
    let atividade: Atividade
    let inicio: Date
    let fim: Date
    var coluna = 0
    var totalColunas = 1
    var id: String { "\(atividade.uid.uuidString)-\(inicio.timeIntervalSince1970)" }
}

struct LinhaDoTempo: View {
    @Environment(AppEstado.self) private var app
    let dias: [Date]
    let atividades: [Atividade]

    private let cal = Calendar.current
    private let alturaHora: CGFloat = 56
    private let larguraHoras: CGFloat = 50

    var body: some View {
        VStack(spacing: 0) {
            cabecalhoDias
            semHora
            Divider()
            ScrollViewReader { proxy in
                ScrollView {
                    TimelineView(.everyMinute) { contexto in
                        grade(agora: contexto.date)
                    }
                    .padding(.bottom, 24)
                }
                .onAppear {
                    let alvo = max(0, cal.component(.hour, from: Date()) - 2)
                    proxy.scrollTo("hora-\(min(alvo, 7))", anchor: .top)
                }
            }
        }
    }

    // Cabeçalho com o nome e número de cada dia
    private var cabecalhoDias: some View {
        HStack(spacing: 0) {
            Color.clear.frame(width: larguraHoras)
            ForEach(dias, id: \.self) { dia in
                let hoje = cal.isDateInToday(dia)
                VStack(spacing: 4) {
                    Text(Fmt.diaCurto(dia))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(cal.component(.day, from: dia))")
                        .font(.subheadline.weight(hoje ? .semibold : .regular))
                        .foregroundStyle(hoje ? Theme.textoNoAcento : Color.primary)
                        .frame(width: 30, height: 30)
                        .background(hoje ? Theme.acento : Color.clear, in: Circle())
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.bottom, 8)
    }

    // Faixa "Sem hora" com tarefas sem horário
    private var semHora: some View {
        HStack(alignment: .top, spacing: 0) {
            Text("Sem\nhora")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.trailing)
                .frame(width: larguraHoras - 8, alignment: .trailing)
                .padding(.trailing, 8)
            ForEach(dias, id: \.self) { dia in
                let itens = atividades
                    .filter { !$0.temHorario && $0.status != .cancelada && $0.aparece(em: dia) }
                    .sorted(by: Atividade.ordenacao)
                VStack(spacing: 4) {
                    ForEach(itens) { a in
                        Button { app.editando = a } label: {
                            HStack(spacing: 4) {
                                Circle().fill(a.contexto.cor).frame(width: 5, height: 5)
                                Text(a.titulo)
                                    .lineLimit(1)
                                    .strikethrough(a.status == .concluida)
                            }
                            .font(.caption2)
                            .foregroundStyle(a.status == .concluida ? Color.secondary : Color.primary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 4)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(a.contexto.cor.opacity(0.14), in: RoundedRectangle(cornerRadius: 6))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 28, alignment: .top)
                .padding(.horizontal, 2)
                .contentShape(Rectangle())
                .onTapGesture {
                    app.nova(NovaAtividadePedido(tipo: .tarefa, data: dia))
                }
            }
        }
        .padding(.bottom, 6)
    }

    private func grade(agora: Date) -> some View {
        HStack(alignment: .top, spacing: 0) {
            // Coluna das horas
            VStack(spacing: 0) {
                ForEach(0..<24, id: \.self) { h in
                    Text(String(format: "%02d:00", h))
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.secondary)
                        .frame(width: larguraHoras - 8, height: alturaHora, alignment: .topTrailing)
                        .padding(.trailing, 8)
                        .offset(y: -6)
                        .id("hora-\(h)")
                }
            }

            ForEach(dias, id: \.self) { dia in
                colunaDia(dia, agora: agora)
            }
        }
        .overlay(alignment: .topLeading) {
            if dias.contains(where: { cal.isDate($0, inSameDayAs: agora) }) {
                indicadorAgora(agora)
            }
        }
    }

    private func colunaDia(_ dia: Date, agora: Date) -> some View {
        let eventos = posicionar(dia)
        return GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                // Linhas das horas
                VStack(spacing: 0) {
                    ForEach(0..<24, id: \.self) { _ in
                        VStack(spacing: 0) {
                            Theme.borda.frame(height: 0.5)
                            Spacer(minLength: 0)
                        }
                        .frame(height: alturaHora)
                    }
                }
                .overlay(alignment: .leading) { Theme.borda.frame(width: 0.5) }
                .contentShape(Rectangle())
                .onTapGesture { local in
                    let hora = min(23, max(0, Int(local.y / alturaHora)))
                    let inicio = cal.date(bySettingHour: hora, minute: 0, second: 0, of: dia) ?? dia
                    app.nova(NovaAtividadePedido(tipo: .compromisso, data: inicio, temHorario: true))
                }

                // Eventos
                ForEach(eventos) { e in
                    let largura = (geo.size.width - 4) / CGFloat(e.totalColunas)
                    blocoEvento(e)
                        .frame(width: max(0, largura - 2), height: altura(e))
                        .offset(x: 2 + CGFloat(e.coluna) * largura, y: posicaoY(e.inicio))
                }
            }
        }
        .frame(height: alturaHora * 24)
        .frame(maxWidth: .infinity)
    }

    private func blocoEvento(_ e: EventoPosicionado) -> some View {
        let a = e.atividade
        let cor = a.cliente?.cor ?? a.contexto.cor
        return Button { app.editando = a } label: {
            HStack(spacing: 0) {
                cor.frame(width: 3)
                VStack(alignment: .leading, spacing: 1) {
                    Text(a.titulo)
                        .font(.caption2.weight(.semibold))
                        .lineLimit(altura(e) > 40 ? 2 : 1)
                        .strikethrough(a.status == .concluida)
                    if altura(e) > 34 {
                        Text(Fmt.hora.string(from: e.inicio))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 5)
                .padding(.vertical, 3)
                Spacer(minLength: 0)
            }
            .frame(maxHeight: .infinity, alignment: .top)
            .foregroundStyle(Color.primary)
            .background(cor.opacity(0.16))
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            .opacity(a.status == .concluida ? 0.55 : 1)
        }
        .buttonStyle(.plain)
    }

    private func indicadorAgora(_ agora: Date) -> some View {
        GeometryReader { geo in
            let colunaLargura = (geo.size.width - larguraHoras) / CGFloat(max(dias.count, 1))
            let indice = dias.firstIndex { cal.isDate($0, inSameDayAs: agora) } ?? 0
            let y = posicaoY(agora)
            ZStack(alignment: .topLeading) {
                Text(Fmt.hora.string(from: agora))
                    .font(.caption2.weight(.semibold).monospacedDigit())
                    .foregroundStyle(Theme.textoNoAcento)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(Theme.acento, in: Capsule())
                    .frame(width: larguraHoras, alignment: .trailing)
                    .offset(y: y - 9)
                Circle()
                    .fill(Theme.acento)
                    .frame(width: 8, height: 8)
                    .offset(x: larguraHoras + colunaLargura * CGFloat(indice) - 4, y: y - 4)
                Theme.acento
                    .frame(width: colunaLargura, height: 1.5)
                    .offset(x: larguraHoras + colunaLargura * CGFloat(indice), y: y - 0.75)
            }
        }
        .allowsHitTesting(false)
    }

    // MARK: Cálculos

    private func posicaoY(_ data: Date) -> CGFloat {
        let c = cal.dateComponents([.hour, .minute], from: data)
        return CGFloat(c.hour ?? 0) * alturaHora + CGFloat(c.minute ?? 0) / 60 * alturaHora
    }

    private func altura(_ e: EventoPosicionado) -> CGFloat {
        let minutos = max(e.fim.timeIntervalSince(e.inicio) / 60, 20)
        let fimDoDia = alturaHora * 24 - posicaoY(e.inicio)
        return min(CGFloat(minutos) / 60 * alturaHora, fimDoDia)
    }

    /// Eventos com horário do dia, distribuídos em colunas quando se sobrepõem.
    private func posicionar(_ dia: Date) -> [EventoPosicionado] {
        var eventos: [EventoPosicionado] = atividades
            .filter { $0.temHorario && $0.status != .cancelada && $0.aparece(em: dia) }
            .compactMap { a in
                guard let data = a.data, let inicio = a.inicio(em: dia) else { return nil }
                let duracao = (a.fimEfetivo ?? data.addingTimeInterval(1800)).timeIntervalSince(data)
                return EventoPosicionado(atividade: a, inicio: inicio, fim: inicio.addingTimeInterval(max(duracao, 900)))
            }
            .sorted { $0.inicio < $1.inicio }

        // Agrupa eventos que se encostam e reparte em colunas
        var grupo: [Int] = []
        var fimGrupo = Date.distantPast

        func fecharGrupo() {
            var fimColunas: [Date] = []
            for i in grupo {
                if let livre = fimColunas.firstIndex(where: { $0 <= eventos[i].inicio }) {
                    eventos[i].coluna = livre
                    fimColunas[livre] = eventos[i].fim
                } else {
                    eventos[i].coluna = fimColunas.count
                    fimColunas.append(eventos[i].fim)
                }
            }
            for i in grupo { eventos[i].totalColunas = max(fimColunas.count, 1) }
            grupo = []
        }

        for i in eventos.indices {
            if eventos[i].inicio >= fimGrupo && !grupo.isEmpty { fecharGrupo() }
            grupo.append(i)
            fimGrupo = grupo.count == 1 ? eventos[i].fim : max(fimGrupo, eventos[i].fim)
        }
        if !grupo.isEmpty { fecharGrupo() }
        return eventos
    }
}

// MARK: - Mês

struct MesView: View {
    @Environment(AppEstado.self) private var app
    @Binding var referencia: Date
    let atividades: [Atividade]

    @State private var selecionado = Calendar.current.startOfDay(for: Date())
    private let cal = Calendar.current

    private var diasDoMes: [Date?] {
        guard let intervalo = cal.dateInterval(of: .month, for: referencia) else { return [] }
        let primeiro = intervalo.start
        let deslocamento = (cal.component(.weekday, from: primeiro) - cal.firstWeekday + 7) % 7
        let quantidade = cal.range(of: .day, in: .month, for: primeiro)?.count ?? 30
        var resultado: [Date?] = Array(repeating: nil, count: deslocamento)
        for i in 0..<quantidade {
            resultado.append(cal.date(byAdding: .day, value: i, to: primeiro))
        }
        while resultado.count % 7 != 0 { resultado.append(nil) }
        return resultado
    }

    private var nomesDias: [String] {
        let simbolos = Fmt.diaSemana.shortWeekdaySymbols ?? ["D", "S", "T", "Q", "Q", "S", "S"]
        let inicio = cal.firstWeekday - 1
        return (0..<7).map { simbolos[(inicio + $0) % 7].replacingOccurrences(of: ".", with: "").capitalizadoPrimeira }
    }

    private func itens(em dia: Date) -> [Atividade] {
        atividades
            .filter { $0.status != .cancelada && $0.aparece(em: dia) }
            .sorted { a, b in
                if a.temHorario != b.temHorario { return !a.temHorario }
                return (a.inicio(em: dia) ?? .distantPast) < (b.inicio(em: dia) ?? .distantPast)
            }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(spacing: 8) {
                    HStack(spacing: 0) {
                        ForEach(Array(nomesDias.enumerated()), id: \.offset) { _, nome in
                            Text(nome)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 6) {
                        ForEach(Array(diasDoMes.enumerated()), id: \.offset) { _, dia in
                            if let dia {
                                celula(dia)
                            } else {
                                Color.clear.frame(height: 46)
                            }
                        }
                    }
                }
                .card(padding: 12)

                let doDia = itens(em: selecionado)
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        TituloSecao(titulo: Fmt.dataPorExtenso(selecionado))
                        Button {
                            app.nova(NovaAtividadePedido(tipo: .tarefa, data: selecionado))
                        } label: {
                            Image(systemName: "plus")
                        }
                        .buttonStyle(.plain)
                    }
                    if doDia.isEmpty {
                        Text("Nada marcado neste dia.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .card()
                    } else {
                        VStack(spacing: 0) {
                            ForEach(doDia) { a in
                                AtividadeRow(atividade: a, dia: selecionado, mostrarData: false)
                                if a.id != doDia.last?.id { Divider().padding(.leading, 38) }
                            }
                        }
                        .card(padding: 12)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .onChange(of: referencia) { _, novo in
            if !cal.isDate(selecionado, equalTo: novo, toGranularity: .month) {
                selecionado = cal.isDate(Date(), equalTo: novo, toGranularity: .month) ? cal.startOfDay(for: Date()) : novo
            }
        }
    }

    private func celula(_ dia: Date) -> some View {
        let ativo = cal.isDate(dia, inSameDayAs: selecionado)
        let hoje = cal.isDateInToday(dia)
        let cores = Array(Set(itens(em: dia).map { $0.contexto })).sorted { $0.rawValue < $1.rawValue }.prefix(3)

        return Button {
            withAnimation(.snappy) { selecionado = dia }
        } label: {
            VStack(spacing: 4) {
                Text("\(cal.component(.day, from: dia))")
                    .font(.subheadline.weight(hoje || ativo ? .semibold : .regular))
                    .foregroundStyle(ativo ? Theme.textoNoAcento : Color.primary)
                    .frame(width: 32, height: 32)
                    .background {
                        if ativo {
                            Circle().fill(Theme.acento)
                        } else if hoje {
                            Circle().stroke(Theme.acento, lineWidth: 1)
                        }
                    }
                HStack(spacing: 3) {
                    ForEach(Array(cores), id: \.self) { c in
                        Circle().fill(c.cor).frame(width: 5, height: 5)
                    }
                }
                .frame(height: 5)
            }
            .frame(maxWidth: .infinity, minHeight: 46)
        }
        .buttonStyle(.plain)
    }
}
