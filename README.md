# 🎄 Le Bureau des Lutins — édition familles

Une application gratuite, sans publicité, exclusivement consacrée à Noël. Chaque famille dispose de son propre Bureau de Noël : lettres, réservations secrètes et cadeaux collectifs.

**STATUT : PROTOTYPE — NE PAS OUVRIR AU PUBLIC AVANT TESTS.**

Cette version est indépendante du Bureau familial d'origine : utiliser **un nouveau projet Supabase**, jamais la base de la famille existante.

## Installation
1. Créer un nouveau projet Supabase et exécuter `schema.sql` dans SQL Editor.
2. Dans Streamlit Community Cloud, déployer `app.py` depuis ce dépôt public.
3. Dans Settings → Secrets, configurer :
```toml
SUPABASE_URL = "https://NOUVEAU-PROJET.supabase.co"
SUPABASE_ANON_KEY = "CLE_PUBLIQUE"
```
4. Vérifier la création d'un bureau, l'inscription d'autres lutins, les listes, réservations et contributions.
5. Créer une **deuxième famille distincte** et vérifier que les données ne se croisent jamais.

Les codes personnels sont sensibles ; ne jamais les mettre dans GitHub ni les communiquer dans une conversation publique.

## À faire avant ouverture aux familles extérieures
- Limitation des tentatives de connexion, des inscriptions et de la création de bureaux.
- Gestion des codes perdus, des invitations révocables et des comptes supprimés.
- Tests automatisés de confidentialité entre familles et de concurrence sur les réservations.
- Information sur les données collectées, leur durée de conservation et leur suppression (RGPD).
- Évaluation des coûts et limites du plan gratuit Supabase et de l'hébergement Streamlit.

Le code est publié pour développement et expérimentation, sans garantie de sécurité ou de disponibilité.

## Droits d’auteur

© 2026 Cécile de Hosson — Tous droits réservés.

Le dépôt est public pour consultation et tests, mais aucune licence de réutilisation, modification ou redistribution n’est accordée pour le moment. Une éventuelle licence libre pourra être définie ultérieurement par la titulaire des droits.

## Audit de sécurité (20 novembre 2026)

Revue statique initiale de `app.py` et `schema.sql` : contrôle des droits d'écriture et séparation par famille prévus dans les fonctions RPC ; masquage des réservations du destinataire dans `board`. Les codes sont générés aléatoirement puis stockés hachés.

Corrections réalisées dans `app.py` : messages d'erreur de connexion et d'opérations rendus génériques pour ne pas exposer de détails internes, et validation minimale des formulaires d'accès.

**Vérifications restantes :** exécuter `audit_securite.sql` dans le **nouveau** projet Supabase, vérifier les droits effectifs, puis réaliser des tests négatifs d'appels RPC directs avec les identifiants de deux familles distinctes. Les essais par interface ne constituent pas un audit de pénétration.

**Risques non levés :** les fonctions `create_family`, `join_family` et `board` sont accessibles depuis Internet avec la clé publique ; aucun dispositif fiable de limitation de débit / anti-bot ne protège ces appels. Ne pas annoncer l'application comme sécurisée pour une diffusion générale. Une protection côté serveur (vérification anti-bot et quotas) est nécessaire avant ouverture publique.

Les données de test sont conservées ; aucune migration destructive n'a été appliquée.


## Renforcement progressif : migration_securite_v1.sql

Le fichier `migration_securite_v1.sql` peut être exécuté dans le **projet Supabase multi-familles**, avec les familles existantes. Il remplace uniquement la fonction `create_family` et conserve les données. Il fixe un plafond global de **12 nouveaux Bureaux par heure et 60 par jour**, avec verrouillage transactionnel pour empêcher les dépassements simultanés.

**Portée limitée** : ce plafond peut lui-même être saturé volontairement, empêchant des familles légitimes de s'inscrire. Il ne filtre ni les adresses IP ni les robots, n'empêche pas les tentatives massives de connexion et ne constitue pas un anti-bot. Ne pas partager largement l'application avant la mise en place d'un véritable contrôle d'abus en amont des fonctions publiques Supabase (par exemple une API intermédiaire avec vérification de challenge et quotas par origine), puis des tests d'intrusion ciblés.

Ordre : exécuter la migration dans Supabase → SQL Editor, vérifier l'absence d'erreurs, vérifier la création d'une nouvelle famille fictive, puis contrôler à nouveau les permissions et les fonctions. Il n'est pas nécessaire de modifier les Secrets ou de régénérer les codes.


## Suppression d'un Bureau — migration V3

1. Exécuter `migration_suppression_v3.sql` dans le projet **Supabase multi-familles**, pas dans le projet familial d'origine.
2. La migration n'efface aucune donnée existante et **conserve le plafond global** de créations de la V1.
3. Pour les Bureaux existants, elle attribue le rôle de créateur au **premier membre enregistré** (à vérifier si des ajouts manuels ont eu lieu).
4. Seul ce membre voit « ⚙️ Gestion du Bureau » dans l'application, et peut supprimer le Bureau après avoir tapé `SUPPRIMER <nom exact du Bureau>` et coché la confirmation.
5. La suppression entraîne l'effacement des membres, listes, réservations et participations par les contraintes de cascade. Elle est irréversible au niveau de la base active ; les éventuelles sauvegardes/historiques du prestataire peuvent avoir des durées propres.
6. Faire le test exclusivement sur un Bureau fictif jetable, **jamais** sur une famille dont les listes doivent être conservées.

## Confidentialité et publication

Une notice informative est visible dans l'application. Elle ne remplace pas une politique RGPD complète (responsable de traitement, contact, durée de conservation, sous-traitants, droits des personnes, éventuelle gestion des mineurs), à préparer avant une vraie diffusion ouverte.

Les appels RPC publics `board`, `create_family` et `join_family` restent directement utilisables en dehors de Streamlit. Les limites globales sur `create_family` réduisent les créations mais ne fournissent **aucune limitation par personne ni véritable protection des tentatives d'accès**. Le masquage d'un bouton, une vérification JavaScript ou un compteur Streamlit ne sauraient résoudre ce point. Pour une diffusion large, il faudra mettre ces accès derrière une protection vérifiée côté serveur (anti-bot et limitation des requêtes) ; ne pas affirmer que l'application est sécurisée avant ces tests.


## Activation anti-abus V4 : ordre obligatoire (ne pas inverser)

La V4 est conçue pour conserver les bureaux, codes et souhaits existants. **Ne pas appliquer le SQL tant que le serveur Streamlit n'a pas ses nouveaux secrets.**

1. Dans **Supabase du projet multi-familles**, retrouver la clé **service_role** (ou clé serveur secrète compatible avec le client Supabase). Elle est très privilégiée : elle doit rester exclusivement dans les secrets du déploiement Streamlit, **jamais dans GitHub, le navigateur, un message ou une capture**. Utiliser uniquement la clé du projet multi-familles, pas celle du Bureau familial.
2. Dans **Streamlit Community Cloud → app familles → Settings → Secrets**, conserver les deux anciens secrets et ajouter :
   ```toml
   SUPABASE_SERVICE_ROLE_KEY = "CLE_SERVEUR_SUPABASE"
   RATE_LIMIT_PEPPER = "UNE_LONGUE_CHAINE_ALEATOIRE_UNIQUE"
   ```
   Générer la seconde localement avec `python -c "import secrets; print(secrets.token_hex(32))"`. Ne partager ni l'une ni l'autre.
3. Enregistrer et redémarrer l'app. **Avant le SQL, les opérations publiques continuent de fonctionner** (anciens droits anon toujours actifs). Une fois la clé serveur en place, Streamlit effectue les appels avec cette clé.
4. Exécuter `migration_antiabus_v4.sql` dans **Supabase SQL Editor** (projet multi-familles). Cette migration crée la table de quotas et **révoque l'exécution anonyme des RPC**. Si on la lance trop tôt, l'application sera indisponible jusqu'à correction des secrets.
5. Vérifier le tableau final : `anon_can_execute=false` et `service_can_execute=true`. Redémarrer Streamlit, puis vérifier connexion, création et invitation sur un Bureau fictif. Si la mise en place échoue, ne pas publier l'app ; revoir la clé et les droits.

La V4 limite, par adresse réseau détectée par Streamlit (ou par quota partagé lorsqu'elle est indisponible) : **15 connexions / 15 min, 4 créations / heure, 12 inscriptions / heure**. Les compteurs sont stockés côté serveur, dans Supabase. L'identifiant réseau y est conservé sous forme HMAC avec une clé de hachage privée ; l'adresse IP brute n'est pas stockée par cette fonctionnalité.

**Limites :** une adresse IP peut être mutualisée (plusieurs proches bloqués ensemble) ; des bots distribués peuvent changer d'IP ; les compteurs expirés requièrent un entretien périodique ; cette V4 n'est pas un service anti-DDoS ni une certification de sécurité. La création globale reste plafonnée par la V1.

Surtout, ne jamais fournir `SUPABASE_SERVICE_ROLE_KEY` à un code côté navigateur ni remettre les droits anon sur les fonctions du Bureau après activation.
