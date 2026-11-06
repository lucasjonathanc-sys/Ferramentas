import { useState } from 'react'
import { useApp } from '../contexto'
import { useEstado, salvarCliente, apagarCliente } from '../store'
import { Cabecalho, EstadoVazio, Folha, Icone, ListaAtividades, Segmento, TituloSecao } from '../componentes/Base'
import { type Cliente, PALETA_CLIENTES, aberta, atrasada, dataDe, jaPassou, novoId, ordenacao } from '../modelo'
import { dinheiro, quando } from '../datas'

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

export function Clientes() {
  const app = useApp()
  const { clientes, atividades } = useEstado()
  const [busca, setBusca] = useState('')
  const [grupo, setGrupo] = useState<'ativos' | 'arquivados'>('ativos')
  const [abertoId, setAbertoId] = useState<string | null>(null)

  const aberto = clientes.find((c) => c.id === abertoId)
  if (aberto) return <ClienteDetalhe cliente={aberto} voltar={() => setAbertoId(null)} />

  const ativos = clientes.filter((c) => c.ativo)
  const arquivados = clientes.filter((c) => !c.ativo)
  const termo = busca.trim().toLocaleLowerCase('pt-BR')
  const visiveis = (grupo === 'ativos' ? ativos : arquivados)
    .filter((c) => !termo || c.nome.toLocaleLowerCase('pt-BR').includes(termo) || c.nicho.toLocaleLowerCase('pt-BR').includes(termo))
    .sort((a, b) => a.nome.localeCompare(b.nome))
  const receita = ativos.reduce((s, c) => s + (c.valorMensal || 0), 0)

  return (
    <div className="conteudo">
      <div className="pilha" style={{ gap: 16 }}>
        <Cabecalho
          titulo="Clientes"
          busca={{ valor: busca, definir: setBusca, placeholder: 'Buscar cliente' }}
          extra={
            <button className="circulo" onClick={() => app.abrir({ tipo: 'cliente' })} aria-label="Novo cliente">
              <Icone nome="mais" tamanho={18} />
            </button>
          }
        />
        <Segmento
          opcoes={[{ valor: 'ativos' as const, titulo: `Ativos · ${ativos.length}` }, { valor: 'arquivados' as const, titulo: 'Arquivados' }]}
          valor={grupo}
          definir={setGrupo}
        />

        {grupo === 'ativos' && receita > 0 && (
          <div className="card linha">
            <span className="medio texto2">Renda extra mensal</span>
            <span className="espaco" />
            <span style={{ fontFamily: 'var(--titulo)', fontSize: 21 }}>{dinheiro(receita)}</span>
          </div>
        )}

        {visiveis.length === 0 ? (
          busca ? <EstadoVazio titulo="Nenhum cliente encontrado" />
            : grupo === 'ativos'
              ? <EstadoVazio titulo="Nenhum cliente cadastrado" botao="Novo cliente" onClick={() => app.abrir({ tipo: 'cliente' })} />
              : <EstadoVazio titulo="Nenhum cliente arquivado" texto="Clientes que você pausar ou encerrar ficam guardados aqui." />
        ) : (
          <div className="pilha-p">
            {visiveis.map((c) => {
              const abertas = atividades.filter((a) => a.clienteId === c.id && aberta(a)).sort(ordenacao)
              const proxima = abertas.find((a) => a.data)
              return (
                <button key={c.id} className="card linha" style={{ padding: 14, gap: 14, textAlign: 'left' }} onClick={() => setAbertoId(c.id)}>
                  <AvatarCliente cliente={c} />
                  <span style={{ flex: 1, minWidth: 0 }}>
                    <span style={{ display: 'block', fontWeight: 500 }}>{c.nome}</span>
                    {c.nicho && <span className="medio texto2" style={{ display: 'block' }}>{c.nicho}</span>}
                    <span className="pequeno texto2">
                      {abertas.length ? `${abertas.length} em aberto` : 'Tudo em dia'}
                      {proxima && (
                        <> · <span style={atrasada(proxima) ? { color: 'var(--alerta)' } : undefined}>{quando(dataDe(proxima)!, proxima.temHorario)}</span></>
                      )}
                    </span>
                  </span>
                  <span style={{ color: 'var(--vinho)' }}><Icone nome="seta" tamanho={18} peso={1.3} /></span>
                </button>
              )
            })}
          </div>
        )}
      </div>
    </div>
  )
}

function ClienteDetalhe({ cliente, voltar }: { cliente: Cliente; voltar: () => void }) {
  const app = useApp()
  const { atividades } = useEstado()
  const [todas, setTodas] = useState(false)

  const itens = atividades
    .filter((a) => a.clienteId === cliente.id && (todas || (aberta(a) && !jaPassou(a))))
    .sort(ordenacao)

  const digitos = cliente.contato.replace(/\D/g, '')
  const whats = digitos.length >= 10 ? `https://wa.me/${digitos.length <= 11 ? '55' + digitos : digitos}` : null
  const insta = cliente.instagram.trim().replace('@', '')

  return (
    <div className="conteudo">
      <div className="pilha" style={{ gap: 20 }}>
        <div className="linha">
          <button className="voltar" onClick={voltar}><Icone nome="voltar" tamanho={18} /> Clientes</button>
          <span className="espaco" />
          <button className="medio" onClick={() => app.abrir({ tipo: 'cliente', id: cliente.id })}>Editar</button>
        </div>

        <div className="pilha-p">
          <div className="linha" style={{ gap: 14 }}>
            <AvatarCliente cliente={cliente} tamanho={60} />
            <div>
              <h1 className="titulo-pagina" style={{ fontSize: 28 }}>{cliente.nome}</h1>
              {cliente.nicho && <div className="texto2">{cliente.nicho}</div>}
              {!cliente.ativo && <div className="pequeno texto2">Arquivado</div>}
            </div>
          </div>
          <div className="fluxo">
            {insta && (
              <a className="tag" href={`https://instagram.com/${insta}`} target="_blank" rel="noreferrer"
                style={{ color: cliente.cor, background: `color-mix(in srgb, ${cliente.cor} 12%, transparent)` }}>
                <Icone nome="camera" tamanho={13} /> @{insta}
              </a>
            )}
            {whats && (
              <a className="tag" href={whats} target="_blank" rel="noreferrer"
                style={{ color: 'var(--sucesso)', background: 'color-mix(in srgb, var(--sucesso) 12%, transparent)' }}>
                <Icone nome="mensagem" tamanho={13} /> WhatsApp
              </a>
            )}
            {cliente.valorMensal > 0 && (
              <span className="tag" style={{ color: 'var(--texto2)', background: 'var(--suave)' }}>
                <Icone nome="dinheiro" tamanho={13} /> {dinheiro(cliente.valorMensal)}/mês
              </span>
            )}
          </div>
        </div>

        <button className="pilula largo" onClick={() => app.abrir({ tipo: 'nova', atividadeTipo: 'tarefa', clienteId: cliente.id })}>
          Nova atividade para {cliente.nome}
          <Icone nome="seta" tamanho={16} peso={1.3} />
        </button>

        <div className="pilha-p">
          <div className="linha">
            <div style={{ flex: 1 }}><TituloSecao titulo="Atividades" /></div>
            <button className="pequeno texto2" onClick={() => setTodas(!todas)}>{todas ? 'Só em aberto' : 'Ver todas'}</button>
          </div>
          {itens.length === 0
            ? <div className="card medio texto2">Nada em aberto para este cliente.</div>
            : <ListaAtividades itens={itens} />}
        </div>

        {cliente.observacoes && (
          <div className="pilha-p">
            <TituloSecao titulo="Observações" />
            <div className="card medio" style={{ whiteSpace: 'pre-wrap' }}>{cliente.observacoes}</div>
          </div>
        )}
      </div>
    </div>
  )
}

export function ClienteEditor({ cliente, fechar }: { cliente?: Cliente; fechar: () => void }) {
  const [nome, setNome] = useState(cliente?.nome ?? '')
  const [nicho, setNicho] = useState(cliente?.nicho ?? '')
  const [instagram, setInstagram] = useState(cliente?.instagram ?? '')
  const [contato, setContato] = useState(cliente?.contato ?? '')
  const [valor, setValor] = useState(cliente?.valorMensal ? String(cliente.valorMensal).replace('.', ',') : '')
  const [cor, setCor] = useState(cliente?.cor ?? PALETA_CLIENTES[Math.floor(Math.random() * PALETA_CLIENTES.length)])
  const [observacoes, setObservacoes] = useState(cliente?.observacoes ?? '')
  const [arquivado, setArquivado] = useState(cliente ? !cliente.ativo : false)

  const podeSalvar = nome.trim().length > 0

  function salvar() {
    if (!podeSalvar) return
    const numero = Number(valor.replace(/[^\d,.-]/g, '').replace(/\./g, '').replace(',', '.')) || 0
    salvarCliente({
      id: cliente?.id ?? novoId(),
      nome: nome.trim(),
      nicho,
      instagram: instagram.trim(),
      contato,
      valorMensal: numero,
      cor,
      observacoes,
      ativo: !arquivado,
      criadoEm: cliente?.criadoEm ?? new Date().toISOString(),
    })
    fechar()
  }

  return (
    <Folha
      titulo={cliente ? 'Editar cliente' : 'Novo cliente'}
      fechar={fechar}
      rodape={
        <>
          <button className="pilula contorno" onClick={fechar}>Cancelar</button>
          <button className="pilula" onClick={salvar} disabled={!podeSalvar}>Salvar</button>
        </>
      }
    >
      <div style={{ display: 'grid', placeItems: 'center' }}>
        <AvatarCliente cliente={{ nome: nome || '?', cor }} tamanho={80} />
      </div>
      <div className="grupo">
        <div className="cores">
          {PALETA_CLIENTES.map((c) => (
            <button key={c} style={{ background: c }} onClick={() => setCor(c)} aria-label={`Cor ${c}`}>
              {c === cor && <Icone nome="check" tamanho={14} peso={2.4} />}
            </button>
          ))}
        </div>
      </div>

      <div>
        <p className="grupo-titulo">Dados</p>
        <div className="grupo">
          <label className="grupo-linha"><input value={nome} onChange={(e) => setNome(e.target.value)} placeholder="Nome da empresa" autoFocus={!cliente} /></label>
          <label className="grupo-linha"><input value={nicho} onChange={(e) => setNicho(e.target.value)} placeholder="Nicho (ex.: confeitaria, salão)" /></label>
          <label className="grupo-linha"><input value={instagram} onChange={(e) => setInstagram(e.target.value)} placeholder="@instagram" autoCapitalize="off" autoCorrect="off" /></label>
          <label className="grupo-linha"><input value={contato} onChange={(e) => setContato(e.target.value)} placeholder="WhatsApp / contato" inputMode="tel" /></label>
        </div>
      </div>

      <div>
        <p className="grupo-titulo">Financeiro</p>
        <div className="grupo">
          <label className="grupo-linha">
            <span>Valor mensal</span>
            <input value={valor} onChange={(e) => setValor(e.target.value)} placeholder="R$ 0,00" inputMode="decimal" style={{ textAlign: 'right' }} />
          </label>
        </div>
      </div>

      <div>
        <p className="grupo-titulo">Observações</p>
        <div className="grupo">
          <label className="grupo-linha">
            <textarea value={observacoes} onChange={(e) => setObservacoes(e.target.value)} placeholder="Identidade visual, tom de voz, dias de postagem..." />
          </label>
        </div>
      </div>

      {cliente && (
        <div>
          <div className="grupo">
            <label className="grupo-linha">
              <span style={{ flex: 1 }}>Arquivar cliente</span>
              <input type="checkbox" checked={arquivado} onChange={(e) => setArquivado(e.target.checked)} style={{ flex: 'none', width: 22, height: 22, accentColor: 'var(--vinho)' }} />
            </label>
            <button
              className="grupo-linha link-perigo"
              style={{ width: '100%' }}
              onClick={() => {
                if (confirm('Apagar este cliente?')) {
                  apagarCliente(cliente.id)
                  fechar()
                }
              }}
            >
              Apagar cliente
            </button>
          </div>
          <p className="grupo-nota">Arquivar tira o cliente da lista sem perder o histórico. Ao apagar, as atividades continuam, só que sem cliente.</p>
        </div>
      )}
    </Folha>
  )
}
