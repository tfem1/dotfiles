# TFEM

Dotfiles Hyprland modulaires avec un shell Quickshell complet, pilotés par un
seul fichier de réglages.

> **TFEM est le nom de ce repo et de sa CLI, pas celui de ton desktop.** Rien à
> l'écran ne porte le nom TFEM : aucune marque dans la barre, l'écran de
> verrouillage, le launcher ou les notifications. Voir
> [Fais-le tien](#fais-le-tien).

**État :** début du projet. L'étape 1 sur 10 est terminée (génération du
thème) ; les palettes et les thèmes d'apps arrivent ensuite. Le plan complet
est dans [docs/roadmap.md](docs/roadmap.md).

## Comment marche le thème

Un seul fichier, `theme.toml`, décrit l'apparence de tout le desktop :
palette, accent, polices, arrondis, espacements, flou, curseur et couleur de
chaque module du shell. `tfem generate` le transforme en fichiers de config
pour chaque app, à leur emplacement habituel :

```
theme.toml ──► validation ──► palette (base16) ──► templates ──► ~/.config/hypr/theme.lua
themes/*.toml ────────────────────┘                              ~/.config/quickshell/<shell>/theme.json
```

- Les palettes sont au format [base16](https://github.com/tinted-theming/home) :
  les thèmes fournis et les palettes extraites d'un wallpaper se présentent de
  la même façon à tous les templates.
- Les fichiers générés ne remplacent jamais tes propres configs. Quand une app
  a besoin d'une ligne pour charger le fichier généré (par exemple
  `require("theme")` dans `hyprland.lua`), cette seule ligne est ajoutée entre
  deux commentaires repères. Tout ce qui serait écrasé est d'abord sauvegardé
  dans `~/.local/state/tfem/backups/`.
- Un réglage invalide est refusé avec un message clair, avant toute écriture.

Détails : [docs/architecture.md](docs/architecture.md) et le format des
templates dans [docs/templates.md](docs/templates.md).

## Essayer

Prérequis pour cette étape : `bash` et Python 3.11 ou plus récent.

```bash
./tfem generate --dry-run --all   # montre ce qui serait écrit
./tfem generate                   # écrit les fichiers des apps installées
```

Tes réglages personnels vont dans `~/.config/tfem/theme.toml` et
`~/.config/tfem/config.json`. Seules les clés que tu y écris remplacent les
valeurs par défaut, par exemple :

```toml
[palette]
accent = "green"

[shape]
radius = 8
```

Lancer les tests :

```bash
PYTHONPATH=scripts:tests python3 -m unittest discover -s tests
```

## Organisation du repo

```
theme.toml            apparence par défaut du desktop (source de vérité unique)
config.json           comportement par défaut du shell (nom du shell, puis plus)
tfem                  CLI
themes/               palettes base16, un fichier par thème
templates/            un template par fichier généré + manifeste targets.toml
scripts/generate.sh   point d'entrée de la génération
scripts/theming/      moteur : réglages, palette, templates, écriture sûre
tests/                tests unitaires et de bout en bout, fichiers de référence
docs/                 architecture, format des templates, feuille de route
```

## Fais-le tien

- **Nom du shell :** la config Quickshell vit dans
  `~/.config/quickshell/<nom>/`. Change `shell.name` dans ton `config.json`
  (par défaut `desktop`).
- **Couleurs :** choisis un thème avec `palette.source`, un accent avec
  `palette.accent`, et remplace une couleur précise avec
  `[palette.overrides]`.
- **Tes propres thèmes :** dépose un fichier de thème base16 dans
  `~/.config/tfem/themes/`. Il passe avant le thème fourni du même nom.
- **Nom de la CLI :** tu préfères `dots` ou `wm` ? Crée un lien vers le même
  script ; son aide affiche le nom sous lequel tu l'appelles :
  `ln -s "$PWD/tfem" ~/.local/bin/dots`

D'autres options (nom affiché, avatar, hostname) arrivent avec la fenêtre de
Settings.

## Crédits et inspirations

- **[Serpantinum](https://github.com/ilyamiro/serpantinum)** (AGPL-3.0) a
  inspiré l'architecture : un seul shell Quickshell séparé de la config du
  compositeur, un fichier de réglages appliqué à chaud, des palettes
  prédéfinies ou tirées du wallpaper avec surcharge couleur par couleur, et
  des thèmes d'apps écrits dans un fichier à part, chargé par une seule ligne
  repérée, au lieu d'écraser les configs. Seules les idées ont été reprises :
  TFEM est une implémentation originale et ne contient aucun code de
  Serpantinum.
- **[tinted-theming](https://github.com/tinted-theming/schemes)** (MIT) pour
  les palettes base16 et la correspondance standard des couleurs du terminal.
- Les références visuelles du futur shell et des écrans de connexion sont
  listées dans [docs/roadmap.md](docs/roadmap.md).

## Licence

[GPL-3.0](LICENSE).
