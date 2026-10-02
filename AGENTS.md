# AGENTS.md

Instructions pour tout assistant de code dans ce dépôt. `CLAUDE.md` l'importe.

## Projet

Simmo : PWA Flutter (web uniquement) de simulation de prêt immobilier, au plus proche de ce que
font les courtiers. Hébergée sur Vercel (site et fonction des ventes DVF). Firebase disponible si
un autre backend devient nécessaire.

## Règles

1. **Minimal partout** : code, explications, retours, questions. Pas de dépendance ni de fichier
   sans besoin immédiat.
2. **Aucune décision silencieuse.** Un doute = une question courte au PO (product owner), avec une
   suggestion argumentée.
3. **`main` uniquement**, pas de branche ni de PR. Vercel déploie chaque push.
4. **Jamais de commit ni de push sans demande explicite du PO.**
5. Avant de rendre la main : `analyze` et `test` verts, rendu vérifié dans le navigateur.
6. Dépôt **public** : aucun secret committé (`env/*.json` est ignoré).

## Ton

Factuel, synthétique, en français. Le PO n'est pas technicien : expliquer l'effet d'un choix, pas
sa mécanique. Toute demande au PO dit à quoi elle sert. Finir par les points en attente du PO.

## Langues

Technique en anglais (code, commentaires, commits, README). Interface, docs et échanges en
français. Interface en français uniquement pour l'instant.

## Commandes

Flutter épinglé par `.fvmrc` (fvm). CLI Node épinglés par `package.json`.

```powershell
fvm flutter pub get
fvm flutter run -d chrome
fvm dart format lib test tool
fvm flutter analyze --fatal-infos
fvm flutter test
node --test tool/sales_api.test.mjs           # tests de la fonction api/sales.mjs
fvm flutter build web --release --no-web-resources-cdn
fvm flutter test tool/generate_icons.dart     # régénère icônes PWA et favicon depuis le logo
npx vercel <cmd>                             # CLI Vercel
npx firebase <cmd>                           # CLI Firebase
gh <cmd>                                     # CLI GitHub (global)
```

À chaque push, Vercel exécute `tool/vercel_build.sh` (Flutter, analyze, tests, build web) et
déploie `api/` en fonctions.

## Code

- Feature-first : `lib/core/` (thème, config), `lib/features/<feature>/`, `lib/shared/`
  (widgets communs), `test/` en miroir.
- Calculs financiers en Dart pur, testés unitairement, tout côté web app (aucun serveur).
- Seul code serveur : `api/sales.mjs` (fonction Vercel, Node sans dépendance). Elle lit les ventes
  DVF géolocalisées (data.gouv.fr), dont les fichiers refusent la lecture directe depuis le
  navigateur, et renvoie les ventes à moins de 500 m sur les deux dernières années publiées.
  Elle tourne à Paris (`regions` dans `vercel.json`), près des données.
  L'adresse est cherchée côté navigateur via le géocodage de l'IGN (`geocoding.dart`).
- Chiffres réglementaires et de marché (notaire, impôt, Action Logement, seuils d'endettement)
  dans `lib/features/simulation/domain/rules.dart`, PTZ dans `ptz.dart`, garantie Crédit Logement
  (relevée sur leur simulateur) dans `guarantee.dart`, taux d'assurance par âge dans `insurance.dart`.
  Les mettre à jour quand la règle change.
- Cinq paramètres principaux (prix, apport, emprunt, durée, mensualité), tous saisissables : deux
  sont calculés, choisis parmi les moins récemment saisis (`dashboard_page.dart`). La mensualité se
  saisit en endettement, en montant, ou « tout compris » (budget logement mensuel, dont on retire
  charges, taxe foncière, énergie et épargne travaux pour obtenir la mensualité).
- Revenus, revenu fiscal, taux, prix saisi, âge, taux de prélèvement saisi, budget du logement,
  prix de négociation, surface et adresse du bien sont gardés sur l'appareil (stockage local du
  navigateur, `saved_inputs.dart`) et rechargés à l'ouverture.
- Budget mensuel (vue acheteur : charges, taxe foncière, énergie, épargne travaux de copro) et
  négociation (offre, plafond, prix affiché) dans `budget.dart`. Ils ne touchent pas aux calculs
  bancaires, sauf les appels de fonds de copro à l'achat, financés avec le projet.
- Zone du bien : remplie par l'adresse du bien, ou recherche par commune dans `assets/data/zonage_abc.csv`, fichier officiel du
  zonage ABC (data.gouv.fr, « Liste des communes selon le zonage ABC ») gardé tel que publié. À
  chaque nouvel arrêté, remplacer le fichier par la nouvelle version.
- Partage : « Partager » copie `https://simmo.centuryspine.org/#<code>`, où le code compacte tous
  les paramètres (`share_link.dart`). Ne jamais réordonner les champs du code : tout changement de
  format passe par une nouvelle version, sinon les liens déjà partagés cassent.
- Pied de page : avertissement, mentions légales, confidentialité (RGPD), « À propos »
  (centuryspine.org), « © 2026 Simmo » (`lib/features/legal/`). Tenir ces textes à jour à chaque
  nouvelle donnée gardée sur l'appareil ou nouveau service tiers.
- Seul garde-fou : la couleur du taux d'endettement (vert ; orange > 33 % ; rouge > 35 %). Aucune
  autre alerte ni plafond de saisie.
- `test/features/simulation/domain/simulator_test.dart` reproduit deux propositions de courtier :
  tout changement de calcul doit les garder vertes.

## Design

Sobre et moderne, inspiré de nuni. Fond `#F4F5FA`, surfaces blanches, bordures fines sans ombre,
texte `#14172B`, une seule couleur d'action : bleu `#2F54EB`. Police Plus Jakarta Sans embarquée.
Rayons 14 (contrôles), 20 (cartes), 28 (dialogues).

- Couleurs uniquement dans `lib/core/theme/app_colors.dart`.
- Composants stylés une fois dans `lib/core/theme/app_theme.dart` ; les écrans ne fixent ni
  couleur ni forme.
