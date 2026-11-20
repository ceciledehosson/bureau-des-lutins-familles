-- Audit en lecture seule — projet Supabase "bureau-des-lutins-familles".
-- À exécuter dans SQL Editor. Ne modifie aucune donnée.
-- Résultats attendus :
--  * Toutes les tables : row_security = true et anon_can_select/insert/update/delete = false
--  * Fonctions RPC : security_definer = true et search_path défini
--  * Aucune fonction supplémentaire accessible à anon non examinée

select 'TABLE' as kind, c.relname as object_name,
       c.relrowsecurity as rls_active,
       has_table_privilege('anon', c.oid, 'SELECT') as anon_can_select,
       has_table_privilege('anon', c.oid, 'INSERT') as anon_can_insert,
       has_table_privilege('anon', c.oid, 'UPDATE') as anon_can_update,
       has_table_privilege('anon', c.oid, 'DELETE') as anon_can_delete
from pg_class c
join pg_namespace n on n.oid=c.relnamespace
where n.nspname='public'
  and c.relname in ('families','members','wishes','reservations','contributions')
  and c.relkind='r'
order by c.relname;

select 'FUNCTION' as kind, p.proname as function_name,
       pg_get_function_identity_arguments(p.oid) as arguments,
       p.prosecdef as security_definer,
       p.proconfig as configuration,
       has_function_privilege('anon',p.oid,'EXECUTE') as anon_can_execute
from pg_proc p
join pg_namespace n on n.oid=p.pronamespace
where n.nspname='public' and p.prokind='f'
order by p.proname;
