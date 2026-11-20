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

## 5 — Turnstile intégré au code (activation séparée)

Le code Streamlit inclut désormais un composant bidirectionnel pour les trois formulaires : connexion, création et invitation. Chaque action vérifie le jeton **sur le serveur** via Cloudflare Siteverify, avec comparaison de l'hôte `bureau-des-lutins-familles.streamlit.app` et échec bloquant si le contrôle est indisponible.

**Par défaut la vérification est désactivée** pour ne pas interrompre les familles pendant le déploiement. Une fois le nouveau code déployé et ses dépendances installées, activer dans **Streamlit → Settings → Secrets** :

```toml
TURNSTILE_ENFORCE = true
```

Les secrets `TURNSTILE_SITE_KEY` et `TURNSTILE_SECRET_KEY` doivent déjà être définis et correspondre au widget configuré pour le bon domaine. La clé secrète ne doit jamais figurer dans GitHub.

**Tester après activation, avant toute diffusion :**
1. Sur l'application, vérifier que la validation apparaît pour les trois onglets (connexion, création et invitation).
2. Soumettre un formulaire **sans jeton** : l'opération doit être refusée.
3. Réussir le contrôle puis se connecter à un compte fictif existant.
4. Créer une famille de test, puis rejoindre une famille fictive.
5. Vérifier que les secrets ne sont jamais affichés dans le navigateur.
6. Si un problème bloque les familles, remettre temporairement `TURNSTILE_ENFORCE = false` dans les Secrets, puis investiguer. Ne pas diffuser publiquement tant que la protection n'est pas effective.

**Limites :** le test réel du widget et de l'API Cloudflare n'est pas exécutable à partir de GitHub seul. Le contrôle protège les trois formulaires d'accès, mais pas les autres RPC après connexion ; l'usage d'une clé `service_role` côté serveur reste un privilège élevé et exige vigilance et contrôles complémentaires. Cela n'est pas un audit de sécurité indépendant. Après activation, les tokens sont éphémères et à usage unique ; une expiration nécessite de renouveler la validation.

## 6 — Durée de conservation décidée : 18 mois d'inactivité

Décision validée : supprimer automatiquement les Bureaux qui restent **18 mois sans utilisation avec un code personnel valide**. Les membres, envies, réservations et participations disparaissent avec le Bureau de la base active. Il n'existe **pas d'alerte individuelle par courriel**, puisque le service ne collecte pas les adresses des familles : il faut informer tous les utilisateurs visiblement avant la création et dans la notice.

**Ordre d'installation :**

1. Code de l'application : il informe de cette règle et tente d'appeler `touch_family_activity` lors d'une connexion réussie et lors des actualisations. Tant que la migration V5a manque, il continue à fonctionner sans couper l'accès.
2. **Installer `migration_conservation_v5a.sql` dans Supabase SQL Editor (multi-familles uniquement)**. Ce fichier ne supprime aucune donnée : les familles déjà présentes reçoivent au minimum **18 mois à compter de l'installation**, et les nouvelles familles commencent leur délai à la création.
3. Vérifier que le tableau final indique `bureaux_eligibles_suppression = 0`. Se connecter à une famille fictive, puis vérifier que `last_activity_at` est mise à jour par un appel autorisé.
4. Après validation de la notice publique, **installer séparément `activation_conservation_v5b.sql`** pour programmer la suppression chaque jour via Supabase Cron (extension pg_cron). Vérifier la tâche via le SELECT final. Cette seconde étape n'a pas été exécutée automatiquement par GitHub.
5. Pour désactiver l'automatisation, exécuter `select cron.unschedule('bureau-lutins-purge-inactifs-18mois');` dans Supabase SQL Editor.

**Limite opérationnelle** : il faut vérifier que les sauvegardes Supabase et les journaux techniques conservent ou non des traces au-delà de la purge de la base active. Les compteurs anti-abus `request_limits` ont leur propre durée de conservation à définir. Une suppression après inactivité ne résout pas ces questions.

Il reste à préciser une adresse de contact publique, la base juridique du traitement et les modalités de réponse aux droits RGPD avant d'annoncer la mise en conformité.
