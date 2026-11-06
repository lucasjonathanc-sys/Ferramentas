import { Fragment, type ReactNode } from 'react'
import { useApp } from '../contexto'
import { useEstado, alternarConclusao, alternarCancelamento, apagarAtividade, alternarItemChecklist, moverParaColuna } from '../store'
import { Folha, Icone, Segmento } from '../componentes/Base'
import { CartaoCliente } from '../componentes/Cliente'
import {
  type Atividade, type ColunaQuadro, COLUNAS, REPETICOES, atrasada, colunaDe, corContexto, dataDe, ehCompromisso, fimEfetivo, inicioEm,
  nomeLembrete, proximaOcorrencia,
} from '../modelo'
import { dataPorExtenso, hora } from '../datas'
import { abrirNoCalendario } from '../ics'

const comHttp = (s: string) => (/^https?:\/\//i.test(s) ? s : `https://${s}`)

/** Transforma os links do texto em links clicáveis. */
function comLinks(texto: string): ReactNode {
  const partes = texto.split(/((?:https?:\/\/|www\.)[^\s]+)/gi)
  return partes.map((p, i) =>
    /^(https?:\/\/|www\.)/i.test(p)
      ? <a key={i} href={comHttp(p)} target="_blank" rel="noreferrer" className="link-dado">{p}</a>
      : <Fragment key={i}>{p}</Fragment>,
  )
}

function duracao(min: number): string {
  const h = Math.floor(min / 60)
  const m = min % 60
  if (h === 0) return `${m} min`
  return m === 0 ? `${h} h` : `${h} h ${m} min`
}

function textoEntrar(link: string): string {
  if (/meet\.google/i.test(link)) return 'Entrar no Google Meet'
  if (/zoom\./i.test(link)) return 'Entrar no Zoom'
  if (/teams\.(microsoft|live)/i.test(link)) return 'Entrar no Teams'
  return 'Entrar na reunião'
}

export function AtividadeDetalhes({ atividade: a, dia, fechar }: { atividade: Atividade; dia?: Date; fechar: () => void }) {
  const app = useApp()
  const { clientes } = useEstado()
  const cliente = clientes.find((c) => c.id === a.clienteId)
  const cor = corContexto(a.contexto)
  const compromisso = ehCompromisso(a)

  // Dia mostrado: a ocorrência tocada, ou a próxima (para repetições)
  const d = dataDe(a)
  const diaRef = d ? (dia ?? (compromisso ? proximaOcorrencia(a) ?? d : d)) : null
  const inicio = d && diaRef ? (a.temHorario ? inicioEm(a, diaRef) ?? d : diaRef) : null
  const minutos = d ? Math.round(((fimEfetivo(a)?.getTime() ?? d.getTime()) - d.getTime()) / 60000) : 0
  const fim = inicio ? new Date(inicio.getTime() + minutos * 60000) : null

  const status =
    a.status === 'concluida' ? { texto: 'Concluída', cor: 'var(--sucesso)' }
      : a.status === 'cancelada' ? { texto: 'Cancelada', cor: 'var(--texto2)' }
        : atrasada(a) ? { texto: 'Atrasada', cor: 'var(--alerta)' }
          : null

  const repeticao = REPETICOES.find((r) => r.valor === a.repeticao)

  return (
    <Folha
      titulo={compromisso ? 'Compromisso' : 'Tarefa'}
      fechar={fechar}
      rodape={
        <>
          <button className="pilula contorno" onClick={fechar}>Fechar</button>
          <button className="pilula" onClick={() => app.abrir({ tipo: 'editar', id: a.id, voltar: { tipo: 'detalhes', id: a.id, dia: dia?.toISOString() } })}>
            Editar
          </button>
        </>
      }
    >
      <div className="pilha-p" style={{ gap: 8 }}>
        <h1 className="titulo-pagina" style={{ fontSize: 28, textDecoration: a.status === 'concluida' ? 'line-through' : undefined }}>
          {a.titulo || 'Sem título'}
        </h1>
        <div className="linha" style={{ gap: 8, flexWrap: 'wrap' }}>
          <span className="tag" style={{ color: cor, background: `color-mix(in srgb, ${cor} 13%, transparent)` }}>
            <span className="bolinha" style={{ background: cor }} /> {a.contexto}
          </span>
          {status && <span className="tag" style={{ color: status.cor, background: 'var(--suave)' }}>{status.texto}</span>}
          {!compromisso && a.prioridade === 2 && (
            <span className="tag" style={{ color: 'var(--alerta)', background: 'var(--suave)' }}><Icone nome="bandeira" tamanho={12} peso={2} /> Prioridade alta</span>
          )}
        </div>
      </div>

      {compromisso && a.link.trim() && a.status !== 'cancelada' && (
        <a className="pilula largo botao-reuniao" href={comHttp(a.link.trim())} target="_blank" rel="noreferrer">
          <span className="linha" style={{ gap: 10 }}><Icone nome="video" tamanho={20} /> {textoEntrar(a.link)}</span>
          <Icone nome="seta" tamanho={16} peso={1.3} />
        </a>
      )}

      <div className="card pilha-p" style={{ gap: 14 }}>
        <div className="detalhe-linha">
          <span className="detalhe-icone"><Icone nome="calendario" tamanho={18} /></span>
          <div>
            {inicio ? (
              <>
                <div>{dataPorExtenso(inicio)}</div>
                <div className="medio texto2">
                  {a.temHorario
                    ? compromisso && fim ? `${hora(inicio)} – ${hora(fim)} · ${duracao(minutos)}` : `Às ${hora(inicio)}`
                    : 'Sem horário'}
                </div>
              </>
            ) : (
              <div className="texto2">Sem data</div>
            )}
          </div>
        </div>

        {a.repeticao !== 'nunca' && repeticao && (
          <div className="detalhe-linha">
            <span className="detalhe-icone"><Icone nome="repetir" tamanho={18} /></span>
            <div>{repeticao.nome}</div>
          </div>
        )}

        {a.lembretes.length > 0 && (
          <div className="detalhe-linha">
            <span className="detalhe-icone"><Icone nome="sino" tamanho={18} /></span>
            <div className="fluxo" style={{ gap: 6 }}>
              {[...a.lembretes].sort((x, y) => x - y).map((m) => <span key={m} className="lembrete-chip" style={{ fontSize: 13, padding: '5px 10px' }}>{nomeLembrete(m)}</span>)}
            </div>
          </div>
        )}

        {compromisso && a.local.trim() && (
          <a className="detalhe-linha" href={`https://maps.apple.com/?q=${encodeURIComponent(a.local.trim())}`} target="_blank" rel="noreferrer" style={{ textDecoration: 'none' }}>
            <span className="detalhe-icone"><Icone nome="pino" tamanho={18} /></span>
            <div style={{ flex: 1 }}>
              <div style={{ whiteSpace: 'pre-wrap' }}>{a.local}</div>
              <div className="pequeno" style={{ color: 'var(--vinho)' }}>Abrir no Mapas</div>
            </div>
          </a>
        )}

        {compromisso && a.link.trim() && (
          <div className="detalhe-linha">
            <span className="detalhe-icone"><Icone nome="video" tamanho={18} /></span>
            <a href={comHttp(a.link.trim())} target="_blank" rel="noreferrer" className="link-dado" style={{ overflowWrap: 'anywhere' }}>
              {a.link.trim().replace(/^https?:\/\//i, '')}
            </a>
          </div>
        )}
      </div>

      {!compromisso && a.status !== 'cancelada' && (
        <div>
          <span className="rotulo">Etapa</span>
          <Segmento
            opcoes={COLUNAS.map((c) => ({ valor: c.valor, titulo: c.valor === 'aprovacao' ? 'Aprovação' : c.nome }))}
            valor={colunaDe(a)}
            definir={(c: ColunaQuadro) => moverParaColuna(a.id, c)}
          />
        </div>
      )}

      {a.checklist.length > 0 && (
        <div>
          <div className="linha" style={{ marginBottom: 8 }}>
            <span className="rotulo" style={{ margin: 0, flex: 1 }}>Checklist</span>
            <span className="pequeno texto2">{a.checklist.filter((i) => i.feito).length} de {a.checklist.length}</span>
          </div>
          <div className="card checklist-editor">
            {a.checklist.map((item) => (
              <button key={item.id} className="checklist-item" style={{ width: '100%', textAlign: 'left' }} onClick={() => alternarItemChecklist(a.id, item.id)}>
                <span className={`check pequeno-check ${item.feito ? 'feito' : ''}`}>
                  {item.feito && <Icone nome="check" tamanho={12} peso={2.4} />}
                </span>
                <span className={item.feito ? 'riscado' : ''} style={{ flex: 1 }}>{item.texto}</span>
              </button>
            ))}
          </div>
        </div>
      )}

      {a.descricao.trim() && (
        <div>
          <span className="rotulo">Descrição</span>
          <div className="card medio" style={{ whiteSpace: 'pre-wrap', overflowWrap: 'anywhere' }}>{comLinks(a.descricao)}</div>
        </div>
      )}

      {cliente && (
        <div>
          <span className="rotulo">Cliente</span>
          <CartaoCliente cliente={cliente} />
        </div>
      )}

      <div className="pilha-p" style={{ alignItems: 'center' }}>
        {!compromisso && (
          <div className="linha" style={{ width: '100%' }}>
            {a.status !== 'cancelada' && (
              <button className="pilula contorno" style={{ flex: 1 }} onClick={() => { alternarConclusao(a.id); fechar() }}>
                <Icone nome={a.status === 'concluida' ? 'voltar' : 'check'} tamanho={16} /> {a.status === 'concluida' ? 'Reabrir' : 'Concluir'}
              </button>
            )}
            <button className="pilula contorno" style={{ flex: 1 }} onClick={() => { alternarCancelamento(a.id); fechar() }}>
              {a.status === 'cancelada' ? 'Reativar' : 'Cancelar tarefa'}
            </button>
          </div>
        )}
        {a.data && (
          <button className="pilula contorno largo" onClick={() => abrirNoCalendario(a, cliente)}>
            <span className="linha" style={{ gap: 8 }}><Icone nome="calMais" tamanho={18} /> Adicionar ao Calendário do iPhone</span>
            <Icone nome="seta" tamanho={16} />
          </button>
        )}
        <button
          className="link-perigo"
          style={{ marginTop: 6 }}
          onClick={() => {
            if (confirm('Apagar esta atividade?')) {
              apagarAtividade(a.id)
              fechar()
            }
          }}
        >
          Apagar
        </button>
      </div>
    </Folha>
  )
}
