// Modelo de dados e regras do app (mesma lógica da versão em Swift).

export type Contexto = 'China Link' | 'Clientes' | 'Pessoal' | 'Faculdade' | 'Igreja'
export type Tipo = 'tarefa' | 'compromisso'
export type Status = 'aberta' | 'concluida' | 'cancelada'
export type Prioridade = 0 | 1 | 2
export type Repeticao = 'nunca' | 'diaria' | 'diasUteis' | 'semanal' | 'mensal' | 'anual'
/** Etapa da tarefa no quadro (estilo Trello). "Feito" é a tarefa concluída. */
export type Etapa = 'aFazer' | 'fazendo' | 'aprovacao'
export type ColunaQuadro = Etapa | 'feito'

export const COLUNAS: { valor: ColunaQuadro; nome: string }[] = [
  { valor: 'aFazer', nome: 'A fazer' },
  { valor: 'fazendo', nome: 'Fazendo' },
  { valor: 'aprovacao', nome: 'Em aprovação' },
  { valor: 'feito', nome: 'Feito' },
]

export const nomeColuna = (c: ColunaQuadro) => COLUNAS.find((x) => x.valor === c)?.nome ?? ''

export interface ItemChecklist {
  id: string
  texto: string
  feito: boolean
}

export const CONTEXTOS: { nome: Contexto; cor: string }[] = [
  { nome: 'China Link', cor: 'var(--vinho)' },
  { nome: 'Clientes', cor: '#B08968' },
  { nome: 'Pessoal', cor: '#5E7556' },
  { nome: 'Faculdade', cor: '#4F5D75' },
  { nome: 'Igreja', cor: '#B8975A' },
]

export const corContexto = (c: Contexto) => CONTEXTOS.find((x) => x.nome === c)?.cor ?? 'var(--taupe)'

export const PRIORIDADES: { valor: Prioridade; nome: string }[] = [
  { valor: 0, nome: 'Baixa' },
  { valor: 1, nome: 'Média' },
  { valor: 2, nome: 'Alta' },
]

export const REPETICOES: { valor: Repeticao; nome: string; curto: string }[] = [
  { valor: 'nunca', nome: 'Não se repete', curto: '' },
  { valor: 'diaria', nome: 'Todo dia', curto: 'Diária' },
  { valor: 'diasUteis', nome: 'Dias úteis (seg a sex)', curto: 'Dias úteis' },
  { valor: 'semanal', nome: 'Toda semana', curto: 'Semanal' },
  { valor: 'mensal', nome: 'Todo mês', curto: 'Mensal' },
  { valor: 'anual', nome: 'Todo ano', curto: 'Anual' },
]

export const OPCOES_LEMBRETE = [0, 5, 15, 30, 60, 120, 1440, 2880]

export function nomeLembrete(min: number): string {
  if (min === 0) return 'Na hora'
  if (min === 1440) return '1 dia antes'
  if (min === 2880) return '2 dias antes'
  if (min >= 60 && min % 60 === 0) return `${min / 60} h antes`
  return `${min} min antes`
}

export const PALETA_CLIENTES = [
  '#7A0E15', '#82766B', '#B08968', '#4F5D75', '#C2A878',
  '#5E7556', '#A85C5C', '#3E3A39', '#9C8A7A', '#6D4C5C',
]

export interface Atividade {
  id: string
  tipo: Tipo
  titulo: string
  descricao: string
  contexto: Contexto
  status: Status
  prioridade: Prioridade
  /** Vencimento (tarefa) ou início (compromisso), em ISO. Tarefa pode não ter data. */
  data: string | null
  /** Se false, a atividade é "sem hora" (só o dia importa). */
  temHorario: boolean
  /** Fim do compromisso (ISO). */
  fim: string | null
  repeticao: Repeticao
  /** Minutos antes de cada lembrete. */
  lembretes: number[]
  local: string
  link: string
  clienteId: string | null
  criadaEm: string
  concluidaEm: string | null
  /** Etapa da tarefa aberta no quadro. */
  etapa: Etapa
  /** Checklist do compromisso. */
  checklist: ItemChecklist[]
}

/** Completa atividades salvas em versões antigas com os campos novos. */
export function normalizarAtividade(a: Atividade): Atividade {
  const etapas: Etapa[] = ['aFazer', 'fazendo', 'aprovacao']
  return {
    ...a,
    etapa: etapas.includes(a.etapa) ? a.etapa : 'aFazer',
    checklist: Array.isArray(a.checklist)
      ? a.checklist.filter((i) => i && typeof i.texto === 'string').map((i) => ({ id: i.id || novoId(), texto: i.texto, feito: !!i.feito }))
      : [],
  }
}

/** Coluna do quadro em que a tarefa aparece. */
export const colunaDe = (a: Atividade): ColunaQuadro => (a.status === 'concluida' ? 'feito' : a.etapa)

export interface Cliente {
  id: string
  nome: string
  nicho: string
  cor: string
  ativo: boolean
  criadoEm: string

  // Contato
  responsavel: string
  /** WhatsApp / telefone */
  contato: string
  email: string
  instagram: string
  tiktok: string
  site: string
  endereco: string

  // Contrato e pagamento
  servicos: string
  valorMensal: number
  /** Dia do mês em que o cliente paga (1–31), ou null. */
  diaPagamento: number | null
  /** Início do contrato (yyyy-mm-dd), ou ''. */
  inicioContrato: string
  /** Meses já pagos, no formato yyyy-mm. */
  pagamentos: string[]

  // Identidade da marca
  cores: string
  fontes: string
  tomDeVoz: string
  publicoAlvo: string
  diasPostagem: string
  linkDrive: string
  linkCanva: string
  linkFotos: string

  observacoes: string
}

/** Completa clientes salvos em versões antigas com os campos novos. */
export function normalizarCliente(c: Partial<Cliente>): Cliente {
  const texto = (v: unknown) => (typeof v === 'string' ? v : '')
  return {
    id: c.id ?? novoId(),
    nome: texto(c.nome),
    nicho: texto(c.nicho),
    cor: texto(c.cor) || '#82766B',
    ativo: c.ativo !== false,
    criadoEm: texto(c.criadoEm) || new Date().toISOString(),
    responsavel: texto(c.responsavel),
    contato: texto(c.contato),
    email: texto(c.email),
    instagram: texto(c.instagram),
    tiktok: texto(c.tiktok),
    site: texto(c.site),
    endereco: texto(c.endereco),
    servicos: texto(c.servicos),
    valorMensal: typeof c.valorMensal === 'number' ? c.valorMensal : 0,
    diaPagamento: typeof c.diaPagamento === 'number' ? c.diaPagamento : null,
    inicioContrato: texto(c.inicioContrato),
    pagamentos: Array.isArray(c.pagamentos) ? c.pagamentos.filter((x): x is string => typeof x === 'string') : [],
    cores: texto(c.cores),
    fontes: texto(c.fontes),
    tomDeVoz: texto(c.tomDeVoz),
    publicoAlvo: texto(c.publicoAlvo),
    diasPostagem: texto(c.diasPostagem),
    linkDrive: texto(c.linkDrive),
    linkCanva: texto(c.linkCanva),
    linkFotos: texto(c.linkFotos),
    observacoes: texto(c.observacoes),
  }
}

export const novoId = () =>
  (typeof crypto !== 'undefined' && 'randomUUID' in crypto)
    ? crypto.randomUUID()
    : `${Date.now().toString(36)}-${Math.random().toString(36).slice(2, 10)}`

// MARK: - Datas

export const inicioDoDia = (d: Date) => new Date(d.getFullYear(), d.getMonth(), d.getDate())
export const somarDias = (d: Date, n: number) => {
  const r = new Date(d)
  r.setDate(r.getDate() + n)
  return r
}
export const somarMeses = (d: Date, n: number) => {
  const r = new Date(d)
  r.setMonth(r.getMonth() + n)
  return r
}
export const mesmoDia = (a: Date, b: Date) =>
  a.getFullYear() === b.getFullYear() && a.getMonth() === b.getMonth() && a.getDate() === b.getDate()
export const ehHoje = (d: Date) => mesmoDia(d, new Date())
export const fimDeSemana = (d: Date) => d.getDay() === 0 || d.getDay() === 6
export const comHora = (dia: Date, h: number, m: number) =>
  new Date(dia.getFullYear(), dia.getMonth(), dia.getDate(), h, m, 0, 0)

export function proximaData(rep: Repeticao, data: Date): Date | null {
  switch (rep) {
    case 'nunca': return null
    case 'diaria': return somarDias(data, 1)
    case 'diasUteis': {
      let d = somarDias(data, 1)
      while (fimDeSemana(d)) d = somarDias(d, 1)
      return d
    }
    case 'semanal': return somarDias(data, 7)
    case 'mensal': return somarMeses(data, 1)
    case 'anual': return somarMeses(data, 12)
  }
}

/** Se uma atividade que começa em `inicio` acontece também em `dia`. */
export function ocorre(rep: Repeticao, inicio: Date, dia: Date): boolean {
  const di = inicioDoDia(inicio).getTime()
  const alvoD = inicioDoDia(dia)
  const alvo = alvoD.getTime()
  if (alvo === di) return true
  if (alvo < di) return false
  switch (rep) {
    case 'nunca': return false
    case 'diaria': return true
    case 'diasUteis': return !fimDeSemana(alvoD)
    case 'semanal': return alvoD.getDay() === inicio.getDay()
    case 'mensal': return alvoD.getDate() === inicio.getDate()
    case 'anual': return alvoD.getDate() === inicio.getDate() && alvoD.getMonth() === inicio.getMonth()
  }
}

// MARK: - Regras de Atividade

export const ehCompromisso = (a: Atividade) => a.tipo === 'compromisso'
export const aberta = (a: Atividade) => a.status === 'aberta'
export const dataDe = (a: Atividade) => (a.data ? new Date(a.data) : null)

export function fimEfetivo(a: Atividade): Date | null {
  const d = dataDe(a)
  if (!d) return null
  if (a.fim) {
    const f = new Date(a.fim)
    if (f > d) return f
  }
  return new Date(d.getTime() + (ehCompromisso(a) ? 60 : 30) * 60000)
}

export function atrasada(a: Atividade): boolean {
  const d = dataDe(a)
  if (!aberta(a) || ehCompromisso(a) || !d) return false
  if (a.temHorario) return d < new Date()
  return inicioDoDia(d) < inicioDoDia(new Date())
}

export function jaPassou(a: Atividade): boolean {
  if (!ehCompromisso(a) || a.repeticao !== 'nunca') return false
  const f = fimEfetivo(a)
  return !!f && f < new Date()
}

export function aparece(a: Atividade, dia: Date): boolean {
  const d = dataDe(a)
  if (!d) return false
  if (ehCompromisso(a)) return ocorre(a.repeticao, d, dia)
  return mesmoDia(d, dia)
}

/** Horário de início numa data específica (para repetições). */
export function inicioEm(a: Atividade, dia: Date): Date | null {
  const d = dataDe(a)
  if (!d) return null
  return comHora(dia, d.getHours(), d.getMinutes())
}

/** Próximo dia (a partir de hoje) em que um compromisso repetido acontece. */
export function proximaOcorrencia(a: Atividade, aPartirDe = new Date()): Date | null {
  const d = dataDe(a)
  if (!d) return null
  if (!ehCompromisso(a) || a.repeticao === 'nunca') return d
  let dia = new Date(Math.max(inicioDoDia(aPartirDe).getTime(), inicioDoDia(d).getTime()))
  for (let i = 0; i < 400; i++) {
    if (ocorre(a.repeticao, d, dia)) return dia
    dia = somarDias(dia, 1)
  }
  return d
}

/** Momento base dos lembretes (sem horário: 9h do dia). */
export function momentoLembrete(a: Atividade): Date | null {
  const d = dataDe(a)
  if (!d) return null
  return a.temHorario ? d : comHora(d, 9, 0)
}

export function ordenacao(a: Atividade, b: Atividade): number {
  if (aberta(a) !== aberta(b)) return aberta(a) ? -1 : 1
  const da = dataDe(a)
  const db = dataDe(b)
  if (da && db) {
    const ca = inicioDoDia(da).getTime()
    const cb = inicioDoDia(db).getTime()
    if (ca !== cb) return ca - cb
    if (a.temHorario !== b.temHorario) return a.temHorario ? -1 : 1
    if (da.getTime() !== db.getTime()) return da.getTime() - db.getTime()
  } else if (da && !db) return -1
  else if (!da && db) return 1
  if (a.prioridade !== b.prioridade) return b.prioridade - a.prioridade
  return b.criadaEm.localeCompare(a.criadaEm)
}
