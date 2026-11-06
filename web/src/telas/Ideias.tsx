import { useState } from 'react'
import { useApp } from '../contexto'
import { useEstado, salvarIdeia, apagarIdeia } from '../store'
import { EstadoVazio, Folha, Icone } from '../componentes/Base'
import { type Ideia, type Cliente, normalizarIdeia } from '../modelo'
import { diaMes } from '../datas'

/** Banco de ideias: ganchos, pautas e copies que viram tarefa com um toque. */
export function Ideias({ busca }: { busca: string }) {
  const app = useApp()
  const { ideias, clientes } = useEstado()
  const [texto, setTexto] = useState('')
  const [clienteId, setClienteId] = useState('')
  const [filtro, setFiltro] = useState('')
  const [editando, setEditando] = useState<Ideia | null>(null)

  const ativos = clientes.filter((c) => c.ativo).sort((a, b) => a.nome.localeCompare(b.nome))
  const clienteDe = (id: string | null) => clientes.find((c) => c.id === id)
  const termo = busca.trim().toLocaleLowerCase('pt-BR')

  const visiveis = ideias.filter((i) => {
    const passaFiltro = !filtro || (filtro === 'geral' ? !i.clienteId : i.clienteId === filtro)
    const passaBusca = !termo || i.texto.toLocaleLowerCase('pt-BR').includes(termo) || i.notas.toLocaleLowerCase('pt-BR').includes(termo)
    return passaFiltro && passaBusca
  })

  function adicionar() {
    const t = texto.trim()
    if (!t) return
    salvarIdeia(normalizarIdeia({ texto: t, clienteId: clienteId || null }))
    setTexto('')
  }

  function virarTarefa(i: Ideia) {
    app.abrir({
      tipo: 'nova',
      atividadeTipo: 'tarefa',
      titulo: i.texto,
      descricao: i.notas,
      clienteId: i.clienteId ?? undefined,
      ideiaId: i.id,
    })
  }

  return (
    <div className="px pilha" style={{ gap: 14 }}>
      <div className="card ideia-nova">
        <textarea
          value={texto}
          onChange={(e) => setTexto(e.target.value)}
          placeholder="Anote uma ideia: gancho, pauta, copy…"
          rows={2}
          enterKeyHint="done"
          onKeyDown={(e) => { if (e.key === 'Enter' && !e.shiftKey) { e.preventDefault(); adicionar() } }}
        />
        <div className="linha" style={{ gap: 8 }}>
          {ativos.length > 0 && (
            <label className="seletor-mini">
              <select value={clienteId} onChange={(e) => setClienteId(e.target.value)}>
                <option value="">Geral</option>
                {ativos.map((c) => <option key={c.id} value={c.id}>{c.nome}</option>)}
              </select>
              <span>{clienteDe(clienteId)?.nome ?? 'Geral'}</span>
              <Icone nome="setas" tamanho={12} />
            </label>
          )}
          <span className="espaco" />
          <button className="pilula" style={{ padding: '9px 16px' }} onClick={adicionar} disabled={!texto.trim()}>Guardar ideia</button>
        </div>
      </div>

      {ideias.length > 0 && ativos.length > 0 && (
        <div className="chips" style={{ padding: 0 }}>
          <button className={`chip ${filtro === '' ? 'ativo' : ''}`} onClick={() => setFiltro('')}>Todas</button>
          <button className={`chip ${filtro === 'geral' ? 'ativo' : ''}`} onClick={() => setFiltro('geral')}>Geral</button>
          {ativos.filter((c) => ideias.some((i) => i.clienteId === c.id)).map((c) => (
            <button key={c.id} className={`chip ${filtro === c.id ? 'ativo' : ''}`} onClick={() => setFiltro(c.id)}>{c.nome}</button>
          ))}
        </div>
      )}

      {visiveis.length === 0 ? (
        <EstadoVazio
          titulo={ideias.length ? 'Nenhuma ideia aqui' : 'Seu banco de ideias'}
          texto={ideias.length ? 'Tente outro filtro ou busca.' : 'Guarde as ideias de posts, ganchos e copies que surgirem no dia. Depois é só transformar em tarefa.'}
        />
      ) : (
        <div className="pilha-p">
          {visiveis.map((i) => {
            const c = clienteDe(i.clienteId)
            return (
              <div key={i.id} className="card ideia" onClick={() => setEditando(i)}>
                <div className="ideia-texto">{i.texto}</div>
                {i.notas && <div className="pequeno texto2 ideia-notas">{i.notas}</div>}
                <div className="linha" style={{ marginTop: 10, gap: 8 }}>
                  <span className="pequeno texto2 linha" style={{ gap: 5 }}>
                    <span className="bolinha" style={{ background: c?.cor ?? 'var(--taupe)' }} />
                    {c?.nome ?? 'Geral'} · {diaMes(new Date(i.criadaEm))}
                  </span>
                  <span className="espaco" />
                  <button
                    className="pilula contorno"
                    style={{ padding: '7px 12px', fontSize: 13 }}
                    onClick={(e) => { e.stopPropagation(); virarTarefa(i) }}
                  >
                    Virar tarefa <Icone nome="seta" tamanho={14} peso={1.4} />
                  </button>
                </div>
              </div>
            )
          })}
        </div>
      )}

      {editando && (
        <IdeiaEditor
          ideia={editando}
          clientes={ativos}
          fechar={() => setEditando(null)}
          virarTarefa={(i) => { setEditando(null); virarTarefa(i) }}
        />
      )}
    </div>
  )
}

function IdeiaEditor({ ideia, clientes, fechar, virarTarefa }: {
  ideia: Ideia
  clientes: Cliente[]
  fechar: () => void
  virarTarefa: (i: Ideia) => void
}) {
  const [f, setF] = useState<Ideia>(ideia)
  const podeSalvar = f.texto.trim().length > 0
  const salvar = () => { if (podeSalvar) { salvarIdeia({ ...f, texto: f.texto.trim() }); fechar() } }

  return (
    <Folha
      titulo="Ideia"
      fechar={fechar}
      rodape={
        <>
          <button className="pilula contorno" onClick={fechar}>Cancelar</button>
          <button className="pilula" onClick={salvar} disabled={!podeSalvar}>Salvar</button>
        </>
      }
    >
      <div>
        <span className="rotulo">Ideia</span>
        <label className="campo" style={{ alignItems: 'flex-start' }}>
          <textarea value={f.texto} onChange={(e) => setF({ ...f, texto: e.target.value })} rows={2} style={{ minHeight: 50 }} />
        </label>
      </div>
      <div>
        <span className="rotulo">Anotações <span className="opc">(opcional)</span></span>
        <label className="campo" style={{ alignItems: 'flex-start' }}>
          <textarea value={f.notas} onChange={(e) => setF({ ...f, notas: e.target.value })} placeholder="Referências, links, rascunho da copy…" rows={4} />
        </label>
      </div>
      {clientes.length > 0 && (
        <div>
          <span className="rotulo">Cliente <span className="opc">(opcional)</span></span>
          <label className="campo">
            <select value={f.clienteId ?? ''} onChange={(e) => setF({ ...f, clienteId: e.target.value || null })}>
              <option value="">Geral</option>
              {clientes.map((c) => <option key={c.id} value={c.id}>{c.nome}</option>)}
            </select>
            <span className="texto2"><Icone nome="setas" tamanho={14} /></span>
          </label>
        </div>
      )}
      <div className="pilha-p" style={{ alignItems: 'center', marginTop: 6 }}>
        <button className="pilula largo" onClick={() => { if (podeSalvar) virarTarefa({ ...f, texto: f.texto.trim() }) }} disabled={!podeSalvar}>
          Transformar em tarefa <Icone nome="seta" tamanho={16} peso={1.3} />
        </button>
        <button
          className="link-perigo"
          style={{ marginTop: 6 }}
          onClick={() => { if (confirm('Apagar esta ideia?')) { apagarIdeia(ideia.id); fechar() } }}
        >
          Apagar ideia
        </button>
      </div>
    </Folha>
  )
}
