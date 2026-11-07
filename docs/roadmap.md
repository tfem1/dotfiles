# Feuille de route

Chaque étape est planifiée, validée, implémentée, puis relue avant la
suivante. Les thèmes passent avant le shell, pour que le shell soit construit
directement avec les bonnes palettes.

## Règles de design

- **Jamais de dégradé, nulle part.** Bordures de fenêtres, boutons, sliders,
  panneaux, fonds et écrans de connexion : uniquement des couleurs unies.
- Les couleurs viennent toujours de la palette active : un nom de teinte,
  jamais un code hex figé.

## 1. Génération du thème — terminé

`theme.toml`, `config.json`, format de thème base16, moteur de templates,
templates Hyprland (Lua) et Quickshell, écriture sûre, `tfem generate`, tests.

## 2. Palettes et thèmes d'apps — prochaine étape

- Importer la collection base16 de
  [tinted-theming/schemes](https://github.com/tinted-theming/schemes) (MIT,
  362 thèmes) avec un script reproductible, un fichier par thème, auteur
  conservé.
- **Vérification des teintes à l'import.** Les slots base16 sont des rôles de
  coloration syntaxique, pas des teintes garanties : le Tokyo Night de
  tinted-theming met un bleu pâle (`#C0CAF5`) dans le slot « rouge » et un
  cyan (`#0DB9D7`) dans le slot « jaune ». L'importeur mesure la teinte de
  chaque slot et corrige ou signale ces thèmes, pour que `red` soit toujours
  rouge dans l'interface (notifications urgentes, batterie faible).
- **Thèmes mis en avant**, affichés en premier dans le sélecteur :
  - *Kanagawa* (et Kanagawa Dragon) : fond nuit, accent **vert** et couleurs
    de modules dans les verts.
  - Beaucoup d'autres thèmes verts : Everforest, Gruvbox Material, et ceux
    repérés par la vérification des teintes.
  - *Tokyo Night* (Night, Storm, Moon) : accent **bleu nuit** et quelques
    modules en **violet**, construit à partir de la palette officielle de
    Tokyo Night pour avoir le vrai bleu et le vrai violet.
- Chaque thème peut proposer un accent et des couleurs de modules, appliqués
  quand tu le choisis ; tu peux toujours les changer ensuite.
- Thèmes de terminal (foot, kitty, alacritty, ghostty, wezterm), GTK et Qt,
  sans jamais écraser les configs existantes.
- `tfem theme <nom>`.

## 3. Shell Quickshell : barre, OSD, launcher, notifications

- Un seul `shell.qml` qui ne fait que composer ; chaque partie cachée dans un
  `Loader`.
- Couleurs lues à chaud depuis le `theme.json` généré (`FileView` +
  `JsonAdapter`).
- **Deux styles visuels, au choix dans les Settings** (`shell.style` dans
  `config.json`), qui partagent les mêmes composants autant que possible :
  - *Material* : barre verticale fine, boutons en pilules arrondies, panneau
    latéral avec raccourcis, notifications et calendrier, carte média.
    Référence : [end-4/dots-hyprland](https://github.com/end-4/dots-hyprland)
    (illogical-impulse).
  - *Mono* : barre en haut avec pilules groupées, police monospace, grosse
    horloge pixel sur le bureau, panneau compact avec avatar, uptime, tuiles
    2×2 et larges sliders. Référence :
    [aelyx-shell](https://github.com/xZepyx/aelyx-shell).
  - Deux implémentations originales : seul le look est reproduit, sans les
    dégradés de certaines références.
- **Dock optionnel** : `dock.enabled` dans `config.json`, assorti au style.
- **Ne pas déranger** : les notifications sont gardées mais pas affichées.

## 4. Wallpapers

Sélecteur (grille, aperçu, transitions, clavier, recherche, favoris), palette
extraite du wallpaper (matugen base16), wallpapers animés si c'est possible.

**Collection : au moins 50 wallpapers de [wallhaven.cc](https://wallhaven.cc),
surtout des forêts, plus des My Little Pony.** De vraies images prises sur le
site, aucune générée.

- wallhaven indique que « toutes les images restent la propriété de leurs
  auteurs », et My Little Pony appartient à Hasbro : les images ne sont donc
  **pas commitées** dans ce repo public. Le repo contient la liste choisie
  (`wallpapers/collection.toml` : identifiant wallhaven, catégorie,
  résolution, lien) et `tfem wallpapers fetch` les télécharge sur ta machine
  via l'API officielle.
- Contenu tout public uniquement (`purity=100`), au moins 1920×1080, chaque
  image vérifiée à la main.
- Disponible sur wallhaven (vérifié via son API) : 268 wallpapers de forêt
  (16:9, les plus populaires de l'année) et 125 wallpapers My Little Pony.
- Catégories : `forest` (la majorité), `pony`, puis les catégories prévues au
  départ (abstrait, minimal, sombre) si tu les veux.
- Les forêts s'accordent naturellement avec les palettes vertes (Kanagawa,
  Everforest) quand la palette est extraite du wallpaper.

## 5. Panneau de contrôle et widgets

- Onglets Wi-Fi, Bluetooth, Réseau et Audio faits sur mesure avec
  `Quickshell.Networking` et `Quickshell.Bluetooth` (sans nmcli ni applet) :
  réseaux avec signal et sécurité, saisie du mot de passe, raison d'un échec,
  appareils Bluetooth avec icône de type et batterie, appairer, connecter,
  oublier, renommer.
- Chaque onglet prend la couleur de son module dans `[modules]`.
- Tuiles rapides :
  - **Ne pas déranger** ;
  - **Anti-veille** : empêche la mise en veille (inhibiteur de veille de
    Quickshell) ;
  - **Mode jeu** : coupe flou, animations et espaces entre fenêtres en un
    clic, puis remet tes réglages (le changement des options Hyprland à chaud
    avec la config Lua reste à vérifier).
- Widgets (horloge, batterie, now playing, CPU/RAM, calendrier), chacun
  optionnel.

## 6. Fenêtre de Settings

Onglets : **Profils**, **Écrans**, **Thèmes**, **Wallpaper**, Barre, Dock,
Widgets (avec les couleurs des modules), Système, Raccourcis, Identité.

- **Profils de look** : enregistrer tout un look (thème, accent, wallpaper ou
  catégorie de wallpapers, style, couleurs des modules, dock) sous un nom et
  passer de l'un à l'autre en un clic. Exemples fournis : *Forêt* (Kanagawa,
  wallpapers de forêt), *Pony* (palette du wallpaper, wallpapers Pony),
  *Tokyo Night*. Rangés dans `~/.config/tfem/profiles/`.
- **Assistant de premier lancement** : nom affiché, style, thème, catégories
  de wallpapers, dock ou non. Tout reste modifiable ensuite.
- Thèmes : parcourir tous les thèmes par famille, recherche, filtre
  clair/sombre, accent, modifier une couleur et enregistrer le résultat comme
  thème perso dans `~/.config/tfem/themes/`.
- Chaque changement est validé, appliqué à chaud, avec « revenir aux valeurs
  par défaut ».

## 7. Écran de verrouillage, écrans de connexion, authentification

- Thème `hyprlock` tiré de `theme.toml`.
- **Agent Polkit intégré** : les demandes de mot de passe administrateur sont
  dessinées par le shell, dans le thème courant (Quickshell 0.3 sait créer un
  agent Polkit).
- Deux thèmes SDDM dans `extras/sddm/`, installés séparément, couleurs tirées
  de la palette :
  - *Horloge empilée* : wallpaper plein écran, date en haut à gauche, grandes
    heures au-dessus des minutes dans la couleur d'accent, « appuie sur une
    touche » puis le formulaire de connexion. Référence :
    [pixie-sddm](https://github.com/xCaptaiN09/pixie-sddm) (MIT).
  - *Panneau d'accueil* : panneau flouté sur le côté du wallpaper avec un
    message d'accueil, l'heure, la date, les champs utilisateur et mot de
    passe, « afficher le mot de passe », la session, et des boutons ronds
    veille / redémarrer / éteindre. L'image est à ton choix : aucune
    illustration sous copyright n'est fournie.

## 8. Écrans et raccourcis

`max-hz.sh` (meilleur mode par écran, branchement à chaud), onglet Écrans,
aide-mémoire des raccourcis (`super + /`). Le changement d'écran à chaud avec
la config Lua reste à vérifier.

## 9. Installeur et CI

Un seul `install.sh` pour Arch, Debian et Fedora, `--profile`, `--dry-run`,
`--uninstall`, sauvegarde obligatoire, alias `dots` et `wm`, CI avec
shellcheck, tests et une simulation dans un conteneur Arch.

## 10. Documentation

Captures par thème, section « Fais-le tien » complète, crédits.
