// 한국뇌심리연구소 홈페이지 - 서비스워커
// 목적: 크롬 안드로이드의 PWA 설치 가능 조건(installability) 충족
//       → 홈 화면에 추가 시 주소창/메뉴 없는 완전한 standalone 앱으로 인식되게 함
const CACHE_NAME = 'kbrain-home-v1';
const CORE_ASSETS = [
  './',
  './index.html',
  './manifest.json'
];

self.addEventListener('install', function(event) {
  event.waitUntil(
    caches.open(CACHE_NAME).then(function(cache) {
      return cache.addAll(CORE_ASSETS);
    }).then(function() {
      return self.skipWaiting();
    })
  );
});

self.addEventListener('activate', function(event) {
  event.waitUntil(
    caches.keys().then(function(keys) {
      return Promise.all(
        keys.filter(function(key) { return key !== CACHE_NAME; })
            .map(function(key) { return caches.delete(key); })
      );
    }).then(function() {
      return self.clients.claim();
    })
  );
});

// 네트워크 우선, 실패 시 캐시 (오프라인에서도 기본 화면은 뜨게)
self.addEventListener('fetch', function(event) {
  if (event.request.method !== 'GET') return;
  event.respondWith(
    fetch(event.request)
      .then(function(response) {
        var responseClone = response.clone();
        caches.open(CACHE_NAME).then(function(cache) {
          cache.put(event.request, responseClone);
        });
        return response;
      })
      .catch(function() {
        return caches.match(event.request);
      })
  );
});
