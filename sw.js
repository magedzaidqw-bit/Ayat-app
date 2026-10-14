// خدمة العمل دون اتصال لبرنامج آيات.
// الاستراتيجية: الشبكة أولاً، ثم النسخة المخزّنة عند انقطاع الاتصال، حتى تصل التحديثات فوراً.
const CACHE_NAME = 'ayat-v2';
const urlsToCache = [
  './',
  './index.html',
  './manifest.json',
  './ayat-logo.png',
  './ayat-logo-192.png'
];

self.addEventListener('install', event => {
  self.skipWaiting();
  event.waitUntil(
    caches.open(CACHE_NAME).then(cache => cache.addAll(urlsToCache))
  );
});

self.addEventListener('activate', event => {
  event.waitUntil(
    caches.keys()
      .then(keys => Promise.all(keys.filter(k => k !== CACHE_NAME).map(k => caches.delete(k))))
      .then(() => self.clients.claim())
  );
});

self.addEventListener('fetch', event => {
  if (event.request.method !== 'GET') return;
  // لا نتدخل في طلبات قاعدة البيانات والخدمات الخارجية
  if (new URL(event.request.url).origin !== self.location.origin) return;
  event.respondWith(
    fetch(event.request)
      .then(response => {
        const copy = response.clone();
        caches.open(CACHE_NAME).then(cache => cache.put(event.request, copy));
        return response;
      })
      .catch(() => caches.match(event.request))
  );
});
