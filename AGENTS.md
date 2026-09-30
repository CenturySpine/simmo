# AGENTS.md

Instructions pour tout assistant de code dans ce dépôt. `CLAUDE.md` l'importe.

## Projet

Simmo : PWA Flutter (web uniquement) de simulation de prêt immobilier, au plus proche de ce que
font les courtiers. Hébergée sur Vercel. Firebase disponible si un backend devient nécessaire.

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
fvm flutter build web --release --no-web-resources-cdn
fvm flutter test tool/generate_icons.dart     # régénère icônes PWA et favicon depuis le logo
npx vercel <cmd>                             # CLI Vercel
npx firebase <cmd>                           # CLI Firebase
gh <cmd>                                     # CLI GitHub (global)
```

À chaque push, Vercel exécute `tool/vercel_build.sh` (Flutter, analyze, test, build web).

## Code

- Feature-first : `lib/core/` (thème, config), `lib/features/<feature>/`, `lib/shared/`
  (widgets communs), `test/` en miroir.
- Calculs financiers en Dart pur, testés unitairement.

## Design

Sobre et moderne, inspiré de nuni. Fond `#F4F5FA`, surfaces blanches, bordures fines sans ombre,
texte `#14172B`, une seule couleur d'action : bleu `#2F54EB`. Police Plus Jakarta Sans embarquée.
Rayons 14 (contrôles), 20 (cartes), 28 (dialogues).

- Couleurs uniquement dans `lib/core/theme/app_colors.dart`.
- Composants stylés une fois dans `lib/core/theme/app_theme.dart` ; les écrans ne fixent ni
  couleur ni forme.
