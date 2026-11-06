import { useState } from 'react'
import { useApp } from '../contexto'
import { useEstado, alternarPagamento, adiarLembreteBackup, diasSemBackup, jaFezBackup } from '../store'
import { mesAtual, pagamentosProximos, textoPagamento } from '../cliente'
import { AvatarCliente } from '../componentes/Cliente'
import { Cabecalho, EstadoVazio, Icone, ListaAtividades, TituloSecao } from '../componentes/Base'
import {
  type Atividade, aberta, aparece, atrasada, dataDe, ehCompromisso, ehHoje, inicioDoDia, inicioEm,
  ordenacao, proximaOcorrencia, somarDias,
} from '../modelo'
import { dataPorExtenso, dinheiro } from '../datas'
import { AvisoInstalar } from './AvisoInstalar'
import { useSituacaoNuvem } from './Sincronizacao'

export function Hoje() {
  const app = useApp()
  const { atividades, clientes, nome } = useEstado()
  const [backupAdiado, setBackupAdiado] = useState(false)
  const nuvem = useSituacaoNuvem()
  const [conviteFechado, setConviteFechado] = useState(() => {
    try { return localStorage.getItem('hb-organiza-convite-nuvem') === '1' } catch { return false }
  })
  const semBackup = backupAdiado ? null : diasSemBackup()
  const pagamentos = pagamentosProximos(clientes)
  const agora = new Date()

  const h = agora.getHours()
  const base = h >= 5 && h < 12 ? 'Bom dia' : h >= 12 && h < 18 ? 'Boa tarde' : 'Boa noite'
  const primeiro = nome.trim().split(' ')[0]
  const saudacao = primeiro ? `${base}, ${primeiro}` : base

  const compromissosHoje = atividades
    .filter((a) => ehCompromisso(a) && a.status !== 'cancelada' && aparece(a, agora))
    .sort((a, b) => (inicioEm(a, agora)?.getTime() ?? 0) - (inicioEm(b, agora)?.getTime() ?? 0))

  const tarefasHoje = atividades
    .filter((a) => {
      if (ehCompromisso(a) || a.status === 'cancelada') return false
      const d = dataDe(a)
      if (d && ehHoje(d)) return true
      return a.status === 'concluida' && !!a.concluidaEm && ehHoje(new Date(a.concluidaEm))
    })
    .sort(ordenacao)

  const atrasadas = atividades.filter((a) => atrasada(a) && !ehHoje(dataDe(a)!)).sort(ordenacao)

  const amanha = inicioDoDia(somarDias(agora, 1))
  const limite = somarDias(amanha, 7)
  const refProximo = (a: Atividade) => (ehCompromisso(a) ? proximaOcorrencia(a, amanha) : dataDe(a))
  const proximosDias = atividades
    .filter((a) => {
      const d = refProximo(a)
      return aberta(a) && !!d && d >= amanha && d < limite
    })
    .sort((a, b) => (refProximo(a)?.getTime() ?? 0) - (refProximo(b)?.getTime() ?? 0))

  const semData = atividades.filter((a) => aberta(a) && !a.data).length
  const feitas = tarefasHoje.filter((a) => a.status === 'concluida').length
  const total = tarefasHoje.length

  return (
    <div className="conteudo">
      <div className="pilha">
        <Cabecalho titulo={saudacao} subtitulo={dataPorExtenso(agora)} pincel />
        <AvisoInstalar />

        {nuvem.tipo === 'fora' && !conviteFechado && (
          <div className="aviso-instalar" style={{ alignItems: 'center' }}>
            <span style={{ color: 'var(--vinho)' }}><Icone nome="nuvem" tamanho={22} /></span>
            <div style={{ flex: 1 }}>
              <b>Sincronize seus dois iPhones.</b> Entre com sua conta e o que mudar em um aparece no outro na hora.
              <div className="linha" style={{ marginTop: 10, gap: 8 }}>
                <button className="pilula" style={{ padding: '8px 14px' }} onClick={() => app.abrir({ tipo: 'ajustes' })}>Entrar</button>
                <button
                  className="pilula contorno"
                  style={{ padding: '8px 14px' }}
                  onClick={() => { try { localStorage.setItem('hb-organiza-convite-nuvem', '1') } catch { /* ignora */ } setConviteFechado(true) }}
                >
                  Agora não
                </button>
              </div>
            </div>
          </div>
        )}

        {nuvem.tipo !== 'conectada' && semBackup !== null && (
          <div className="aviso-instalar" style={{ alignItems: 'center' }}>
            <span style={{ color: 'var(--vinho)' }}><Icone nome="pasta" tamanho={20} /></span>
            <div style={{ flex: 1 }}>
              <b>{jaFezBackup() ? `Faz ${semBackup} dias sem backup.` : 'Que tal salvar um backup?'}</b>{' '}
              Seus dados ficam só neste iPhone; uma cópia no iCloud Drive evita perder tudo.
              <div className="linha" style={{ marginTop: 10, gap: 8 }}>
                <button className="pilula" style={{ padding: '8px 14px' }} onClick={() => app.abrir({ tipo: 'ajustes' })}>Salvar backup</button>
                <button className="pilula contorno" style={{ padding: '8px 14px' }} onClick={() => { adiarLembreteBackup(3); setBackupAdiado(true) }}>Agora não</button>
              </div>
            </div>
          </div>
        )}

        {pagamentos.length > 0 && (
          <div className="pilha-p">
            <TituloSecao titulo="Pagamentos" detalhe={String(pagamentos.length)} />
            <div className="card p12">
              {pagamentos.map((p, i) => (
                <div key={p.cliente.id}>
                  <div className="item" style={{ alignItems: 'center', cursor: 'default' }}>
                    <AvatarCliente cliente={p.cliente} tamanho={34} />
                    <div style={{ flex: 1, minWidth: 0 }}>
                      <div className="item-titulo">{p.cliente.nome}</div>
                      <div className="item-meta">
                        <span style={{ color: p.tipo === 'atrasado' ? 'var(--alerta)' : p.tipo === 'hoje' ? 'var(--vinho)' : undefined }}>
                          {textoPagamento(p)}
                        </span>
                        <span>·</span>
                        <span>{dinheiro(p.cliente.valorMensal)}</span>
                      </div>
                    </div>
                    <button className="pilula contorno" style={{ padding: '7px 12px', fontSize: 13 }} onClick={() => alternarPagamento(p.cliente.id, mesAtual())}>
                      <Icone nome="check" tamanho={14} /> Pago
                    </button>
                  </div>
                  {i < pagamentos.length - 1 && <div className="sep" style={{ marginLeft: 46 }} />}
                </div>
              ))}
            </div>
          </div>
        )}

        {atividades.length === 0 ? (
          <EstadoVazio
            titulo="Comece pela primeira atividade"
            texto="Tarefas e compromissos que você criar aparecem aqui, organizados por dia."
            botao="Nova atividade"
            onClick={() => app.abrir({ tipo: 'nova' })}
          />
        ) : (
          <>
            <div className="card">
              <div className="linha" style={{ alignItems: 'baseline' }}>
                <span className="medio" style={{ fontWeight: 500 }}>
                  {total === 0 ? 'Sem tarefas para hoje' : `${feitas} de ${total} feitas hoje`}
                </span>
                <span className="espaco" />
                <span className="medio texto2">
                  {compromissosHoje.length} compromisso{compromissosHoje.length === 1 ? '' : 's'}
                </span>
              </div>
              <div className="progresso"><div style={{ width: `${total ? (feitas / total) * 100 : 0}%` }} /></div>
            </div>

            <Secao titulo="Agenda de hoje" itens={compromissosHoje} dia={agora} vazio="Nenhum compromisso hoje." />
            {atrasadas.length > 0 && <Secao titulo="Atrasadas" itens={atrasadas} cor="var(--alerta)" />}
            <Secao titulo="Para hoje" itens={tarefasHoje} vazio="Nada com vencimento hoje." />
            {proximosDias.length > 0 && <Secao titulo="Próximos dias" itens={proximosDias} />}
            {semData > 0 && (
              <p className="pequeno texto2" style={{ textAlign: 'center', margin: 0 }}>
                {semData} tarefa{semData === 1 ? '' : 's'} sem data na aba Tarefas
              </p>
            )}
          </>
        )}
      </div>
    </div>
  )
}

function Secao({ titulo, itens, dia, cor, vazio }: { titulo: string; itens: Atividade[]; dia?: Date; cor?: string; vazio?: string }) {
  if (itens.length === 0 && !vazio) return null
  return (
    <div className="pilha-p">
      <TituloSecao titulo={titulo} detalhe={itens.length ? String(itens.length) : undefined} cor={cor} />
      {itens.length === 0 ? (
        <div className="card medio texto2">{vazio}</div>
      ) : (
        <ListaAtividades itens={itens} dia={dia} mostrarData={!dia} />
      )}
    </div>
  )
}
