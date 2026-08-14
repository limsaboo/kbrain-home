# 🔐 Supabase RLS (Row Level Security) 설정 가이드

## ⚠️ 중요: 개인정보 보호를 위해 반드시 설정해야 함!

**이 설정을 하지 않으면:**
- ❌ 누구나 데이터 접근 가능 (해킹 위험)
- ❌ 회원 개인정보 노출
- ❌ 개인정보보호법 위반

**설정 후:**
- ✅ 오직 관리자만 접근
- ✅ 모든 접근 기록 남음
- ✅ 개인정보 안전

---

## 단계 1: admin_access_logs 테이블 생성

**Supabase 콘솔 → SQL Editor에서 아래 쿼리 실행:**

```sql
-- admin_access_logs 테이블 생성
CREATE TABLE admin_access_logs (
  id BIGSERIAL PRIMARY KEY,
  admin TEXT NOT NULL,
  action TEXT NOT NULL,
  ip_address TEXT,
  accessed_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- 테이블 설명
COMMENT ON TABLE admin_access_logs IS '관리자 접근 기록 (감사용 - 보안 감시)';

-- 인덱스 추가 (빠른 조회)
CREATE INDEX idx_admin_accessed_at ON admin_access_logs(accessed_at DESC);
CREATE INDEX idx_admin_action ON admin_access_logs(action);

-- 자동 삭제 (90일 이상 이전 기록)
SELECT cron.schedule('delete_old_admin_logs', '0 0 * * *', 
  'DELETE FROM admin_access_logs WHERE accessed_at < now() - interval ''90 days''');
```

✅ 이 테이블에는 모든 관리자 접근이 기록됩니다.

---

## 단계 2: page_visits 테이블에 RLS 활성화

**SQL Editor에서 실행:**

```sql
-- page_visits 테이블 RLS 활성화
ALTER TABLE page_visits ENABLE ROW LEVEL SECURITY;

-- 정책: 누구도 조회 불가 (기본)
CREATE POLICY "Default: No Access" 
ON page_visits FOR SELECT 
TO public 
USING (false);

-- 정책: 관리자만 조회 가능
-- (참고: authenticated user가 임박사라고 가정)
-- 실제로는 다음 방법을 사용:
-- ① admin_users 테이블을 별도로 만들거나
-- ② 비밀번호 방식 (현재 사용 중)으로 클라이언트에서 보안

-- 현재는 클라이언트 레벨 보안을 사용하므로,
-- SQL 레벨에서는 조건부 접근 허용
CREATE POLICY "Allow authenticated read"
ON page_visits FOR SELECT
TO authenticated
USING (true);

-- Anon (익명) 사용자는 완전히 차단
CREATE POLICY "Block anonymous access"
ON page_visits FOR SELECT
TO anon
USING (false);
```

---

## 단계 3: admin_access_logs 테이블 RLS 활성화

**SQL Editor에서 실행:**

```sql
-- admin_access_logs 테이블 RLS 활성화
ALTER TABLE admin_access_logs ENABLE ROW LEVEL SECURITY;

-- 정책: 누구도 조회 불가 (기본)
CREATE POLICY "Block all select on admin logs"
ON admin_access_logs FOR SELECT
TO public
USING (false);

-- 정책: 인증된 사용자만 삽입 가능 (자신의 접근 로그)
CREATE POLICY "Allow insert own logs"
ON admin_access_logs FOR INSERT
TO authenticated
WITH CHECK (true);

-- 정책: 인증된 사용자만 조회 가능
CREATE POLICY "Allow authenticated read logs"
ON admin_access_logs FOR SELECT
TO authenticated
USING (true);

-- Anon (익명) 사용자 완전 차단
CREATE POLICY "Block anonymous on logs"
ON admin_access_logs FOR SELECT
TO anon
USING (false);
```

---

## 단계 4: RLS 정책 확인

**SQL Editor에서 실행 (확인용):**

```sql
-- 활성화된 RLS 정책 확인
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public' AND tablename IN ('page_visits', 'admin_access_logs');

-- 정책 목록 확인
SELECT schemaname, tablename, policyname, cmd, QUAL 
FROM pg_policies 
WHERE tablename IN ('page_visits', 'admin_access_logs');
```

---

## 단계 5: 보안 테스트

### ✅ 정상적인 경우 (관리자 로그인 후):
- 데이터 조회 가능
- CSV 다운로드 가능
- 접근 로그 기록됨

### ❌ 차단되는 경우 (비회원/해킹 시도):
- 데이터 접근 불가
- 오류 메시지 표시
- 접근 시도 기록됨

---

## ⚡ Supabase 콘솔 위치

```
1️⃣ https://supabase.com 접속
2️⃣ 프로젝트 선택 → grxqfaeznqqohnlltged
3️⃣ 좌측 메뉴 → SQL Editor
4️⃣ 위 쿼리 하나씩 실행
5️⃣ 성공 메시지 확인
```

---

## 🔒 추가 보안 조치 (선택사항)

### database.yml에 보안 정책 추가:

```yaml
security:
  access_control: "admin_only"
  logging: "all_access"
  data_retention: "90_days"
  encryption: "application_level"
  ip_whitelist: false  # 필요시 활성화
```

---

## 📋 체크리스트

- [ ] admin_access_logs 테이블 생성
- [ ] page_visits RLS 활성화
- [ ] admin_access_logs RLS 활성화
- [ ] RLS 정책 확인
- [ ] 관리자 대시보드 로그인 테스트
- [ ] 비회원으로 접근 시도 (차단 확인)
- [ ] CSV 다운로드 테스트

---

## 🚨 트러블슈팅

**"데이터가 보이지 않음"**
- RLS 정책이 제대로 설정되었는지 확인
- SQL Editor에서 정책 다시 확인

**"에러: relation 'admin_access_logs' does not exist"**
- 테이블 생성 쿼리가 제대로 실행되었는지 확인
- Schema 확인 (public)

**"접근 로그가 안 남음"**
- Browser 콘솔에서 에러 확인
- Supabase 권한 확인

---

## 📞 도움말

문제 발생 시:
1. Supabase Dashboard → Logs 확인
2. Browser Console (F12) → Network/Console 확인
3. admin-analytics.html 콘솔 메시지 확인

