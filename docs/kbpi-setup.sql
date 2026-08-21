-- ============================================================
--  한국뇌심리연구소 - 1단계 기록 기반 구축
--  Supabase → SQL Editor 에 전체 복사 후 RUN 한 번만 실행하세요.
--  기존 테이블은 건드리지 않습니다. 새 테이블만 추가합니다.
-- ============================================================

-- ── 1. 페이지 방문/체류시간 기록 ─────────────────────────────
create table if not exists public.page_views (
  id           bigserial primary key,
  created_at   timestamptz not null default now(),
  session_id   text not null,              -- 방문 1회를 묶는 값
  visitor_id   text,                       -- 같은 기기 재방문 식별
  member_email text,                       -- 로그인 시에만 기록
  page         text not null,              -- 예: /bhc.html
  page_title   text,
  referrer     text,
  duration_sec integer default 0,          -- 체류 시간(초)
  device       text,                       -- mobile / desktop
  is_final     boolean default true        -- 페이지 이탈 시 기록 여부
);
create index if not exists idx_pv_created on public.page_views (created_at desc);
create index if not exists idx_pv_page    on public.page_views (page);
create index if not exists idx_pv_session on public.page_views (session_id);
create index if not exists idx_pv_member  on public.page_views (member_email);

-- ── 2. BHC 검사 결과 (현재 저장 안 되고 있음) ────────────────
create table if not exists public.bhc_results (
  id            bigserial primary key,
  created_at    timestamptz not null default now(),
  name          text,
  age_at_test   integer,
  gender        text,
  region        text,
  member_email  text,
  score_memory     integer,   -- 기억
  score_speed      integer,   -- 속도
  score_focus      integer,   -- 집중
  score_emotion    integer,   -- 감정
  score_judgment   integer,   -- 판단
  score_execution  integer,   -- 실행
  score_control    integer,   -- 조절
  score_space      integer,   -- 공간
  health_score  integer,      -- 8영역 평균(뇌 건강도)
  brain_age     integer,
  grade         text,
  duration_sec  integer
);
create index if not exists idx_bhc_created on public.bhc_results (created_at desc);

-- ── 3. 소식 / 이벤트 / 세미나 ────────────────────────────────
create table if not exists public.notices (
  id          bigserial primary key,
  created_at  timestamptz not null default now(),
  category    text not null default '소식',  -- 소식 / 이벤트 / 세미나 / 쿠폰
  title       text not null,
  body        text,
  link_url    text,
  starts_on   date,
  ends_on     date,
  is_published boolean default true,
  view_count  integer default 0
);
create index if not exists idx_notices_pub on public.notices (is_published, created_at desc);

-- ── 4. 관리자 접근 로그 (기존 대시보드가 찾던 없는 테이블) ────
create table if not exists public.admin_access_logs (
  id         bigserial primary key,
  created_at timestamptz not null default now(),
  action     text not null,
  detail     text
);

-- ── 5. RLS: 저장은 허용, 조회는 차단 ─────────────────────────
alter table public.page_views       enable row level security;
alter table public.bhc_results      enable row level security;
alter table public.notices          enable row level security;
alter table public.admin_access_logs enable row level security;

drop policy if exists pv_insert  on public.page_views;
create policy pv_insert  on public.page_views       for insert to public with check (true);

drop policy if exists bhc_insert on public.bhc_results;
create policy bhc_insert on public.bhc_results      for insert to public with check (true);

drop policy if exists log_insert on public.admin_access_logs;
create policy log_insert on public.admin_access_logs for insert to public with check (true);

-- 소식은 게시된 것만 누구나 읽기 가능(홈페이지 노출용)
drop policy if exists notices_read on public.notices;
create policy notices_read on public.notices for select to public using (is_published = true);

-- ── 6. 관리자 통계 함수 (개인정보 미포함, 집계만 반환) ────────
create or replace function public.kbpi_stats(days integer default 30)
returns json
language sql
security definer
set search_path = public
as $$
  select json_build_object(
    'generated_at', now(),
    'range_days',   days,

    'visits_total',  (select count(*) from page_views),
    'visits_range',  (select count(*) from page_views where created_at > now() - (days || ' days')::interval),
    'visits_today',  (select count(*) from page_views where created_at >= date_trunc('day', now())),
    'sessions_range',(select count(distinct session_id) from page_views where created_at > now() - (days || ' days')::interval),
    'visitors_range',(select count(distinct visitor_id) from page_views where created_at > now() - (days || ' days')::interval),
    'avg_stay_sec',  (select coalesce(round(avg(duration_sec)),0) from page_views where created_at > now() - (days || ' days')::interval and duration_sec > 0),

    'members_total', (select count(*) from members),
    'members_marketing', (select count(*) from members where marketing_agree = true),
    'bhc_total',     (select count(*) from bhc_results),
    'bac_total',     (select count(*) from bac_results),
    'coupons_total', (select count(*) from coupons),
    'coupons_used',  (select count(*) from coupon_usage),

    'by_page', (select coalesce(json_agg(t),'[]'::json) from (
        select page, count(*) as views,
               count(distinct session_id) as sessions,
               coalesce(round(avg(nullif(duration_sec,0))),0) as avg_sec
        from page_views where created_at > now() - (days || ' days')::interval
        group by page order by count(*) desc limit 25) t),

    'by_day', (select coalesce(json_agg(t),'[]'::json) from (
        select to_char(date_trunc('day', created_at),'MM-DD') as day,
               count(*) as views, count(distinct session_id) as sessions
        from page_views where created_at > now() - (days || ' days')::interval
        group by date_trunc('day', created_at) order by date_trunc('day', created_at)) t),

    'by_device', (select coalesce(json_agg(t),'[]'::json) from (
        select coalesce(device,'미상') as device, count(*) as views
        from page_views where created_at > now() - (days || ' days')::interval
        group by 1 order by count(*) desc) t),

    'by_referrer', (select coalesce(json_agg(t),'[]'::json) from (
        select case when referrer is null or referrer='' then '직접 접속'
                    else split_part(split_part(referrer,'//',2),'/',1) end as source,
               count(*) as views
        from page_views where created_at > now() - (days || ' days')::interval
        group by 1 order by count(*) desc limit 12) t),

    'bhc_by_grade', (select coalesce(json_agg(t),'[]'::json) from (
        select grade, count(*) as n, round(avg(health_score)) as avg_score
        from bhc_results group by grade order by count(*) desc) t),

    'bhc_domain_avg', (select row_to_json(t) from (
        select round(avg(score_memory)) as 기억, round(avg(score_speed)) as 속도,
               round(avg(score_focus)) as 집중,  round(avg(score_emotion)) as 감정,
               round(avg(score_judgment)) as 판단, round(avg(score_execution)) as 실행,
               round(avg(score_control)) as 조절, round(avg(score_space)) as 공간
        from bhc_results) t),

    'bhc_by_age', (select coalesce(json_agg(t),'[]'::json) from (
        select (age_at_test/10*10)::text || '대' as band, count(*) as n,
               round(avg(health_score)) as avg_score
        from bhc_results where age_at_test is not null group by 1 order by 1) t),

    'members_by_month', (select coalesce(json_agg(t),'[]'::json) from (
        select to_char(date_trunc('month', created_at),'YYYY-MM') as month, count(*) as n
        from members group by 1 order by 1 desc limit 12) t),

    'top_members', (select coalesce(json_agg(t),'[]'::json) from (
        select member_email as email, count(*) as views,
               count(distinct session_id) as sessions,
               coalesce(round(sum(duration_sec)/60.0,1),0) as total_min,
               max(created_at) as last_seen
        from page_views where member_email is not null
        group by member_email order by count(*) desc limit 20) t)
  );
$$;

revoke all on function public.kbpi_stats(integer) from public;
grant execute on function public.kbpi_stats(integer) to anon, authenticated;

-- ── 7. 소식 등록/수정용 함수 (비밀번호 확인 후에만 동작) ──────
create or replace function public.kbpi_notice_save(
  pw text, p_id bigint, p_category text, p_title text,
  p_body text, p_link text, p_starts date, p_ends date, p_published boolean)
returns json
language plpgsql
security definer
set search_path = public
as $$
declare v_id bigint;
begin
  if pw is distinct from 'brain2025!' then
    return json_build_object('ok', false, 'error', '비밀번호 불일치');
  end if;
  if p_id is null or p_id = 0 then
    insert into notices(category,title,body,link_url,starts_on,ends_on,is_published)
    values (p_category,p_title,p_body,p_link,p_starts,p_ends,coalesce(p_published,true))
    returning id into v_id;
  else
    update notices set category=p_category, title=p_title, body=p_body,
      link_url=p_link, starts_on=p_starts, ends_on=p_ends,
      is_published=coalesce(p_published,true)
    where id=p_id returning id into v_id;
  end if;
  return json_build_object('ok', true, 'id', v_id);
end; $$;

grant execute on function public.kbpi_notice_save(text,bigint,text,text,text,text,date,date,boolean) to anon, authenticated;

-- ── 8. 소식 목록 조회 (관리자용: 미게시 포함) ────────────────
create or replace function public.kbpi_notice_list(pw text)
returns json
language sql
security definer
set search_path = public
as $$
  select case when pw is distinct from 'brain2025!' then '[]'::json
    else coalesce((select json_agg(t) from (
      select id, category, title, body, link_url, starts_on, ends_on,
             is_published, created_at
      from notices order by created_at desc limit 100) t),'[]'::json) end;
$$;

grant execute on function public.kbpi_notice_list(text) to anon, authenticated;

-- ============================================================
--  실행 완료 후 아래로 확인하세요
--  select public.kbpi_stats(30);
-- ============================================================
