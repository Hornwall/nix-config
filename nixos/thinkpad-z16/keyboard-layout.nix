{ lib, pkgs, ...}:
{
  console.useXkbConfig = true;

  services.xserver = {
    xkb = {
      layout = "us-custom";
      extraLayouts.us-custom = {
        description = "My custom US layout";
        languages = [ "eng" ];
        symbolsFile = pkgs.writeText "xkb-layout" ''
          xkb_symbols "us-custom"
          {
            include "us(basic)"
            include "level3(ralt_switch)" 

            key <AD11> { [ bracketleft, braceleft, aring, Aring	] };
	    key <AC10> { [ semicolon, colon, odiaeresis, Odiaeresis ] };
            key <AC11> { [ apostrophe, quotedbl, adiaeresis, Adiaeresis ] };
          };
        '';
      };
    };
  };
}
