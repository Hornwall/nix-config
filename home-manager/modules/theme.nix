{ pkgs, ... }:

{
  # Dark Adwaita everywhere. Also writes the org.gnome.desktop.interface dconf
  # keys (color-scheme, gtk-theme, cursor-theme), which the GTK portal exposes
  # to apps under Hyprland, so no gsettings calls or GTK_THEME are needed.
  gtk = {
    enable = true;
    colorScheme = "dark";
    theme.name = "Adwaita-dark"; # built into GTK 3
    cursorTheme = {
      name = "Adwaita";
      package = pkgs.adwaita-icon-theme;
      size = 24;
    };
    # libadwaita (GTK 4) follows color-scheme; don't override its stylesheet.
    gtk4.theme = null;
  };
}
