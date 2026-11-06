import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

declare const process: { env: Record<string, string | undefined> }

// Publicado no GitHub Pages em https://<usuário>.github.io/<repositório>/.
// O workflow passa o caminho em BASE_PATH (ex.: /db-organiza/), então renomear o
// repositório não exige mudar o código. Localmente usa /Ferramentas/.
export default defineConfig({
  base: process.env.BASE_PATH || '/Ferramentas/',
  plugins: [react()],
})
