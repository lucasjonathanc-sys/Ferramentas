import { type ReactNode, useEffect } from 'react'
import { useApp } from '../contexto'
import { useEstado, alternarConclusao } from '../store'
import {
  type Atividade, type Contexto, aberta, atrasada, corContexto, dataDe, ehCompromisso, fimEfetivo,
  inicioEm, proximaOcorrencia,
} from '../modelo'
import { hora, quando } from '../datas'

// MARK: - Ícones (traço fino, no estilo SF Symbols)

const caminhos: Record<string, ReactNode> = {
  casa: <path d="M3 10.5 12 3l9 7.5V20a1 1 0 0 1-1 1h-5v-6h-6v6H4a1 1 0 0 1-1-1z" />,
  lista: <><path d="M9 6h12M9 12h12M9 18h12" /><path d="m3 6 1.5 1.5L7 5M3 12l1.5 1.5L7 11M3 18l1.5 1.5L7 17" /></>,
  calendario: <><rect x="3" y="5" width="18" height="16" rx="2" /><path d="M3 10h18M8 3v4M16 3v4" /></>,
  pessoas: <><circle cx="9" cy="8" r="3.5" /><path d="M2.5 20c.6-3.5 3.3-5.5 6.5-5.5s5.9 2 6.5 5.5" /><path d="M16 4.8a3.5 3.5 0 0 1 0 6.4M18 14.8c2 .7 3.2 2.5 3.5 5.2" /></>,
  mais: <path d="M12 5v14M5 12h14" />,
  sino: <><path d="M6 16V11a6 6 0 1 1 12 0v5l2 2H4z" /><path d="M10 20a2 2 0 0 0 4 0" /></>,
  lupa: <><circle cx="11" cy="11" r="7" /><path d="m20 20-4-4" /></>,
  x: <path d="M6 6l12 12M18 6 6 18" />,
  check: <path d="m5 12.5 4.5 4.5L19 7.5" />,
  seta: <path d="M4 12h15m-5-6 6 6-6 6" />,
  voltar: <path d="m15 5-7 7 7 7" />,
  avancar: <path d="m9 5 7 7-7 7" />,
  repetir: <><path d="M17 2l3 3-3 3" /><path d="M4 11V9a4 4 0 0 1 4-4h12M7 22l-3-3 3-3" /><path d="M20 13v2a4 4 0 0 1-4 4H4" /></>,
  bandeira: <path d="M5 21V4m0 0h11l-2 4 2 4H5" />,
  baixo: <path d="m6 9 6 6 6-6" />,
  cima: <path d="m6 15 6-6 6 6" />,
  setas: <path d="m8 9 4-4 4 4M8 15l4 4 4-4" />,
  lixo: <><path d="M4 7h16M9 7V4h6v3M6 7l1 13h10l1-13" /></>,
  camera: <><rect x="3" y="7" width="18" height="13" rx="2" /><circle cx="12" cy="13.5" r="3.5" /><path d="M8 7l2-3h4l2 3" /></>,
  mensagem: <path d="M4 5h16v11H8l-4 4z" />,
  dinheiro: <><rect x="2.5" y="6" width="19" height="12" rx="2" /><circle cx="12" cy="12" r="2.5" /></>,
  calMais: <><rect x="3" y="5" width="18" height="16" rx="2" /><path d="M3 10h18M8 3v4M16 3v4M12 13v5M9.5 15.5h5" /></>,
  compartilhar: <><path d="M12 3v12M8 7l4-4 4 4" /><path d="M5 12v8h14v-8" /></>,
}

export function Icone({ nome, tamanho = 20, peso = 1.6 }: { nome: string; tamanho?: number; peso?: number }) {
  return (
    <svg width={tamanho} height={tamanho} viewBox="0 0 24 24" fill="none" stroke="currentColor"
      strokeWidth={peso} strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
      {caminhos[nome]}
    </svg>
  )
}

// MARK: - Elementos da marca

export function Pincel({ largura = 130 }: { largura?: number }) {
  return (
    <svg className="pincel" width={largura} height="12" viewBox="0 0 130 12" fill="none" aria-hidden="true">
      <path d="M2 9 C 45 -2, 80 16, 128 3" stroke="var(--vinho)" strokeWidth="2.5" strokeLinecap="round" />
    </svg>
  )
}

export function Asterisco({ tamanho = 20 }: { tamanho?: number }) {
  return (
    <svg width={tamanho} height={tamanho} viewBox="0 0 24 24" fill="none" stroke="var(--vinho)" strokeWidth="1.5" strokeLinecap="round" aria-hidden="true">
      <path d="M12 2v20M2 12h20M4.9 4.9l14.2 14.2M19.1 4.9 4.9 19.1" />
    </svg>
  )
}

export function Logo({ tamanho = 28 }: { tamanho?: number }) {
  return (
    <span style={{ fontFamily: 'var(--titulo)', fontSize: tamanho, lineHeight: 1 }}>
      DB<span style={{ color: 'var(--vinho)' }}>.</span>
    </span>
  )
}

// MARK: - Cabeçalho

export function Cabecalho(props: {
  titulo: string
  subtitulo?: string
  busca?: { valor: string; definir: (v: string) => void; placeholder: string }
  pincel?: boolean
  extra?: ReactNode
}) {
  const app = useApp()
  const { nome } = useEstado()
  return (
    <div>
      <h1 className="titulo-pagina">{props.titulo}</h1>
      {props.pincel && <Pincel />}
      {props.subtitulo && <div className="subtitulo">{props.subtitulo}</div>}
      <div className="cab-acoes">
        {props.busca ? (
          <label className="busca">
            <span className="texto2"><Icone nome="lupa" tamanho={18} /></span>
            <input
              value={props.busca.valor}
              onChange={(e) => props.busca!.definir(e.target.value)}
              placeholder={props.busca.placeholder}
              autoCorrect="off"
            />
            {props.busca.valor && (
              <button className="texto2" onClick={() => props.busca!.definir('')} aria-label="Limpar busca">
                <Icone nome="x" tamanho={16} />
              </button>
            )}
          </label>
        ) : (
          <span className="espaco" />
        )}
        {props.extra}
        <button className="circulo" onClick={() => app.abrir({ tipo: 'lembretes' })} aria-label="Próximos lembretes">
          <Icone nome="sino" tamanho={18} />
        </button>
        <button className="avatar" onClick={() => app.abrir({ tipo: 'ajustes' })} aria-label="Ajustes">
          {(nome.trim()[0] ?? 'H').toUpperCase()}
        </button>
      </div>
    </div>
  )
}

// MARK: - Barra de abas com + central

export type Aba = 'hoje' | 'tarefas' | 'agenda' | 'clientes'

export function BarraAbas({ aba, definir }: { aba: Aba; definir: (a: Aba) => void }) {
  const app = useApp()
  const item = (destino: Aba, icone: string, titulo: string) => (
    <button className={`aba ${aba === destino ? 'ativa' : ''}`} onClick={() => definir(destino)}>
      <span className="icone"><Icone nome={icone} tamanho={20} peso={aba === destino ? 2 : 1.6} /></span>
      {titulo}
    </button>
  )
  return (
    <nav className="barra">
      {item('hoje', 'casa', 'Hoje')}
      {item('tarefas', 'lista', 'Tarefas')}
      <button className="mais" onClick={() => app.abrir({ tipo: 'nova' })} aria-label="Nova atividade">
        <span><Icone nome="mais" tamanho={26} peso={1.8} /></span>
      </button>
      {item('agenda', 'calendario', 'Agenda')}
      {item('clientes', 'pessoas', 'Clientes')}
    </nav>
  )
}

// MARK: - Chips e controles

export function Chip({ titulo, ativo, onClick }: { titulo: string; ativo: boolean; onClick: () => void }) {
  return <button className={`chip ${ativo ? 'ativo' : ''}`} onClick={onClick}>{titulo}</button>
}

export function ChipContexto({ contexto, ativo, onClick }: { contexto: Contexto; ativo: boolean; onClick: () => void }) {
  const cor = corContexto(contexto)
  return (
    <button
      className={`chip-ctx ${ativo ? 'ativo' : ''}`}
      onClick={onClick}
      style={ativo ? { color: cor, borderColor: cor, background: `color-mix(in srgb, ${cor} 14%, transparent)` } : undefined}
    >
      <span className="bolinha" style={{ background: cor }} />
      {contexto}
    </button>
  )
}

export function Segmento<T extends string | number>(props: {
  opcoes: { valor: T; titulo: string }[]
  valor: T
  definir: (v: T) => void
}) {
  return (
    <div className="segmento">
      {props.opcoes.map((o) => (
        <button key={String(o.valor)} className={o.valor === props.valor ? 'ativo' : ''} onClick={() => props.definir(o.valor)}>
          {o.titulo}
        </button>
      ))}
    </div>
  )
}

export function EstadoVazio(props: { titulo: string; texto?: string; botao?: string; onClick?: () => void }) {
  return (
    <div className="vazio">
      <Asterisco />
      <h3>{props.titulo}</h3>
      {props.texto && <p>{props.texto}</p>}
      {props.botao && (
        <button className="pilula" style={{ marginTop: 6 }} onClick={props.onClick}>
          <Icone nome="mais" tamanho={16} /> {props.botao}
        </button>
      )}
    </div>
  )
}

export function TituloSecao({ titulo, detalhe, cor }: { titulo: string; detalhe?: string; cor?: string }) {
  return (
    <div className="linha">
      <h2 className="titulo-secao" style={cor ? { color: cor } : undefined}>{titulo}</h2>
      <span className="espaco" />
      {detalhe && <span className="detalhe">{detalhe}</span>}
    </div>
  )
}

// MARK: - Folha (sheet) de baixo para cima

export function Folha(props: {
  titulo: string
  fechar: () => void
  children: ReactNode
  rodape?: ReactNode
}) {
  useEffect(() => {
    const tecla = (e: KeyboardEvent) => e.key === 'Escape' && props.fechar()
    window.addEventListener('keydown', tecla)
    return () => window.removeEventListener('keydown', tecla)
  }, [props])
  return (
    <div className="folha-fundo" onClick={props.fechar}>
      <div className="folha" onClick={(e) => e.stopPropagation()} role="dialog" aria-label={props.titulo}>
        <div className="alca" />
        <div className="folha-cab">
          <h2>{props.titulo}</h2>
          <button className="circulo" style={{ width: 36, height: 36 }} onClick={props.fechar} aria-label="Fechar">
            <Icone nome="x" tamanho={16} />
          </button>
        </div>
        <div className="folha-corpo">{props.children}</div>
        {props.rodape && <div className="folha-rodape">{props.rodape}</div>}
      </div>
    </div>
  )
}

// MARK: - Linha de atividade

export function ItemAtividade({ atividade: a, dia, mostrarData = true }: { atividade: Atividade; dia?: Date; mostrarData?: boolean }) {
  const app = useApp()
  const { clientes } = useEstado()
  const cliente = clientes.find((c) => c.id === a.clienteId)
  const cor = corContexto(a.contexto)

  let textoQuando: string | null = null
  const d = dataDe(a)
  if (d && (mostrarData || a.temHorario)) {
    if (!mostrarData) {
      const ini = (dia && inicioEm(a, dia)) || d
      if (ehCompromisso(a)) {
        const dur = (fimEfetivo(a)?.getTime() ?? d.getTime()) - d.getTime()
        textoQuando = `${hora(ini)}–${hora(new Date(ini.getTime() + dur))}`
      } else textoQuando = hora(ini)
    } else {
      const ref = ehCompromisso(a) ? (proximaOcorrencia(a) ?? d) : d
      textoQuando = quando(inicioEm(a, ref) ?? ref, a.temHorario)
    }
  }

  return (
    <div className="item" onClick={() => app.abrir({ tipo: 'editar', id: a.id })}>
      {ehCompromisso(a) ? (
        <span className="marcador-cal" style={{ color: cor, background: `color-mix(in srgb, ${cor} 14%, transparent)` }}>
          <Icone nome="calendario" tamanho={14} />
        </span>
      ) : (
        <button
          className={`check ${a.status === 'concluida' ? 'feito' : a.status === 'cancelada' ? 'cancelado' : ''}`}
          onClick={(e) => {
            e.stopPropagation()
            if (a.status !== 'cancelada') alternarConclusao(a.id)
          }}
          aria-label={a.status === 'concluida' ? 'Reabrir' : 'Concluir'}
        >
          {a.status === 'concluida' && <Icone nome="check" tamanho={14} peso={2.4} />}
          {a.status === 'cancelada' && <Icone nome="x" tamanho={12} peso={2.4} />}
        </button>
      )}
      <div style={{ flex: 1, minWidth: 0 }}>
        <div className="linha" style={{ alignItems: 'baseline', gap: 6 }}>
          <span className={`item-titulo ${aberta(a) ? '' : 'riscado'}`} style={{ flex: 1 }}>{a.titulo || 'Sem título'}</span>
          {a.prioridade === 2 && aberta(a) && <span style={{ color: 'var(--alerta)' }}><Icone nome="bandeira" tamanho={12} peso={2} /></span>}
        </div>
        <div className="item-meta">
          <span className="bolinha" style={{ background: cor }} />
          <span>{cliente?.nome ?? a.contexto}</span>
          {textoQuando && (
            <>
              <span>·</span>
              <span style={atrasada(a) ? { color: 'var(--alerta)' } : undefined}>{textoQuando}</span>
            </>
          )}
          {a.repeticao !== 'nunca' && <Icone nome="repetir" tamanho={12} />}
          {a.lembretes.length > 0 && aberta(a) && <Icone nome="sino" tamanho={12} />}
          {a.status === 'cancelada' && <span>· Cancelada</span>}
        </div>
      </div>
    </div>
  )
}

export function ListaAtividades({ itens, dia, mostrarData = true }: { itens: Atividade[]; dia?: Date; mostrarData?: boolean }) {
  return (
    <div className="card p12">
      {itens.map((a, i) => (
        <div key={a.id + (dia?.toDateString() ?? '')}>
          <ItemAtividade atividade={a} dia={dia} mostrarData={mostrarData} />
          {i < itens.length - 1 && <div className="sep" />}
        </div>
      ))}
    </div>
  )
}
