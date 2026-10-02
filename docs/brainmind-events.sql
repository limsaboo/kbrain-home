-- BrainMind 이용 기록 (재생 시작 / 하단 링크 클릭). 개인정보 없음, 저장만 허용·조회 차단.
create table if not exists public.brainmind_events (
  id         bigserial primary key,
  created_at timestamptz not null default now(),
  event      text not null check (event in ('play','cta_click','back_click')),
  track_id   text check (track_id is null or char_length(track_id) <= 20),
  target     text check (target is null or char_length(target) <= 200),
  visitor_id text check (visitor_id is null or char_length(visitor_id) <= 60),
  session_id text check (session_id is null or char_length(session_id) <= 60),
  device     text check (device is null or device in ('mobile','desktop'))
);
create index if not exists idx_bme_created on public.brainmind_events (created_at desc);
create index if not exists idx_bme_track   on public.brainmind_events (track_id);

alter table public.brainmind_events enable row level security;
drop policy if exists bme_insert on public.brainmind_events;
create policy bme_insert on public.brainmind_events for insert to public with check (true);

revoke select, update, delete on public.brainmind_events from anon, authenticated;
-- 되돌리기: drop table public.brainmind_events;
