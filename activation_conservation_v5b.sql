-- V5b - ACTIVATION DE LA SUPPRESSION AUTOMATIQUE
-- À lancer seulement APRÈS V5a, contrôle du résultat, et information
-- des utilisateurs dans l'application. Projet Supabase MULTI-FAMILLES.
--
-- Supabase Cron (pg_cron) exécute le nettoyage chaque jour à 03:17 UTC.
-- Un Bureau n'est éligible qu'après 18 mois depuis sa dernière activité
-- enregistrée par un membre qui possède un code personnel valide.
-- La procédure ne supprime rien tant qu'aucune famille n'a atteint ce délai.

create extension if not exists pg_cron with schema pg_catalog;

select cron.schedule(
  'bureau-lutins-purge-inactifs-18mois',
  '17 3 * * *',
  $$select public.purge_inactive_families();$$
);

-- Vérifier que la tâche est bien programmée :
select jobname,schedule,command,active
from cron.job
where jobname='bureau-lutins-purge-inactifs-18mois';

-- Pour DÉSACTIVER la suppression automatique :
-- select cron.unschedule('bureau-lutins-purge-inactifs-18mois');
