/* 뇌 5분 퀴즈 서비스워커 — 문서는 항상 서버 우선(network-first), 실패 시 저장본 */
const V='quiz-2026-11-10-v1';
self.addEventListener('install',e=>{self.skipWaiting()});
self.addEventListener('activate',e=>{e.waitUntil(caches.keys().then(k=>Promise.all(k.filter(x=>x.startsWith('quiz-')&&x!==V).map(x=>caches.delete(x)))).then(()=>self.clients.claim()))});
self.addEventListener('fetch',e=>{
 const r=e.request,u=new URL(r.url);
 if(r.method!=='GET'||u.origin!==location.origin||!u.pathname.startsWith('/quiz/'))return;
 e.respondWith(fetch(r).then(res=>{const c=res.clone();caches.open(V).then(ch=>ch.put(r,c));return res}).catch(()=>caches.match(r).then(m=>m||caches.match('/quiz/'))));
});
