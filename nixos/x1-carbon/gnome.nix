{
  programs = {
    call.enable = true;

    dconf.profile.user.databases = [{
      settings = with lib.gvariant; {
        "org/gnome/desktop/datetime" = {
          automatic-timezone = true;
        };

        "org/gnome/desktop/wm/keybindings" = {
          switch-to-workspace-1 = ['<Alt>1'];
          switch-to-workspace-2 = ['<Alt>2'];
          switch-to-workspace-3 = ['<Alt>2'];
          switch-to-workspace-4 = ['<Alt>4'];
          switch-to-workspace-5 = ['<Alt>5'];
        };
      };
    }];
  }
}
