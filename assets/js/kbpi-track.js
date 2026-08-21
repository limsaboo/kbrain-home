/* ============================================================
   한국뇌심리연구소 - 방문/체류시간 기록 스크립트
   사용법: 각 페이지 </body> 앞에 아래 한 줄 추가
     <script src="/assets/js/kbpi-track.js" defer></script>
   특징
     - 개인정보를 수집하지 않습니다(로그인한 회원 이메일만 선택 기록)
     - 실패해도 페이지에 영향을 주지 않습니다(전 구간 try/catch)
     - 관리자 페이지는 자동 제외
   ============================================================ */
(function () {
  "use strict";
  try {
    var URL_BASE = "https://grxqfaeznqqohnlltged.supabase.co";
    var KEY = "sb_publishable_Sgv6BVPo1dOnVICcX1tfzA_gf7T5Z4I";
    var ENDPOINT = URL_BASE + "/rest/v1/page_views";

    var path = location.pathname || "/";

    /* 관리자·미리보기 화면은 통계에서 제외 */
    if (/admin|dashboard/i.test(path)) return;
    if (/[?&]preview=1/.test(location.search)) return;

    /* ---- 방문자/세션 식별값 (개인정보 아님, 무작위 문자열) ---- */
    function rid() {
      return Date.now().toString(36) + Math.random().toString(36).slice(2, 10);
    }
    function get(store, key) {
      try { return store.getItem(key); } catch (e) { return null; }
    }
    function set(store, key, val) {
      try { store.setItem(key, val); } catch (e) {}
    }

    var visitorId = get(localStorage, "kbpi_vid");
    if (!visitorId) { visitorId = rid(); set(localStorage, "kbpi_vid", visitorId); }

    var sessionId = get(sessionStorage, "kbpi_sid");
    if (!sessionId) { sessionId = rid(); set(sessionStorage, "kbpi_sid", sessionId); }

    /* 로그인한 회원이 있으면 이메일만 (없으면 null) */
    var memberEmail =
      get(localStorage, "kbpi_member_email") ||
      get(localStorage, "memberEmail") ||
      get(sessionStorage, "memberEmail") || null;

    var device = /Mobi|Android|iPhone|iPad/i.test(navigator.userAgent) ? "mobile" : "desktop";

    var startedAt = Date.now();
    var sent = false;

    function payload(isFinal) {
      return JSON.stringify([{
        session_id: sessionId,
        visitor_id: visitorId,
        member_email: memberEmail,
        page: path,
        page_title: (document.title || "").slice(0, 120),
        referrer: document.referrer || null,
        duration_sec: Math.min(7200, Math.round((Date.now() - startedAt) / 1000)),
        device: device,
        is_final: !!isFinal
      }]);
    }

    function send(isFinal) {
      if (sent) return;
      sent = true;
      var body = payload(isFinal);
      try {
        /* sendBeacon 은 페이지가 닫혀도 전송을 보장합니다 */
        if (navigator.sendBeacon) {
          var blob = new Blob([body], { type: "application/json" });
          var ok = navigator.sendBeacon(
            ENDPOINT + "?apikey=" + encodeURIComponent(KEY), blob);
          if (ok) return;
        }
      } catch (e) {}
      try {
        fetch(ENDPOINT, {
          method: "POST",
          keepalive: true,
          headers: {
            "apikey": KEY,
            "Authorization": "Bearer " + KEY,
            "Content-Type": "application/json",
            "Prefer": "return=minimal"
          },
          body: body
        }).catch(function () {});
      } catch (e) {}
    }

    /* 페이지를 떠날 때 1건 기록 */
    document.addEventListener("visibilitychange", function () {
      if (document.visibilityState === "hidden") send(true);
    });
    window.addEventListener("pagehide", function () { send(true); });

    /* 오래 머무는 경우 유실 방지: 3분 시점에 중간 기록 후 타이머 재시작 */
    setTimeout(function () {
      if (sent) return;
      send(false);
      sent = false;
      startedAt = Date.now();
    }, 180000);
  } catch (e) {
    /* 통계 실패가 화면에 영향을 주지 않도록 조용히 무시 */
  }
})();
