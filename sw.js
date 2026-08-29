/* ==========================================================
   한국뇌심리연구소 서비스워커
   버전: 2026-08-30-v2

   [기존 문제]
   - cache-first 방식이라 저장된 것이 있으면 서버를 보지 않음
     → 홈페이지를 수정해도 방문자는 예전 화면을 계속 봄
   - 캐시 이름이 'kbrain-v1'로 고정되어 낡은 캐시가 사라지지 않음
   - HTML까지 캐시에 넣어 수정이 반영되지 않음

   [수정 방침]
   - HTML(문서)는 network-first: 항상 서버를 먼저 본다
   - CSS/JS/이미지/영상은 stale-while-revalidate:
     화면은 즉시 뜨고, 뒤에서 최신본을 받아 다음 방문에 반영
   - 배포할 때 CACHE_VERSION만 올리면 낡은 캐시가 자동 삭제됨
   ========================================================== */

const CACHE_VERSION = '2026-08-30-v2';
const CACHE_NAME    = `kbrain-${CACHE_VERSION}`;

/* 오프라인 대비 최소 자산만 미리 저장 (HTML은 넣지 않음) */
const PRECACHE = [
  '/assets/css/main.css',
  '/assets/css/mobile-fix.css',
  '/icon-192.png',
  '/manifest.json'
];

/* ---------- 설치 ---------- */
self.addEventListener('install', event => {
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then(cache => cache.addAll(PRECACHE).catch(() => {}))
      .then(() => self.skipWaiting())
  );
});

/* ---------- 활성화: 예전 캐시 전부 삭제 ---------- */
self.addEventListener('activate', event => {
  event.waitUntil(
    caches.keys()
      .then(names => Promise.all(
        names.map(n => (n !== CACHE_NAME ? caches.delete(n) : null))
      ))
      .then(() => self.clients.claim())
  );
});

/* ---------- 요청 처리 ---------- */
self.addEventListener('fetch', event => {
  const req = event.request;

  /* GET이 아니거나 외부 도메인이면 그대로 통과 */
  if (req.method !== 'GET') return;

  const url = new URL(req.url);
  if (url.origin !== self.location.origin) return;

  /* Supabase 등 API 호출은 캐시하지 않음 */
  if (url.pathname.startsWith('/rest/') || url.search.includes('apikey')) return;

  const isDocument =
    req.mode === 'navigate' ||
    req.destination === 'document' ||
    url.pathname.endsWith('.html') ||
    url.pathname === '/';

  /* ===== HTML: 서버 우선 ===== */
  if (isDocument) {
    event.respondWith(
      fetch(req)
        .then(res => {
          if (res && res.status === 200) {
            const copy = res.clone();
            caches.open(CACHE_NAME).then(c => c.put(req, copy));
          }
          return res;
        })
        .catch(() =>
          /* 네트워크 실패(오프라인)일 때만 저장본 사용 */
          caches.match(req).then(r => r || caches.match('/index.html'))
        )
    );
    return;
  }

  /* ===== 그 외 자산: 저장본 즉시 표시 + 뒤에서 갱신 ===== */
  event.respondWith(
    caches.match(req).then(cached => {
      const network = fetch(req)
        .then(res => {
          if (res && res.status === 200 && res.type !== 'opaque') {
            const copy = res.clone();
            caches.open(CACHE_NAME).then(c => c.put(req, copy));
          }
          return res;
        })
        .catch(() => cached);

      return cached || network;
    })
  );
});

/* ---------- 관리자용: 즉시 갱신 명령 ---------- */
self.addEventListener('message', event => {
  if (event.data === 'SKIP_WAITING') self.skipWaiting();
  if (event.data === 'CLEAR_CACHE') {
    caches.keys().then(names => names.forEach(n => caches.delete(n)));
  }
});
