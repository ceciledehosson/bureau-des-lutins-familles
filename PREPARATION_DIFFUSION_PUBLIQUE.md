# Préparation à la diffusion publique (Facebook / Instagram)

**Statut : préparation. Ne pas annoncer que l'anti-robots est opérationnel sans test du formulaire et de la vérification serveur.**

## 1 — Audit sécurité sans modifier les familles
Exécuter `audit_avant_publication.sql` dans Supabase SQL Editor du projet multi-familles. Vérifier que chaque ligne est « OK ». Il s'agit uniquement de contrôles de permissions et de structure ; **cela ne remplace pas des tests d'intrusion ni des tests négatifs entre familles**.

Tests supplémentaires sur **deux familles fictives uniquement** :
- le code personnel A ne doit pas afficher les listes de B ;
- un code invalide ne donne aucun accès ;
- le destinataire ne voit jamais les réservations sur ses propres souhaits ;
- un membre non créateur ne peut pas supprimer son Bureau ;
- une invitation ne donne pas les droits du créateur ;
- l'achat, la participation et la libération ne doivent affecter que les souhaits de la famille autorisée.
Ces points doivent aussi être vérifiés par appels API de test, pas seulement en cliquant dans l'interface.

## 2 — Anti-bot à ajouter avant diffusion ouverte

Choix proposé : **Cloudflare Turnstile**, vérifié par le serveur avant toute création de Bureau ou inscription. Pour une protection plus complète, prévoir aussi la vérification sur la connexion. Il faut :
- créer un widget Turnstile pour le domaine **`bureau-des-lutins-familles.streamlit.app`** (sans `https://` ni `/`) ;
- obtenir deux valeurs distinctes : la **site key** (publique) et la **secret key** (privée) ;
- ajouter ces valeurs seulement à la configuration appropriée (secret key dans les Secrets du serveur Streamlit, jamais sur GitHub) ;
- installer et vérifier le composant d'interface qui retourne le jeton au processus Python ;
- valider **côté serveur** chaque jeton par un POST HTTPS à `https://challenges.cloudflare.com/turnstile/v0/siteverify` avec délai réseau et refus par défaut ;
- refuser l'action si le jeton est absent, invalide, expiré ou réutilisé ;
- conserver les quotas Supabase V4, et ajouter des limites au trafic si la diffusion devient importante.

**Important** : un simple dessin « Je ne suis pas un robot », un widget sans vérification côté serveur ou un appel à `siteverify` après la création du Bureau ne protègent rien.

Ne pas changer le code en production avant d'avoir les clés et un parcours de test garantissant que les familles existantes peuvent toujours se connecter.

Documentation : https://developers.cloudflare.com/turnstile/get-started/server-side-validation/

## 3 — Politique de confidentialité (brouillon à compléter, ne pas publier tel quel)

**Service** : Le Bureau des Lutins, application gratuite consacrée exclusivement à Noël.

**Responsable du traitement et contact** : Cécile de Hosson — **[adresse de contact dédiée à préciser]**.

**Finalités** : créer un Bureau familial, organiser les listes d'envies, les réservations secrètes et les participations aux cadeaux ; prévenir les abus automatisés.

**Données** : nom du Bureau, prénoms ou pseudonymes, souhaits et détails saisis, prix indicatifs, liens, réservations et participations ; empreintes des codes d'accès et d'invitation ; identifiants de quota hachés à partir de données de connexion selon disponibilité technique. Aucune adresse e-mail n'est nécessaire à l'utilisation.

**Destinataires** : les membres du même Bureau selon les droits applicables ; hébergeurs techniques Streamlit Community Cloud et Supabase pour les données nécessaires au service ; **Cloudflare en cas d'activation de Turnstile** pour la vérification anti-bot. Les listes de souhaits ne sont pas rendues publiques.

**Base juridique proposée** : **[à déterminer en fonction du statut réel de l'activité et des traitements ; ne pas affirmer sans analyse]**.

**Durée de conservation** : **[durée précise à définir, puis appliquer techniquement]**. Tant que la suppression automatique n'est pas installée, ne pas annoncer qu'elle existe. Un créateur peut supprimer son Bureau via la fonction de gestion.

**Droits des personnes** : accès, rectification, effacement et autres droits selon leur applicabilité, à exercer via **[contact à préciser]**. Le titulaire d'une lettre peut modifier ou supprimer ses propres souhaits. Une réclamation peut être adressée à la CNIL.

**Mineurs** : **[choisir des conditions d'utilisation appropriées et les documenter]**.

**Transferts et conservation technique** : **[vérifier lieux d'hébergement, contrats des prestataires et sauvegardes / rétention]**.

Source de cadrage : https://www.cnil.fr/fr/conformite-rgpd-information-des-personnes-et-transparence

## 4 — Décisions restant à prendre
- Adresse e-mail de contact (elle sera visible du public).
- Règle de conservation (par exemple suppression des Bureaux de Noël après une période définie **avec information préalable** ; à ne pas activer sans avoir vérifié les conséquences).
- Domaine du déploiement Streamlit confirmé : `bureau-des-lutins-familles.streamlit.app`.
- Critères d'ouverture (tests réussis, usage et coûts du plan gratuit, processus de support minimal).

**Les trois sujets ne sont pas entièrement finalisés par ce document.**
