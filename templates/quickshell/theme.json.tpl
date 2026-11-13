{
  "palette": {
    "name": {{ palette.name | json }},
    "variant": {{ palette.variant | json }}
  },
  "colors": {
    "bg": {{ bg | json }},
    "bgAlt": {{ bg_alt | json }},
    "surface": {{ surface | json }},
    "muted": {{ muted | json }},
    "subtle": {{ subtle | json }},
    "fg": {{ fg | json }},
    "fgBright": {{ fg_bright | json }},
    "accent": {{ accent | json }},
    "accent2": {{ accent2 | json }},
    "accent3": {{ accent3 | json }},
    "red": {{ red | json }},
    "orange": {{ orange | json }},
    "yellow": {{ yellow | json }},
    "green": {{ green | json }},
    "cyan": {{ cyan | json }},
    "blue": {{ blue | json }},
    "purple": {{ purple | json }},
    "brown": {{ brown | json }}
  },
  "modules": {
    "workspaces": {{ modules.workspaces | json }},
    "clock": {{ modules.clock | json }},
    "media": {{ modules.media | json }},
    "resources": {{ modules.resources | json }},
    "battery": {{ modules.battery | json }},
    "wifi": {{ modules.wifi | json }},
    "network": {{ modules.network | json }},
    "bluetooth": {{ modules.bluetooth | json }},
    "audio": {{ modules.audio | json }},
    "brightness": {{ modules.brightness | json }},
    "notifications": {{ modules.notifications | json }}
  },
  "font": {
    "sans": {{ font.sans | json }},
    "mono": {{ font.mono | json }},
    "size": {{ font.size }}
  },
  "shape": {
    "radius": {{ shape.radius }},
    "border": {{ shape.border }}
  },
  "effects": {
    "opacity": {{ effects.opacity }},
    "blur": {{ effects.blur }},
    "animations": {{ effects.animations }},
    "gameMode": {{ effects.game_mode }},
    "powerSaver": {{ effects.power_saver }}
  },
  "bar": {
    "position": {{ bar.position | json }},
    "transparent": {{ bar.transparent }},
    "layout": {{ bar.layout | json }},
    "workspaces": {{ bar.workspaces | json }}
  },
  "dock": {
    "enabled": {{ dock.enabled }},
    "position": {{ dock.position | json }},
    "opacity": {{ dock.opacity }},
    "autohide": {{ dock.autohide }},
    "pinned": {{ dock.pinned | json }}
  },
  "widgets": {
    "corner": {{ widgets.corner | json }},
    "clock": {{ widgets.clock }},
    "audio": {{ widgets.audio }},
    "media": {{ widgets.media }},
    "calendar": {{ widgets.calendar }},
    "places": {{ widgets.places | json }},
    "cpu": {{ widgets.cpu }},
    "gpu": {{ widgets.gpu }},
    "ram": {{ widgets.ram }},
    "disk": {{ widgets.disk }}
  },
  "wallpaper": {{ wallpaper.path | json }}
}
