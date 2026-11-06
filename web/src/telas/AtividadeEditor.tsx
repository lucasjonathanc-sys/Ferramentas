import { useMemo, useState } from 'react'
import { Folha, Icone, Segmento, ChipContexto } from '../componentes/Base'
import { useEstado, salvarAtividade, apagarAtividade, alternarConclusao, alternarCancelamento } from '../store'
import {
  type Atividade, type Contexto, type Etapa, type ItemChecklist, type Prioridade, type Repeticao, type Tipo,
  CONTEXTOS, OPCOES_LEMBRETE, PRIORIDADES, REPETICOES, comHora, ehHoje, fimEfetivo, inicioDoDia, nomeLembrete, novoId, somarDias,
} from '../modelo'
import { deInputData, deInputHora, paraInputData, paraInputHora } from '../datas'
import { abrirNoCalendario } from '../ics'
import { CartaoCliente } from '../componentes/Cliente'

interface Props {
  fechar: () => void
  atividade?: Atividade
  pedido?: { atividadeTipo?: Tipo; data?: Date; temHorario?: boolean; clienteId?: string; etapa?: Etapa }
}

function proximaHoraCheia(dia: Date): Date {
  if (ehHoje(dia)) {
    const d = new Date()
    d.setHours(d.getHours() + 1, 0, 0, 0)
    return d
  }
  return comHora(dia, 9, 0)
}

export function AtividadeEditor({ fechar, atividade, pedido }: Props) {
  const { clientes } = useEstado()
  const enderecoDe = (id: string | null | undefined) => clientes.find((c) => c.id === id)?.endereco.trim() ?? ''
  const editando = !!atividade

  // Estado inicial
  const inicial = useMemo(() => {
    if (atividade) {
      const d = atividade.data ? new Date(atividade.data) : new Date()
      const fim = fimEfetivo(atividade) ?? new Date(d.getTime() + 3600000)
      return {
        tipo: atividade.tipo,
        titulo: atividade.titulo,
        temData: !!atividade.data,
        dia: d,
        temHorario: atividade.temHorario,
        hora: atividade.temHorario ? d : proximaHoraCheia(new Date()),
        horaFim: fim,
        contexto: atividade.contexto,
        clienteId: atividade.clienteId,
        descricao: atividade.descricao,
        prioridade: atividade.prioridade,
        repeticao: atividade.repeticao,
        lembretes: atividade.lembretes,
        local: atividade.local,
        link: atividade.link,
        maisOpcoes: !!atividade.descricao || atividade.repeticao !== 'nunca' || !!atividade.local || !!atividade.link,
        etapa: atividade.etapa,
        checklist: atividade.checklist,
      }
    }
    const tipo: Tipo = pedido?.atividadeTipo ?? 'tarefa'
    const dia = pedido?.data ?? new Date()
    const comHorario = tipo === 'compromisso' || !!pedido?.temHorario
    const h = pedido?.temHorario && pedido.data ? pedido.data : proximaHoraCheia(dia)
    return {
      tipo,
      titulo: '',
      temData: true,
      dia,
      temHorario: comHorario,
      hora: h,
      horaFim: new Date(h.getTime() + 3600000),
      contexto: (pedido?.clienteId ? 'Clientes' : 'China Link') as Contexto,
      clienteId: pedido?.clienteId ?? null,
      descricao: '',
      prioridade: 1 as Prioridade,
      repeticao: 'nunca' as Repeticao,
      lembretes: tipo === 'compromisso' ? [15] : [],
      local: tipo === 'compromisso' ? enderecoDe(pedido?.clienteId) : '',
      link: '',
      maisOpcoes: false,
      etapa: (pedido?.etapa ?? 'aFazer') as Etapa,
      checklist: [] as ItemChecklist[],
    }
  }, [atividade, pedido])

  const [tipo, setTipo] = useState<Tipo>(inicial.tipo)
  const [titulo, setTitulo] = useState(inicial.titulo)
  const [temData, setTemData] = useState(inicial.temData)
  const [dia, setDia] = useState(inicial.dia)
  const [temHorario, setTemHorario] = useState(inicial.temHorario)
  const [hora, setHora] = useState(inicial.hora)
  const [horaFim, setHoraFim] = useState(inicial.horaFim)
  const [contexto, setContexto] = useState<Contexto>(inicial.contexto)
  const [clienteId, setClienteId] = useState<string | null>(inicial.clienteId)
  const [maisOpcoes, setMaisOpcoes] = useState(inicial.maisOpcoes)
  const [descricao, setDescricao] = useState(inicial.descricao)
  const [prioridade, setPrioridade] = useState<Prioridade>(inicial.prioridade)
  const [repeticao, setRepeticao] = useState<Repeticao>(inicial.repeticao)
  const [lembretes, setLembretes] = useState<number[]>(inicial.lembretes)
  const [local, setLocal] = useState(inicial.local)
  const [link, setLink] = useState(inicial.link)
  const [checklist, setChecklist] = useState<ItemChecklist[]>(inicial.checklist)
  const [novoItem, setNovoItem] = useState('')

  const ehCompromisso = tipo === 'compromisso'
  const podeSalvar = titulo.trim().length > 0
  const cliente = clientes.find((c) => c.id === clienteId)
  const clientesVisiveis = clientes.filter((c) => c.ativo || c.id === clienteId).sort((a, b) => a.nome.localeCompare(b.nome))

  function mudarTipo(t: Tipo) {
    setTipo(t)
    // Atividade nova: lembrete automático (15 min antes) só nos compromissos, se ela ainda não mexeu nos lembretes
    if (!editando) {
      const padrao = (x: Tipo) => (x === 'compromisso' ? [15] : [])
      if (lembretes.join() === padrao(tipo).join()) setLembretes(padrao(t))
    }
    if (t === 'compromisso') {
      if (!local.trim() && cliente?.endereco.trim()) setLocal(cliente.endereco.trim())
      setTemData(true)
      if (!temHorario) {
        setTemHorario(true)
        const h = proximaHoraCheia(dia)
        setHora(h)
        setHoraFim(new Date(h.getTime() + 3600000))
      }
    }
  }

  function mudarHoraInicio(valor: string) {
    const [h, m] = deInputHora(valor)
    const nova = comHora(dia, h, m)
    const duracao = Math.max(horaFim.getTime() - hora.getTime(), 15 * 60000)
    setHora(nova)
    setHoraFim(new Date(nova.getTime() + duracao))
  }

  function montar(): Atividade {
    let data: string | null = null
    let fim: string | null = null
    let comHorario = false
    if (temData || ehCompromisso) {
      if (temHorario || ehCompromisso) {
        const inicio = comHora(dia, hora.getHours(), hora.getMinutes())
        data = inicio.toISOString()
        comHorario = true
        if (ehCompromisso) {
          let f = comHora(dia, horaFim.getHours(), horaFim.getMinutes())
          if (f <= inicio) f = somarDias(f, 1)
          fim = f.toISOString()
        }
      } else {
        data = inicioDoDia(dia).toISOString()
      }
    }
    return {
      id: atividade?.id ?? novoId(),
      tipo,
      titulo: titulo.trim(),
      descricao,
      contexto,
      status: atividade?.status ?? 'aberta',
      prioridade,
      data,
      temHorario: comHorario,
      fim,
      repeticao,
      lembretes: [...lembretes].sort((a, b) => a - b),
      local: ehCompromisso ? local : '',
      link: ehCompromisso ? link : '',
      clienteId,
      criadaEm: atividade?.criadaEm ?? new Date().toISOString(),
      concluidaEm: atividade?.concluidaEm ?? null,
      etapa: inicial.etapa,
      checklist: ehCompromisso ? checklist.filter((i) => i.texto.trim()) : (atividade?.checklist ?? []),
    }
  }

  function salvar() {
    if (!podeSalvar) return
    const a = montar()
    if (ehCompromisso && novoItem.trim()) a.checklist = [...a.checklist, { id: novoId(), texto: novoItem.trim(), feito: false }]
    salvarAtividade(a)
    fechar()
  }

  const duracaoTexto = (() => {
    let min = Math.round((comHora(dia, horaFim.getHours(), horaFim.getMinutes()).getTime() - comHora(dia, hora.getHours(), hora.getMinutes()).getTime()) / 60000)
    if (min <= 0) min += 24 * 60
    const h = Math.floor(min / 60)
    const m = min % 60
    if (h === 0) return `${m} min`
    return m === 0 ? `${h} h` : `${h} h ${m} min`
  })()

  const rotulo = (texto: string, opcional = false) => (
    <span className="rotulo">{texto} {opcional && <span className="opc">(opcional)</span>}</span>
  )

  return (
    <Folha
      titulo={editando ? 'Editar atividade' : 'Nova atividade'}
      fechar={fechar}
      rodape={
        <>
          <button className="pilula contorno" onClick={fechar}>Cancelar</button>
          <button className="pilula" onClick={salvar} disabled={!podeSalvar}>Salvar</button>
        </>
      }
    >
      <Segmento
        opcoes={[{ valor: 'tarefa' as Tipo, titulo: 'Tarefa' }, { valor: 'compromisso' as Tipo, titulo: 'Compromisso' }]}
        valor={tipo}
        definir={mudarTipo}
      />

      <div>
        {rotulo('Título')}
        <label className="campo">
          <input
            value={titulo}
            onChange={(e) => setTitulo(e.target.value)}
            placeholder={ehCompromisso ? 'Ex.: Reunião de pauta' : 'O que precisa ser feito?'}
            autoFocus={!editando}
            enterKeyHint="done"
          />
        </label>
      </div>

      <div className="dupla">
        <div>
          {rotulo(ehCompromisso ? 'Data' : 'Vencimento', !ehCompromisso)}
          {temData || ehCompromisso ? (
            <label className="campo">
              <input type="date" value={paraInputData(dia)} onChange={(e) => e.target.value && setDia(deInputData(e.target.value))} />
              {!ehCompromisso && (
                <button className="texto2" onClick={(e) => { e.preventDefault(); setTemData(false); setTemHorario(false) }} aria-label="Remover data">
                  <Icone nome="x" tamanho={14} />
                </button>
              )}
            </label>
          ) : (
            <button className="campo texto2" onClick={() => setTemData(true)}>
              <span className="espaco">Sem data</span><Icone nome="mais" tamanho={14} />
            </button>
          )}
        </div>
        <div>
          {rotulo(ehCompromisso ? 'Início' : 'Horário', !ehCompromisso)}
          {temHorario ? (
            <label className="campo">
              <input type="time" value={paraInputHora(hora)} onChange={(e) => e.target.value && mudarHoraInicio(e.target.value)} />
              {!ehCompromisso && (
                <button className="texto2" onClick={(e) => { e.preventDefault(); setTemHorario(false) }} aria-label="Remover horário">
                  <Icone nome="x" tamanho={14} />
                </button>
              )}
            </label>
          ) : (
            <button className="campo texto2" onClick={() => { setTemData(true); setTemHorario(true); setHora(proximaHoraCheia(dia)) }}>
              <span className="espaco">Adicionar</span><Icone nome="mais" tamanho={14} />
            </button>
          )}
        </div>
      </div>

      {ehCompromisso && (
        <div>
          {rotulo('Fim')}
          <label className="campo">
            <input
              type="time"
              value={paraInputHora(horaFim)}
              onChange={(e) => {
                if (!e.target.value) return
                const [h, m] = deInputHora(e.target.value)
                setHoraFim(comHora(dia, h, m))
              }}
            />
            <span className="texto2 pequeno">{duracaoTexto}</span>
          </label>
        </div>
      )}

      <div>
        {rotulo('Contexto')}
        <div className="fluxo">
          {CONTEXTOS.map((c) => (
            <ChipContexto key={c.nome} contexto={c.nome} ativo={contexto === c.nome} onClick={() => setContexto(c.nome)} />
          ))}
        </div>
      </div>

      <div>
        {rotulo('Cliente', true)}
        <label className="campo">
          <select
            value={clienteId ?? ''}
            onChange={(e) => {
              const id = e.target.value || null
              // Nos compromissos, o endereço do cliente entra no Local (se estiver vazio ou com o endereço do cliente anterior)
              if (ehCompromisso && (!local.trim() || local.trim() === enderecoDe(clienteId))) setLocal(enderecoDe(id))
              setClienteId(id)
              if (id) setContexto('Clientes')
            }}
          >
            <option value="">{clientesVisiveis.length ? 'Nenhum' : 'Nenhum (cadastre na aba Clientes)'}</option>
            {clientesVisiveis.map((c) => <option key={c.id} value={c.id}>{c.nome}</option>)}
          </select>
          <span className="texto2"><Icone nome="setas" tamanho={14} /></span>
        </label>
        {cliente && <div style={{ marginTop: 10 }}><CartaoCliente cliente={cliente} /></div>}
      </div>

      {ehCompromisso && (
        <div>
          {rotulo('Checklist', true)}
          <div className="card checklist-editor">
            {checklist.map((item) => (
              <div key={item.id} className="checklist-item">
                <button
                  className={`check pequeno-check ${item.feito ? 'feito' : ''}`}
                  onClick={() => setChecklist(checklist.map((i) => (i.id === item.id ? { ...i, feito: !i.feito } : i)))}
                  aria-label={item.feito ? 'Desmarcar' : 'Marcar como feito'}
                >
                  {item.feito && <Icone nome="check" tamanho={12} peso={2.4} />}
                </button>
                <input
                  value={item.texto}
                  onChange={(e) => setChecklist(checklist.map((i) => (i.id === item.id ? { ...i, texto: e.target.value } : i)))}
                  className={item.feito ? 'riscado' : ''}
                />
                <button className="texto2" onClick={() => setChecklist(checklist.filter((i) => i.id !== item.id))} aria-label="Remover item">
                  <Icone nome="x" tamanho={14} />
                </button>
              </div>
            ))}
            <form
              className="checklist-item"
              onSubmit={(e) => {
                e.preventDefault()
                const texto = novoItem.trim()
                if (!texto) return
                setChecklist([...checklist, { id: novoId(), texto, feito: false }])
                setNovoItem('')
              }}
            >
              <span className="texto2" style={{ width: 22, display: 'grid', placeItems: 'center' }}><Icone nome="mais" tamanho={16} /></span>
              <input value={novoItem} onChange={(e) => setNovoItem(e.target.value)} placeholder="Adicionar item (ex.: levar referências)" enterKeyHint="done" />
            </form>
          </div>
        </div>
      )}

      <div className="pilha-p">
        <button className="campo" onClick={() => setMaisOpcoes(!maisOpcoes)}>
          <span className="espaco">
            <span style={{ display: 'block', fontSize: 15, fontWeight: 500 }}>Mais opções</span>
            <span className="texto2 pequeno">
              {ehCompromisso ? 'Descrição, local, link, repetição e lembretes' : 'Descrição, prioridade, repetição e lembretes'}
            </span>
          </span>
          <span className="texto2"><Icone nome={maisOpcoes ? 'cima' : 'baixo'} tamanho={16} /></span>
        </button>

        {maisOpcoes && (
          <div className="pilha" style={{ gap: 16, marginTop: 6 }}>
            {!ehCompromisso && (
              <div>
                {rotulo('Prioridade')}
                <Segmento opcoes={PRIORIDADES.map((p) => ({ valor: p.valor, titulo: p.nome }))} valor={prioridade} definir={setPrioridade} />
              </div>
            )}

            <div>
              {rotulo('Repetição')}
              <label className="campo">
                <select value={repeticao} onChange={(e) => setRepeticao(e.target.value as Repeticao)}>
                  {REPETICOES.map((r) => <option key={r.valor} value={r.valor}>{r.nome}</option>)}
                </select>
                <span className="texto2"><Icone nome="setas" tamanho={14} /></span>
              </label>
            </div>

            <div>
              {rotulo('Lembretes')}
              <div className="fluxo">
                {[...lembretes].sort((a, b) => a - b).map((m) => (
                  <span key={m} className="lembrete-chip">
                    {nomeLembrete(m)}
                    <button onClick={() => setLembretes(lembretes.filter((x) => x !== m))} aria-label={`Remover ${nomeLembrete(m)}`}>
                      <Icone nome="x" tamanho={12} peso={2.2} />
                    </button>
                  </span>
                ))}
                {OPCOES_LEMBRETE.some((m) => !lembretes.includes(m)) && (
                  <label className="add-lembrete">
                    Adicionar lembrete <Icone nome="setas" tamanho={12} />
                    <select
                      value=""
                      onChange={(e) => {
                        const m = Number(e.target.value)
                        if (e.target.value !== '' && !lembretes.includes(m)) setLembretes([...lembretes, m])
                      }}
                    >
                      <option value="" disabled>Adicionar lembrete</option>
                      {OPCOES_LEMBRETE.filter((m) => !lembretes.includes(m)).map((m) => (
                        <option key={m} value={m}>{nomeLembrete(m)}</option>
                      ))}
                    </select>
                  </label>
                )}
              </div>
              <p className="grupo-nota" style={{ marginLeft: 0 }}>
                Para receber os avisos com o app fechado, use “Adicionar ao Calendário” depois de salvar.
              </p>
            </div>

            {ehCompromisso && (
              <>
                <div>
                  {rotulo('Local', true)}
                  <label className="campo"><input value={local} onChange={(e) => setLocal(e.target.value)} placeholder="Sala, endereço..." /></label>
                </div>
                <div>
                  {rotulo('Link da reunião', true)}
                  <label className="campo">
                    <input value={link} onChange={(e) => setLink(e.target.value)} placeholder="Meet, Zoom, Teams..." inputMode="url" autoCapitalize="off" autoCorrect="off" />
                  </label>
                </div>
              </>
            )}

            <div>
              {rotulo('Descrição')}
              <label className="campo" style={{ alignItems: 'flex-start' }}>
                <textarea value={descricao} onChange={(e) => setDescricao(e.target.value)} placeholder="Briefing, pauta, links, observações..." rows={4} />
              </label>
            </div>
          </div>
        )}
      </div>

      {editando && atividade && (
        <div className="pilha-p" style={{ alignItems: 'center', marginTop: 8 }}>
          {atividade.data && (
            <button
              className="pilula contorno largo"
              onClick={() => {
                const a = montar()
                if (podeSalvar) salvarAtividade(a)
                abrirNoCalendario(a, clientes.find((c) => c.id === a.clienteId))
              }}
            >
              <span className="linha" style={{ gap: 8 }}><Icone nome="calMais" tamanho={18} /> Adicionar ao Calendário do iPhone</span>
              <Icone nome="seta" tamanho={16} />
            </button>
          )}
          {!ehCompromisso && (
            <div className="linha" style={{ width: '100%' }}>
              <button
                className="pilula contorno"
                style={{ flex: 1 }}
                onClick={() => {
                  if (podeSalvar) salvarAtividade(montar())
                  alternarConclusao(atividade.id)
                  fechar()
                }}
              >
                {atividade.status === 'concluida' ? 'Reabrir' : 'Concluir'}
              </button>
              <button
                className="pilula contorno"
                style={{ flex: 1 }}
                onClick={() => {
                  if (podeSalvar) salvarAtividade(montar())
                  alternarCancelamento(atividade.id)
                  fechar()
                }}
              >
                {atividade.status === 'cancelada' ? 'Reativar' : 'Cancelar tarefa'}
              </button>
            </div>
          )}
          <button
            className="link-perigo"
            style={{ marginTop: 6 }}
            onClick={() => {
              if (confirm('Apagar esta atividade?')) {
                apagarAtividade(atividade.id)
                fechar()
              }
            }}
          >
            Apagar
          </button>
        </div>
      )}

      {!editando && (
        <p className="grupo-nota" style={{ textAlign: 'center' }}>
          Depois de salvar, abra a atividade para adicioná-la ao Calendário do iPhone com os lembretes.
        </p>
      )}
    </Folha>
  )
}
