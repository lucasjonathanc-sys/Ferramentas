import type { ReactNode } from 'react'
import type { Cliente } from '../modelo'
import { atalhosDoCliente, corSituacao, formatarTelefone, situacaoPagamento } from '../cliente'
import { Icone } from './Base'

const iniciais = (nome: string) =>
  nome.split(' ').filter(Boolean).slice(0, 2).map((p) => p[0]).join('').toUpperCase() || '?'

export function AvatarCliente({ cliente, tamanho = 46 }: { cliente: Pick<Cliente, 'nome' | 'cor'>; tamanho?: number }) {
  return (
    <span
      className="avatar-cliente"
      style={{
        width: tamanho, height: tamanho, fontSize: tamanho * 0.38,
        color: cliente.cor, background: `color-mix(in srgb, ${cliente.cor} 15%, transparent)`,
      }}
    >
      {iniciais(cliente.nome)}
    </span>
  )
}

/** Botões rápidos: WhatsApp, Instagram, TikTok, e-mail, site, mapa, Drive, Canva, fotos. */
export function BotoesCliente({ cliente }: { cliente: Cliente }) {
  const atalhos = atalhosDoCliente(cliente)
  if (!atalhos.length) return null
  return (
    <div className="atalhos">
      {atalhos.map((a) => (
        <a key={a.chave} className="atalho" href={a.url} target="_blank" rel="noreferrer" onClick={(e) => e.stopPropagation()}>
          <span className="atalho-icone" style={{ color: cliente.cor, background: `color-mix(in srgb, ${cliente.cor} 13%, transparent)` }}>
            <Icone nome={a.icone} tamanho={18} />
          </span>
          <span>{a.titulo}</span>
        </a>
      ))}
    </div>
  )
}

function Linha({ rotulo, children }: { rotulo: string; children: ReactNode }) {
  return (
    <div className="dado">
      <span className="dado-rotulo">{rotulo}</span>
      <span className="dado-valor">{children}</span>
    </div>
  )
}

/** Resumo do perfil, mostrado dentro da atividade quando ela tem cliente. */
export function CartaoCliente({ cliente }: { cliente: Cliente }) {
  const situacao = situacaoPagamento(cliente)
  const dados: [string, string][] = [
    ['Responsável', cliente.responsavel],
    ['WhatsApp', formatarTelefone(cliente.contato)],
    ['Serviços', cliente.servicos],
    ['Tom de voz', cliente.tomDeVoz],
    ['Público', cliente.publicoAlvo],
    ['Cores', cliente.cores],
    ['Fontes', cliente.fontes],
    ['Postagens', cliente.diasPostagem],
    ['Endereço', cliente.endereco],
  ]
  const preenchidos = dados.filter(([, v]) => v.trim())

  return (
    <div className="card cartao-cliente" style={{ borderColor: `color-mix(in srgb, ${cliente.cor} 35%, var(--borda))` }}>
      <div className="linha" style={{ gap: 12 }}>
        <AvatarCliente cliente={cliente} tamanho={42} />
        <div style={{ flex: 1, minWidth: 0 }}>
          <div style={{ fontFamily: 'var(--titulo)', fontSize: 18 }}>{cliente.nome}</div>
          {cliente.nicho && <div className="pequeno texto2">{cliente.nicho}</div>}
        </div>
      </div>
      {situacao && (
        <div className="pequeno" style={{ color: corSituacao(situacao), marginTop: 10 }}>● {situacao.texto}</div>
      )}
      {preenchidos.length > 0 && (
        <div className="dados" style={{ marginTop: 10 }}>
          {preenchidos.map(([r, v]) => <Linha key={r} rotulo={r}>{v}</Linha>)}
        </div>
      )}
      <div style={{ marginTop: 12 }}><BotoesCliente cliente={cliente} /></div>
      {!preenchidos.length && !atalhosDoCliente(cliente).length && (
        <div className="pequeno texto2" style={{ marginTop: 6 }}>
          Complete o perfil na aba Clientes para os dados aparecerem aqui.
        </div>
      )}
    </div>
  )
}

export { Linha as LinhaDado }
