import { createContext, useContext } from 'react'

/** Folhas (sheets) que podem ser abertas de qualquer tela. */
export type Folha =
  | { tipo: 'nova'; atividadeTipo?: 'tarefa' | 'compromisso'; data?: Date; temHorario?: boolean; clienteId?: string }
  | { tipo: 'editar'; id: string }
  | { tipo: 'ajustes' }
  | { tipo: 'lembretes' }
  | { tipo: 'cliente'; id?: string }

export interface AppAcoes {
  abrir: (f: Folha) => void
  fechar: () => void
}

export const AppContexto = createContext<AppAcoes>({ abrir: () => {}, fechar: () => {} })
export const useApp = () => useContext(AppContexto)
