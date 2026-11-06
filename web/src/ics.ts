// Gera um arquivo .ics para adicionar a atividade ao Calendário do iPhone,
// com os lembretes como alarmes (assim os avisos chegam mesmo com o app fechado).
import { type Atividade, type Cliente, dataDe, fimEfetivo, somarDias } from './modelo'

const p2 = (n: number) => String(n).padStart(2, '0')
const dataLocal = (d: Date) => `${d.getFullYear()}${p2(d.getMonth() + 1)}${p2(d.getDate())}`
const dataHoraLocal = (d: Date) => `${dataLocal(d)}T${p2(d.getHours())}${p2(d.getMinutes())}00`
const dataHoraUTC = (d: Date) =>
  `${d.getUTCFullYear()}${p2(d.getUTCMonth() + 1)}${p2(d.getUTCDate())}T${p2(d.getUTCHours())}${p2(d.getUTCMinutes())}${p2(d.getUTCSeconds())}Z`

const escapar = (s: string) => s.replace(/\\/g, '\\\\').replace(/\n/g, '\\n').replace(/,/g, '\\,').replace(/;/g, '\\;')

function regra(a: Atividade): string | null {
  switch (a.repeticao) {
    case 'nunca': return null
    case 'diaria': return 'RRULE:FREQ=DAILY'
    case 'diasUteis': return 'RRULE:FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR'
    case 'semanal': return 'RRULE:FREQ=WEEKLY'
    case 'mensal': return 'RRULE:FREQ=MONTHLY'
    case 'anual': return 'RRULE:FREQ=YEARLY'
  }
}

export function gerarICS(a: Atividade, cliente?: Cliente | null): string | null {
  const inicio = dataDe(a)
  if (!inicio) return null

  const linhas = [
    'BEGIN:VCALENDAR',
    'VERSION:2.0',
    'PRODID:-//DB. Organiza//PT-BR',
    'CALSCALE:GREGORIAN',
    'METHOD:PUBLISH',
    'BEGIN:VEVENT',
    `UID:${a.id}@hb-organiza`,
    `DTSTAMP:${dataHoraUTC(new Date())}`,
  ]

  if (a.temHorario) {
    const fim = fimEfetivo(a) ?? new Date(inicio.getTime() + 30 * 60000)
    linhas.push(`DTSTART:${dataHoraLocal(inicio)}`, `DTEND:${dataHoraLocal(fim)}`)
  } else {
    linhas.push(`DTSTART;VALUE=DATE:${dataLocal(inicio)}`, `DTEND;VALUE=DATE:${dataLocal(somarDias(inicio, 1))}`)
  }

  const titulo = a.tipo === 'tarefa' ? `✓ ${a.titulo}` : a.titulo
  linhas.push(`SUMMARY:${escapar(titulo)}`)

  const lista = a.checklist.map((i) => `${i.feito ? '☑' : '☐'} ${i.texto}`).join('\n')
  const partes = [a.contexto, cliente?.nome, a.descricao, lista, a.link].filter(Boolean) as string[]
  if (partes.length) linhas.push(`DESCRIPTION:${escapar(partes.join('\n'))}`)
  if (a.local) linhas.push(`LOCATION:${escapar(a.local)}`)
  if (a.link) linhas.push(`URL:${a.link.startsWith('http') ? a.link : `https://${a.link}`}`)
  const r = regra(a)
  if (r) linhas.push(r)

  for (const min of a.lembretes) {
    // Sem horário: lembrete relativo às 9h do dia (evento de dia inteiro começa à 0h)
    const minutos = a.temHorario ? min : min - 9 * 60
    const gatilho = minutos >= 0 ? `-PT${minutos}M` : `PT${-minutos}M`
    linhas.push('BEGIN:VALARM', 'ACTION:DISPLAY', `DESCRIPTION:${escapar(a.titulo)}`, `TRIGGER:${gatilho}`, 'END:VALARM')
  }

  linhas.push('END:VEVENT', 'END:VCALENDAR')
  return linhas.join('\r\n')
}

/** Abre o .ics; no iPhone aparece a opção "Adicionar ao Calendário". */
export function abrirNoCalendario(a: Atividade, cliente?: Cliente | null) {
  const ics = gerarICS(a, cliente)
  if (!ics) return
  const nome = (a.titulo || 'atividade').replace(/[^\p{L}\p{N} _-]/gu, '').slice(0, 40) || 'atividade'
  const arquivo = new Blob([ics], { type: 'text/calendar;charset=utf-8' })
  const url = URL.createObjectURL(arquivo)
  const link = document.createElement('a')
  link.href = url
  link.download = `${nome}.ics`
  document.body.appendChild(link)
  link.click()
  link.remove()
  setTimeout(() => URL.revokeObjectURL(url), 10000)
}
