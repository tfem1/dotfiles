/* Generated from theme.toml: do not edit by hand,
   change a setting and run the generator again.
   Loaded by the @import line at the top of gtk.css: the adw-gtk3 theme
   reads these named colors (the default GTK 3 Adwaita does not).
   Shade and border colors keep their defaults (transparent black). */

@define-color accent_bg_color {{ accent }};
@define-color accent_fg_color {{ bg }};
@define-color accent_color {{ accent }};
@define-color destructive_bg_color {{ red }};
@define-color destructive_fg_color {{ bg }};
@define-color destructive_color {{ red }};
@define-color success_bg_color {{ green }};
@define-color success_fg_color {{ bg }};
@define-color success_color {{ green }};
@define-color warning_bg_color {{ yellow }};
@define-color warning_fg_color {{ bg }};
@define-color warning_color {{ yellow }};
@define-color error_bg_color {{ red }};
@define-color error_fg_color {{ bg }};
@define-color error_color {{ red }};
@define-color window_bg_color {{ bg }};
@define-color window_fg_color {{ fg }};
@define-color view_bg_color {{ bg_alt }};
@define-color view_fg_color {{ fg }};
@define-color headerbar_bg_color {{ surface }};
@define-color headerbar_fg_color {{ fg }};
@define-color headerbar_backdrop_color {{ bg }};
@define-color sidebar_bg_color {{ bg_alt }};
@define-color sidebar_fg_color {{ fg }};
@define-color sidebar_backdrop_color {{ bg_alt }};
@define-color secondary_sidebar_bg_color {{ bg }};
@define-color secondary_sidebar_fg_color {{ fg }};
@define-color secondary_sidebar_backdrop_color {{ bg }};
@define-color card_bg_color {{ surface }};
@define-color card_fg_color {{ fg }};
@define-color dialog_bg_color {{ surface }};
@define-color dialog_fg_color {{ fg }};
@define-color popover_bg_color {{ surface }};
@define-color popover_fg_color {{ fg }};
@define-color thumbnail_bg_color {{ surface }};
@define-color thumbnail_fg_color {{ fg }};

/* adw-gtk3 writes white text on accent buttons: with pastel accents the
   theme's own text color reads better. */
button.suggested-action { color: @accent_fg_color; }
