import { useApp } from '../contexto'
import { useEstado } from '../store'
import { Cabecalho, EstadoVazio, ListaAtividades, TituloSecao } from '../componentes/Base'
import {
  type Atividade, aberta, aparece, atrasada, dataDe, ehCompromisso, ehHoje, inicioDoDia, inicioEm,
  ordenacao, proximaOcorrencia, somarDias,
} from '../modelo'
import { dataPorExtenso } from '../datas'
import { AvisoInstalar } from './AvisoInstalar'

export function Hoje() {
  const app = useApp()
  const { atividades, nome } = useEstado()
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
