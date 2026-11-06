import { useState, useSyncExternalStore } from 'react'
import { entrar, esqueciSenha, ouvirSituacao, sair, situacaoNuvem } from '../nuvem'
import { Icone } from '../componentes/Base'

export const useSituacaoNuvem = () => useSyncExternalStore(ouvirSituacao, situacaoNuvem)

/** Seção dos Ajustes para entrar na conta e manter os dois iPhones iguais. */
export function SecaoSincronizacao() {
  const situacao = useSituacaoNuvem()
  const [email, setEmail] = useState('')
  const [senha, setSenha] = useState('')
  const [mensagem, setMensagem] = useState<string | null>(null)
  const [ocupado, setOcupado] = useState(false)

  if (situacao.tipo === 'desligada') return null

  if (situacao.tipo === 'conectada') {
    return (
      <div>
        <p className="grupo-titulo">Sincronização</p>
        <div className="grupo">
          <div className="grupo-linha">
            <span style={{ color: 'var(--sucesso)' }}><Icone nome="nuvem" tamanho={20} /></span>
            <span style={{ flex: 1, minWidth: 0 }}>
              <span style={{ display: 'block' }}>Sincronizando</span>
              <span className="pequeno texto2" style={{ overflowWrap: 'anywhere' }}>{situacao.email}</span>
            </span>
          </div>
          <button
            className="grupo-linha link-perigo"
            style={{ width: '100%' }}
            onClick={async () => {
              if (!confirm('Sair da conta neste iPhone? Seus dados continuam na nuvem e no outro iPhone; este fica vazio até você entrar de novo.')) return
              await sair()
            }}
          >
            Sair deste iPhone
          </button>
        </div>
        <p className="grupo-nota">O que você muda aqui aparece no outro iPhone em segundos. Sem internet, ele guarda e envia quando a conexão voltar.</p>
      </div>
    )
  }

  async function aoEntrar() {
    setOcupado(true)
    setMensagem(null)
    const erro = await entrar(email, senha)
    setOcupado(false)
    if (erro) setMensagem(erro)
    else setSenha('')
  }

  return (
    <div>
      <p className="grupo-titulo">Sincronização</p>
      <div className="grupo">
        <label className="grupo-linha">
          <input type="email" value={email} onChange={(e) => setEmail(e.target.value)} placeholder="E-mail" autoCapitalize="off" autoCorrect="off" autoComplete="username" />
        </label>
        <label className="grupo-linha">
          <input type="password" value={senha} onChange={(e) => setSenha(e.target.value)} placeholder="Senha" autoComplete="current-password"
            onKeyDown={(e) => { if (e.key === 'Enter') void aoEntrar() }} />
        </label>
        <button className="grupo-linha" style={{ width: '100%', fontWeight: 600 }} disabled={ocupado || !email.trim() || !senha} onClick={aoEntrar}>
          {ocupado ? 'Entrando…' : 'Entrar e sincronizar'}
        </button>
      </div>
      <p className="grupo-nota">
        Entre com a mesma conta nos dois iPhones para eles ficarem sempre iguais. O que já está neste iPhone vai junto para a nuvem.{' '}
        <button className="link-dado" onClick={async () => setMensagem(await esqueciSenha(email))}>Esqueci a senha</button>
      </p>
      {mensagem && <p className="grupo-nota" style={{ color: 'var(--texto)' }}>{mensagem}</p>}
    </div>
  )
}
