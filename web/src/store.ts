// Estado do app, salvo no próprio iPhone (localStorage).
import { useSyncExternalStore } from 'react'
import {
  type Atividade, type Cliente, type ColunaQuadro, aberta, dataDe, ehCompromisso, normalizarAtividade, normalizarCliente, novoId, proximaData,
} from './modelo'

const CHAVE = 'hb-organiza-v1'

export interface Estado {
  atividades: Atividade[]
  clientes: Cliente[]
  nome: string
}

const vazio: Estado = { atividades: [], clientes: [], nome: 'Hanna' }

function carregar(): Estado {
  try {
    const bruto = localStorage.getItem(CHAVE)
    if (!bruto) return vazio
    const dados = JSON.parse(bruto)
    return {
      atividades: Array.isArray(dados.atividades) ? dados.atividades.map(normalizarAtividade) : [],
      clientes: Array.isArray(dados.clientes) ? dados.clientes.map(normalizarCliente) : [],
      nome: typeof dados.nome === 'string' ? dados.nome : 'Hanna',
    }
  } catch {
    return vazio
  }
}

let estado: Estado = carregar()
const ouvintes = new Set<() => void>()

function definir(novo: Estado) {
  estado = novo
  try {
    localStorage.setItem(CHAVE, JSON.stringify(estado))
  } catch {
    // armazenamento cheio ou bloqueado: mantém em memória
  }
  ouvintes.forEach((f) => f())
}

export function useEstado(): Estado {
  return useSyncExternalStore(
    (f) => {
      ouvintes.add(f)
      return () => ouvintes.delete(f)
    },
    () => estado,
  )
}

/** Pede ao navegador para não apagar os dados sozinho. */
export function pedirArmazenamentoPersistente() {
  try {
    navigator.storage?.persist?.()
  } catch {
    // ignora
  }
}

// MARK: - Atividades

export function salvarAtividade(a: Atividade) {
  const existe = estado.atividades.some((x) => x.id === a.id)
  definir({
    ...estado,
    atividades: existe ? estado.atividades.map((x) => (x.id === a.id ? a : x)) : [...estado.atividades, a],
  })
}

export function apagarAtividade(id: string) {
  definir({ ...estado, atividades: estado.atividades.filter((x) => x.id !== id) })
}

/** Conclui (ou reabre) uma tarefa. Se ela se repete, cria a próxima. */
export function alternarConclusao(id: string) {
  const a = estado.atividades.find((x) => x.id === id)
  if (!a) return
  if (a.status === 'concluida') {
    salvarAtividade({ ...a, status: 'aberta', concluidaEm: null })
    return
  }
  const concluida: Atividade = { ...a, status: 'concluida', concluidaEm: new Date().toISOString() }
  const d = dataDe(a)
  const proxima = !ehCompromisso(a) && a.repeticao !== 'nunca' && d ? proximaData(a.repeticao, d) : null
  if (proxima) {
    const nova: Atividade = {
      ...a,
      id: novoId(),
      status: 'aberta',
      etapa: 'aFazer',
      data: proxima.toISOString(),
      criadaEm: new Date().toISOString(),
      concluidaEm: null,
    }
    concluida.repeticao = 'nunca' // quem repete agora é a nova
    definir({
      ...estado,
      atividades: [...estado.atividades.map((x) => (x.id === id ? concluida : x)), nova],
    })
  } else {
    salvarAtividade(concluida)
  }
}

export function alternarCancelamento(id: string) {
  const a = estado.atividades.find((x) => x.id === id)
  if (!a) return
  salvarAtividade({ ...a, status: a.status === 'cancelada' ? 'aberta' : 'cancelada', concluidaEm: null })
}

/** Apaga concluídas/canceladas e compromissos passados há mais de 30 dias. */
export function itensAntigos(): Atividade[] {
  const limite = Date.now() - 30 * 86400000
  return estado.atividades.filter((a) => {
    if (a.status === 'concluida') return new Date(a.concluidaEm ?? a.criadaEm).getTime() < limite
    if (a.status === 'cancelada') return new Date(a.criadaEm).getTime() < limite
    if (aberta(a) && ehCompromisso(a) && a.repeticao === 'nunca' && a.data) {
      return new Date(a.fim ?? a.data).getTime() < limite
    }
    return false
  })
}

export function limparAntigos() {
  const ids = new Set(itensAntigos().map((a) => a.id))
  definir({ ...estado, atividades: estado.atividades.filter((a) => !ids.has(a.id)) })
}

// MARK: - Clientes

export function salvarCliente(c: Cliente) {
  const existe = estado.clientes.some((x) => x.id === c.id)
  definir({
    ...estado,
    clientes: existe ? estado.clientes.map((x) => (x.id === c.id ? c : x)) : [...estado.clientes, c],
  })
}

/** Apaga o cliente; as atividades continuam, só que sem cliente. */
export function apagarCliente(id: string) {
  definir({
    ...estado,
    clientes: estado.clientes.filter((c) => c.id !== id),
    atividades: estado.atividades.map((a) => (a.clienteId === id ? { ...a, clienteId: null } : a)),
  })
}

// MARK: - Ajustes e backup

export function definirNome(nome: string) {
  definir({ ...estado, nome })
}

export function exportarBackup(): string {
  return JSON.stringify({ app: 'DB. Organiza', versao: 1, exportadoEm: new Date().toISOString(), ...estado }, null, 2)
}

/** Restaura um backup. Retorna false se o arquivo não for válido. */
export function importarBackup(texto: string): boolean {
  try {
    const dados = JSON.parse(texto)
    if (!Array.isArray(dados.atividades) || !Array.isArray(dados.clientes)) return false
    definir({
      atividades: dados.atividades.map(normalizarAtividade),
      clientes: dados.clientes.map(normalizarCliente),
      nome: typeof dados.nome === 'string' ? dados.nome : estado.nome,
    })
    return true
  } catch {
    return false
  }
}

/** Marca ou desmarca um mês (yyyy-mm) como pago. */
export function alternarPagamento(clienteId: string, mes: string) {
  const c = estado.clientes.find((x) => x.id === clienteId)
  if (!c) return
  const pagamentos = c.pagamentos.includes(mes) ? c.pagamentos.filter((m) => m !== mes) : [...c.pagamentos, mes]
  salvarCliente({ ...c, pagamentos })
}

/** Move a tarefa para uma coluna do quadro. "Feito" conclui; sair de "Feito" reabre. */
export function moverParaColuna(id: string, coluna: ColunaQuadro) {
  const a = estado.atividades.find((x) => x.id === id)
  if (!a || ehCompromisso(a)) return
  if (coluna === 'feito') {
    if (a.status !== 'concluida') alternarConclusao(id)
    return
  }
  salvarAtividade({ ...a, etapa: coluna, status: 'aberta', concluidaEm: null })
}

/** Marca ou desmarca um item do checklist de um compromisso. */
export function alternarItemChecklist(atividadeId: string, itemId: string) {
  const a = estado.atividades.find((x) => x.id === atividadeId)
  if (!a) return
  salvarAtividade({ ...a, checklist: a.checklist.map((i) => (i.id === itemId ? { ...i, feito: !i.feito } : i)) })
}

/** Cria um cartão rápido no quadro: só o título, sem data e sem lembrete. */
export function criarCartaoRapido(titulo: string, etapa: Exclude<ColunaQuadro, 'feito'>) {
  const texto = titulo.trim()
  if (!texto) return
  salvarAtividade({
    id: novoId(),
    tipo: 'tarefa',
    titulo: texto,
    descricao: '',
    contexto: 'China Link',
    status: 'aberta',
    prioridade: 1,
    data: null,
    temHorario: false,
    fim: null,
    repeticao: 'nunca',
    lembretes: [],
    local: '',
    link: '',
    clienteId: null,
    criadaEm: new Date().toISOString(),
    concluidaEm: null,
    etapa,
    checklist: [],
  })
}
