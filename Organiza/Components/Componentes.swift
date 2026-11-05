import SwiftData
import SwiftUI

struct Chip: View {
    let texto: String
    var icone: String? = nil
    var cor: Color

    var body: some View {
        HStack(spacing: 4) {
            if let icone {
                Image(systemName: icone)
            }
            Text(texto)
                .lineLimit(1)
        }
        .font(.caption2.weight(.semibold))
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .foregroundStyle(cor)
        .background(cor.opacity(0.14), in: Capsule())
    }
}

/// Monograma "HB" no mesmo estilo do ícone do app.
struct LogoHB: View {
    var tamanho: CGFloat = 52

    var body: some View {
        Text("HB")
            .font(.system(size: tamanho * 0.42, weight: .bold, design: .default))
            .foregroundStyle(.white)
            .frame(width: tamanho, height: tamanho)
            .background(Theme.gradiente, in: RoundedRectangle(cornerRadius: tamanho * 0.28, style: .continuous))
            .shadow(color: Theme.lilas.opacity(0.35), radius: 8, y: 4)
    }
}

struct AnelProgresso: View {
    let progresso: Double
    var cor: Color = Theme.lilas
    var espessura: CGFloat = 10

    var body: some View {
        ZStack {
            Circle()
                .stroke(cor.opacity(0.18), lineWidth: espessura)
            Circle()
                .trim(from: 0, to: max(0.001, min(progresso, 1)))
                .stroke(cor, style: StrokeStyle(lineWidth: espessura, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.snappy, value: progresso)
        }
    }
}

struct TituloSecao: View {
    let titulo: String
    let icone: String
    var cor: Color = Theme.lilas
    var detalhe: String? = nil

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icone)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(cor)
            Text(titulo)
                .font(.headline)
            Spacer()
            if let detalhe {
                Text(detalhe)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct CartaoVazio: View {
    let texto: String
    var icone: String = "sparkles"

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icone)
                .foregroundStyle(Theme.lilas)
            Text(texto)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .card()
    }
}

struct AvatarCliente: View {
    let cliente: Cliente
    var tamanho: CGFloat = 40

    var body: some View {
        Text(cliente.iniciais)
            .font(.system(size: tamanho * 0.38, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
            .frame(width: tamanho, height: tamanho)
            .background(cliente.cor.gradient, in: Circle())
    }
}

/// Barra horizontal de filtro por frente (Todas / China Link / Freela / Pessoal).
struct FiltroFrente: View {
    @Binding var selecao: Frente?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                botao(nil, "Todas", "square.stack.fill", Theme.lilas)
                ForEach(Frente.allCases) { frente in
                    botao(frente, frente.rawValue, frente.icone, frente.cor)
                }
            }
            .padding(.horizontal, 2)
        }
    }

    private func botao(_ frente: Frente?, _ texto: String, _ icone: String, _ cor: Color) -> some View {
        let ativo = selecao == frente
        return Button {
            withAnimation(.snappy) { selecao = frente }
        } label: {
            Label(texto, systemImage: icone)
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .foregroundStyle(ativo ? Color.white : cor)
                .background(ativo ? cor : cor.opacity(0.12), in: Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Linhas

struct TarefaRow: View {
    let tarefa: Tarefa
    var mostrarFrente = true
    var onTap: () -> Void = {}

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Button {
                withAnimation(.snappy) {
                    tarefa.alternarConclusao()
                    Notificacoes.atualizar(tarefa)
                }
            } label: {
                Image(systemName: tarefa.concluida ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(tarefa.concluida ? Theme.menta : tarefa.frente.cor)
                    .contentTransition(.symbolEffect(.replace))
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline) {
                    Text(tarefa.titulo.isEmpty ? "Sem título" : tarefa.titulo)
                        .font(.body.weight(.medium))
                        .strikethrough(tarefa.concluida)
                        .foregroundStyle(tarefa.concluida ? Color.secondary : Color.primary)
                        .lineLimit(2)
                    Spacer(minLength: 4)
                    if tarefa.prioridade == .alta && !tarefa.concluida {
                        Image(systemName: "flag.fill")
                            .font(.caption)
                            .foregroundStyle(Theme.vermelho)
                    }
                }

                HStack(spacing: 6) {
                    Chip(texto: tarefa.tipo.rawValue, icone: tarefa.tipo.icone, cor: tarefa.tipo.cor)
                    if let cliente = tarefa.cliente {
                        Chip(texto: cliente.nome, cor: cliente.cor)
                    } else if mostrarFrente {
                        Chip(texto: tarefa.frente.rawValue, cor: tarefa.frente.cor)
                    }
                    if let prazo = tarefa.prazo {
                        Chip(
                            texto: Fmt.prazo(prazo),
                            icone: tarefa.atrasada ? "exclamationmark.circle.fill" : "clock",
                            cor: tarefa.atrasada ? Theme.vermelho : .secondary
                        )
                    }
                    if tarefa.status == .fazendo || tarefa.status == .aprovacao {
                        Chip(texto: tarefa.status.rawValue, icone: tarefa.status.icone, cor: tarefa.status.cor)
                    }
                }

                if let progresso = tarefa.progressoEtapas, !tarefa.concluida {
                    HStack(spacing: 8) {
                        ProgressView(value: progresso)
                            .tint(tarefa.frente.cor)
                        let feitas = (tarefa.etapas ?? []).filter(\.feita).count
                        Text("\(feitas)/\(tarefa.etapas?.count ?? 0)")
                            .font(.caption2.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .contentShape(Rectangle())
            .onTapGesture(perform: onTap)
        }
        .padding(.vertical, 4)
    }
}

struct CompromissoRow: View {
    let compromisso: Compromisso
    var onTap: () -> Void = {}

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .trailing, spacing: 2) {
                Text(Fmt.hora.string(from: compromisso.inicio))
                    .font(.subheadline.weight(.bold).monospacedDigit())
                Text(Fmt.hora.string(from: compromisso.fim))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            .frame(width: 48, alignment: .trailing)

            RoundedRectangle(cornerRadius: 2)
                .fill(compromisso.tipo.cor)
                .frame(width: 4)

            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(compromisso.titulo.isEmpty ? "Sem título" : compromisso.titulo)
                        .font(.body.weight(.medium))
                        .lineLimit(2)
                    if compromisso.acontecendoAgora {
                        Text("AGORA")
                            .font(.caption2.weight(.heavy))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .foregroundStyle(.white)
                            .background(Theme.vermelho, in: Capsule())
                    }
                }
                HStack(spacing: 6) {
                    Chip(texto: compromisso.tipo.rawValue, icone: compromisso.tipo.icone, cor: compromisso.tipo.cor)
                    if let cliente = compromisso.cliente {
                        Chip(texto: cliente.nome, cor: cliente.cor)
                    } else {
                        Chip(texto: compromisso.frente.rawValue, cor: compromisso.frente.cor)
                    }
                }
                if !compromisso.local.isEmpty {
                    Label(compromisso.local, systemImage: "mappin.and.ellipse")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 0)
            if let url = compromisso.url {
                Link(destination: url) {
                    Image(systemName: "video.circle.fill")
                        .font(.title2)
                        .foregroundStyle(compromisso.tipo.cor)
                }
            }
        }
        .opacity(compromisso.jaPassou ? 0.55 : 1)
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
        .padding(.vertical, 4)
    }
}
