# Do not modify this file!  It was generated by ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes
# to /etc/nixos/configuration.nix instead.
{ config, lib, pkgs, modulesPath, ... }:

{
  imports =
    [ (modulesPath + "/installer/scan/not-detected.nix")
    ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "nvme" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ "dm-snapshot" ];
  boot.initrd.luks.devices = {
	root = {
		device = "/dev/disk/by-uuid/010ef325-0808-417c-8e61-87a7c967b37a";
		preLVM = true;
		allowDiscards = true;
	};
  };
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" =
    { device = "/dev/disk/by-uuid/298b0112-7be0-4b54-a502-06b0f1a319e5";
      fsType = "btrfs";
      options = [ "subvol=@root" ];
    };

  fileSystems."/var" =
    { device = "/dev/disk/by-uuid/298b0112-7be0-4b54-a502-06b0f1a319e5";
      fsType = "btrfs";
      options = [ "subvol=@var" ];
    };

  fileSystems."/home" =
    { device = "/dev/disk/by-uuid/298b0112-7be0-4b54-a502-06b0f1a319e5";
      fsType = "btrfs";
      options = [ "subvol=@home" ];
    };

  fileSystems."/.snapshots" =
    { device = "/dev/disk/by-uuid/298b0112-7be0-4b54-a502-06b0f1a319e5";
      fsType = "btrfs";
      options = [ "subvol=@snapshots" ];
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/EA10-C606";
      fsType = "vfat";
    };

  swapDevices =
    [ { device = "/dev/disk/by-uuid/54554ea0-38b2-448e-8122-a05fc964fb35"; }
    ];

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.enp0s31f6.useDHCP = lib.mkDefault true;
  # networking.interfaces.wlp0s20f3.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
