/* ==========================================================
   한국뇌심리연구소 — 업데이트 감지 배너
   목적: 임박사님이 페이지를 열어둔 채로 있는 동안 서버에
   새 배포가 올라가면, 새로고침 없이는 예전 코드가 계속
   실행되는 문제(서비스워커가 "이미 열린 탭"까지는 갱신하지
   못함)를 사용자에게 알려 즉시 새로고침하도록 안내한다.

   동작:
   - 페이지 로드 시 /version.json 을 한 번 읽어 기준값 저장
   - 25초마다, 그리고 탭이 다시 화면에 보일 때마다 재확인
   - 기준값과 다르면 화면 하단에 "새 버전이 있습니다" 배너 표시
   - 배너를 탭하면 즉시 새로고침

   새 페이지에 적용하려면:
   <script src="/assets/js/update-checker.js" defer></script>
   한 줄만 추가하면 된다. version.json은 배포 때마다 갱신되어야
   갱신 알림이 정상 동작한다.
   ========================================================== */
(function () {
  var CHECK_INTERVAL_MS = 25000;
  var VERSION_URL = '/version.json';
  var baseVersion = null;
  var bannerShown = false;

  function fetchVersion() {
    return fetch(VERSION_URL + '?t=' + Date.now(), { cache: 'no-store' })
      .then(function (res) { return res.ok ? res.json() : null; })
      .then(function (data) { return data && data.v; })
      .catch(function () { return null; });
  }

  function showUpdateBanner() {
    if (bannerShown) return;
    bannerShown = true;
    var banner = document.createElement('div');
    banner.id = 'kbrainUpdateBanner';
    banner.textContent = '🔄 새 버전이 있습니다 — 탭하여 새로고침';
    banner.setAttribute('role', 'button');
    banner.style.cssText = [
      'position:fixed', 'left:50%', 'bottom:18px', 'transform:translateX(-50%)',
      'z-index:99999', 'background:#111827', 'color:#fff',
      'font-size:14px', 'font-weight:700', 'padding:12px 20px',
      'border-radius:999px', 'box-shadow:0 6px 20px rgba(0,0,0,.3)',
      'cursor:pointer', 'white-space:nowrap', 'letter-spacing:-0.2px'
    ].join(';');
    banner.addEventListener('click', function () {
      window.location.reload();
    });
    document.body.appendChild(banner);
  }

  function checkVersion() {
    fetchVersion().then(function (v) {
      if (!v) return;
      if (baseVersion === null) { baseVersion = v; return; }
      if (v !== baseVersion) showUpdateBanner();
    });
  }

  function init() {
    fetchVersion().then(function (v) { baseVersion = v; });
    setInterval(checkVersion, CHECK_INTERVAL_MS);
    document.addEventListener('visibilitychange', function () {
      if (document.visibilityState === 'visible') checkVersion();
    });
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }
})();
