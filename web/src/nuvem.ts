// Sincronização com a nuvem (Firebase): login por e-mail e senha + Firestore.
// Os dados continuam guardados no iPhone; a nuvem mantém os dois aparelhos iguais.
//
// Estrutura no Firestore (cada pessoa só acessa a própria pasta, pelas regras):
//   usuarios/{uid}/atividades/{id}
//   usuarios/{uid}/clientes/{id}
//   usuarios/{uid}/ideias/{id}
//   usuarios/{uid}/config/perfil   → { nome }
import { initializeApp } from 'firebase/app'
import {
  type Auth, connectAuthEmulator, getAuth, onAuthStateChanged, sendPasswordResetEmail, signInWithEmailAndPassword, signOut,
} from 'firebase/auth'
import {
  type Firestore, collection, connectFirestoreEmulator, doc, getDoc, getDocs, initializeFirestore, onSnapshot,
  persistentLocalCache, persistentMultipleTabManager, writeBatch, type Unsubscribe,
} from 'firebase/firestore'
import { firebaseConfig } from './firebaseConfig'
import {
  type Estado, aplicarDaNuvem, estadoAtual, limparDadosLocais, registrarSincronizacao,
} from './store'
import { normalizarAtividade, normalizarCliente, normalizarIdeia } from './modelo'
import type { Atividade, Cliente, Ideia } from './modelo'

// MARK: - Situação da sincronização (para a tela)

export type SituacaoNuvem =
  | { tipo: 'desligada' } // Firebase ainda não configurado no código
  | { tipo: 'iniciando' }
  | { tipo: 'fora' } // configurado, mas ninguém entrou neste aparelho
  | { tipo: 'conectada'; email: string }

let situacao: SituacaoNuvem = firebaseConfig ? { tipo: 'iniciando' } : { tipo: 'desligada' }
const ouvintes = new Set<() => void>()
const mudarSituacao = (s: SituacaoNuvem) => {
  situacao = s
  ouvintes.forEach((f) => f())
}
export const situacaoNuvem = () => situacao
export function ouvirSituacao(f: () => void) {
  ouvintes.add(f)
  return () => { ouvintes.delete(f) }
}

// MARK: - Inicialização

const CHAVE_SINCRONIZADO = 'hb-organiza-nuvem-uid'
const COLECOES = ['atividades', 'clientes', 'ideias'] as const
type Colecao = (typeof COLECOES)[number]

let auth: Auth | null = null
let db: Firestore | null = null
let pararDeOuvir: Unsubscribe[] = []

export function iniciarNuvem() {
  if (!firebaseConfig || auth) return
  const app = initializeApp(firebaseConfig)
  auth = getAuth(app)
  db = initializeFirestore(app, {
    ignoreUndefinedProperties: true,
    // Cache no aparelho: funciona sem internet e sincroniza quando voltar
    localCache: persistentLocalCache({ tabManager: persistentMultipleTabManager() }),
  })
  if (import.meta.env.VITE_FIREBASE_EMULADOR) {
    connectAuthEmulator(auth, 'http://127.0.0.1:9099', { disableWarnings: true })
    connectFirestoreEmulator(db, '127.0.0.1', 8080)
  }
  onAuthStateChanged(auth, (usuario) => {
    pararSincronizacao()
    if (!usuario) {
      mudarSituacao({ tipo: 'fora' })
      return
    }
    mudarSituacao({ tipo: 'conectada', email: usuario.email ?? '' })
    void comecarSincronizacao(usuario.uid)
  })
}

// MARK: - Login

const mensagensErro: Record<string, string> = {
  'auth/invalid-credential': 'E-mail ou senha incorretos.',
  'auth/wrong-password': 'E-mail ou senha incorretos.',
  'auth/user-not-found': 'E-mail ou senha incorretos.',
  'auth/invalid-email': 'Esse e-mail não parece válido.',
  'auth/too-many-requests': 'Muitas tentativas. Espere alguns minutos e tente de novo.',
  'auth/network-request-failed': 'Sem internet. Conecte e tente de novo.',
  'auth/user-disabled': 'Essa conta foi desativada.',
}
const traduzir = (e: unknown) =>
  mensagensErro[(e as { code?: string })?.code ?? ''] ?? 'Não deu certo. Confira os dados e tente de novo.'

export async function entrar(email: string, senha: string): Promise<string | null> {
  if (!auth) return 'A sincronização ainda não está configurada.'
  try {
    await signInWithEmailAndPassword(auth, email.trim(), senha)
    return null
  } catch (e) {
    return traduzir(e)
  }
}

export async function esqueciSenha(email: string): Promise<string> {
  if (!auth) return 'A sincronização ainda não está configurada.'
  if (!email.trim()) return 'Digite o seu e-mail acima primeiro.'
  try {
    await sendPasswordResetEmail(auth, email.trim())
    return 'Enviamos um link para criar uma senha nova. Confira o e-mail (e o spam).'
  } catch (e) {
    return traduzir(e)
  }
}

/** Sai da conta neste aparelho. Os dados continuam na nuvem e no outro iPhone. */
export async function sair() {
  if (!auth) return
  pararSincronizacao()
  await signOut(auth)
  localStorage.removeItem(CHAVE_SINCRONIZADO)
  limparDadosLocais()
}

// MARK: - Sincronização

function pararSincronizacao() {
  registrarSincronizacao(null)
  pararDeOuvir.forEach((f) => f())
  pararDeOuvir = []
}

const pasta = (uid: string, c: Colecao) => collection(db!, 'usuarios', uid, c)
const perfilRef = (uid: string) => doc(db!, 'usuarios', uid, 'config', 'perfil')

async function comecarSincronizacao(uid: string) {
  if (!db) return

  // Primeiro login neste aparelho: junta o que já estava no iPhone com o que está na nuvem
  if (localStorage.getItem(CHAVE_SINCRONIZADO) !== uid) {
    await juntarComANuvem(uid)
    localStorage.setItem(CHAVE_SINCRONIZADO, uid)
  }

  // A partir daqui, toda mudança feita no app vai para a nuvem...
  registrarSincronizacao((antes, depois) => { void enviarMudancas(uid, antes, depois) })

  // ...e tudo que muda na nuvem (inclusive vindo do outro iPhone) chega ao vivo
  pararDeOuvir.push(
    onSnapshot(pasta(uid, 'atividades'), (snap) => {
      aplicarDaNuvem({ atividades: snap.docs.map((d) => normalizarAtividade(d.data() as Atividade)) })
    }),
    onSnapshot(pasta(uid, 'clientes'), (snap) => {
      aplicarDaNuvem({ clientes: snap.docs.map((d) => normalizarCliente(d.data() as Cliente)) })
    }),
    onSnapshot(pasta(uid, 'ideias'), (snap) => {
      aplicarDaNuvem({ ideias: snap.docs.map((d) => normalizarIdeia(d.data() as Ideia)) })
    }),
    onSnapshot(perfilRef(uid), (snap) => {
      const nome = snap.data()?.nome
      if (typeof nome === 'string') aplicarDaNuvem({ nome })
    }),
  )
}

/** Envia para a nuvem o que existe neste iPhone e ainda não existe lá (nada é apagado). */
async function juntarComANuvem(uid: string) {
  const local = estadoAtual()
  const lotes: Array<() => Promise<void>> = []
  let lote = writeBatch(db!)
  let ops = 0
  const adicionar = (fn: (b: ReturnType<typeof writeBatch>) => void) => {
    fn(lote)
    ops++
    if (ops === 450) {
      const atual = lote
      lotes.push(() => atual.commit())
      lote = writeBatch(db!)
      ops = 0
    }
  }

  for (const c of COLECOES) {
    const naNuvem = new Set((await getDocs(pasta(uid, c))).docs.map((d) => d.id))
    for (const item of local[c] as { id: string }[]) {
      if (!naNuvem.has(item.id)) adicionar((b) => b.set(doc(pasta(uid, c), item.id), item))
    }
  }
  const perfil = await getDoc(perfilRef(uid))
  if (!perfil.exists()) adicionar((b) => b.set(perfilRef(uid), { nome: local.nome }))

  if (ops > 0) lotes.push(() => lote.commit())
  for (const enviar of lotes) await enviar()
}

/** Compara antes e depois e envia só o que mudou (criado, alterado ou apagado). */
async function enviarMudancas(uid: string, antes: Estado, depois: Estado) {
  if (!db) return
  let lote = writeBatch(db)
  let ops = 0
  const enviar: Promise<void>[] = []
  const registrar = (fn: (b: ReturnType<typeof writeBatch>) => void) => {
    fn(lote)
    if (++ops === 450) {
      enviar.push(lote.commit())
      lote = writeBatch(db!)
      ops = 0
    }
  }

  for (const c of COLECOES) {
    const velhos = new Map((antes[c] as { id: string }[]).map((x) => [x.id, JSON.stringify(x)]))
    const novos = new Map((depois[c] as { id: string }[]).map((x) => [x.id, x]))
    for (const [id, item] of novos) {
      if (velhos.get(id) !== JSON.stringify(item)) registrar((b) => b.set(doc(pasta(uid, c), id), item))
    }
    for (const id of velhos.keys()) {
      if (!novos.has(id)) registrar((b) => b.delete(doc(pasta(uid, c), id)))
    }
  }
  if (antes.nome !== depois.nome) registrar((b) => b.set(perfilRef(uid), { nome: depois.nome }))

  if (ops > 0) enviar.push(lote.commit())
  // Sem internet, o Firestore guarda no aparelho e envia quando a conexão voltar
  await Promise.all(enviar).catch(() => {})
}
