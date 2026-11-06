import { useState, type ReactNode } from 'react'
import { useApp } from '../contexto'
import { useEstado, salvarCliente, apagarCliente, alternarPagamento } from '../store'
import { Cabecalho, EstadoVazio, Folha, Icone, ListaAtividades, Segmento, TituloSecao } from '../componentes/Base'
import { AvatarCliente, BotoesCliente, LinhaDado } from '../componentes/Cliente'
import { type Cliente, PALETA_CLIENTES, aberta, atrasada, dataDe, jaPassou, normalizarCliente, ordenacao } from '../modelo'
import { corSituacao, formatarTelefone, mesAtual, situacaoPagamento } from '../cliente'
import { deInputData, dinheiro, quando } from '../datas'


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
  const casa = (c: Cliente) =>
    [c.nome, c.nicho, c.responsavel, c.instagram].some((v) => v.toLocaleLowerCase('pt-BR').includes(termo))
  const visiveis = (grupo === 'ativos' ? ativos : arquivados)
    .filter((c) => !termo || casa(c))
    .sort((a, b) => a.nome.localeCompare(b.nome))
  const receita = ativos.reduce((s, c) => s + (c.valorMensal || 0), 0)
  const recebido = ativos.filter((c) => c.pagamentos.includes(mesAtual())).reduce((s, c) => s + (c.valorMensal || 0), 0)

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
          <div className="card">
            <div className="linha">
              <span className="medio texto2">Renda extra mensal</span>
              <span className="espaco" />
              <span style={{ fontFamily: 'var(--titulo)', fontSize: 21 }}>{dinheiro(receita)}</span>
            </div>
            <div className="progresso"><div style={{ width: `${(recebido / receita) * 100}%`, background: 'var(--sucesso)' }} /></div>
            <div className="pequeno texto2" style={{ marginTop: 6 }}>{dinheiro(recebido)} recebido este mês</div>
          </div>
        )}

        {visiveis.length === 0 ? (
          busca ? <EstadoVazio titulo="Nenhum cliente encontrado" />
            : grupo === 'ativos'
              ? <EstadoVazio titulo="Nenhum cliente cadastrado" texto="Cadastre o perfil de cada cliente uma vez e puxe os dados nas tarefas e compromissos." botao="Novo cliente" onClick={() => app.abrir({ tipo: 'cliente' })} />
              : <EstadoVazio titulo="Nenhum cliente arquivado" texto="Clientes que você pausar ou encerrar ficam guardados aqui." />
        ) : (
          <div className="pilha-p">
            {visiveis.map((c) => {
              const abertas = atividades.filter((a) => a.clienteId === c.id && aberta(a) && !jaPassou(a)).sort(ordenacao)
              const proxima = abertas.find((a) => a.data)
              const situacao = c.ativo ? situacaoPagamento(c) : null
              return (
                <button key={c.id} className="card linha" style={{ padding: 14, gap: 14, textAlign: 'left' }} onClick={() => setAbertoId(c.id)}>
                  <AvatarCliente cliente={c} />
                  <span style={{ flex: 1, minWidth: 0 }}>
                    <span style={{ display: 'block', fontWeight: 500 }}>{c.nome}</span>
                    {(c.nicho || c.responsavel) && (
                      <span className="medio texto2" style={{ display: 'block' }}>{[c.nicho, c.responsavel].filter(Boolean).join(' · ')}</span>
                    )}
                    <span className="pequeno texto2" style={{ display: 'block' }}>
                      {abertas.length ? `${abertas.length} em aberto` : 'Tudo em dia'}
                      {proxima && (
                        <> · <span style={atrasada(proxima) ? { color: 'var(--alerta)' } : undefined}>{quando(dataDe(proxima)!, proxima.temHorario)}</span></>
                      )}
                    </span>
                    {situacao && situacao.tipo !== 'pendente' && (
                      <span className="pequeno" style={{ display: 'block', color: corSituacao(situacao) }}>● {situacao.texto}</span>
                    )}
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

// MARK: - Perfil do cliente

function Secao({ titulo, dados, children }: { titulo: string; dados: [string, ReactNode][]; children?: ReactNode }) {
  const preenchidos = dados.filter(([, v]) => v !== '' && v !== null && v !== undefined)
  if (!preenchidos.length && !children) return null
  return (
    <div className="pilha-p">
      <TituloSecao titulo={titulo} />
      <div className="card">
        {preenchidos.length > 0 && <div className="dados">{preenchidos.map(([r, v]) => <LinhaDado key={r} rotulo={r}>{v}</LinhaDado>)}</div>}
        {children}
      </div>
    </div>
  )
}

function ClienteDetalhe({ cliente: c, voltar }: { cliente: Cliente; voltar: () => void }) {
  const app = useApp()
  const { atividades } = useEstado()
  const [todas, setTodas] = useState(false)

  const itens = atividades
    .filter((a) => a.clienteId === c.id && (todas || (aberta(a) && !jaPassou(a))))
    .sort(ordenacao)

  const situacao = situacaoPagamento(c)
  const pagoEsteMes = c.pagamentos.includes(mesAtual())
  const inicio = c.inicioContrato ? deInputData(c.inicioContrato).toLocaleDateString('pt-BR', { day: 'numeric', month: 'long', year: 'numeric' }) : ''
  const link = (url: string) => (url ? <a href={/^https?:/i.test(url) ? url : `https://${url}`} target="_blank" rel="noreferrer" className="link-dado">{url.replace(/^https?:\/\/(www\.)?/i, '')}</a> : '')

  return (
    <div className="conteudo">
      <div className="pilha" style={{ gap: 20 }}>
        <div className="linha">
          <button className="voltar" onClick={voltar}><Icone nome="voltar" tamanho={18} /> Clientes</button>
          <span className="espaco" />
          <button className="medio" onClick={() => app.abrir({ tipo: 'cliente', id: c.id })}>Editar</button>
        </div>

        <div className="pilha-p" style={{ gap: 14 }}>
          <div className="linha" style={{ gap: 14 }}>
            <AvatarCliente cliente={c} tamanho={60} />
            <div style={{ minWidth: 0 }}>
              <h1 className="titulo-pagina" style={{ fontSize: 28 }}>{c.nome}</h1>
              {(c.nicho || c.responsavel) && <div className="texto2">{[c.nicho, c.responsavel].filter(Boolean).join(' · ')}</div>}
              {!c.ativo && <div className="pequeno texto2">Arquivado</div>}
            </div>
          </div>
          <BotoesCliente cliente={c} />
        </div>

        {c.valorMensal > 0 && (
          <div className="card">
            <div className="linha" style={{ alignItems: 'baseline' }}>
              <span style={{ fontFamily: 'var(--titulo)', fontSize: 22 }}>{dinheiro(c.valorMensal)}</span>
              <span className="texto2 medio">/mês</span>
              <span className="espaco" />
              {c.diaPagamento && <span className="pequeno texto2">vence dia {c.diaPagamento}</span>}
            </div>
            {situacao && <div className="pequeno" style={{ color: corSituacao(situacao), marginTop: 6 }}>● {situacao.texto}</div>}
            <button className={`pilula ${pagoEsteMes ? 'contorno' : ''}`} style={{ width: '100%', marginTop: 12 }} onClick={() => alternarPagamento(c.id, mesAtual())}>
              {pagoEsteMes ? 'Desmarcar pagamento deste mês' : 'Marcar este mês como pago'}
            </button>
          </div>
        )}

        <button className="pilula largo" onClick={() => app.abrir({ tipo: 'nova', atividadeTipo: 'tarefa', clienteId: c.id })}>
          Nova atividade para {c.nome}
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

        <Secao titulo="Contato" dados={[
          ['Responsável', c.responsavel], ['WhatsApp', formatarTelefone(c.contato)], ['E-mail', c.email],
          ['Instagram', c.instagram], ['TikTok', c.tiktok], ['Site', link(c.site)], ['Endereço', c.endereco],
        ]} />
        <Secao titulo="Contrato" dados={[
          ['Serviços', c.servicos], ['Valor', c.valorMensal ? `${dinheiro(c.valorMensal)} por mês` : ''],
          ['Pagamento', c.diaPagamento ? `Todo dia ${c.diaPagamento}` : ''], ['Início', inicio],
        ]} />
        <Secao titulo="Identidade da marca" dados={[
          ['Cores', c.cores], ['Fontes', c.fontes], ['Tom de voz', c.tomDeVoz], ['Público-alvo', c.publicoAlvo],
          ['Postagens', c.diasPostagem], ['Drive', link(c.linkDrive)], ['Canva', link(c.linkCanva)], ['Fotos', link(c.linkFotos)],
        ]} />
        {c.observacoes && (
          <div className="pilha-p">
            <TituloSecao titulo="Observações" />
            <div className="card medio" style={{ whiteSpace: 'pre-wrap' }}>{c.observacoes}</div>
          </div>
        )}
      </div>
    </div>
  )
}

// MARK: - Cadastro / edição

/** Seção do cadastro que abre e fecha, para o formulário ficar curto. */
function Recolhivel({ titulo, preenchidos, children }: { titulo: string; preenchidos: number; children: ReactNode }) {
  const [aberta, setAberta] = useState(false)
  return (
    <div>
      <button className={`recolhivel ${aberta ? 'aberta' : ''}`} onClick={() => setAberta(!aberta)} aria-expanded={aberta}>
        <span style={{ flex: 1 }}>{titulo}</span>
        <span className="pequeno texto2">{preenchidos ? `${preenchidos} preenchido${preenchidos === 1 ? '' : 's'}` : 'Opcional'}</span>
        <span className="texto2"><Icone nome={aberta ? 'cima' : 'baixo'} tamanho={16} /></span>
      </button>
      {aberta && <div style={{ marginTop: 10 }}>{children}</div>}
    </div>
  )
}

function Campo(props: {
  rotulo: string
  valor: string
  definir: (v: string) => void
  placeholder?: string
  tipo?: 'text' | 'email' | 'tel' | 'url' | 'date' | 'number'
  modo?: 'text' | 'email' | 'tel' | 'url' | 'decimal' | 'numeric'
  multilinha?: boolean
}) {
  return (
    <label className="grupo-linha campo-rotulado">
      <span className="campo-nome">{props.rotulo}</span>
      {props.multilinha ? (
        <textarea value={props.valor} onChange={(e) => props.definir(e.target.value)} placeholder={props.placeholder} rows={2} />
      ) : (
        <input
          type={props.tipo ?? 'text'}
          value={props.valor}
          onChange={(e) => props.definir(e.target.value)}
          placeholder={props.placeholder}
          inputMode={props.modo}
          autoCapitalize={props.tipo === 'email' || props.tipo === 'url' || props.modo === 'url' ? 'off' : undefined}
          autoCorrect={props.tipo === 'email' || props.tipo === 'url' || props.modo === 'url' ? 'off' : undefined}
        />
      )}
    </label>
  )
}

export function ClienteEditor({ cliente, fechar }: { cliente?: Cliente; fechar: () => void }) {
  const [f, setF] = useState<Cliente>(() =>
    cliente ?? normalizarCliente({ cor: PALETA_CLIENTES[Math.floor(Math.random() * PALETA_CLIENTES.length)] }),
  )
  const [valor, setValor] = useState(cliente?.valorMensal ? String(cliente.valorMensal).replace('.', ',') : '')
  const [dia, setDia] = useState(cliente?.diaPagamento ? String(cliente.diaPagamento) : '')

  const campo = (k: keyof Cliente) => ({
    valor: String(f[k] ?? ''),
    definir: (v: string) => setF((x) => ({ ...x, [k]: v })),
  })
  const podeSalvar = f.nome.trim().length > 0
  const contar = (chaves: (keyof Cliente)[]) => chaves.filter((k) => String(f[k] ?? '').trim()).length

  function salvar() {
    if (!podeSalvar) return
    const numero = Number(valor.replace(/[^\d,.-]/g, '').replace(/\./g, '').replace(',', '.')) || 0
    const d = Math.round(Number(dia))
    salvarCliente({
      ...f,
      nome: f.nome.trim(),
      instagram: f.instagram.trim(),
      tiktok: f.tiktok.trim(),
      email: f.email.trim(),
      valorMensal: numero,
      diaPagamento: d >= 1 && d <= 31 ? d : null,
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
        <AvatarCliente cliente={{ nome: f.nome || '?', cor: f.cor }} tamanho={80} />
      </div>
      <div className="grupo">
        <div className="cores">
          {PALETA_CLIENTES.map((c) => (
            <button key={c} style={{ background: c }} onClick={() => setF({ ...f, cor: c })} aria-label={`Cor ${c}`}>
              {c === f.cor && <Icone nome="check" tamanho={14} peso={2.4} />}
            </button>
          ))}
        </div>
      </div>

      <div>
        <p className="grupo-titulo">Empresa</p>
        <div className="grupo">
          <Campo rotulo="Nome" {...campo('nome')} placeholder="Nome da empresa" />
          <Campo rotulo="Nicho" {...campo('nicho')} placeholder="Ex.: confeitaria, salão" />
        </div>
      </div>

      <Recolhivel titulo="Contato" preenchidos={contar(['responsavel', 'contato', 'email', 'instagram', 'tiktok', 'site', 'endereco'])}>
        <div className="grupo">
          <Campo rotulo="Responsável" {...campo('responsavel')} placeholder="Com quem você fala" />
          <Campo rotulo="WhatsApp" {...campo('contato')} placeholder="(11) 99999-9999" tipo="tel" modo="tel" />
          <Campo rotulo="E-mail" {...campo('email')} placeholder="contato@empresa.com" tipo="email" modo="email" />
          <Campo rotulo="Instagram" {...campo('instagram')} placeholder="@perfil" modo="url" />
          <Campo rotulo="TikTok" {...campo('tiktok')} placeholder="@perfil" modo="url" />
          <Campo rotulo="Site" {...campo('site')} placeholder="empresa.com.br" modo="url" />
          <Campo rotulo="Endereço" {...campo('endereco')} placeholder="Rua, número, bairro, cidade" multilinha />
        </div>
        <p className="grupo-nota">O endereço já entra no Local quando você cria um compromisso com este cliente.</p>
      </Recolhivel>

      <Recolhivel titulo="Contrato e pagamento" preenchidos={contar(['servicos', 'inicioContrato']) + (valor.trim() ? 1 : 0) + (dia.trim() ? 1 : 0)}>
        <div className="grupo">
          <Campo rotulo="Serviços" {...campo('servicos')} placeholder="Ex.: 12 posts e 4 vídeos por mês" multilinha />
          <Campo rotulo="Valor mensal" valor={valor} definir={setValor} placeholder="R$ 0,00" modo="decimal" />
          <Campo rotulo="Dia de pagamento" valor={dia} definir={setDia} placeholder="Ex.: 10" modo="numeric" />
          <Campo rotulo="Início do contrato" {...campo('inicioContrato')} tipo="date" />
        </div>
      </Recolhivel>

      <Recolhivel titulo="Identidade da marca" preenchidos={contar(['cores', 'fontes', 'tomDeVoz', 'publicoAlvo', 'diasPostagem', 'linkDrive', 'linkCanva', 'linkFotos'])}>
        <div className="grupo">
          <Campo rotulo="Cores" {...campo('cores')} placeholder="Ex.: rosa #F4A6B8, marrom" />
          <Campo rotulo="Fontes" {...campo('fontes')} placeholder="Ex.: Playfair e Montserrat" />
          <Campo rotulo="Tom de voz" {...campo('tomDeVoz')} placeholder="Ex.: leve, divertido, próximo" multilinha />
          <Campo rotulo="Público-alvo" {...campo('publicoAlvo')} placeholder="Ex.: mulheres de 25 a 40 anos" multilinha />
          <Campo rotulo="Postagens" {...campo('diasPostagem')} placeholder="Ex.: ter e qui às 18h" />
          <Campo rotulo="Drive" {...campo('linkDrive')} placeholder="Link da pasta" modo="url" />
          <Campo rotulo="Canva" {...campo('linkCanva')} placeholder="Link do Canva" modo="url" />
          <Campo rotulo="Fotos" {...campo('linkFotos')} placeholder="Link das fotos" modo="url" />
        </div>
      </Recolhivel>

      <Recolhivel titulo="Observações" preenchidos={contar(['observacoes'])}>
        <div className="grupo">
          <label className="grupo-linha">
            <textarea value={f.observacoes} onChange={(e) => setF({ ...f, observacoes: e.target.value })} placeholder="Anotações gerais sobre o cliente" />
          </label>
        </div>
      </Recolhivel>

      {cliente && (
        <div>
          <div className="grupo">
            <label className="grupo-linha">
              <span style={{ flex: 1 }}>Arquivar cliente</span>
              <input type="checkbox" checked={!f.ativo} onChange={(e) => setF({ ...f, ativo: !e.target.checked })} style={{ flex: 'none', width: 22, height: 22, accentColor: 'var(--vinho)' }} />
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
