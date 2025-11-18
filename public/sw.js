// Service Worker for flipbook app
// Cache version
const CACHE_VERSION = 'v1';
const STATIC_CACHE = `static-${CACHE_VERSION}`;
const RUNTIME_CACHE = `runtime-${CACHE_VERSION}`;

// Core assets to always cache (add more if needed)
const CORE_ASSETS = [
  '/',
  '/logo_transparent.png',
  '/favicon.svg',
  '/images/thumbnails/album1.jpg',
  '/images/thumbnails/album2.jpg',
  '/images/thumbnails/album3.jpg',
  '/pdfs/catalog.pdf',
  '/pdfs/portfolio.pdf'
];

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(STATIC_CACHE).then(cache => cache.addAll(CORE_ASSETS))
      .then(() => self.skipWaiting())
  );
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then(keys => Promise.all(
      keys.filter(k => ![STATIC_CACHE, RUNTIME_CACHE].includes(k)).map(k => caches.delete(k))
    )).then(() => self.clients.claim())
  );
});

// Helper: cache-first for images (with graceful fallback)
async function cacheFirst(request) {
  const cache = await caches.open(RUNTIME_CACHE);
  const cached = await cache.match(request);
  if (cached) return cached;
  try {
    const response = await fetch(request);
    if (response && response.status === 200) {
      cache.put(request, response.clone());
    }
    return response;
  } catch (err) {
    return cached || Response.error();
  }
}

// Helper: network-first for PDFs (so updates propagate)
async function networkFirst(request) {
  const cache = await caches.open(RUNTIME_CACHE);
  try {
    const response = await fetch(request);
    if (response && response.status === 200) {
      cache.put(request, response.clone());
    }
    return response;
  } catch (err) {
    const cached = await cache.match(request);
    return cached || Response.error();
  }
}

self.addEventListener('fetch', (event) => {
  const { request } = event;
  const url = new URL(request.url);

  // Only handle same-origin requests
  if (url.origin !== self.location.origin) return;

  // Images
  if (request.destination === 'image' || /\.(png|jpg|jpeg|gif|webp|svg)$/i.test(url.pathname)) {
    event.respondWith(cacheFirst(request));
    return;
  }

  // PDFs
  if (/\.pdf$/i.test(url.pathname)) {
    event.respondWith(networkFirst(request));
    return;
  }
});

// Dynamic precache of flipbook pages (sent from page script)
self.addEventListener('message', async (event) => {
  const { type, urls } = event.data || {};
  if (type === 'PRECACHE_FLIPBOOK' && Array.isArray(urls)) {
    const cache = await caches.open(RUNTIME_CACHE);
    urls.forEach(async (u) => {
      try {
        const req = new Request(u);
        const existing = await cache.match(req);
        if (!existing) {
          const resp = await fetch(req);
            if (resp && resp.status === 200) {
              cache.put(req, resp.clone());
            }
        }
      } catch (e) {
        // Ignore individual failures
      }
    });
  }
});

