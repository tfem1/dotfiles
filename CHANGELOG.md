# Journal des modifications

Les changements notables du projet sont consignés ici. Le format suit
[Keep a Changelog](https://keepachangelog.com/fr/1.1.0/).

## [Non publié]

### Ajouté

- `theme.toml` : source de vérité unique de l'apparence du desktop (palette,
  accent, polices, formes, effets, curseur, icônes, une couleur par module du
  shell).
- `config.json` : réglages du shell, en commençant par son nom.
- Palette base16 Catppuccin Mocha (reprise de tinted-theming/schemes).
- Génération du thème (`tfem generate`, `scripts/generate.sh`) : validation
  des réglages avec des messages clairs, palette avec surcharges, moteur de
  templates avec filtres de couleur, écriture sûre (écriture atomique,
  sauvegardes, lignes d'include repérées, rechargement seulement si un fichier
  a changé), `--dry-run`, `--only`, `--all`.
- Templates pour Hyprland (config Lua, Hyprland 0.55+) et pour le shell
  Quickshell (`theme.json`).
- Tests unitaires et de bout en bout avec fichiers de référence.
- Feuille de route : thèmes avant le shell, deux styles (Material et Mono),
  profils de look, assistant de premier lancement, dock optionnel, mode jeu,
  ne pas déranger, anti-veille, agent Polkit, deux thèmes SDDM, collection de
  wallpapers wallhaven.
