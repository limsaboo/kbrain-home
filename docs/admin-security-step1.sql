-- ============================================================
-- A 1단계: 관리자 인증 서버화 + 서버 함수 준비 (2026-10-03, 임박사 승인)
-- 기존 화면은 그대로 동작합니다(비밀번호 값은 같고, 확인 위치만 서버로 이동).
-- 공개 권한 잠금은 3단계(admin-security-step3.sql)에서 별도로 합니다.
-- ============================================================

-- 1) 관리자 비밀번호(암호화 저장) + 실패 기록
create table if not exists public.kbpi_admin_secret (
  id int primary key default 1 check (id = 1),
  pw_hash text not null,
  updated_at timestamptz not null default now()
);
alter table public.kbpi_admin_secret enable row level security;
revoke all on public.kbpi_admin_secret from anon, authenticated;

create table if not exists public.kbpi_admin_fails (
  id bigint generated always as identity primary key,
  at timestamptz not null default now()
);
alter table public.kbpi_admin_fails enable row level security;
revoke all on public.kbpi_admin_fails from anon, authenticated;

-- 현재 비밀번호로 시작(화면이 바로 멈추지 않도록). 3단계 후 반드시 변경.
insert into public.kbpi_admin_secret(id, pw_hash)
values (1, extensions.crypt('__CURRENT_PW__', extensions.gen_salt('bf', 10)))
on conflict (id) do nothing;

-- 2) 내부 확인 함수 (15분 내 10회 실패 시 잠시 잠김)
create or replace function public.kbpi_admin_ok(pw text)
returns boolean language plpgsql security definer set search_path = public, extensions as $$
declare h text; fails int;
begin
  select count(*) into fails from kbpi_admin_fails where at > now() - interval '15 minutes';
  if fails >= 10 then return false; end if;
  select pw_hash into h from kbpi_admin_secret where id = 1;
  if pw is not null and h is not null and crypt(pw, h) = h then return true; end if;
  insert into kbpi_admin_fails default values;
  delete from kbpi_admin_fails where at < now() - interval '1 day';
  return false;
end $$;
revoke all on function public.kbpi_admin_ok(text) from public, anon, authenticated;

-- 3) 화면에서 부르는 관리자 확인
create or replace function public.kbpi_admin_check(pw text)
returns json language plpgsql security definer set search_path = public as $$
declare ok boolean := kbpi_admin_ok(pw);
begin
  insert into admin_access_logs(action, detail) values (case when ok then '관리자 확인 성공' else '관리자 확인 실패' end, null);
  return json_build_object('ok', ok);
end $$;

create or replace function public.kbpi_admin_change_pw(old_pw text, new_pw text)
returns json language plpgsql security definer set search_path = public, extensions as $$
begin
  if not kbpi_admin_ok(old_pw) then return json_build_object('ok', false, 'error', '현재 비밀번호가 맞지 않습니다'); end if;
  if new_pw is null or char_length(new_pw) < 8 then return json_build_object('ok', false, 'error', '새 비밀번호는 8자 이상'); end if;
  update kbpi_admin_secret set pw_hash = crypt(new_pw, gen_salt('bf', 10)), updated_at = now() where id = 1;
  insert into admin_access_logs(action, detail) values ('관리자 비밀번호 변경', null);
  return json_build_object('ok', true);
end $$;

-- 4) 기존 관리자 함수: 하드코딩 비교 → 서버 확인으로 교체 (동작 동일)
create or replace function public.kbpi_coupons(pw text, only_unused boolean default false, sys text default null)
returns json language sql security definer set search_path = public as $$
  select case when not kbpi_admin_ok(pw) then json_build_object('ok', false)
  else json_build_object(
    'ok', true,
    'summary', (select coalesce(json_agg(t),'[]'::json) from (
        select system_type as 시스템, count(*) as 발행,
               sum(total_uses) as 총가능, sum(used_count) as 사용, sum(remain_count) as 잔여,
               count(*) filter (where used_count = 0) as 미사용장수,
               count(*) filter (where remain_count <= 0) as 소진장수
        from coupons group by system_type order by count(*) desc) t),
    'recent_use', (select coalesce(json_agg(t),'[]'::json) from (
        select coupon_code, system_type, remain_after, used_at
        from coupon_usage order by used_at desc limit 30) t),
    'list', (select coalesce(json_agg(t),'[]'::json) from (
        select coupon_code, system_type, total_uses, used_count, remain_count, is_active,
               case when used_count = 0 then '미사용'
                    when remain_count <= 0 then '소진' else '일부사용' end as 상태
        from coupons
        where (sys is null or system_type = sys)
          and (not only_unused or used_count = 0)
        order by coupon_code limit 500) t)
  ) end;
$$;

create or replace function public.kbpi_notice_list(pw text)
returns json language sql security definer set search_path = public as $$
  select case when not kbpi_admin_ok(pw) then '[]'::json
    else coalesce((select json_agg(t) from (
      select id, category, title, body, link_url, starts_on, ends_on, is_published, created_at
      from notices order by created_at desc limit 100) t),'[]'::json) end;
$$;

create or replace function public.kbpi_notice_save(pw text, p_id bigint, p_category text, p_title text, p_body text, p_link text, p_starts date, p_ends date, p_published boolean)
returns json language plpgsql security definer set search_path = public as $$
declare v_id bigint;
begin
  if not kbpi_admin_ok(pw) then
    return json_build_object('ok', false, 'error', '비밀번호 불일치');
  end if;
  if p_id is null or p_id = 0 then
    insert into notices(category,title,body,link_url,starts_on,ends_on,is_published)
    values (p_category,p_title,p_body,p_link,p_starts,p_ends,coalesce(p_published,true))
    returning id into v_id;
  else
    update notices set category=p_category, title=p_title, body=p_body,
      link_url=p_link, starts_on=p_starts, ends_on=p_ends, is_published=coalesce(p_published,true)
    where id=p_id returning id into v_id;
  end if;
  return json_build_object('ok', true, 'id', v_id);
end $$;

-- 관리자 통계 (회원 이메일이 들어 있어 비밀번호 필요)
create or replace function public.kbpi_admin_stats(pw text, days int default 30)
returns json language plpgsql security definer set search_path = public as $$
begin
  if not kbpi_admin_ok(pw) then return json_build_object('ok', false); end if;
  return kbpi_stats(days);
end $$;

-- 5) 쿠폰 확인 (연락처·이메일은 돌려주지 않음)
create or replace function public.kbpi_coupon_check(p_code text, p_systems text[] default null)
returns json language plpgsql security definer set search_path = public as $$
declare c coupons;
begin
  select * into c from coupons
   where coupon_code = upper(trim(p_code)) and is_active = true
     and (p_systems is null or system_type = any(p_systems))
   limit 1;
  if not found then return json_build_object('ok', false, 'error', 'invalid'); end if;
  if c.expire_date is not null and c.expire_date < now() then return json_build_object('ok', false, 'error', 'expired'); end if;
  if c.remain_count <= 0 then return json_build_object('ok', false, 'error', 'exhausted'); end if;
  return json_build_object('ok', true, 'coupon_code', c.coupon_code, 'coupon_type', c.coupon_type,
    'buyer_type', c.buyer_type, 'buyer_name', c.buyer_name, 'buyer_memo', c.buyer_memo,
    'total_uses', c.total_uses, 'used_count', c.used_count, 'remain_count', c.remain_count,
    'expire_date', c.expire_date, 'system_type', c.system_type);
end $$;

-- 6) 쿠폰 사용 (차감 + 이력, 동시 사용 방지)
create or replace function public.kbpi_coupon_redeem(
  p_code text, p_systems text[] default null, p_usage_system text default null,
  p_examinee_name text default null, p_examinee_display text default null,
  p_diagnosis_id bigint default null, p_birth_year int default null, p_birth_month int default null, p_gender text default null)
returns json language plpgsql security definer set search_path = public as $$
declare c coupons; r int;
begin
  select * into c from coupons
   where coupon_code = upper(trim(p_code)) and is_active = true
     and (p_systems is null or system_type = any(p_systems))
   limit 1 for update;
  if not found then return json_build_object('ok', false, 'error', 'invalid'); end if;
  if c.expire_date is not null and c.expire_date < now() then return json_build_object('ok', false, 'error', 'expired'); end if;
  if c.remain_count <= 0 then return json_build_object('ok', false, 'error', 'exhausted'); end if;
  r := c.remain_count - 1;
  update coupons set used_count = coalesce(used_count,0) + 1, remain_count = r where id = c.id;
  insert into coupon_usage(coupon_code, coupon_type, buyer_type, examinee_name, examinee_display,
                           birth_year, birth_month, gender, system_type, diagnosis_id, remain_after)
  values (c.coupon_code, c.coupon_type, c.buyer_type, left(p_examinee_name,50), left(p_examinee_display,80),
          p_birth_year, p_birth_month, left(p_gender,10), left(coalesce(p_usage_system, c.system_type),20), p_diagnosis_id, r);
  return json_build_object('ok', true, 'coupon_code', c.coupon_code, 'coupon_type', c.coupon_type,
    'buyer_type', c.buyer_type, 'buyer_name', c.buyer_name, 'buyer_memo', c.buyer_memo,
    'total_uses', c.total_uses, 'used_count', coalesce(c.used_count,0) + 1, 'remain_count', r, 'remain_after', r);
end $$;

-- 7) 쿠폰 발행 (관리자)
create or replace function public.kbpi_coupon_issue(pw text, p_code text, p_coupon_type text, p_buyer_name text,
  p_buyer_type text, p_contact text, p_memo text, p_uses int, p_system text, p_amount int, p_expire timestamptz)
returns json language plpgsql security definer set search_path = public as $$
declare v_id bigint;
begin
  if not kbpi_admin_ok(pw) then return json_build_object('ok', false, 'error', '관리자 확인 실패'); end if;
  if p_code !~ '^[A-Z]{2,4}-[0-9]{6}-[A-Z0-9]{4}$' then return json_build_object('ok', false, 'error', '코드 형식 오류'); end if;
  insert into coupons(coupon_code, coupon_type, buyer_name, buyer_type, buyer_contact, buyer_memo,
                      total_uses, used_count, remain_count, system_type, purchase_amount, expire_date, is_active, issued_by)
  values (p_code, p_coupon_type, p_buyer_name, p_buyer_type, p_contact, p_memo,
          greatest(coalesce(p_uses,1),1), 0, greatest(coalesce(p_uses,1),1), coalesce(p_system,'all'),
          coalesce(p_amount,0), p_expire, true, '임찬우소장')
  returning id into v_id;
  return json_build_object('ok', true, 'id', v_id, 'coupon_code', p_code);
exception when unique_violation then
  return json_build_object('ok', false, 'error', '중복 코드');
end $$;

-- 8) 회원가입 (중복 확인·추천인·마일리지·축하쿠폰을 서버에서 한 번에)
create or replace function public.kbpi_signup(p_name text, p_email text, p_phone text, p_marketing boolean, p_ref_code text)
returns json language plpgsql security definer set search_path = public as $$
declare
  v_email text := lower(trim(p_email));
  v_ref members;
  v_my_ref text; v_coupon text; v_ref_coupon text; v_base text; i int;
begin
  if p_name is null or char_length(trim(p_name)) = 0 or v_email !~ '^[^@\s]+@[^@\s]+\.[^@\s]+$' then
    return json_build_object('ok', false, 'error', 'invalid');
  end if;
  if exists (select 1 from members where lower(email) = v_email) then
    return json_build_object('ok', false, 'error', 'dup_email');
  end if;
  if coalesce(trim(p_ref_code),'') <> '' then
    select * into v_ref from members where referral_code = upper(trim(p_ref_code)) limit 1;
    if not found then return json_build_object('ok', false, 'error', 'bad_ref'); end if;
  end if;
  v_base := upper(left(regexp_replace(coalesce(p_name,''), '[^a-zA-Z0-9가-힣]', '', 'g'), 3));
  if v_base = '' then v_base := 'MBR'; end if;
  for i in 1..10 loop
    v_my_ref := v_base || '-' || upper(substr(md5(random()::text), 1, 5));
    exit when not exists (select 1 from members where referral_code = v_my_ref);
  end loop;
  insert into members(name, email, phone, referral_code, referred_by, mileage_balance, marketing_agree)
  values (left(trim(p_name),50), v_email, left(nullif(trim(p_phone),''),30), v_my_ref,
          case when v_ref.id is not null then v_ref.referral_code end, 100, coalesce(p_marketing,false));
  insert into mileage_ledger(member_email, change_amount, reason) values (v_email, 100, '회원가입 축하 마일리지');
  for i in 1..10 loop
    v_coupon := 'MEM-' || to_char(now() at time zone 'Asia/Seoul', 'YYMMDD') || '-' || upper(substr(md5(random()::text), 1, 4));
    exit when not exists (select 1 from coupons where coupon_code = v_coupon);
  end loop;
  insert into coupons(coupon_code, system_type, coupon_type, is_active, remain_count, used_count, buyer_memo)
  values (v_coupon, 'all', 'free', true, 1, 0, '회원가입 축하쿠폰 (' || v_email || ')');
  if v_ref.id is not null then
    for i in 1..10 loop
      v_ref_coupon := 'MEM-' || to_char(now() at time zone 'Asia/Seoul', 'YYMMDD') || '-' || upper(substr(md5(random()::text), 1, 4));
      exit when not exists (select 1 from coupons where coupon_code = v_ref_coupon);
    end loop;
    insert into coupons(coupon_code, system_type, coupon_type, is_active, remain_count, used_count, buyer_memo)
    values (v_ref_coupon, 'all', 'free', true, 1, 0, '추천인 보상쿠폰 (추천: ' || v_ref.email || ' → 가입: ' || v_email || ')');
    insert into mileage_ledger(member_email, change_amount, reason) values (v_ref.email, 100, '추천인 등록 보상 (피추천인: ' || v_email || ')');
    update members set mileage_balance = coalesce(mileage_balance,0) + 100 where id = v_ref.id;
  end if;
  return json_build_object('ok', true, 'coupon_code', v_coupon, 'referral_code', v_my_ref);
end $$;

-- 9) 뇌궁합 결과 저장 / 찾기 (일반: 저장코드 정확히 일치, 관리자: 이름 검색)
create or replace function public.kbpi_diagnosis_save(p jsonb)
returns json language plpgsql security definer set search_path = public as $$
declare v_id bigint;
begin
  insert into brain_diagnosis(name_a,birth_year_a,birth_month_a,age_a,gender_a,name_b,birth_year_b,birth_month_b,age_b,gender_b,name_c,birth_year_c,birth_month_c,age_c,gender_c,relation,num_people,a_left,a_right,a_whole,a_condition,a_control,b_left,b_right,b_whole,b_condition,b_control,c_left,c_right,c_whole,c_condition,c_control,sim_ab,grade_ab,grade_type_ab,sim_ac,sim_bc,search_code)
  select name_a,birth_year_a,birth_month_a,age_a,gender_a,name_b,birth_year_b,birth_month_b,age_b,gender_b,name_c,birth_year_c,birth_month_c,age_c,gender_c,relation,num_people,a_left,a_right,a_whole,a_condition,a_control,b_left,b_right,b_whole,b_condition,b_control,c_left,c_right,c_whole,c_condition,c_control,sim_ab,grade_ab,grade_type_ab,sim_ac,sim_bc,search_code from jsonb_populate_record(null::brain_diagnosis, p)
  returning id into v_id;
  return json_build_object('ok', true, 'id', v_id);
exception when unique_violation then
  return json_build_object('ok', false, 'error', 'dup_code');
end $$;

create or replace function public.kbpi_diagnosis_search(p_query text, p_pw text default null)
returns setof brain_diagnosis language plpgsql security definer set search_path = public as $$
declare q text := trim(coalesce(p_query,''));
begin
  if q = '' then return; end if;
  if p_pw is not null and kbpi_admin_ok(p_pw) then
    return query select * from brain_diagnosis
      where name_a ilike '%'||q||'%' or name_b ilike '%'||q||'%' or name_c ilike '%'||q||'%'
      order by created_at desc limit 20;
  else
    return query select * from brain_diagnosis where search_code = upper(q) limit 1;
  end if;
end $$;

-- 10) 메인 누적 방문자 수
create or replace function public.kbpi_visit_count()
returns bigint language sql security definer set search_path = public as $$
  select count(*) from page_visits;
$$;

grant execute on function
  public.kbpi_admin_check(text), public.kbpi_admin_change_pw(text,text), public.kbpi_admin_stats(text,int),
  public.kbpi_coupon_check(text,text[]), public.kbpi_coupon_redeem(text,text[],text,text,text,bigint,int,int,text),
  public.kbpi_coupon_issue(text,text,text,text,text,text,text,int,text,int,timestamptz),
  public.kbpi_signup(text,text,text,boolean,text), public.kbpi_diagnosis_save(jsonb),
  public.kbpi_diagnosis_search(text,text), public.kbpi_visit_count()
to anon, authenticated;
