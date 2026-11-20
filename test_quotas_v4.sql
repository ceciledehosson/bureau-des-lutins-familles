-- Test non destructif des quotas V4.
-- Ne touche ni aux codes ni aux données familiales.
-- Un identifiant aléatoire est utilisé pour chaque série puis ses compteurs sont retirés.
-- Exécuter dans Supabase SQL Editor du projet "familles".

do $$
declare
 test_hash text := pg_catalog.encode(extensions.gen_random_bytes(32), 'hex');
 action_name text;
 max_ok integer;
 n integer;
 answer boolean;
begin
 foreach action_name in array array['login','create','join'] loop
   max_ok := case action_name when 'login' then 15
                    when 'create' then 4 else 12 end;
   for n in 1..(max_ok + 1) loop
     answer := public.check_request_limit(test_hash, action_name);
     if answer is distinct from (n <= max_ok) then
       raise exception 'ÉCHEC du quota % : essai %, obtenu %, attendu %',
          action_name, n, answer, (n <= max_ok);
     end if;
   end loop;
   raise notice 'OK : % accepte % tentatives et bloque la %e',
     action_name, max_ok, max_ok + 1;
 end loop;

 delete from public.request_limits
 where visitor_hash = test_hash;

 raise notice 'TESTS TERMINÉS : 3 quotas vérifiés, compteurs fictifs nettoyés.';
end
$$;
