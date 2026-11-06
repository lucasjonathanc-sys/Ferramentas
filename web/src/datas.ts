// Formatação de datas em português.
import { inicioDoDia, mesmoDia, somarDias } from './modelo'

const LOCALE = 'pt-BR'

const cap = (s: string) => (s ? s[0].toLocaleUpperCase(LOCALE) + s.slice(1) : s)
const semPonto = (s: string) => s.replace(/\./g, '')

export const hora = (d: Date) =>
  `${String(d.getHours()).padStart(2, '0')}:${String(d.getMinutes()).padStart(2, '0')}`

export const dataPorExtenso = (d: Date) =>
  cap(d.toLocaleDateString(LOCALE, { weekday: 'long', day: 'numeric', month: 'long' }))

export const diaCurto = (d: Date) => cap(semPonto(d.toLocaleDateString(LOCALE, { weekday: 'short' })))

export const diaMes = (d: Date) => semPonto(d.toLocaleDateString(LOCALE, { day: 'numeric', month: 'short' }))

export const diaMesLongo = (d: Date) => d.toLocaleDateString(LOCALE, { day: 'numeric', month: 'long' })

export const mesAno = (d: Date) => cap(d.toLocaleDateString(LOCALE, { month: 'long', year: 'numeric' }))

export const dataCampo = (d: Date) =>
  d.toLocaleDateString(LOCALE, { day: 'numeric', month: 'short', year: 'numeric' })

/** "Hoje · 18:00", "Amanhã", "Ontem", "12 nov · 14:00" */
export function quando(d: Date, temHorario: boolean): string {
  const h = temHorario ? ` · ${hora(d)}` : ''
  const hoje = new Date()
  if (mesmoDia(d, hoje)) return 'Hoje' + h
  if (mesmoDia(d, somarDias(hoje, 1))) return 'Amanhã' + h
  if (mesmoDia(d, somarDias(hoje, -1))) return 'Ontem' + h
  return diaMes(d) + h
}

/** "5 a 7 de novembro", "30 out a 1 nov" */
export function intervalo(a: Date, b: Date): string {
  if (mesmoDia(a, b)) return diaMesLongo(a)
  if (a.getMonth() === b.getMonth()) return `${a.getDate()} a ${diaMesLongo(b)}`
  return `${diaMes(a)} a ${diaMes(b)}`
}

export const dinheiro = (v: number) => v.toLocaleString(LOCALE, { style: 'currency', currency: 'BRL' })

/** yyyy-mm-dd para <input type="date"> */
export const paraInputData = (d: Date) =>
  `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`

export const deInputData = (s: string): Date => {
  const [y, m, d] = s.split('-').map(Number)
  return new Date(y, (m || 1) - 1, d || 1)
}

export const paraInputHora = (d: Date) => hora(d)

export const deInputHora = (s: string): [number, number] => {
  const [h, m] = s.split(':').map(Number)
  return [h || 0, m || 0]
}

export const hojeZero = () => inicioDoDia(new Date())
