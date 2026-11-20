-- Étape 2 seulement, APRÈS ajout de SUPABASE_SERVICE_ROLE_KEY dans Streamlit.
-- Migration anti-abus V4 : limite les requêtes côté serveur et ferme les RPC à anon.
-- Ne supprime aucune famille ni aucune liste.

begin;

create table if not exists public.request_limits (
  visitor_hash text not null,
  action text not null,
  window_start timestamptz not null,
  attempts integer not null default 0,
  primary key(visitor_hash, action, window_start),
  constraint request_limits_attempts_positive check (attempts >= 0)
);
alter table public.request_limits enable row level security;
revoke all on public.request_limits from public, anon, authenticated;

-- Uniquement accessible au serveur avec service_role.
create or replace function public.check_request_limit(
  p_visitor_hash text, p_action text)
returns boolean language plpgsql security definer set search_path = ''
as $$
declare
  limit_count integer;
  window_size interval;
  bucket timestamptz;
  attempts_now integer;
begin
  if p_visitor_hash is null or
     length(p_visitor_hash) <> 64 or
     p_visitor_hash !~ '^[0-9a-f]{64}$' then
    return false;
  end if;
  case p_action
    when 'login' then limit_count:=15; window_size:=interval '15 minutes';
    when 'create' then limit_count:=4; window_size:=interval '1 hour';
    when 'join' then limit_count:=12; window_size:=interval '1 hour';
    else return false;
  end case;
  bucket := to_timestamp(
    floor(extract(epoch from pg_catalog.now()) / extract(epoch from window_size))
    * extract(epoch from window_size)
  );
  insert into public.request_limits(visitor_hash, action, window_start, attempts)
  values(p_visitor_hash, p_action, bucket, 1)
  on conflict(visitor_hash,action,window_start)
  do update set attempts=public.request_limits.attempts + 1
  returning attempts into attempts_now;
  return attempts_now <= limit_count;
end; $$;

revoke all on function public.check_request_limit(text,text) from public,anon,authenticated;
grant execute on function public.check_request_limit(text,text) to service_role;

-- Les opérations passent dorénavant par le serveur Streamlit seulement.
-- Ne pas exécuter avant d'avoir configuré SUPABASE_SERVICE_ROLE_KEY !
revoke execute on all functions in schema public from public,anon,authenticated;

grant execute on function public.create_family(text,text) to service_role;
grant execute on function public.join_family(text,text) to service_role;
grant execute on function public.board(text) to service_role;
grant execute on function public.save_wish(text,uuid,text,text,numeric,text,text) to service_role;
grant execute on function public.delete_wish(text,uuid) to service_role;
grant execute on function public.reserve_wish(text,uuid,text) to service_role;
grant execute on function public.contribute(text,uuid,text,numeric) to service_role;
grant execute on function public.my_family_management(text) to service_role;
grant execute on function public.delete_family(text,text) to service_role;
grant execute on function public.check_request_limit(text,text) to service_role;

commit;

-- Contrôle attendu : anon_can_execute = false, service_can_execute = true.
select p.proname,
       has_function_privilege('anon',p.oid,'EXECUTE') as anon_can_execute,
       has_function_privilege('service_role',p.oid,'EXECUTE') as service_can_execute
from pg_proc p
join pg_namespace n on p.pronamespace=n.oid
where n.nspname='public' and p.prokind='f'
order by p.proname;
