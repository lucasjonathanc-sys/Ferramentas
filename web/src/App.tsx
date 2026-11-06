import { useEffect, useState } from 'react'
import { AppContexto, type Folha } from './contexto'
import { useEstado, pedirArmazenamentoPersistente } from './store'
import { BarraAbas, type Aba } from './componentes/Base'
import { Hoje } from './telas/Hoje'
import { Tarefas } from './telas/Tarefas'
import { Agenda } from './telas/Agenda'
import { Clientes, ClienteEditor } from './telas/Clientes'
import { AtividadeEditor } from './telas/AtividadeEditor'
import { AtividadeDetalhes } from './telas/AtividadeDetalhes'
import { Ajustes, Lembretes } from './telas/Ajustes'

export function App() {
  const { atividades, clientes } = useEstado()
  const [aba, setAba] = useState<Aba>('hoje')
  const [folha, setFolha] = useState<Folha | null>(null)

  useEffect(() => pedirArmazenamentoPersistente(), [])

  const fechar = () => setFolha(null)

  let conteudoFolha = null
  if (folha?.tipo === 'nova') {
    conteudoFolha = <AtividadeEditor key={JSON.stringify(folha)} fechar={fechar} pedido={folha} />
  } else if (folha?.tipo === 'detalhes') {
    const a = atividades.find((x) => x.id === folha.id)
    conteudoFolha = a ? <AtividadeDetalhes key={`d-${a.id}`} atividade={a} dia={folha.dia ? new Date(folha.dia) : undefined} fechar={fechar} /> : null
  } else if (folha?.tipo === 'editar') {
    const a = atividades.find((x) => x.id === folha.id)
    // Ao terminar de editar, volta para os detalhes (se veio de lá)
    const voltar = () => setFolha(folha.voltar ?? null)
    conteudoFolha = a ? <AtividadeEditor key={a.id} fechar={voltar} atividade={a} /> : null
  } else if (folha?.tipo === 'ajustes') {
    conteudoFolha = <Ajustes fechar={fechar} />
  } else if (folha?.tipo === 'lembretes') {
    conteudoFolha = <Lembretes fechar={fechar} />
  } else if (folha?.tipo === 'cliente') {
    const c = folha.id ? clientes.find((x) => x.id === folha.id) : undefined
    conteudoFolha = <ClienteEditor key={folha.id ?? 'novo'} cliente={c} fechar={fechar} />
  }

  return (
    <AppContexto.Provider value={{ abrir: setFolha, fechar }}>
      <div className="app">
        <main style={{ flex: 1, minHeight: 0, display: 'flex', flexDirection: 'column' }}>
          {aba === 'hoje' && <Hoje />}
          {aba === 'tarefas' && <Tarefas />}
          {aba === 'agenda' && <Agenda />}
          {aba === 'clientes' && <Clientes />}
        </main>
        <BarraAbas aba={aba} definir={setAba} />
      </div>
      {conteudoFolha}
    </AppContexto.Provider>
  )
}
