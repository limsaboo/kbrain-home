/* 강사 오디션 연습실 - 서비스워커 (앱 파일을 폰에 저장해 빠르게 열고, 최신 버전을 우선 확인) */
var CACHE='audition-v1';
var SHELL=['./','index.html','manifest.json','icon-192.png','icon-512.png','icon-maskable-512.png','apple-touch-icon.png',
  'img/place_hall.jpg','img/place_living.jpg','img/place_class.jpg','img/place_cafe.jpg','img/place_studio.jpg','img/place_garden.jpg'];
self.addEventListener('install',function(e){
  self.skipWaiting();
  e.waitUntil(caches.open(CACHE).then(function(c){return Promise.all(SHELL.map(function(u){return c.add(u).catch(function(){})}))}));
});
self.addEventListener('activate',function(e){
  e.waitUntil(caches.keys().then(function(ks){return Promise.all(ks.filter(function(k){return k!==CACHE}).map(function(k){return caches.delete(k)}))}).then(function(){return self.clients.claim()}));
});
self.addEventListener('fetch',function(e){
  var r=e.request; if(r.method!=='GET')return;
  var u=new URL(r.url); if(u.origin!==location.origin)return; /* 외부(표정 분석 도구)는 건드리지 않음 */
  /* 네트워크 우선, 실패하면 저장본 → 최신 버전을 항상 먼저 보고, 인터넷이 없으면 저장본으로 열림 */
  e.respondWith(fetch(r).then(function(res){
    if(res&&res.ok){var cp=res.clone(); caches.open(CACHE).then(function(c){c.put(r,cp)})}
    return res;
  }).catch(function(){return caches.match(r).then(function(m){return m||caches.match('index.html')})}));
});
