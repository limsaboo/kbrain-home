-- ============================================================
-- Coming Soon 페이지(강사양성과정 등) 사전 알림 신청 테이블
-- Supabase SQL Editor에서 실행
-- ============================================================

CREATE TABLE IF NOT EXISTS coming_soon_signups (
  id BIGSERIAL PRIMARY KEY,
  email TEXT NOT NULL,
  program TEXT NOT NULL,        -- 예: 'teacher', 'bips', 'senior-instructor', 'academy', 'goods', 'campus'
  created_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE coming_soon_signups ENABLE ROW LEVEL SECURITY;

CREATE POLICY "누구나 사전알림 신청 가능" ON coming_soon_signups
  FOR INSERT WITH CHECK (true);

CREATE POLICY "사전알림 조회 허용" ON coming_soon_signups
  FOR SELECT USING (true);
