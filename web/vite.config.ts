import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

// Publicado no GitHub Pages em https://<usuário>.github.io/Ferramentas/
export default defineConfig({
  base: '/Ferramentas/',
  plugins: [react()],
})
