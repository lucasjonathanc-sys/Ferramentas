// Service worker simples: guarda o app para abrir sem internet.
// Páginas: busca na rede primeiro (para pegar atualizações) e usa o cache se estiver offline.
// Arquivos (JS, CSS, fontes, ícones): usa o cache e atualiza em segundo plano.
const CACHE = 'hb-organiza-v1'
const ESCOPO = self.registration.scope

self.addEventListener('install', (e) => {
  e.waitUntil(caches.open(CACHE).then((c) => c.addAll([ESCOPO])).then(() => self.skipWaiting()))
})

self.addEventListener('activate', (e) => {
  e.waitUntil(
    caches.keys()
      .then((chaves) => Promise.all(chaves.filter((k) => k !== CACHE).map((k) => caches.delete(k))))
      .then(() => self.clients.claim()),
  )
})

self.addEventListener('fetch', (e) => {
  const req = e.request
  if (req.method !== 'GET' || !req.url.startsWith(ESCOPO)) return

  if (req.mode === 'navigate') {
    e.respondWith(
      fetch(req)
        .then((res) => {
          // Só guarda páginas que vieram certas; se o site estiver fora do ar (404), usa a cópia salva
          if (!res.ok) return caches.match(ESCOPO).then((salva) => salva || res)
          const copia = res.clone()
          caches.open(CACHE).then((c) => c.put(ESCOPO, copia))
          return res
        })
        .catch(() => caches.match(ESCOPO)),
    )
    return
  }

  e.respondWith(
    caches.match(req).then((emCache) => {
      const rede = fetch(req)
        .then((res) => {
          if (res.ok) {
            const copia = res.clone()
            caches.open(CACHE).then((c) => c.put(req, copia))
          }
          return res
        })
        .catch(() => emCache)
      return emCache || rede
    }),
  )
})
