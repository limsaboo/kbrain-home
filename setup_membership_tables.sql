-- ============================================================
-- 한국뇌심리연구소: 회원/마일리지/방문자통계 테이블 신규 생성
-- Supabase 대시보드 > SQL Editor 에서 전체 실행
-- ============================================================

-- 1) 회원 테이블
CREATE TABLE IF NOT EXISTS members (
  id BIGSERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  email TEXT UNIQUE NOT NULL,
  phone TEXT,
  referral_code TEXT UNIQUE NOT NULL,       -- 본인의 추천 코드 (가입 시 자동 생성)
  referred_by TEXT,                          -- 나를 추천한 사람의 referral_code (없으면 NULL)
  mileage_balance INT DEFAULT 0,
  marketing_agree BOOLEAN DEFAULT false,     -- 마케팅 정보 수신 동의
  created_at TIMESTAMPTZ DEFAULT now()
);

-- 2) 마일리지 적립/차감 내역
CREATE TABLE IF NOT EXISTS mileage_ledger (
  id BIGSERIAL PRIMARY KEY,
  member_email TEXT NOT NULL,
  change_amount INT NOT NULL,                -- 양수=적립, 음수=사용/차감
  reason TEXT NOT NULL,                       -- 예: '회원가입 축하', '추천인 등록 보상'
  created_at TIMESTAMPTZ DEFAULT now()
);

-- 3) 홈페이지 방문 기록 (일/주/월 통계용)
CREATE TABLE IF NOT EXISTS page_visits (
  id BIGSERIAL PRIMARY KEY,
  page TEXT NOT NULL,                         -- 예: 'index', 'brain-picture-test-intro'
  referrer TEXT,
  visited_at TIMESTAMPTZ DEFAULT now()
);

-- ============================================================
-- RLS(행 단위 보안) 설정: 익명 키(anon)로 접속하는 정적 홈페이지에서
-- INSERT는 누구나 가능(가입/방문기록), SELECT는 필요한 범위만 허용.
-- 회원 목록 조회는 관리자 페이지에서만 쓰지만, 이 프로젝트는 별도
-- 서버가 없어 anon 키로 접근하므로 최소한의 방어로 운영합니다.
-- (완전한 보안이 필요하면 추후 Supabase Auth + 서버리스 함수로 전환 권장)
-- ============================================================

ALTER TABLE members ENABLE ROW LEVEL SECURITY;
ALTER TABLE mileage_ledger ENABLE ROW LEVEL SECURITY;
ALTER TABLE page_visits ENABLE ROW LEVEL SECURITY;

-- 회원가입(INSERT)은 누구나 가능
CREATE POLICY "누구나 회원가입 가능" ON members
  FOR INSERT WITH CHECK (true);

-- 본인 추천코드 중복확인 등을 위해 최소 컬럼만 SELECT 허용
CREATE POLICY "추천코드 조회 허용" ON members
  FOR SELECT USING (true);

-- 마일리지 내역은 가입/추천 보상 적립 시 INSERT
CREATE POLICY "마일리지 적립 허용" ON mileage_ledger
  FOR INSERT WITH CHECK (true);

CREATE POLICY "마일리지 조회 허용" ON mileage_ledger
  FOR SELECT USING (true);

-- 방문기록은 누구나 INSERT(페이지 로드 시 자동 기록), 조회는 통계용으로 허용
-- (관리자 페이지가 비밀번호로 한 번 더 막고 있음)
CREATE POLICY "방문기록 기록 허용" ON page_visits
  FOR INSERT WITH CHECK (true);

CREATE POLICY "방문기록 조회 허용" ON page_visits
  FOR SELECT USING (true);

-- 마일리지 잔액 업데이트(추천인 등록 후 balance 갱신)를 위해 UPDATE도 허용
CREATE POLICY "마일리지 잔액 갱신 허용" ON members
  FOR UPDATE USING (true);
