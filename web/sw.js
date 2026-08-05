const CACHE_NAME = 'bookrabbit-offline-v1';
const OFFLINE_URL = 'offline.html';

const ASSETS_TO_CACHE = [
  './',
  './index.html',
  './offline.html',
  './assets/images/no_internet.png',
  './assets/assets/images/no_internet.png',
  './favicon.png',
  './manifest.json'
];

// 1. Install Event: Cache essential assets & offline HTML page
self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => {
      console.log('[ServiceWorker] Pre-caching BookRabbit offline page & assets');
      return cache.addAll(ASSETS_TO_CACHE).catch((err) => {
        console.warn('[ServiceWorker] Pre-cache partial warning:', err);
        return cache.add(OFFLINE_URL);
      });
    }).then(() => self.skipWaiting())
  );
});

// 2. Activate Event: Clean old caches and claim clients immediately
self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((cacheNames) => {
      return Promise.all(
        cacheNames.map((cacheName) => {
          if (cacheName !== CACHE_NAME) {
            console.log('[ServiceWorker] Removing old cache:', cacheName);
            return caches.delete(cacheName);
          }
        })
      );
    }).then(() => self.clients.claim())
  );
});

// 3. Fetch Event: Intercept network requests & serve offline.html when network is down
self.addEventListener('fetch', (event) => {
  if (event.request.mode === 'navigate') {
    event.respondWith(
      fetch(event.request).catch(() => {
        console.log('[ServiceWorker] Offline detected for navigation. Serving custom offline page.');
        return caches.match(OFFLINE_URL).then((response) => {
          if (response) {
            return response;
          }
          return caches.match('./offline.html');
        });
      })
    );
    return;
  }

  // Handle static asset requests (Network-first with Cache Fallback)
  event.respondWith(
    fetch(event.request).catch(() => {
      return caches.match(event.request);
    })
  );
});
