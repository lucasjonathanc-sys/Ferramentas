import { useState } from 'react'
import { Icone } from '../componentes/Base'

const CHAVE = 'hb-organiza-aviso-instalar'

/** Mostra como adicionar à Tela de Início quando aberto no Safari (fora do modo app). */
export function AvisoInstalar() {
  const instalado =
    window.matchMedia?.('(display-mode: standalone)').matches ||
    (navigator as Navigator & { standalone?: boolean }).standalone === true
  const [fechado, setFechado] = useState(() => localStorage.getItem(CHAVE) === '1')

  if (instalado || fechado) return null

  return (
    <div className="aviso-instalar">
      <span style={{ color: 'var(--vinho)', marginTop: 2 }}><Icone nome="compartilhar" tamanho={20} /></span>
      <div style={{ flex: 1 }}>
        <b>Instale como app:</b> no Safari, toque em <b>Compartilhar</b> e depois em{' '}
        <b>“Adicionar à Tela de Início”</b>. O DB. Organiza aparece com ícone próprio e abre em tela cheia.
      </div>
      <button
        onClick={() => { localStorage.setItem(CHAVE, '1'); setFechado(true) }}
        aria-label="Fechar aviso"
        style={{ color: 'var(--texto2)' }}
      >
        <Icone nome="x" tamanho={16} />
      </button>
    </div>
  )
}
