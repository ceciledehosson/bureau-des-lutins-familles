-- Migration V3 : suppression volontaire d'un Bureau par son créateur.
-- À exécuter uniquement sur Supabase "bureau-des-lutins-familles".
-- N'efface aucune donnée lors de l'installation.
-- Les Bureaux historiques sont attribués à leur PREMIER membre inscrit.
-- IMPORTANT : cette hypothèse est correcte pour le parcours normal de création,
-- mais doit être vérifiée avant de communiquer sur la fonction.

begin;

alter table public.families
  add column if not exists owner_id uuid;

-- L'ID du membre créateur n'était pas mémorisé auparavant :
-- le premier membre, créé dans la même transaction que la famille,
-- est le meilleur substitut pour les familles historiques.
update public.families f
set owner_id = (
    select m.id from public.members m
    where m.family_id = f.id
    order by m.created_at, m.id
    limit 1
)
where owner_id is null;

do $$
begin
 if not exists (
  select 1 from pg_constraint
  where conname = 'families_owner_id_fkey'
    and conrelid = 'public.families'::regclass
 ) then
  alter table public.families
  add constraint families_owner_id_fkey
  foreign key (owner_id) references public.members(id) on delete set null;
 end if;
end
$$;

-- Préserve les plafonds globaux anti-abus de migration_securite_v1.sql.
create or replace function public.create_family(p_title text, p_name text)
returns jsonb
language plpgsql security definer set search_path=''
as $$
declare
 f_id uuid;
 creator_id uuid;
 invite text;
 access_code text;
 recent_hour integer;
 recent_day integer;
begin
 if length(trim(coalesce(p_title,''))) not between 1 and 80
 or length(trim(coalesce(p_name,''))) not between 1 and 60 then
  raise exception 'Nom de famille ou prénom invalide';
 end if;

 perform pg_catalog.pg_advisory_xact_lock(20261120,1);
 select count(*) filter(where created_at > pg_catalog.now() - interval '1 hour'),
        count(*) filter(where created_at > pg_catalog.now() - interval '1 day')
 into recent_hour,recent_day from public.families;
 if recent_hour >= 12 or recent_day >= 60 then
   raise exception 'Le Bureau des Lutins reçoit trop de nouveaux bureaux ; réessaie plus tard';
 end if;

 invite := pg_catalog.encode(extensions.gen_random_bytes(24),'hex');
 access_code := pg_catalog.encode(extensions.gen_random_bytes(24),'hex');
 insert into public.families(title,invite_hash)
 values(trim(p_title),pg_catalog.encode(extensions.digest(invite,'sha256'),'hex'))
 returning id into f_id;
 insert into public.members(family_id,name,code_hash)
 values(f_id,trim(p_name),pg_catalog.encode(extensions.digest(access_code,'sha256'),'hex'))
 returning id into creator_id;
 update public.families set owner_id=creator_id where id=f_id;
 return pg_catalog.jsonb_build_object('code',access_code,'invitation',invite);
end; $$;

-- Renvoi d'une indication non sensible : ce membre est-il le créateur ?
-- Ne modifie pas l'API board utilisée par la V2 : fonction dédiée.
create or replace function public.my_family_management(p_code text)
returns jsonb
language plpgsql security definer set search_path=''
as $$
declare mid uuid; fid uuid; ftitle text; is_creator boolean;
begin
 select id, family_id into mid,fid from public.members
 where code_hash=pg_catalog.encode(extensions.digest(coalesce(p_code,''),'sha256'),'hex');
 if mid is null then return null; end if;
 select title, (owner_id=mid) into ftitle,is_creator from public.families where id=fid;
 return pg_catalog.jsonb_build_object(
  'title',ftitle,'is_creator',coalesce(is_creator,false));
end; $$;

-- Suppression irréversible par la personne créatrice avec confirmation exacte.
create or replace function public.delete_family(
  p_code text, p_confirmation text)
returns void
language plpgsql security definer set search_path=''
as $$
declare mid uuid; fid uuid; ftitle text;
begin
 select m.id,m.family_id into mid,fid
 from public.members m
 where m.code_hash=pg_catalog.encode(extensions.digest(coalesce(p_code,''),'sha256'),'hex');
 if mid is null then raise exception 'Accès refusé'; end if;
 select f.title into ftitle from public.families f
 where f.id=fid and f.owner_id=mid for update;
 if not found then raise exception 'Seul le créateur peut supprimer ce Bureau'; end if;
 if coalesce(p_confirmation,'') <> 'SUPPRIMER ' || ftitle then
  raise exception 'Confirmation incorrecte';
 end if;
 -- Suppression CASCADE : membres, souhaits, réservations, contributions.
 delete from public.families where id=fid and owner_id=mid;
end; $$;

revoke all on function public.my_family_management(text) from public;
revoke all on function public.delete_family(text,text) from public;
grant execute on function public.my_family_management(text) to anon,authenticated;
grant execute on function public.delete_family(text,text) to anon,authenticated;

commit;

-- Vérification (lecture seule) : noms et créateurs historiques.
-- SELECT f.title, m.name AS createur_attribue FROM public.families f
-- LEFT JOIN public.members m ON m.id=f.owner_id ORDER BY f.created_at;
