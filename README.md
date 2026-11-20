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
