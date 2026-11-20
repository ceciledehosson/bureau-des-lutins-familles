-- Audit public avant diffusion, SANS MODIFICATION des données.
-- À exécuter dans le projet Supabase multi-familles.
-- La ligne de résultat doit indiquer "OK" pour chaque contrôle.

with expected_functions(signature) as (
 values
 ('public.board(text)'),
 ('public.check_request_limit(text,text)'),
 ('public.contribute(text,uuid,text,numeric)'),
 ('public.create_family(text,text)'),
 ('public.delete_family(text,text)'),
 ('public.delete_wish(text,uuid)'),
 ('public.join_family(text,text)'),
 ('public.my_family_management(text)'),
 ('public.reserve_wish(text,uuid,text)'),
 ('public.save_wish(text,uuid,text,numeric,text,text)')
),
functions_audit as (
 select signature,
        to_regprocedure(signature) as oid
 from expected_functions
),
tables_audit as (
 select c.relname, c.relrowsecurity
 from pg_class c join pg_namespace n on n.oid=c.relnamespace
 where n.nspname='public'
   and c.relkind='r'
   and c.relname in ('families','members','wishes','reservations',
                     'contributions','request_limits')
),
checks as (
 select 'RPC non exposées à anon et authenticated' as controle,
  case when bool_and(
    oid is not null
    and not has_function_privilege('anon',oid,'EXECUTE')
    and not has_function_privilege('authenticated',oid,'EXECUTE')
    and has_function_privilege('service_role',oid,'EXECUTE')
  ) then 'OK' else 'À VÉRIFIER' end as resultat
 from functions_audit
 union all
 select 'RLS activée sur les 6 tables', case when count(*)=6
  and bool_and(relrowsecurity) then 'OK' else 'À VÉRIFIER' end
 from tables_audit
 union all
 select 'Tables inaccessibles directement aux utilisateurs publics',
 case when bool_and(
   not has_table_privilege('anon',format('public.%I',relname),'SELECT,INSERT,UPDATE,DELETE')
   and not has_table_privilege('authenticated',format('public.%I',relname),'SELECT,INSERT,UPDATE,DELETE')
 ) and count(*)=6 then 'OK' else 'À VÉRIFIER' end
 from tables_audit
 union all
 select 'Créateur attribué aux bureaux existants',
 case when not exists(select 1 from public.families where owner_id is null)
 then 'OK' else 'À VÉRIFIER' end
 union all
 select 'Aucun code personnel stocké en clair',
 case when not exists (
  select 1 from information_schema.columns
  where table_schema='public' and table_name='members'
   and column_name in ('code','access_code','personal_code')
 ) then 'OK' else 'À VÉRIFIER' end
)
select * from checks order by controle;
