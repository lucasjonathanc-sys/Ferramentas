import { useState } from 'react'
import { useEstado } from '../store'
import { Cabecalho, Chip, EstadoVazio, ListaAtividades, Segmento } from '../componentes/Base'
import { Quadro } from './Quadro'
import {
  type Atividade, aberta, atrasada, dataDe, ehCompromisso, inicioDoDia, inicioEm, jaPassou,
  proximaOcorrencia, somarDias,
} from '../modelo'

type FiltroStatus = 'abertas' | 'concluidas' | 'canceladas'
type FiltroTipo = 'todas' | 'tarefas' | 'compromissos'
type Visao = 'lista' | 'quadro'
const CHAVE_VISAO = 'hb-organiza-visao-tarefas'

function visaoSalva(): Visao {
  try { return localStorage.getItem(CHAVE_VISAO) === 'quadro' ? 'quadro' : 'lista' } catch { return 'lista' }
}

export function Tarefas() {
  const { atividades, clientes } = useEstado()
  const [busca, setBusca] = useState('')
  const [status, setStatus] = useState<FiltroStatus>('abertas')
  const [tipo, setTipo] = useState<FiltroTipo>('todas')
  const [visao, setVisaoEstado] = useState<Visao>(visaoSalva)
  const setVisao = (v: Visao) => {
    setVisaoEstado(v)
    try { localStorage.setItem(CHAVE_VISAO, v) } catch { /* ignora */ }
  }

  const termo = busca.trim().toLocaleLowerCase('pt-BR')
  const nomeCliente = (a: Atividade) => clientes.find((c) => c.id === a.clienteId)?.nome ?? ''

  const filtradas = atividades.filter((a) => {
    const passaStatus =
      status === 'abertas' ? aberta(a) && !jaPassou(a)
        : status === 'concluidas' ? a.status === 'concluida' || (aberta(a) && jaPassou(a))
          : a.status === 'cancelada'
    const passaTipo = tipo === 'todas' || (tipo === 'tarefas' ? !ehCompromisso(a) : ehCompromisso(a))
    const passaBusca = !termo
      || a.titulo.toLocaleLowerCase('pt-BR').includes(termo)
      || a.descricao.toLocaleLowerCase('pt-BR').includes(termo)
      || nomeCliente(a).toLocaleLowerCase('pt-BR').includes(termo)
    return passaStatus && passaTipo && passaBusca
  })

  const grupos = agrupar(filtradas, status)

  const vazio = busca
    ? ['Nada encontrado', 'Tente buscar outro título.']
    : status === 'abertas' ? ['Nenhuma tarefa em aberto', 'Use o botão + para criar uma tarefa.']
      : status === 'concluidas' ? ['Nenhuma tarefa concluída', 'O que você concluir aparece aqui.']
        : ['Nenhuma tarefa cancelada', 'Tarefas canceladas ficam guardadas aqui.']

  return (
    <div className="conteudo sem-padding">
      <div className="pilha" style={{ gap: 14 }}>
        <div className="px pilha" style={{ gap: 14 }}>
          <Cabecalho titulo="Tarefas" busca={{ valor: busca, definir: setBusca, placeholder: 'Buscar por título' }} />
          <Segmento
            opcoes={[{ valor: 'lista' as Visao, titulo: 'Lista' }, { valor: 'quadro' as Visao, titulo: 'Quadro' }]}
            valor={visao}
            definir={setVisao}
          />
        </div>
        {visao === 'quadro' ? <Quadro busca={busca} /> : <>
        <div className="chips">
          <Chip titulo="Abertas" ativo={status === 'abertas'} onClick={() => setStatus('abertas')} />
          <Chip titulo="Concluídas" ativo={status === 'concluidas'} onClick={() => setStatus('concluidas')} />
          <Chip titulo="Canceladas" ativo={status === 'canceladas'} onClick={() => setStatus('canceladas')} />
          <Chip titulo="Só tarefas" ativo={tipo === 'tarefas'} onClick={() => setTipo(tipo === 'tarefas' ? 'todas' : 'tarefas')} />
          <Chip titulo="Só compromissos" ativo={tipo === 'compromissos'} onClick={() => setTipo(tipo === 'compromissos' ? 'todas' : 'compromissos')} />
        </div>

        <div className="px pilha" style={{ gap: 18 }}>
          {grupos.length === 0 ? (
            <EstadoVazio titulo={vazio[0]} texto={vazio[1]} />
          ) : (
            grupos.map(([titulo, itens]) => (
              <div key={titulo || 'todos'} className="pilha-p">
                {titulo && (
                  <h3 className="titulo-secao" style={{ fontSize: 17, color: titulo === 'Atrasadas' ? 'var(--alerta)' : 'var(--texto2)' }}>
                    {titulo}
                  </h3>
                )}
                <ListaAtividades itens={itens} />
              </div>
            ))
          )}
        </div>
        </>}
      </div>
    </div>
  )
}

/** Agrupa por Atrasadas, Hoje, Amanhã, Próximos 7 dias, Mais adiante e Sem data. */
function agrupar(itens: Atividade[], status: FiltroStatus): [string, Atividade[]][] {
  if (status !== 'abertas') {
    const chave = (a: Atividade) => a.concluidaEm ?? a.data ?? a.criadaEm
    const ordenadas = [...itens].sort((a, b) => chave(b).localeCompare(chave(a)))
    return ordenadas.length ? [['', ordenadas]] : []
  }

  const ref = (a: Atividade) => (ehCompromisso(a) ? proximaOcorrencia(a) : dataDe(a))
  const hoje = inicioDoDia(new Date())
  const amanha = somarDias(hoje, 1)
  const depoisDeAmanha = somarDias(hoje, 2)
  const semana = somarDias(hoje, 8)

  const g: Record<string, Atividade[]> = {
    'Atrasadas': [], 'Hoje': [], 'Amanhã': [], 'Próximos 7 dias': [], 'Mais adiante': [], 'Sem data': [],
  }
  for (const a of itens) {
    const d = ref(a)
    if (!d) g['Sem data'].push(a)
    else if (atrasada(a) && d < hoje) g['Atrasadas'].push(a)
    else if (d < amanha) g['Hoje'].push(a)
    else if (d < depoisDeAmanha) g['Amanhã'].push(a)
    else if (d < semana) g['Próximos 7 dias'].push(a)
    else g['Mais adiante'].push(a)
  }

  const momento = (a: Atividade) => {
    const d = ref(a)
    return d ? (inicioEm(a, d) ?? d) : null
  }
  const ordenar = (lista: Atividade[]) =>
    lista.sort((a, b) => {
      const da = momento(a)
      const db = momento(b)
      if (da && db) {
        if (inicioDoDia(da).getTime() === inicioDoDia(db).getTime() && a.temHorario !== b.temHorario) return a.temHorario ? -1 : 1
        if (da.getTime() !== db.getTime()) return da.getTime() - db.getTime()
      }
      return b.prioridade - a.prioridade
    })

  return Object.entries(g)
    .map(([t, l]) => [t, t === 'Sem data' ? l.sort((a, b) => b.prioridade - a.prioridade) : ordenar(l)] as [string, Atividade[]])
    .filter(([, l]) => l.length > 0)
}
