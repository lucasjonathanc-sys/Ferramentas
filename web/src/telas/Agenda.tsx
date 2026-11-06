import { useEffect, useRef, useState } from 'react'
import { useApp } from '../contexto'
import { useEstado } from '../store'
import { Cabecalho, Icone, ListaAtividades, Segmento, TituloSecao } from '../componentes/Base'
import {
  type Atividade, aparece, corContexto, dataDe, ehHoje, fimEfetivo, inicioDoDia, inicioEm, mesmoDia,
  ordenacao, somarDias, somarMeses, comHora,
} from '../modelo'
import { dataPorExtenso, diaCurto, hora, intervalo, mesAno } from '../datas'

type Modo = 'dia' | 'semana' | 'mes'
/** Dias na visão "Semana" (3, como no vídeo, para caber no iPhone). */
const DIAS_SEMANA = 3
const ALTURA_HORA = 56

export function Agenda() {
  const { atividades: todas, clientes } = useEstado()
  const [clienteFiltro, setClienteFiltro] = useState('')
  const ativos = clientes.filter((c) => c.ativo || c.id === clienteFiltro).sort((a, b) => a.nome.localeCompare(b.nome))
  const clienteSelecionado = clientes.find((c) => c.id === clienteFiltro)
  // Calendário de conteúdo por cliente: mostra só as atividades do cliente escolhido
  const atividades = clienteFiltro ? todas.filter((a) => a.clienteId === clienteFiltro) : todas
  const [modo, setModo] = useState<Modo>('semana')
  const [referencia, setReferencia] = useState(() => inicioDoDia(new Date()))

  const dias = Array.from({ length: modo === 'dia' ? 1 : DIAS_SEMANA }, (_, i) => somarDias(referencia, i))
  const titulo =
    modo === 'dia' ? dataPorExtenso(referencia)
      : modo === 'semana' ? intervalo(dias[0], dias[dias.length - 1])
        : mesAno(referencia)
  const mostrandoHoje = modo === 'mes' ? false : dias.some(ehHoje)

  function avancar(dir: number) {
    if (modo === 'dia') setReferencia(somarDias(referencia, dir))
    else if (modo === 'semana') setReferencia(somarDias(referencia, dir * DIAS_SEMANA))
    else {
      const m = somarMeses(new Date(referencia.getFullYear(), referencia.getMonth(), 1), dir)
      setReferencia(m)
    }
  }

  return (
    <div className="app" style={{ height: '100%' }}>
      <div className="px pilha" style={{ gap: 14, paddingTop: 'calc(var(--seguro-topo) + 14px)', paddingBottom: 12 }}>
        <Cabecalho
          titulo="Agenda"
          extra={ativos.length > 0 ? (
            <label
              className="seletor-cliente"
              style={clienteSelecionado ? { borderColor: clienteSelecionado.cor, color: clienteSelecionado.cor } : undefined}
              aria-label="Filtrar por cliente"
            >
              <select value={clienteFiltro} onChange={(e) => setClienteFiltro(e.target.value)}>
                <option value="">Todos os clientes</option>
                {ativos.map((c) => <option key={c.id} value={c.id}>{c.nome}</option>)}
              </select>
              {clienteSelecionado && <span className="bolinha" style={{ background: clienteSelecionado.cor, width: 8, height: 8 }} />}
              <span className="seletor-cliente-texto">{clienteSelecionado?.nome ?? 'Todos os clientes'}</span>
              <Icone nome="setas" tamanho={12} />
            </label>
          ) : undefined}
        />
        <Segmento
          opcoes={[{ valor: 'dia' as Modo, titulo: 'Dia' }, { valor: 'semana' as Modo, titulo: 'Semana' }, { valor: 'mes' as Modo, titulo: 'Mês' }]}
          valor={modo}
          definir={setModo}
        />
        <div className="agenda-nav">
          <button onClick={() => avancar(-1)} aria-label="Anterior"><Icone nome="voltar" tamanho={18} /></button>
          <span className="titulo-periodo">{titulo}</span>
          <button onClick={() => avancar(1)} aria-label="Próximo"><Icone nome="avancar" tamanho={18} /></button>
          <span className="espaco" />
          <button className="botao-hoje" disabled={mostrandoHoje} onClick={() => setReferencia(inicioDoDia(new Date()))}>Hoje</button>
        </div>
      </div>

      {modo === 'mes'
        ? <Mes referencia={referencia} atividades={atividades} />
        : <LinhaDoTempo dias={dias} atividades={atividades} />}
    </div>
  )
}

// MARK: - Linha do tempo

interface Evento { atividade: Atividade; inicio: Date; fim: Date; coluna: number; colunas: number }

function posicionar(atividades: Atividade[], dia: Date): Evento[] {
  const eventos: Evento[] = atividades
    .filter((a) => a.temHorario && a.status !== 'cancelada' && aparece(a, dia))
    .map((a) => {
      const d = dataDe(a)!
      const ini = inicioEm(a, dia)!
      const dur = Math.max((fimEfetivo(a)?.getTime() ?? d.getTime() + 1800000) - d.getTime(), 900000)
      return { atividade: a, inicio: ini, fim: new Date(ini.getTime() + dur), coluna: 0, colunas: 1 }
    })
    .sort((a, b) => a.inicio.getTime() - b.inicio.getTime())

  // Reparte em colunas os eventos que se sobrepõem
  let grupo: Evento[] = []
  let fimGrupo = 0
  const fechar = () => {
    const fins: number[] = []
    for (const e of grupo) {
      const livre = fins.findIndex((f) => f <= e.inicio.getTime())
      if (livre >= 0) { e.coluna = livre; fins[livre] = e.fim.getTime() } else { e.coluna = fins.length; fins.push(e.fim.getTime()) }
    }
    for (const e of grupo) e.colunas = Math.max(fins.length, 1)
    grupo = []
  }
  for (const e of eventos) {
    if (grupo.length && e.inicio.getTime() >= fimGrupo) fechar()
    grupo.push(e)
    fimGrupo = grupo.length === 1 ? e.fim.getTime() : Math.max(fimGrupo, e.fim.getTime())
  }
  if (grupo.length) fechar()
  return eventos
}

const posY = (d: Date) => d.getHours() * ALTURA_HORA + (d.getMinutes() / 60) * ALTURA_HORA

function LinhaDoTempo({ dias, atividades }: { dias: Date[]; atividades: Atividade[] }) {
  const app = useApp()
  const rolagem = useRef<HTMLDivElement>(null)
  const [agora, setAgora] = useState(new Date())

  useEffect(() => {
    const t = setInterval(() => setAgora(new Date()), 60000)
    return () => clearInterval(t)
  }, [])

  useEffect(() => {
    const alvo = Math.min(Math.max(new Date().getHours() - 2, 0), 7)
    rolagem.current?.scrollTo({ top: alvo * ALTURA_HORA })
  }, [])

  const indiceHoje = dias.findIndex((d) => mesmoDia(d, agora))

  return (
    <div className="app" style={{ flex: 1, minHeight: 0 }}>
      <div className="tl-cab" style={{ paddingRight: 8 }}>
        <div className="tl-horas" />
        {dias.map((d) => (
          <div className="dia" key={d.toDateString()}>
            <div className="nome">{diaCurto(d)}</div>
            <div className={`num ${ehHoje(d) ? 'hoje' : ''}`}>{d.getDate()}</div>
          </div>
        ))}
      </div>

      <div className="tl-semhora" style={{ paddingRight: 8 }}>
        <div className="rot">Sem<br />hora</div>
        {dias.map((d) => {
          const itens = atividades.filter((a) => !a.temHorario && a.status !== 'cancelada' && aparece(a, d)).sort(ordenacao)
          return (
            <div
              className="col"
              key={d.toDateString()}
              onClick={(e) => e.target === e.currentTarget && app.abrir({ tipo: 'nova', atividadeTipo: 'tarefa', data: d })}
            >
              {itens.map((a) => {
                const cor = corContexto(a.contexto)
                return (
                  <button
                    key={a.id}
                    className="pill-semhora"
                    style={{ background: `color-mix(in srgb, ${cor} 14%, transparent)`, color: a.status === 'concluida' ? 'var(--texto2)' : undefined, textDecoration: a.status === 'concluida' ? 'line-through' : undefined }}
                    onClick={() => app.abrir({ tipo: 'detalhes', id: a.id, dia: d.toISOString() })}
                  >
                    <span className="bolinha" style={{ background: cor, width: 5, height: 5 }} />
                    <span style={{ overflow: 'hidden', textOverflow: 'ellipsis' }}>{a.titulo}</span>
                  </button>
                )
              })}
            </div>
          )
        })}
      </div>

      <div className="tl-scroll" ref={rolagem}>
        <div className="tl-grade" style={{ position: 'relative', paddingRight: 8, paddingBottom: 24 }}>
          <div className="tl-horas">
            {Array.from({ length: 24 }, (_, h) => (
              <div className="tl-hora" key={h}>{String(h).padStart(2, '0')}:00</div>
            ))}
          </div>
          {dias.map((d) => (
            <div
              className="tl-col"
              key={d.toDateString()}
              onClick={(e) => {
                if (e.target !== e.currentTarget && !(e.target as HTMLElement).classList.contains('tl-linha')) return
                const r = e.currentTarget.getBoundingClientRect()
                const h = Math.min(23, Math.max(0, Math.floor((e.clientY - r.top) / ALTURA_HORA)))
                app.abrir({ tipo: 'nova', atividadeTipo: 'compromisso', data: comHora(d, h, 0), temHorario: true })
              }}
            >
              {Array.from({ length: 24 }, (_, h) => <div className="tl-linha" key={h} />)}
              {posicionar(atividades, d).map((e) => {
                const cor = corContexto(e.atividade.contexto)
                const largura = 100 / e.colunas
                const altura = Math.min(Math.max(((e.fim.getTime() - e.inicio.getTime()) / 3600000) * ALTURA_HORA, 20), 24 * ALTURA_HORA - posY(e.inicio))
                return (
                  <button
                    key={e.atividade.id}
                    className="evento"
                    style={{
                      top: posY(e.inicio),
                      height: altura,
                      left: `calc(${e.coluna * largura}% + 2px)`,
                      width: `calc(${largura}% - 4px)`,
                      background: `color-mix(in srgb, ${cor} 16%, var(--fundo))`,
                      opacity: e.atividade.status === 'concluida' ? 0.55 : 1,
                    }}
                    onClick={() => app.abrir({ tipo: 'detalhes', id: e.atividade.id, dia: d.toISOString() })}
                  >
                    <span className="barra-cor" style={{ background: cor }} />
                    <span className="txt">
                      <b style={{ whiteSpace: altura > 40 ? 'normal' : 'nowrap', textDecoration: e.atividade.status === 'concluida' ? 'line-through' : undefined }}>
                        {e.atividade.titulo}
                      </b>
                      {altura > 34 && <span className="texto2">{hora(e.inicio)}</span>}
                    </span>
                  </button>
                )
              })}
            </div>
          ))}

          {indiceHoje >= 0 && (
            <>
              <span className="agora-rotulo" style={{ top: posY(agora) - 9 }}>{hora(agora)}</span>
              <span
                className="agora-ponto"
                style={{ top: posY(agora) - 4, left: `calc(50px + (100% - 58px) * ${indiceHoje / dias.length} - 4px)` }}
              />
              <span
                className="agora-linha"
                style={{ top: posY(agora) - 0.75, left: `calc(50px + (100% - 58px) * ${indiceHoje / dias.length})`, width: `calc((100% - 58px) / ${dias.length})` }}
              />
            </>
          )}
        </div>
      </div>
    </div>
  )
}

// MARK: - Mês

function Mes({ referencia, atividades }: { referencia: Date; atividades: Atividade[] }) {
  const app = useApp()
  const [selecionado, setSelecionado] = useState(() => inicioDoDia(new Date()))

  // Ao trocar de mês, seleciona o dia 1 (ou hoje, se for o mês atual)
  useEffect(() => {
    if (selecionado.getMonth() !== referencia.getMonth() || selecionado.getFullYear() !== referencia.getFullYear()) {
      const hoje = new Date()
      setSelecionado(hoje.getMonth() === referencia.getMonth() && hoje.getFullYear() === referencia.getFullYear()
        ? inicioDoDia(hoje) : new Date(referencia.getFullYear(), referencia.getMonth(), 1))
    }
  }, [referencia]) // eslint-disable-line react-hooks/exhaustive-deps

  const primeiro = new Date(referencia.getFullYear(), referencia.getMonth(), 1)
  const quantidade = new Date(referencia.getFullYear(), referencia.getMonth() + 1, 0).getDate()
  const celulas: (Date | null)[] = Array(primeiro.getDay()).fill(null)
  for (let i = 0; i < quantidade; i++) celulas.push(somarDias(primeiro, i))
  while (celulas.length % 7) celulas.push(null)

  const itensDo = (d: Date) =>
    atividades
      .filter((a) => a.status !== 'cancelada' && aparece(a, d))
      .sort((a, b) => {
        if (a.temHorario !== b.temHorario) return a.temHorario ? 1 : -1
        return (inicioEm(a, d)?.getTime() ?? 0) - (inicioEm(b, d)?.getTime() ?? 0)
      })

  const doDia = itensDo(selecionado)

  return (
    <div className="conteudo" style={{ paddingTop: 0 }}>
      <div className="pilha" style={{ gap: 16 }}>
        <div className="card" style={{ padding: 12 }}>
          <div className="mes-cab">{['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'].map((n) => <div key={n}>{n}</div>)}</div>
          <div className="mes-grade">
            {celulas.map((d, i) => {
              if (!d) return <div key={i} />
              const cores = [...new Set(itensDo(d).map((a) => a.contexto))].slice(0, 3)
              const sel = mesmoDia(d, selecionado)
              return (
                <button key={i} className="mes-dia" onClick={() => setSelecionado(d)}>
                  <span className={`n ${sel ? 'sel' : ehHoje(d) ? 'hoje' : ''}`}>{d.getDate()}</span>
                  <span className="pontos">{cores.map((c) => <i key={c} style={{ background: corContexto(c) }} />)}</span>
                </button>
              )
            })}
          </div>
        </div>

        <div className="pilha-p">
          <div className="linha">
            <div style={{ flex: 1 }}><TituloSecao titulo={dataPorExtenso(selecionado)} /></div>
            <button onClick={() => app.abrir({ tipo: 'nova', atividadeTipo: 'tarefa', data: selecionado })} aria-label="Nova atividade neste dia">
              <Icone nome="mais" tamanho={20} />
            </button>
          </div>
          {doDia.length === 0
            ? <div className="card medio texto2">Nada marcado neste dia.</div>
            : <ListaAtividades itens={doDia} dia={selecionado} mostrarData={false} />}
        </div>
      </div>
    </div>
  )
}
