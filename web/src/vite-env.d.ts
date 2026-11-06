/// <reference types="vite/client" />

interface ImportMetaEnv {
  /** Só para testes locais: conecta nos emuladores do Firebase */
  readonly VITE_FIREBASE_EMULADOR?: string
}
