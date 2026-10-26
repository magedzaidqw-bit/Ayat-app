// خدمة عمل بسيطة: شرطها فقط أن يعتبر المتصفح الموقع قابلاً للتثبيت كتطبيق.
// لا تُخزّن أي شيء: كل الطلبات تذهب للشبكة مباشرة، فلا تظهر نسخ قديمة أبداً.
self.addEventListener('install', function(e){ self.skipWaiting(); });
self.addEventListener('activate', function(e){
  e.waitUntil(caches.keys().then(function(ks){ return Promise.all(ks.map(function(k){ return caches.delete(k); })); }).then(function(){ return self.clients.claim(); }));
});
self.addEventListener('fetch', function(e){ e.respondWith(fetch(e.request)); });
