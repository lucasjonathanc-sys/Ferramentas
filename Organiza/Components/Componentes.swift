import Observation
import SwiftData
import SwiftUI

// MARK: - Estado global de navegação

/// Pedido para abrir o formulário "Nova atividade" já preenchido.
struct NovaAtividadePedido: Identifiable {
    let id = UUID()
    var tipo: TipoAtividade = .tarefa
    var data: Date? = nil
    var temHorario = false
    var cliente: Cliente? = nil
}

@Observable
final class AppEstado {
    var novaAtividade: NovaAtividadePedido?
    var editando: Atividade?
    var mostrarAjustes = false
    var mostrarLembretes = false

    func nova(_ pedido: NovaAtividadePedido = NovaAtividadePedido()) {
        novaAtividade = pedido
    }
}

enum Aba: Hashable {
    case hoje, tarefas, agenda, clientes
}

// MARK: - Barra inferior com botão + central

struct BarraAbas: View {
    @Binding var aba: Aba
    var onNova: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            item(.hoje, "house", "Hoje")
            item(.tarefas, "checklist", "Tarefas")
            Button(action: onNova) {
                Image(systemName: "plus")
                    .font(.title2.weight(.medium))
                    .foregroundStyle(Theme.textoNoAcento)
                    .frame(width: 56, height: 56)
                    .background(Theme.acento, in: Circle())
                    .shadow(color: .black.opacity(0.18), radius: 10, y: 4)
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity)
            .offset(y: -8)
            .accessibilityLabel("Nova atividade")
            item(.agenda, "calendar", "Agenda")
            item(.clientes, "person.2", "Clientes")
        }
        .padding(.horizontal, 8)
        .padding(.top, 6)
        .padding(.bottom, 2)
        .background {
            Theme.card
                .overlay(alignment: .top) { Theme.borda.frame(height: 0.5) }
                .ignoresSafeArea(edges: .bottom)
        }
    }

    private func item(_ destino: Aba, _ icone: String, _ titulo: String) -> some View {
        let ativo = aba == destino
        return Button {
            aba = destino
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icone)
                    .font(.system(size: 18, weight: ativo ? .semibold : .regular))
                    .frame(width: 48, height: 30)
                    .background(ativo ? Theme.marcaSuave : Color.clear, in: Capsule())
                Text(titulo)
                    .font(.caption2)
            }
            .foregroundStyle(ativo ? Color.primary : Color.secondary)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Cabeçalho das páginas

struct CabecalhoPagina<Extra: View>: View {
    let titulo: String
    var subtitulo: String?
    var busca: Binding<String>?
    var placeholderBusca: String
    let extra: Extra

    @Environment(AppEstado.self) private var app

    init(
        _ titulo: String,
        subtitulo: String? = nil,
        busca: Binding<String>? = nil,
        placeholderBusca: String = "Buscar",
        @ViewBuilder extra: () -> Extra
    ) {
        self.titulo = titulo
        self.subtitulo = subtitulo
        self.busca = busca
        self.placeholderBusca = placeholderBusca
        self.extra = extra()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(titulo)
                    .font(Theme.tituloSerifado())
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
                if let subtitulo {
                    Text(subtitulo)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            HStack(spacing: 10) {
                if let busca {
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)
                        TextField(placeholderBusca, text: busca)
                            .autocorrectionDisabled()
                        if !busca.wrappedValue.isEmpty {
                            Button {
                                busca.wrappedValue = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill").foregroundStyle(.tertiary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Theme.campo, in: Capsule())
                    .overlay(Capsule().stroke(Theme.borda, lineWidth: 1))
                } else {
                    Spacer()
                }
                extra
                BotaoCircular(icone: "bell") { app.mostrarLembretes = true }
                AvatarUsuaria { app.mostrarAjustes = true }
            }
        }
    }
}

extension CabecalhoPagina where Extra == EmptyView {
    init(_ titulo: String, subtitulo: String? = nil, busca: Binding<String>? = nil, placeholderBusca: String = "Buscar") {
        self.init(titulo, subtitulo: subtitulo, busca: busca, placeholderBusca: placeholderBusca) { EmptyView() }
    }
}

struct BotaoCircular: View {
    let icone: String
    var acao: () -> Void

    var body: some View {
        Button(action: acao) {
            Image(systemName: icone)
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(Color.primary)
                .frame(width: 40, height: 40)
                .background(Theme.campo, in: Circle())
                .overlay(Circle().stroke(Theme.borda, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

struct AvatarUsuaria: View {
    @AppStorage("nomeUsuaria") private var nome = "Hanna"
    var acao: () -> Void

    var body: some View {
        Button(action: acao) {
            Text(String(nome.first ?? "H").uppercased())
                .font(.system(size: 18, weight: .regular, design: .serif))
                .foregroundStyle(Theme.marca)
                .frame(width: 40, height: 40)
                .background(Theme.marcaSuave, in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Ajustes")
    }
}

/// Monograma "HB" no estilo do ícone do app.
struct LogoHB: View {
    var tamanho: CGFloat = 52

    var body: some View {
        Text("HB")
            .font(.system(size: tamanho * 0.42, weight: .bold))
            .foregroundStyle(Theme.textoNoAcento)
            .frame(width: tamanho, height: tamanho)
            .background(Theme.acento, in: RoundedRectangle(cornerRadius: tamanho * 0.28, style: .continuous))
    }
}

// MARK: - Chips

/// Chip de filtro (preto quando selecionado, como "Abertas" no vídeo).
struct FiltroChip: View {
    let titulo: String
    let ativo: Bool
    var acao: () -> Void

    var body: some View {
        Button(action: acao) {
            Text(titulo)
                .font(.subheadline.weight(ativo ? .semibold : .regular))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .foregroundStyle(ativo ? Theme.textoNoAcento : Color.primary)
                .background(ativo ? Theme.acento : Theme.campo, in: Capsule())
                .overlay(Capsule().stroke(ativo ? Color.clear : Theme.borda, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

/// Chip de contexto com bolinha colorida.
struct ContextoChip: View {
    let contexto: Contexto
    let ativo: Bool
    var acao: () -> Void

    var body: some View {
        Button(action: acao) {
            HStack(spacing: 6) {
                Circle().fill(contexto.cor).frame(width: 7, height: 7)
                Text(contexto.rawValue)
                    .font(.subheadline)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .foregroundStyle(ativo ? contexto.cor : Color.primary)
            .background(ativo ? contexto.cor.opacity(0.14) : Theme.campo, in: Capsule())
            .overlay(Capsule().stroke(ativo ? contexto.cor : Theme.borda, lineWidth: ativo ? 1.5 : 1))
        }
        .buttonStyle(.plain)
    }
}

/// Layout simples que quebra linha (para os chips de contexto).
struct FluxoLayout: Layout {
    var espacamento: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let largura = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, alturaLinha: CGFloat = 0, maiorX: CGFloat = 0
        for v in subviews {
            let t = v.sizeThatFits(.unspecified)
            if x > 0 && x + t.width > largura {
                x = 0
                y += alturaLinha + espacamento
                alturaLinha = 0
            }
            x += t.width + espacamento
            maiorX = max(maiorX, x - espacamento)
            alturaLinha = max(alturaLinha, t.height)
        }
        return CGSize(width: min(maiorX, largura), height: y + alturaLinha)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, alturaLinha: CGFloat = 0
        for v in subviews {
            let t = v.sizeThatFits(.unspecified)
            if x > bounds.minX && x + t.width > bounds.maxX {
                x = bounds.minX
                y += alturaLinha + espacamento
                alturaLinha = 0
            }
            v.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(t))
            x += t.width + espacamento
            alturaLinha = max(alturaLinha, t.height)
        }
    }
}

/// Seletor em pílula (Tarefa | Compromisso, Dia | Semana | Mês...).
struct SegmentoPilula<Valor: Hashable>: View {
    let opcoes: [Valor]
    @Binding var selecao: Valor
    let titulo: (Valor) -> String

    var body: some View {
        HStack(spacing: 4) {
            ForEach(opcoes, id: \.self) { opcao in
                let ativo = opcao == selecao
                Button {
                    withAnimation(.snappy(duration: 0.25)) { selecao = opcao }
                } label: {
                    Text(titulo(opcao))
                        .font(.subheadline.weight(ativo ? .semibold : .regular))
                        .foregroundStyle(ativo ? Color.primary : Color.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background {
                            if ativo {
                                Capsule().fill(Theme.card)
                                    .shadow(color: .black.opacity(0.08), radius: 4, y: 1)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Theme.suave, in: Capsule())
    }
}

struct Chip: View {
    let texto: String
    var icone: String? = nil
    var cor: Color = .secondary

    var body: some View {
        HStack(spacing: 4) {
            if let icone { Image(systemName: icone) }
            Text(texto).lineLimit(1)
        }
        .font(.caption.weight(.medium))
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .foregroundStyle(cor)
        .background(cor.opacity(0.12), in: Capsule())
    }
}

// MARK: - Outros

struct EstadoVazio: View {
    let titulo: String
    var texto: String? = nil
    var botao: String? = nil
    var acao: () -> Void = {}

    var body: some View {
        VStack(spacing: 10) {
            Text(titulo)
                .font(.headline)
            if let texto {
                Text(texto)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            if let botao {
                Button(action: acao) {
                    Label(botao, systemImage: "plus")
                }
                .buttonStyle(PilulaStyle())
                .padding(.top, 6)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .padding(.horizontal, 24)
    }
}

struct TituloSecao: View {
    let titulo: String
    var detalhe: String? = nil
    var cor: Color = .primary

    var body: some View {
        HStack {
            Text(titulo)
                .font(.system(.title3, design: .serif))
                .foregroundStyle(cor)
            Spacer()
            if let detalhe {
                Text(detalhe).font(.subheadline).foregroundStyle(.secondary)
            }
        }
    }
}

struct AvatarCliente: View {
    let cliente: Cliente
    var tamanho: CGFloat = 40

    var body: some View {
        Text(cliente.iniciais)
            .font(.system(size: tamanho * 0.38, weight: .medium, design: .serif))
            .foregroundStyle(cliente.cor)
            .frame(width: tamanho, height: tamanho)
            .background(cliente.cor.opacity(0.15), in: Circle())
    }
}

// MARK: - Linha de atividade

struct AtividadeRow: View {
    @Environment(\.modelContext) private var context
    @Environment(AppEstado.self) private var app
    let atividade: Atividade
    /// Dia em que está sendo exibida (para mostrar o horário certo de repetições).
    var dia: Date? = nil
    var mostrarData = true

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            marcador

            VStack(alignment: .leading, spacing: 5) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(atividade.titulo.isEmpty ? "Sem título" : atividade.titulo)
                        .font(.body)
                        .strikethrough(!atividade.aberta)
                        .foregroundStyle(atividade.aberta ? Color.primary : Color.secondary)
                        .lineLimit(2)
                    Spacer(minLength: 4)
                    if atividade.prioridade == .alta && atividade.aberta {
                        Image(systemName: "flag.fill").font(.caption2).foregroundStyle(Theme.alerta)
                    }
                }

                HStack(spacing: 6) {
                    Circle().fill(atividade.contexto.cor).frame(width: 6, height: 6)
                    Text(atividade.cliente?.nome ?? atividade.contexto.rawValue)
                        .lineLimit(1)
                    if let texto = textoQuando {
                        Text("·")
                        Text(texto)
                            .foregroundStyle(atividade.atrasada ? Theme.alerta : Color.secondary)
                            .lineLimit(1)
                    }
                    if atividade.repeticao != .nunca {
                        Image(systemName: "repeat")
                    }
                    if !atividade.lembretes.isEmpty && atividade.aberta {
                        Image(systemName: "bell")
                    }
                    if atividade.status == .cancelada {
                        Text("· Cancelada")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)

                if let progresso = atividade.progressoEtapas, atividade.aberta {
                    HStack(spacing: 8) {
                        ProgressView(value: progresso).tint(atividade.contexto.cor)
                        Text("\((atividade.etapas ?? []).filter(\.feita).count)/\(atividade.etapas?.count ?? 0)")
                            .font(.caption2.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
        .onTapGesture { app.editando = atividade }
    }

    @ViewBuilder
    private var marcador: some View {
        if atividade.ehCompromisso {
            Image(systemName: "calendar")
                .font(.system(size: 13))
                .foregroundStyle(atividade.contexto.cor)
                .frame(width: 26, height: 26)
                .background(atividade.contexto.cor.opacity(0.14), in: Circle())
        } else {
            Button {
                withAnimation(.snappy) { Acoes.alternarConclusao(atividade, context: context) }
            } label: {
                ZStack {
                    Circle()
                        .stroke(atividade.status == .aberta ? Theme.borda : Color.clear, lineWidth: 1.5)
                    if atividade.status == .concluida {
                        Circle().fill(Theme.acento)
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Theme.textoNoAcento)
                    } else if atividade.status == .cancelada {
                        Circle().fill(Theme.suave)
                        Image(systemName: "xmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(width: 26, height: 26)
            }
            .buttonStyle(.plain)
            .disabled(atividade.status == .cancelada)
        }
    }

    private var textoQuando: String? {
        guard mostrarData || atividade.temHorario, let data = atividade.data else { return nil }
        if !mostrarData {
            let inicio = (dia.flatMap { atividade.inicio(em: $0) }) ?? data
            if atividade.ehCompromisso, let fim = atividade.fimEfetivo {
                let duracao = fim.timeIntervalSince(data)
                return "\(Fmt.hora.string(from: inicio))–\(Fmt.hora.string(from: inicio.addingTimeInterval(duracao)))"
            }
            return Fmt.hora.string(from: inicio)
        }
        let referencia = atividade.ehCompromisso ? (atividade.proximaOcorrencia() ?? data) : data
        let inicio = atividade.inicio(em: referencia) ?? referencia
        return Fmt.quando(inicio, temHorario: atividade.temHorario)
    }
}
