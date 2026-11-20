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

Le code est publié pour développement et expérimentation, sans garantie de sécurité ou de disponibilité. Licence open source à déterminer.
