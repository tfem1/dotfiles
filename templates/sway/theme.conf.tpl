# Generated from theme.toml ({{ palette.name }}): do not edit by hand,
# change a setting and run the generator again. Included by ~/.config/sway/config.

font pango:{{ font.sans }} {{ font.size }}
default_border pixel {{ shape.border }}
default_floating_border pixel {{ shape.border }}
titlebar_border_thickness {{ shape.border }}
gaps inner {{ shape.gaps_in }}
gaps outer {{ shape.gaps_out }}

# class                 border             background     text              indicator          child_border
client.focused          {{ accent | hex }} {{ bg | hex }} {{ fg | hex }}    {{ accent2 | hex }} {{ accent | hex }}
client.focused_inactive {{ surface | hex }} {{ bg | hex }} {{ muted | hex }} {{ surface | hex }} {{ surface | hex }}
client.unfocused        {{ surface | hex }} {{ bg | hex }} {{ muted | hex }} {{ surface | hex }} {{ surface | hex }}
client.urgent           {{ red | hex }}    {{ bg | hex }} {{ fg | hex }}    {{ red | hex }}    {{ red | hex }}

seat * xcursor_theme {{ cursor.theme }} {{ cursor.size }}
