-- Sécurisation progressive du Bureau des Lutins (20 novembre 2026).
-- Migration non destructive : ne touche pas aux familles, codes, listes ou cadeaux existants.
-- IMPORTANT : limite globale de créations, mesure temporaire anti-abus,
-- PAS une protection anti-robot individuelle ni un contrôle par adresse IP.

create or replace function public.create_family(p_title text, p_name text)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  f_id uuid;
  invite text;
  access_code text;
  recent_hour integer;
  recent_day integer;
begin
  if length(trim(coalesce(p_title, ''))) not between 1 and 80
     or length(trim(coalesce(p_name, ''))) not between 1 and 60 then
    raise exception 'Nom de famille ou prénom invalide';
  end if;

  -- Sérialise les inscriptions pour rendre les plafonds atomiques.
  perform pg_catalog.pg_advisory_xact_lock(20261120, 1);

  select count(*) filter(where created_at > pg_catalog.now() - interval '1 hour'),
         count(*) filter(where created_at > pg_catalog.now() - interval '1 day')
    into recent_hour, recent_day
    from public.families;

  -- Préserve le service pour quelques familles de test, évite une explosion de coûts.
  -- Si ce plafond est atteint, toute nouvelle famille est temporairement bloquée :
  -- ce n'est PAS une mesure suffisante contre les attaques par déni de service.
  if recent_hour >= 12 or recent_day >= 60 then
    raise exception 'Le Bureau des Lutins reçoit trop de nouveaux bureaux ; réessaie plus tard';
  end if;

  invite := pg_catalog.encode(extensions.gen_random_bytes(24), 'hex');
  access_code := pg_catalog.encode(extensions.gen_random_bytes(24), 'hex');
  insert into public.families(title, invite_hash)
  values(
    trim(p_title),
    pg_catalog.encode(extensions.digest(invite, 'sha256'), 'hex')
  ) returning id into f_id;

  insert into public.members(family_id, name, code_hash)
  values(
    f_id,
    trim(p_name),
    pg_catalog.encode(extensions.digest(access_code, 'sha256'), 'hex')
  );
  return pg_catalog.jsonb_build_object('code', access_code, 'invitation', invite);
end;
$$;

revoke all on function public.create_family(text, text) from public;
grant execute on function public.create_family(text, text) to anon, authenticated;

-- Un compte de test SQL Editor fonctionne toujours avec les appels actuels.
-- Vérification : SELECT proname, prosecdef, proconfig FROM pg_proc
-- WHERE oid = 'public.create_family(text,text)'::regprocedure;
