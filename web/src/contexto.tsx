import { createContext, useContext } from 'react'
import type { Etapa } from './modelo'

/** Folhas (sheets) que podem ser abertas de qualquer tela. */
export type Folha =
  | { tipo: 'nova'; atividadeTipo?: 'tarefa' | 'compromisso'; data?: Date; temHorario?: boolean; clienteId?: string; etapa?: Etapa }
  | { tipo: 'detalhes'; id: string; /** ocorrência tocada (ISO), para repetições */ dia?: string }
  | { tipo: 'editar'; id: string; /** folha para voltar ao fechar */ voltar?: Folha }
  | { tipo: 'ajustes' }
  | { tipo: 'lembretes' }
  | { tipo: 'cliente'; id?: string }

export interface AppAcoes {
  abrir: (f: Folha) => void
  fechar: () => void
}

export const AppContexto = createContext<AppAcoes>({ abrir: () => {}, fechar: () => {} })
export const useApp = () => useContext(AppContexto)
