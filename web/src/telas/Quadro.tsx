import { useEffect, useRef, useState, type PointerEvent as ReactPointerEvent } from 'react'
import { useApp } from '../contexto'
import { useEstado, moverParaColuna, criarCartaoRapido } from '../store'
import { Icone } from '../componentes/Base'
import {
  type Atividade, type ColunaQuadro, COLUNAS, atrasada, colunaDe, corContexto, dataDe, ehCompromisso, ordenacao,
} from '../modelo'
import { quando } from '../datas'

/** Concluídas que continuam aparecendo na coluna "Feito". */
const DIAS_NO_FEITO = 7
const ESPERA_ARRASTAR = 320 // ms segurando para começar a arrastar
const TOLERANCIA = 8 // px que o dedo pode mexer antes de virar rolagem

interface Arrasto {
  id: string
  x: number
  y: number
  dx: number
  dy: number
  largura: number
  alvo: ColunaQuadro | null
}

export function Quadro({ busca }: { busca: string }) {
  const app = useApp()
  const { atividades, clientes } = useEstado()
  const [arrasto, setArrasto] = useState<Arrasto | null>(null)
  const [adicionando, setAdicionando] = useState<ColunaQuadro | null>(null)
  const quadroRef = useRef<HTMLDivElement>(null)
  const colunasRef = useRef<Partial<Record<ColunaQuadro, HTMLDivElement | null>>>({})
  const arrastando = useRef(false)
  const ignorarClique = useRef(false)
  const pressao = useRef<{ id: string; x: number; y: number; timer: number; el: HTMLElement; pointerId: number } | null>(null)
  const autoRolagem = useRef(0)

  const termo = busca.trim().toLocaleLowerCase('pt-BR')
  const limiteFeito = Date.now() - DIAS_NO_FEITO * 86400000
  const nomeCliente = (a: Atividade) => clientes.find((c) => c.id === a.clienteId)?.nome ?? ''

  const tarefas = atividades.filter((a) => {
    if (ehCompromisso(a) || a.status === 'cancelada') return false
    if (a.status === 'concluida' && new Date(a.concluidaEm ?? a.criadaEm).getTime() < limiteFeito) return false
    return !termo || a.titulo.toLocaleLowerCase('pt-BR').includes(termo) || nomeCliente(a).toLocaleLowerCase('pt-BR').includes(termo)
  })

  const porColuna = (c: ColunaQuadro) => {
    const lista = tarefas.filter((a) => colunaDe(a) === c)
    return c === 'feito'
      ? lista.sort((a, b) => (b.concluidaEm ?? '').localeCompare(a.concluidaEm ?? ''))
      : lista.sort((x, y) => {
        // Com data primeiro (por data); sem data por ordem de criação, o mais novo embaixo (como no Trello)
        if (!x.data && !y.data) return x.criadaEm.localeCompare(y.criadaEm)
        return ordenacao(x, y)
      })
  }

  // Bloqueia a rolagem da página enquanto arrasta (iOS precisa de listener não passivo)
  useEffect(() => {
    const el = quadroRef.current
    if (!el) return
    const bloquear = (e: TouchEvent) => { if (arrastando.current) e.preventDefault() }
    el.addEventListener('touchmove', bloquear, { passive: false })
    return () => el.removeEventListener('touchmove', bloquear)
  }, [])

  const colunaEm = (x: number, y: number): ColunaQuadro | null => {
    for (const c of COLUNAS) {
      const r = colunasRef.current[c.valor]?.getBoundingClientRect()
      if (r && x >= r.left && x <= r.right && y >= r.top - 40 && y <= r.bottom + 400) return c.valor
    }
    return null
  }

  // Rola o quadro para o lado quando o cartão chega perto da borda
  const rolarSePerto = (x: number) => {
    cancelAnimationFrame(autoRolagem.current)
    const q = quadroRef.current
    if (!q) return
    const r = q.getBoundingClientRect()
    const vel = x < r.left + 40 ? -10 : x > r.right - 40 ? 10 : 0
    if (!vel) return
    const passo = () => {
      q.scrollLeft += vel
      autoRolagem.current = requestAnimationFrame(passo)
    }
    autoRolagem.current = requestAnimationFrame(passo)
  }

  function aoPressionar(e: ReactPointerEvent<HTMLDivElement>, a: Atividade) {
    if (e.button !== 0) return
    const el = e.currentTarget
    const { clientX: x, clientY: y, pointerId } = e
    const timer = window.setTimeout(() => {
      const r = el.getBoundingClientRect()
      arrastando.current = true
      try { el.setPointerCapture(pointerId) } catch { /* ignora */ }
      navigator.vibrate?.(10)
      setArrasto({ id: a.id, x, y, dx: x - r.left, dy: y - r.top, largura: r.width, alvo: colunaDe(a) })
    }, ESPERA_ARRASTAR)
    pressao.current = { id: a.id, x, y, timer, el, pointerId }
  }

  function aoMover(e: ReactPointerEvent<HTMLDivElement>) {
    const p = pressao.current
    if (!p) return
    if (!arrastando.current) {
      // Mexeu antes do tempo: é rolagem, não arrasto
      if (Math.abs(e.clientX - p.x) > TOLERANCIA || Math.abs(e.clientY - p.y) > TOLERANCIA) {
        clearTimeout(p.timer)
        pressao.current = null
      }
      return
    }
    const alvo = colunaEm(e.clientX, e.clientY)
    setArrasto((s) => (s ? { ...s, x: e.clientX, y: e.clientY, alvo } : s))
    rolarSePerto(e.clientX)
  }

  function aoSoltar() {
    const p = pressao.current
    if (p) clearTimeout(p.timer)
    cancelAnimationFrame(autoRolagem.current)
    if (arrastando.current && arrasto) {
      ignorarClique.current = true
      setTimeout(() => { ignorarClique.current = false }, 50)
      const a = atividades.find((x) => x.id === arrasto.id)
      if (a && arrasto.alvo && arrasto.alvo !== colunaDe(a)) moverParaColuna(a.id, arrasto.alvo)
    }
    arrastando.current = false
    pressao.current = null
    setArrasto(null)
  }

  const arrastada = arrasto ? atividades.find((a) => a.id === arrasto.id) : null

  return (
    <>
      <div className="quadro" ref={quadroRef} style={arrasto ? { scrollSnapType: 'none' } : undefined}>
        {COLUNAS.map((c) => {
          const itens = porColuna(c.valor)
          const destacada = arrasto?.alvo === c.valor && arrastada && colunaDe(arrastada) !== c.valor
          return (
            <div key={c.valor} className={`coluna ${destacada ? 'alvo' : ''}`} ref={(el) => { colunasRef.current[c.valor] = el }}>
              <div className="coluna-cab">
                <span className={`coluna-ponto coluna-${c.valor}`} />
                <span className="coluna-nome">{c.nome}</span>
                <span className="coluna-conta">{itens.length}</span>
                <span className="espaco" />
                {c.valor !== 'feito' && (
                  <button
                    className="coluna-mais"
                    onClick={() => app.abrir({ tipo: 'nova', atividadeTipo: 'tarefa', etapa: c.valor as Exclude<ColunaQuadro, 'feito'> })}
                    aria-label={`Nova tarefa em ${c.nome}`}
                  >
                    <Icone nome="mais" tamanho={16} />
                  </button>
                )}
              </div>
              <div className="coluna-cartoes">
                {itens.map((a) => (
                  <Cartao
                    key={a.id}
                    atividade={a}
                    cliente={nomeCliente(a)}
                    fantasma={arrasto?.id === a.id}
                    onPointerDown={(e) => aoPressionar(e, a)}
                    onPointerMove={aoMover}
                    onPointerUp={aoSoltar}
                    onPointerCancel={aoSoltar}
                    onClick={() => { if (!ignorarClique.current) app.abrir({ tipo: 'detalhes', id: a.id }) }}
                  />
                ))}
                {itens.length === 0 && (
                  <div className="coluna-vazia">
                    {c.valor === 'feito' ? `Concluídas nos últimos ${DIAS_NO_FEITO} dias aparecem aqui` : 'Arraste um cartão para cá'}
                  </div>
                )}
                {c.valor !== 'feito' && (adicionando === c.valor ? (
                  <CartaoRapido
                    etapa={c.valor as Exclude<ColunaQuadro, 'feito'>}
                    fechar={() => setAdicionando(null)}
                  />
                ) : (
                  <button className="coluna-adicionar" onClick={() => setAdicionando(c.valor)}>
                    <Icone nome="mais" tamanho={14} /> Adicionar cartão
                  </button>
                ))}
              </div>
            </div>
          )
        })}
      </div>

      {arrasto && arrastada && (
        <div
          className="cartao cartao-arrastado"
          style={{ left: arrasto.x - arrasto.dx, top: arrasto.y - arrasto.dy, width: arrasto.largura }}
        >
          <ConteudoCartao atividade={arrastada} cliente={nomeCliente(arrastada)} />
        </div>
      )}
    </>
  )
}

function ConteudoCartao({ atividade: a, cliente }: { atividade: Atividade; cliente: string }) {
  const cor = corContexto(a.contexto)
  const d = dataDe(a)
  const feito = a.status === 'concluida'
  return (
    <>
      <div className="cartao-etiqueta" style={{ background: cor }} />
      <div className={`cartao-titulo ${feito ? 'riscado' : ''}`}>{a.titulo || 'Sem título'}</div>
      <div className="cartao-meta">
        <span className="linha" style={{ gap: 5 }}>
          <span className="bolinha" style={{ background: cor }} />
          {cliente || a.contexto}
        </span>
        {d && (
          <span className={`cartao-data ${atrasada(a) ? 'atrasada' : ''} ${feito ? 'feita' : ''}`}>
            <Icone nome="calendario" tamanho={11} /> {quando(d, a.temHorario)}
          </span>
        )}
        {a.prioridade === 2 && !feito && <span style={{ color: 'var(--alerta)' }}><Icone nome="bandeira" tamanho={12} peso={2} /></span>}
        {a.repeticao !== 'nunca' && <Icone nome="repetir" tamanho={12} />}
      </div>
    </>
  )
}

function Cartao(props: {
  atividade: Atividade
  cliente: string
  fantasma: boolean
  onPointerDown: (e: ReactPointerEvent<HTMLDivElement>) => void
  onPointerMove: (e: ReactPointerEvent<HTMLDivElement>) => void
  onPointerUp: () => void
  onPointerCancel: () => void
  onClick: () => void
}) {
  const a = props.atividade
  return (
    <div
      className={`cartao ${props.fantasma ? 'fantasma' : ''}`}
      onPointerDown={props.onPointerDown}
      onPointerMove={props.onPointerMove}
      onPointerUp={props.onPointerUp}
      onPointerCancel={props.onPointerCancel}
      onClick={props.onClick}
      onContextMenu={(e) => e.preventDefault()}
    >
      <ConteudoCartao atividade={a} cliente={props.cliente} />
      <label className="cartao-mover" onClick={(e) => e.stopPropagation()} onPointerDown={(e) => e.stopPropagation()} aria-label="Mover para…">
        <Icone nome="setas-lado" tamanho={14} />
        <select
          value=""
          onChange={(e) => e.target.value && moverParaColuna(a.id, e.target.value as ColunaQuadro)}
        >
          <option value="" disabled>Mover para…</option>
          {COLUNAS.filter((c) => c.valor !== colunaDe(a)).map((c) => <option key={c.valor} value={c.valor}>{c.nome}</option>)}
        </select>
      </label>
    </div>
  )
}

/** Campo para criar um cartão só com o título, direto na coluna (como no Trello). */
function CartaoRapido({ etapa, fechar }: { etapa: Exclude<ColunaQuadro, 'feito'>; fechar: () => void }) {
  const [titulo, setTitulo] = useState('')
  const campo = useRef<HTMLTextAreaElement>(null)

  useEffect(() => { campo.current?.focus() }, [])

  const adicionar = () => {
    if (!titulo.trim()) return
    criarCartaoRapido(titulo, etapa)
    setTitulo('')
    campo.current?.focus()
  }

  return (
    <div className="cartao-rapido">
      <textarea
        ref={campo}
        value={titulo}
        rows={2}
        placeholder="Título do cartão…"
        enterKeyHint="done"
        onChange={(e) => setTitulo(e.target.value)}
        onKeyDown={(e) => {
          if (e.key === 'Enter') { e.preventDefault(); adicionar() }
          if (e.key === 'Escape') fechar()
        }}
        onBlur={() => { if (!titulo.trim()) fechar() }}
      />
      <div className="linha">
        <button className="pilula" style={{ padding: '9px 16px' }} onMouseDown={(e) => e.preventDefault()} onClick={adicionar} disabled={!titulo.trim()}>
          Adicionar
        </button>
        <button className="texto2" onMouseDown={(e) => e.preventDefault()} onClick={fechar} aria-label="Cancelar">
          <Icone nome="x" tamanho={18} />
        </button>
        <span className="espaco" />
        <span className="pequeno texto2">Detalhes depois, no cartão</span>
      </div>
    </div>
  )
}
