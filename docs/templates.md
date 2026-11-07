# Format des templates

Un template est le fichier qu'une app attend, avec des balises `{{ … }}` là où
vont les valeurs de `theme.toml`. Les templates vivent dans `templates/` et
sont listés dans `templates/targets.toml`.

## Balises

```
{{ nom }}                     une valeur
{{ nom | filtre }}            une valeur passée dans un filtre
{{ nom | alpha:0.8 | hypr }}  les filtres s'appliquent de gauche à droite
```

Une variable ou un filtre inconnu est une erreur qui indique le fichier et la
ligne, avec une suggestion quand un nom proche existe. Un `{{` seul n'est pas
autorisé ; écris `{ {` si tu as vraiment besoin de deux accolades.

## Variables

| Groupe | Noms | Exemple |
|---|---|---|
| Palette brute | `base00` … `base0F` (surcharges appliquées) | `#1e1e2e` |
| Rôles | `bg` `bg_alt` `surface` `muted` `subtle` `fg` `fg_bright` | |
| Teintes | `red` `orange` `yellow` `green` `cyan` `blue` `purple` `brown` | |
| Accent | `accent` (la teinte choisie dans `palette.accent`) | |
| Terminal | `ansi0` … `ansi15` | |
| Couleurs des modules | `modules.wifi`, `modules.audio`, … | |
| Infos de palette | `palette.name` `palette.family` `palette.variant` `palette.author` | `"dark"` |
| Réglages | chaque clé de `theme.toml`, en notation pointée | `shape.radius`, `font.sans` |

`wallpaper.path` est toujours un chemin absolu (un chemin relatif pointe dans
`wallpapers/`).

Correspondance rôles → slots base16 : `bg`=00, `bg_alt`=01, `surface`=02,
`muted`=03, `subtle`=04, `fg`=05, `fg_bright`=06, `red`=08, `orange`=09,
`yellow`=0A, `green`=0B, `cyan`=0C, `blue`=0D, `purple`=0E, `brown`=0F. Les
couleurs du terminal suivent la correspondance officielle de tinted-theming.

## Filtres

| Filtre | Résultat | Usage |
|---|---|---|
| aucun / `hex` | `#cba6f7` (`#cba6f7cc` si transparente) | CSS, la plupart des apps |
| `strip` | `cba6f7` | foot et autres fichiers ini |
| `alpha:0.8` | la couleur à 80 % d'opacité | à combiner avec un autre filtre |
| `hypr` | `rgba(cba6f7ff)` | Hyprland, hyprlock |
| `argb` | `#cccba6f7` | Qt et QML (l'alpha vient **en premier**) |
| `rgb` | `203, 166, 247` | `rgba()` en CSS |
| `json` | `"Inter"`, `"#cba6f7"`, `12`, `true` | fichiers JSON, chaînes Lua |

Les booléens s'écrivent `true` / `false`, les nombres sous leur forme la plus
courte.

**Piège :** QML lit `#rrggbbaa` comme `#aarrggbb`. Garde des couleurs opaques
dans `theme.json` et applique l'opacité côté QML, ou utilise `argb`.

## Manifeste des cibles

```toml
[kitty]
template = "terminal/kitty.conf.tpl"           # relatif à templates/
output   = "{config}/kitty/palette.conf"       # {config} = $XDG_CONFIG_HOME
needs    = "kitty"                             # ignorée si kitty n'est pas installé
reload   = "pkill -USR1 -x kitty"              # lancée seulement si le fichier a changé
include  = { into = "{config}/kitty/kitty.conf", line = "include palette.conf", create = true }
```

Clés de `include` : `into` et `line` (obligatoires), `comment` (préfixe des
repères, `#` par défaut), `position` (`end` ou `start`), `create` (`false` par
défaut : une config d'app absente n'est pas créée, et on t'indique la ligne à
ajouter). Le placeholder `{shell}` est le nom du shell défini dans
`config.json`.

## Ajouter une app

1. Écris `templates/<groupe>/<fichier>.tpl` avec les variables ci-dessus.
2. Ajoute une entrée dans `templates/targets.toml`.
3. Lance `./tfem generate --dry-run --all --only <nom>` et vérifie le diff.
4. Ajoute un test avec fichier de référence dans `tests/test_generate.py`.
