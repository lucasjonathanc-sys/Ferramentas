import type { FirebaseOptions } from 'firebase/app'

// Configuração do app no Firebase (Configurações do projeto → Seus apps → Web).
// Pode ficar no código público: quem protege os dados são o login e as regras
// do Firestore (arquivo firestore.rules). Enquanto for null, a sincronização fica desligada.
const configuracao: FirebaseOptions | null = null

// Só para testes locais com os emuladores do Firebase (projeto "demo-", sem nuvem de verdade)
const emulador: FirebaseOptions = { apiKey: 'teste', authDomain: 'demo-db-organiza.firebaseapp.com', projectId: 'demo-db-organiza', appId: 'teste' }

export const firebaseConfig: FirebaseOptions | null = import.meta.env.VITE_FIREBASE_EMULADOR ? emulador : configuracao
