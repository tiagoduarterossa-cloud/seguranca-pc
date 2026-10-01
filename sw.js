// Mudar a versão sempre que alterares algum ficheiro, para o iPhone buscar a nova.
const CACHE = 'seg-pc-v9';
const ASSETS = [
  './',
  './index.html',
  './manifest.webmanifest',
  './icons/apple-touch-icon.png',
  './icons/icon-192.png',
  './icons/icon-512.png',
  './icons/icon-maskable-512.png'
];

self.addEventListener('install', (e) => {
  e.waitUntil(caches.open(CACHE).then((c) => c.addAll(ASSETS)).then(() => self.skipWaiting()));
});

self.addEventListener('activate', (e) => {
  e.waitUntil(
    caches.keys()
      .then((keys) => Promise.all(keys.filter((k) => k !== CACHE).map((k) => caches.delete(k))))
      .then(() => self.clients.claim())
  );
});

// O ecrã Estado da app pergunta a versão e a lista de ficheiros para confirmar o modo offline.
self.addEventListener('message', (e) => {
  if (e.data && e.data.type === 'info' && e.ports[0]) e.ports[0].postMessage({ cache: CACHE, assets: ASSETS });
});

self.addEventListener('fetch', (e) => {
  if (e.request.method !== 'GET') return;
  const url = new URL(e.request.url);
  if (url.origin !== self.location.origin) return;

  // Página: tenta a rede para apanhar atualizações, sem rede usa a cópia guardada.
  if (e.request.mode === 'navigate') {
    e.respondWith(
      fetch(e.request)
        .then((res) => {
          const copy = res.clone();
          caches.open(CACHE).then((c) => c.put('./index.html', copy));
          return res;
        })
        .catch(() => caches.match('./index.html'))
    );
    return;
  }

  // Restantes ficheiros: cache primeiro.
  e.respondWith(caches.match(e.request).then((r) => r || fetch(e.request)));
});
