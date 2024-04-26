{ config, lib, pkgs, ... }:
{
  programs = {
    dconf.profiles.user.databases = [{
      settings = with lib.gvariant; {
        "org/gnome/desktop/datetime" = {
          automatic-timezone = true;
        };

        "org/gnome/desktop/wm/keybindings" = {
          switch-to-workspace-1 = [ "<Alt>1" ];
          switch-to-workspace-2 = [ "<Alt>2" ];
          switch-to-workspace-3 = [ "<Alt>3" ];
          switch-to-workspace-4 = [ "<Alt>4" ];
          switch-to-workspace-5 = [ "<Alt>5" ];
          move-to-workspace-1 = [ "<Shift><Alt>1" ];
          move-to-workspace-2 = [ "<Shift><Alt>2" ];
          move-to-workspace-3 = [ "<Shift><Alt>3" ];
          move-to-workspace-4 = [ "<Shift><Alt>4" ];
          move-to-workspace-5 = [ "<Shift><Alt>5" ];
        };

        "org/gnome/settings-daemon/plugins/media-keys" = {
          screensaver = [ "<Super>Escape" ];
        };

        "org/gnome/shell" = {
          enabled-extensions = [
            "pop-shell@system76.com"
            "dash-to-panel@jderose9.github.com"
          ];
        };
      };
    }];
  };

   # Allow login/authentication with fingerprint or password
  # - https://github.com/NixOS/nixpkgs/issues/171136
  # - https://discourse.nixos.org/t/fingerprint-auth-gnome-gdm-wont-allow-typing-password/35295
  security.pam.services.login.fprintAuth = false;
  security.pam.services.gdm-fingerprint = lib.mkIf (config.services.fprintd.enable) {
    text = ''
      auth       required                    pam_shells.so
      auth       requisite                   pam_nologin.so
      auth       requisite                   pam_faillock.so      preauth
      auth       required                    ${pkgs.fprintd}/lib/security/pam_fprintd.so
      auth       optional                    pam_permit.so
      auth       required                    pam_env.so
      auth       [success=ok default=1]      ${pkgs.gnome.gdm}/lib/security/pam_gdm.so
      auth       optional                    ${pkgs.gnome.gnome-keyring}/lib/security/pam_gnome_keyring.so

      account    include                     login

      password   required                    pam_deny.so

      session    include                     login
      session    optional                    ${pkgs.gnome.gnome-keyring}/lib/security/pam_gnome_keyring.so auto_start
    '';
  };
  security.pam.services.gdm.enableGnomeKeyring = true;

  xdg.portal = {
    config = {
      gnome = {
        default = [
          "gnome"
          "gtk"
        ];
        "org.freedesktop.impl.portal.Secret" = [
          "gnome-keyring"
        ];
      };
    };
  };
}
