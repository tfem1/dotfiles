# Architecture

## Où vivent les fichiers

| Emplacement | Contenu | Qui l'écrit |
|---|---|---|
| Le repo (installé dans `~/.local/share/tfem`) | défauts, thèmes, templates, scripts | le projet |
| `~/.config/tfem/` | ton `theme.toml`, ton `config.json`, tes `themes/` | toi, la fenêtre de Settings |
| `~/.config/<app>/` | fichiers générés (`hypr/theme.lua`, …) | la génération uniquement |
| `~/.local/state/tfem/` | sauvegardes, registre des fichiers générés | la génération uniquement |

Tes fichiers ne contiennent que les clés que tu as changées : chacune remplace
la valeur par défaut du même nom. Mettre le projet à jour n'entre donc jamais
en conflit avec tes réglages, et « revenir aux valeurs par défaut » revient à
supprimer une clé.

## Deux fichiers de réglages, une règle

- `theme.toml` contient l'**apparence** : palette, accent, polices, formes,
  effets, wallpaper, curseur, icônes, couleurs des modules.
- `config.json` contient **tout le reste** : nom du shell, puis barre, dock,
  widgets, écrans et identité. Le shell le lit à chaud.

## Étapes de la génération

1. **Charger** les défauts du repo, puis ton fichier par-dessus
   (`settings.py`).
2. **Valider** chaque clé avec `schema.py` : type, bornes, valeurs permises.
   Tous les problèmes sont listés d'un coup, et rien n'est écrit s'il y en a un.
3. **Résoudre la palette** (`palette.py`) : trouver le fichier de thème (tes
   `themes/` d'abord), appliquer `[palette.overrides]`, en déduire les rôles
   lisibles (`bg`, `fg`, `accent`…) et les 16 couleurs du terminal.
4. **Construire le contexte** (`context.py`) : la liste à plat de toutes les
   variables utilisables dans un template ; une teinte comme `"blue"` devient
   une vraie couleur.
5. **Rendre chaque cible** listée dans `templates/targets.toml`
   (`template.py`, `filters.py`). Un template cassé ne fait échouer que sa
   propre cible.
6. **Écrire sans risque** (`writer.py`) :
   - résultat identique : rien n'est touché et l'app n'est pas rechargée ;
   - fichier que la génération n'a pas produit (ou modifié à la main) :
     sauvegardé d'abord ;
   - écriture atomique (fichier temporaire puis renommage) ;
   - les lignes d'include sont placées entre des repères
     `>>> generated: <cible> >>>`, ajoutées une seule fois, et une config d'app
     absente n'est jamais créée, sauf si la cible l'autorise (un
     `hyprland.lua` vide masquerait la config par défaut de Hyprland).
7. **Recharger** l'app quand son fichier a changé et qu'elle est installée.

## Idées reprises de Serpantinum

Des idées seulement, pas de code (Serpantinum est sous AGPL-3.0) :

- une seule instance Quickshell comme shell, séparée de la config du
  compositeur, elle-même découpée en petits modules ;
- un fichier de réglages surveillé et appliqué à chaud ;
- des palettes prédéfinies ou tirées du wallpaper, avec surcharge couleur par
  couleur ;
- des thèmes d'apps dans un fichier généré à part, chargé par une seule ligne
  repérée, sans jamais écraser la config de l'utilisateur ;
- ne recharger une app que si son fichier généré a changé ;
- une CLI qui reflète la fenêtre de Settings, pour que les deux écrivent par
  le même chemin.

## Hypothèses vérifiées et points à confirmer

- Hyprland 0.57 ne lit plus que `hyprland.lua` (le format `.conf` a été
  retiré), donc le template Hyprland produit du Lua. `require("theme")` charge
  `~/.config/hypr/theme.lua`.
- À confirmer sur une vraie session : que `hyprctl reload` relance bien les
  fichiers chargés avec `require` (le wiki dit que chaque `require` s'exécute
  dans son propre scope, sans parler de cache).
