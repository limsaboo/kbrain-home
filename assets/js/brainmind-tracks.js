/* ============================================================
   BrainMind 곡 목록 데이터 파일  (brainmind-tracks.js)
   ------------------------------------------------------------
   곡을 추가·수정·순서변경 하려면 이 파일만 고치면 됩니다.
   brainmind.html 은 건드리지 않아도 됩니다.
   파일 맨 아래 "곡 추가 방법" 안내를 참고하세요.
   ============================================================ */
/* ------------------------------------------------------------
   음원 등록표
   ------------------------------------------------------------
   id    : 홈페이지 내부 관리번호 (Suno 공식 ID 아님)
   title : 곡 제목
   style : Suno 스타일 표기 (화면에서 확인된 값 그대로)
   made  : Suno 제작 화면 표기일
   len   : 재생시간
   desc  : 감상 안내 문구
   src   : ★ 실제 음원 경로 또는 실제 공개 URL. 확인 전에는 반드시 "" 로 둘 것.
           예) src: "/assets/audio/BM-001_너에게편지를써.mp3"
   ============================================================ */

var TRACKS = [
  {
    id: "BM-001",
    title: "너에게 편지를 써",
    style: "ballad, K-pop, singer-songwriter",
    made: "2025-09-28",
    len: "2분 15초",
    desc: "말로 다 못한 마음을 편지처럼 눌러 담은 곡입니다. 조용히 혼자 있을 때 들어보세요.",
    src: "/assets/audio/BM-001.mp3"
  },
  {
    id: "BM-002",
    title: "나의 사랑, 그대여",
    style: "korean trot, emo, husky male vocals",
    made: "2025-09-27",
    len: "2분 47초",
    desc: "오래 함께한 사람을 떠올리며 듣기 좋은 곡입니다.",
    src: "/assets/audio/BM-002.mp3"
  },
  {
    id: "BM-003",
    title: "늘 내 곁에 너",
    len: "2분 50초",
    desc: "곁에 있는 사람의 소중함을 담은 곡입니다.",
    src: "/assets/audio/BM-003.mp3"
  },
  {
    id: "BM-004",
    title: "시니어의 하루",
    len: "2분 31초",
    desc: "평범한 하루를 따뜻하게 그린 곡입니다.",
    src: "/assets/audio/BM-004.mp3"
  },
  {
    id: "BM-005",
    title: "인생은 차차차",
    len: "1분 27초",
    desc: "가볍고 경쾌하게 들으시기 좋은 곡입니다.",
    src: "/assets/audio/BM-005.mp3"
  },
  {
    id: "BM-006",
    title: "브라보 내 인생",
    len: "3분 16초",
    desc: "지나온 삶을 응원하는 마음을 담은 곡입니다.",
    src: "/assets/audio/BM-006.mp3"
  },
  {
    id: "BM-007",
    title: "돌아와",
    len: "1분 55초",
    desc: "그리운 마음을 담은 곡입니다.",
    src: "/assets/audio/BM-007.mp3"
  },
  {
    id: "BM-008",
    title: "품바아리랑",
    len: "2분 51초",
    desc: "흥과 해학이 담긴 곡입니다.",
    src: "/assets/audio/BM-008.mp3"
  },
  {
    id: "BM-009",
    title: "아그들아 담배 좀 끊어라",
    len: "3분 30초",
    desc: "정겨운 잔소리를 노래로 담은 곡입니다.",
    src: "/assets/audio/BM-009.mp3"
  },
  {
    id: "BM-010",
    title: "우린 지금 짬뽕을 먹으러 간다",
    len: "1분 50초",
    desc: "일상의 소소한 즐거움을 담은 곡입니다.",
    src: "/assets/audio/BM-010.mp3"
  },
  {
    id: "BM-011",
    title: "요들 크리스마스 캐롤",
    len: "1분 13초",
    desc: "연말 분위기를 위한 계절 한정곡입니다.",
    src: "/assets/audio/BM-011.mp3"
  },
  {
    id: "BM-012",
    title: "내 청춘, 다시 한번",
    style: "trot, Korean traditional pop",
    made: "2025-09-27",
    len: "3분 20초",
    desc: "지나온 시간을 원망이 아니라 반가움으로 바라보게 하는 곡입니다.",
    src: "/assets/audio/BM-012.mp3"
  },
  {
    id: "BM-013",
    title: "인생은 지금부터야",
    style: "trot, retro pop",
    made: "2025-09-27",
    len: "2분 31초",
    desc: "기운이 필요한 아침에 한 번 틀어두시면 좋은 곡입니다.",
    src: "/assets/audio/BM-013.mp3"
  },
  {
    id: "BM-014",
    title: "나야나",
    style: "deep husky male vocals, korean trot",
    made: "2025-12-07",
    len: "2분 20초",
    desc: "흥겹고 힘찬 리듬으로 기분을 북돋우는 곡입니다.",
    src: "/assets/audio/BM-014.mp3"
  },
  {
    id: "BM-015",
    title: "추억의 크리스마스 카드",
    style: "acoustic, holiday, K-pop ballad",
    made: "2025-09-29",
    len: "1분 29초",
    desc: "연말 분위기 속 그리운 추억을 담은 곡입니다.",
    src: "/assets/audio/BM-015.mp3"
  },
  {
    id: "BM-016",
    title: "알프스 산장의 만두라면",
    len: "1분 55초",
    desc: "재치와 유머가 담긴 곡입니다.",
    src: "/assets/audio/BM-016.mp3"
  },
  {
    id: "BM-017",
    title: "젊은 연인",
    style: "여성보컬",
    len: "2분 36초",
    desc: "설레는 마음을 담은 곡입니다.",
    src: "/assets/audio/BM-017.mp3"
  },
  {
    id: "BM-018",
    title: "99팔팔123死",
    style: "Remastered",
    len: "2분 38초",
    desc: "건강하게 오래 살자는 마음을 담은 곡입니다.",
    src: "/assets/audio/BM-018.mp3"
  },
  {
    id: "BM-019",
    title: "인생의 후반전",
    len: "2분 46초",
    desc: "삶의 후반을 담담하게 그린 곡입니다.",
    src: "/assets/audio/BM-019.mp3"
  },
  {
    id: "BM-020",
    title: "먼 길 떠나는 밤",
    len: "2분 17초",
    desc: "긴 여정을 떠나는 마음을 담은 곡입니다.",
    src: "/assets/audio/BM-020.mp3"
  },
  {
    id: "BM-021",
    title: "Our Concert Forever",
    len: "1분 22초",
    desc: "함께하는 순간을 담은 곡입니다.",
    src: "/assets/audio/BM-021.mp3"
  },
  {
    id: "BM-022",
    title: "오 해피 크리스마스 캐롤",
    len: "2분 13초",
    desc: "연말 분위기를 위한 계절 한정곡입니다.",
    src: "/assets/audio/BM-022.mp3"
  },
  {
    id: "BM-023",
    title: "청춘아 가지마",
    len: "3분 12초",
    desc: "흘러가는 젊음을 붙잡고 싶은 마음을 담은 곡입니다.",
    src: "/assets/audio/BM-023.mp3"
  },
  {
    id: "BM-024",
    title: "내 인생의 연장전",
    len: "3분 15초",
    desc: "다시 뛰는 인생 후반전을 응원하는 곡입니다.",
    src: "/assets/audio/BM-024.mp3"
  },
  {
    id: "BM-025",
    title: "첫눈",
    len: "2분 30초",
    desc: "첫눈이 내리는 날의 설렘을 담은 곡입니다.",
    src: "/assets/audio/BM-025.mp3"
  },
  {
    id: "BM-026",
    title: "사랑은 돌고 돈다",
    len: "2분 8초",
    desc: "돌고 도는 인연의 마음을 담은 곡입니다.",
    src: "/assets/audio/BM-026.mp3"
  },
  {
    id: "BM-027",
    title: "추억의 만두가게",
    len: "2분 45초",
    desc: "정겨운 옛 추억을 떠올리게 하는 곡입니다.",
    src: "/assets/audio/BM-027.mp3"
  },
  {
    id: "BM-028",
    title: "왜 왔니",
    len: "2분 49초",
    desc: "재치있는 가사가 담긴 곡입니다.",
    src: "/assets/audio/BM-028.mp3"
  },
  {
    id: "BM-029",
    title: "호떡이 좋아",
    len: "2분 2초",
    desc: "소소한 행복을 노래한 곡입니다.",
    src: "/assets/audio/BM-029.mp3"
  },
  {
    id: "BM-030",
    title: "노래를 부릅시다",
    len: "2분 53초",
    desc: "다 함께 흥겹게 부르기 좋은 곡입니다.",
    src: "/assets/audio/BM-030.mp3"
  },
  {
    id: "BM-031",
    title: "난 네가 좋아",
    len: "2분 15초",
    desc: "솔직한 마음을 담은 곡입니다.",
    src: "/assets/audio/BM-031.mp3"
  },
  {
    id: "BM-032",
    title: "겨울 밤, 밤샘공부와 라면",
    len: "3분 33초",
    desc: "추운 밤 함께한 시간을 담은 곡입니다.",
    src: "/assets/audio/BM-032.mp3"
  },
  {
    id: "BM-033",
    title: "고생 끝, 행복 시작",
    len: "1분 32초",
    desc: "지나온 고생을 다독이는 곡입니다.",
    src: "/assets/audio/BM-033.mp3"
  },
  {
    id: "BM-034",
    title: "트로트 차차차",
    len: "1분 27초",
    desc: "가볍고 경쾌한 트로트 리듬의 곡입니다.",
    src: "/assets/audio/BM-034.mp3"
  },
  {
    id: "BM-035",
    title: "시니어 전성시대 (백년해로 듀엣)",
    style: "임찬우, 김정란",
    len: "2분 2초",
    desc: "부부가 함께 부르는 듀엣곡입니다.",
    src: "/assets/audio/BM-035.mp3"
  },
  {
    id: "BM-036",
    title: "연(緣)",
    style: "Remastered",
    len: "2분 44초",
    desc: "인연의 소중함을 담은 곡입니다.",
    src: "/assets/audio/BM-036.mp3"
  },
  {
    id: "BM-037",
    title: "크리스만두 요들",
    len: "2분 22초",
    desc: "연말 분위기를 위한 계절 한정곡입니다.",
    src: "/assets/audio/BM-037.mp3"
  },
  {
    id: "BM-038",
    title: "김치찌개",
    len: "3분 7초",
    desc: "정겨운 일상을 노래한 곡입니다.",
    src: "/assets/audio/BM-038.mp3"
  },
  {
    id: "BM-039",
    title: "그땐 몰랐어",
    len: "2분 53초",
    desc: "지나고서야 깨닫는 마음을 담은 곡입니다.",
    src: "/assets/audio/BM-039.mp3"
  }
];

var BINAURAL = [
  { id: "BN-08", title: "8Hz 알파 대역",  len: "10분 00초", desc: "8Hz 알파 대역이 담긴 음악입니다.", src: "/assets/audio/8Hz_alpha_binaural_beat.mp3" },
  { id: "BN-09", title: "9Hz 알파 대역",  len: "10분 00초", desc: "9Hz 알파 대역이 담긴 음악입니다.", src: "/assets/audio/9Hz_alpha_binaural_beat.mp3" },
  { id: "BN-10", title: "10Hz 알파 대역", len: "10분 00초", desc: "10Hz 알파 대역이 담긴 음악입니다.", src: "/assets/audio/10Hz_alpha_binaural_beat.mp3" },
  { id: "BN-11", title: "11Hz 알파 대역", len: "10분 00초", desc: "11Hz 알파 대역이 담긴 음악입니다.", src: "/assets/audio/11Hz_alpha_binaural_beat.mp3" },
  { id: "BN-12", title: "12Hz SMR 대역",  len: "10분 00초", desc: "12Hz SMR 대역이 담긴 음악입니다.", src: "/assets/audio/12Hz_smr_binaural_beat.mp3" },
  { id: "BN-13", title: "13Hz SMR 대역",  len: "10분 00초", desc: "13Hz SMR 대역이 담긴 음악입니다.", src: "/assets/audio/13Hz_smr_binaural_beat.mp3" },
  { id: "BN-14", title: "14Hz SMR 대역",  len: "10분 00초", desc: "14Hz SMR 대역이 담긴 음악입니다.", src: "/assets/audio/14Hz_smr_binaural_beat.mp3" },
  { id: "BN-15", title: "15Hz SMR 대역",  len: "10분 00초", desc: "15Hz SMR 대역이 담긴 음악입니다.", src: "/assets/audio/15Hz_smr_binaural_beat.mp3" }
];

/* ------------------------------------------------------------
   곡 추가 방법
   1) 음원 mp3 를 /assets/audio/ 에 올립니다.
   2) 위 TRACKS 맨 아래(] 바로 앞)에 같은 모양으로 한 곡을 추가합니다.
      쉼표(,) 위치를 꼭 확인하세요. 마지막 곡 뒤에는 쉼표를 쓰지 않습니다.
   3) src 가 비어 있으면 화면에 "음원 준비 중"으로 표시됩니다.
   4) 저작권·사용권한은 별도 기록표(BrainMind_저작권기록표.xlsx)에 반드시 함께 기록합니다.
   ------------------------------------------------------------ */
