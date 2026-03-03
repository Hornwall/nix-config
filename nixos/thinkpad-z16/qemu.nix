{
  programs.virt-manager.enable = true;
  users.groups.libvirtd.members = ["hannes"];
  virtualisation.libvirtd.enable = true;
  virtualisation.spiceUSBRedirection.enable = true;
}
