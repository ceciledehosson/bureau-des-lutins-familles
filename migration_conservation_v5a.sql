-- V5a - conservation des Bureaux (NON DESTRUCTIVE)
-- À installer dans Supabase SQL Editor, projet MULTI-FAMILLES uniquement.
-- Aucune famille ni aucun cadeau n'est supprimé par ce fichier.
-- Toutes les familles existantes obtiennent une nouvelle période de 18 mois
-- à compter de l'installation de cette migration (pour éviter une suppression surprise).

begin;
alter table public.families
 add column if not exists last_activity_at timestamptz;

-- Si la colonne vient d'être ajoutée, TOUTES les familles historiques
-- démarrent le délai à maintenant. Les valeurs déjà définies ne sont pas écrasées.
update public.families
set last_activity_at = pg_catalog.now()
where last_activity_at is null;

alter table public.families
 alter column last_activity_at set default pg_catalog.now();
alter table public.families
 alter column last_activity_at set not null;

-- Uniquement les appels authentifiés par un code de membre peuvent
-- remettre à zéro le délai : l'ID de famille n'est pas un justificatif.
create or replace function public.touch_family_activity(p_code text)
returns void
language plpgsql security definer set search_path=''
as $$
declare fid uuid;
begin
 select family_id into fid
 from public.members
 where code_hash=pg_catalog.encode(
   extensions.digest(coalesce(p_code,''),'sha256'),'hex'
 );
 if fid is null then
  raise exception 'Code personnel invalide';
 end if;
 update public.families
 set last_activity_at=pg_catalog.now()
 where id=fid;
end; $$;

-- Prévisualisation sans effacement.
create or replace function public.preview_inactive_families()
returns table(family_id uuid, family_title text, last_activity_at timestamptz)
language sql security definer set search_path=''
as $$
 select id,title,last_activity_at from public.families
 where last_activity_at <= pg_catalog.now()-interval '18 months'
 order by last_activity_at;
$$;

-- Procédure de purge, installée mais NON PLANIFIÉE dans V5a.
-- Ne l'exécuter qu'une fois l'information affichée, les tests et la
-- programmation V5b validés.
create or replace function public.purge_inactive_families()
returns integer language plpgsql security definer set search_path=''
as $$
declare deleted_count integer;
begin
 -- Suppression en cascade des membres, envies, réservations et participations.
 delete from public.families
 where last_activity_at <= pg_catalog.now()-interval '18 months';
 get diagnostics deleted_count = row_count;
 return deleted_count;
end; $$;

revoke all on function public.touch_family_activity(text) from public,anon,authenticated;
grant execute on function public.touch_family_activity(text) to service_role;
revoke all on function public.preview_inactive_families() from public,anon,authenticated,service_role;
revoke all on function public.purge_inactive_families() from public,anon,authenticated,service_role;
-- Seul le rôle d'administration SQL pourra prévisualiser / planifier la purge.
commit;

-- Contrôle sans suppression :
select count(*) as bureaux,
       count(*) filter(where last_activity_at <= now()-interval '18 months')
         as bureaux_eligibles_suppression
from public.families;
