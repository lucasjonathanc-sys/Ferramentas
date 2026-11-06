// Atalhos e situação de pagamento dos clientes (CRM).
import type { Cliente } from './modelo'

const comHttp = (s: string) => (/^https?:\/\//i.test(s) ? s : `https://${s}`)
const usuario = (s: string) => s.trim().replace(/^@/, '').replace(/^https?:\/\/(www\.)?(instagram|tiktok)\.com\/@?/i, '').replace(/\/$/, '')

export interface Atalho {
  chave: string
  titulo: string
  icone: string
  url: string
}

/** Botões rápidos com os dados preenchidos do cliente. */
export function atalhosDoCliente(c: Cliente): Atalho[] {
  const lista: Atalho[] = []
  const digitos = c.contato.replace(/\D/g, '')
  if (digitos.length >= 10) {
    lista.push({ chave: 'whats', titulo: 'WhatsApp', icone: 'mensagem', url: `https://wa.me/${digitos.length <= 11 ? '55' + digitos : digitos}` })
  }
  if (c.instagram.trim()) lista.push({ chave: 'insta', titulo: 'Instagram', icone: 'camera', url: `https://instagram.com/${usuario(c.instagram)}` })
  if (c.tiktok.trim()) lista.push({ chave: 'tiktok', titulo: 'TikTok', icone: 'play', url: `https://www.tiktok.com/@${usuario(c.tiktok)}` })
  if (c.email.trim()) lista.push({ chave: 'email', titulo: 'E-mail', icone: 'email', url: `mailto:${c.email.trim()}` })
  if (c.site.trim()) lista.push({ chave: 'site', titulo: 'Site', icone: 'globo', url: comHttp(c.site.trim()) })
  if (c.endereco.trim()) lista.push({ chave: 'mapa', titulo: 'Mapa', icone: 'pino', url: `https://maps.apple.com/?q=${encodeURIComponent(c.endereco.trim())}` })
  if (c.linkDrive.trim()) lista.push({ chave: 'drive', titulo: 'Drive', icone: 'pasta', url: comHttp(c.linkDrive.trim()) })
  if (c.linkCanva.trim()) lista.push({ chave: 'canva', titulo: 'Canva', icone: 'pincel', url: comHttp(c.linkCanva.trim()) })
  if (c.linkFotos.trim()) lista.push({ chave: 'fotos', titulo: 'Fotos', icone: 'foto', url: comHttp(c.linkFotos.trim()) })
  return lista
}

export const mesAtual = (d = new Date()) => `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}`

export type SituacaoPagamento = { tipo: 'pago' | 'pendente' | 'atrasado'; texto: string } | null

/** Situação do pagamento do mês atual (só para quem tem valor mensal). */
export function situacaoPagamento(c: Cliente, hoje = new Date()): SituacaoPagamento {
  if (!c.valorMensal) return null
  if (c.pagamentos.includes(mesAtual(hoje))) return { tipo: 'pago', texto: 'Pago este mês' }
  if (!c.diaPagamento) return { tipo: 'pendente', texto: 'Pagamento do mês pendente' }
  const ultimoDia = new Date(hoje.getFullYear(), hoje.getMonth() + 1, 0).getDate()
  const dia = Math.min(c.diaPagamento, ultimoDia)
  if (hoje.getDate() > dia) return { tipo: 'atrasado', texto: `Pagamento atrasado (dia ${dia})` }
  if (hoje.getDate() === dia) return { tipo: 'pendente', texto: 'Pagamento vence hoje' }
  return { tipo: 'pendente', texto: `Pagamento vence dia ${dia}` }
}

export const corSituacao = (s: NonNullable<SituacaoPagamento>) =>
  s.tipo === 'pago' ? 'var(--sucesso)' : s.tipo === 'atrasado' ? 'var(--alerta)' : 'var(--texto2)'

/** "11999998888" → "(11) 99999-8888" (mantém o texto se não for um celular/telefone BR). */
export function formatarTelefone(t: string): string {
  let d = t.replace(/\D/g, '')
  if (d.length > 11 && d.startsWith('55')) d = d.slice(2)
  if (d.length === 11) return `(${d.slice(0, 2)}) ${d.slice(2, 7)}-${d.slice(7)}`
  if (d.length === 10) return `(${d.slice(0, 2)}) ${d.slice(2, 6)}-${d.slice(6)}`
  return t
}
