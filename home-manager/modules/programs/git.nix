{ config, lib, pkgs, ... }:

{
  programs.git = {
    enable = true;

    settings ={
      core.excludesfile = "~/.gitignore";
      user = {
        name = "Hannes Hornwall";
        email = "hannes@hornwall.me";
      };

      alias = {
        st = "status -sb";
        lg = "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --date=relative";
        fixup = "!git log -n 50 --pretty=format:'%h %s' --no-merges | fzf | cut -c -7 | xargs -o git commit --fixup";
        squash = "!f() { git fetch origin main && git rebase -i --autosquash $(git merge-base main HEAD); }; f";
      };
    };
  };
}
