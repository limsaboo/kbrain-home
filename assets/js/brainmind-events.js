/* ============================================================
   BrainMind 이용 기록 스크립트 (brainmind-events.js)
   ------------------------------------------------------------
   기록하는 것 : 곡 재생 시작, 하단 버튼·링크 클릭 (횟수 분석용)
   기록하지 않는 것 : 이름·연락처·이메일 등 개인정보 (무작위 방문 코드만 사용)
   페이지 방문과 체류시간은 기존 kbpi-track.js 가 기록합니다.
   실패해도 화면과 재생에 영향이 없도록 전 구간 try/catch 입니다.
   ============================================================ */
(function () {
  "use strict";
  try {
    if (/[?&]preview=1/.test(location.search)) return;

    var URL_BASE = "https://grxqfaeznqqohnlltged.supabase.co";
    var KEY = "sb_publishable_Sgv6BVPo1dOnVICcX1tfzA_gf7T5Z4I";
    var ENDPOINT = URL_BASE + "/rest/v1/kbpi_events";

    function read(store, key) { try { return store.getItem(key); } catch (e) { return null; } }
    var device = /Mobi|Android|iPhone|iPad/i.test(navigator.userAgent) ? "mobile" : "desktop";

    function send(eventName, trackId, target) {
      try {
        var row = {
          event: eventName,
          track_id: trackId || null,
          target: target ? String(target).slice(0, 200) : null,
          visitor_id: read(localStorage, "kbpi_vid"),
          session_id: read(sessionStorage, "kbpi_sid"),
          page: location.pathname,
          source: ((new URLSearchParams(location.search)).get("from") || (new URLSearchParams(location.search)).get("utm_source") || "").slice(0, 100) || null,
          device: device
        };
        fetch(ENDPOINT, {
          method: "POST",
          keepalive: true,
          mode: "cors",
          headers: {
            "apikey": KEY,
            "Authorization": "Bearer " + KEY,
            "Content-Type": "application/json",
            "Prefer": "return=minimal"
          },
          body: JSON.stringify([row])
        }).catch(function () {});
      } catch (e) {}
    }

    /* 곡 주소(src) → 곡 번호(id) */
    function idFromSrc(src) {
      try {
        var all = [].concat(typeof TRACKS !== "undefined" ? TRACKS : [], typeof BINAURAL !== "undefined" ? BINAURAL : []);
        var path = String(src || "").replace(location.origin, "");
        for (var i = 0; i < all.length; i++) {
          if (all[i].src === path) return all[i].id;
        }
      } catch (e) {}
      return null;
    }

    /* 재생: 곡을 처음부터 시작할 때만 1회 (일시정지 후 이어듣기는 제외) */
    var audio = document.getElementById("bmAudio");
    if (audio) {
      audio.addEventListener("play", function () {
        if (audio.currentTime > 1) return;
        send("play", idFromSrc(audio.getAttribute("src")), null);
      });
    }

    /* 링크 클릭: 하단 CTA(무료측정), 보조 링크, 돌아가기 */
    document.addEventListener("click", function (e) {
      var a = e.target && e.target.closest ? e.target.closest("a.bm-next, a.bm-back") : null;
      if (!a) return;
      var name = a.classList.contains("bm-back") ? "back_click" : "cta_click";
      send(name, null, a.getAttribute("href"));
    });
  } catch (e) {
    /* 기록 실패가 화면에 영향을 주지 않도록 조용히 무시 */
  }
})();
