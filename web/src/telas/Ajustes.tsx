import { useRef, useState } from 'react'
import { Folha, Logo } from '../componentes/Base'
import { useApp } from '../contexto'
import { useEstado, definirNome, exportarBackup, importarBackup, itensAntigos, limparAntigos } from '../store'
import {
  type Atividade, aberta, corContexto, ehCompromisso, momentoLembrete, nomeLembrete, inicioEm, proximaOcorrencia,
} from '../modelo'
import { paraInputData, quando } from '../datas'

export function Ajustes({ fechar }: { fechar: () => void }) {
  const estado = useEstado()
  const [mensagem, setMensagem] = useState<string | null>(null)
  const entrada = useRef<HTMLInputElement>(null)
  const antigos = itensAntigos().length

  async function salvarBackup() {
    const texto = exportarBackup()
    const nome = `hb-organiza-backup-${paraInputData(new Date())}.json`
    const arquivo = new File([texto], nome, { type: 'application/json' })
    // No iPhone abre a folha de compartilhar (Salvar em Arquivos, iCloud Drive, AirDrop...)
    const nav = navigator as Navigator & { canShare?: (d: { files: File[] }) => boolean }
    if (nav.canShare?.({ files: [arquivo] })) {
      try {
        await navigator.share({ files: [arquivo], title: 'Backup HB Organiza' })
        setMensagem('Backup pronto.')
        return
      } catch {
        // usuária cancelou: cai no download abaixo só se não houver share
        return
      }
    }
    const url = URL.createObjectURL(arquivo)
    const a = document.createElement('a')
    a.href = url
    a.download = nome
    a.click()
    setTimeout(() => URL.revokeObjectURL(url), 10000)
    setMensagem('Backup salvo.')
  }

  async function restaurar(f: File | undefined) {
    if (!f) return
    const texto = await f.text()
    if (!confirm('Restaurar este backup? O que está no app agora será substituído.')) return
    setMensagem(importarBackup(texto) ? 'Backup restaurado.' : 'Esse arquivo não é um backup válido do HB Organiza.')
  }

  return (
    <Folha titulo="Ajustes" fechar={fechar}>
      <div className="card linha" style={{ gap: 14 }}>
        <span style={{ width: 56, height: 56, borderRadius: 14, background: 'var(--fundo)', display: 'grid', placeItems: 'center' }}>
          <Logo tamanho={30} />
        </span>
        <div>
          <div style={{ fontFamily: 'var(--titulo)', fontSize: 18 }}>HB Organiza</div>
          <div className="pequeno texto2">Feito com carinho para a {estado.nome.trim() || 'Hanna'} 🤍</div>
        </div>
      </div>

      <div>
        <p className="grupo-titulo">Como te chamar</p>
        <div className="grupo">
          <label className="grupo-linha">
            <input value={estado.nome} onChange={(e) => definirNome(e.target.value)} placeholder="Seu nome" autoCapitalize="words" />
          </label>
        </div>
        <p className="grupo-nota">Aparece na saudação da tela Hoje.</p>
      </div>

      <div>
        <p className="grupo-titulo">Backup</p>
        <div className="grupo">
          <button className="grupo-linha" style={{ width: '100%' }} onClick={salvarBackup}>Salvar backup</button>
          <button className="grupo-linha" style={{ width: '100%' }} onClick={() => entrada.current?.click()}>Restaurar backup</button>
        </div>
        <input ref={entrada} type="file" accept="application/json,.json" hidden onChange={(e) => { restaurar(e.target.files?.[0]); e.target.value = '' }} />
        <p className="grupo-nota">
          Os dados ficam só neste iPhone. Salve um backup de vez em quando (no app Arquivos ou no iCloud Drive) para não perder nada
          se o app for apagado da tela de início.
        </p>
        {mensagem && <p className="grupo-nota" style={{ color: 'var(--texto)' }}>{mensagem}</p>}
      </div>

      <div>
        <p className="grupo-titulo">Organização</p>
        <div className="grupo">
          <button
            className="grupo-linha link-perigo"
            style={{ width: '100%', opacity: antigos ? 1 : 0.4 }}
            disabled={!antigos}
            onClick={() => confirm(`Apagar ${antigos} itens antigos?`) && limparAntigos()}
          >
            Limpar itens antigos ({antigos})
          </button>
        </div>
        <p className="grupo-nota">Apaga tarefas concluídas ou canceladas e compromissos que já passaram há mais de 30 dias.</p>
      </div>
    </Folha>
  )
}

/** Aberta pelo sininho: próximos lembretes dos próximos 14 dias. */
export function Lembretes({ fechar }: { fechar: () => void }) {
  const app = useApp()
  const { atividades } = useEstado()
  const agora = Date.now()
  const limite = agora + 14 * 86400000

  const itens: { a: Atividade; quando: Date; min: number }[] = []
  for (const a of atividades) {
    if (!aberta(a) || !a.lembretes.length) continue
    let base = momentoLembrete(a)
    if (!base) continue
    if (ehCompromisso(a) && a.repeticao !== 'nunca') {
      const dia = proximaOcorrencia(a)
      const ini = dia && inicioEm(a, dia)
      if (ini) base = ini
    }
    for (const min of a.lembretes) {
      const q = new Date(base.getTime() - min * 60000)
      if (q.getTime() > agora && q.getTime() < limite) itens.push({ a, quando: q, min })
    }
  }
  itens.sort((x, y) => x.quando.getTime() - y.quando.getTime())

  return (
    <Folha titulo="Próximos lembretes" fechar={fechar}>
      {itens.length === 0 ? (
        <div className="card medio texto2">Nenhum lembrete nos próximos 14 dias.</div>
      ) : (
        <div className="card p12">
          {itens.map(({ a, quando: q, min }, i) => (
            <div key={`${a.id}-${min}`}>
              <div className="item" onClick={() => app.abrir({ tipo: 'detalhes', id: a.id })}>
                <span className="bolinha" style={{ background: corContexto(a.contexto), width: 8, height: 8, marginTop: 7 }} />
                <div>
                  <div className="item-titulo">{a.titulo}</div>
                  <div className="item-meta">{quando(q, true)} · {nomeLembrete(min)}</div>
                </div>
              </div>
              {i < itens.length - 1 && <div className="sep" style={{ marginLeft: 20 }} />}
            </div>
          ))}
        </div>
      )}
      <p className="grupo-nota">
        O app web não consegue tocar o alarme sozinho com o app fechado. Para receber o aviso no horário, abra a atividade e toque
        em “Adicionar ao Calendário do iPhone”: os lembretes vão junto.
      </p>
    </Folha>
  )
}
