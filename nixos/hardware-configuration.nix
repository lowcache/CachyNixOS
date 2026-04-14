# Do not modify this file!  It was generated automatically and
# will be overwritten on the next nixos-rebuild switch.
#
# You should edit this file in /etc/nixos/ and run 'nixos-rebuild switch'
# to update this configuration.
#
# Hardware configuration auto-generated for your system
# Based on live inspection of ghost's CachyOS system

{ config, pkgs, ... }:

{
  imports = [ ];

  boot.initrd.availableKernelModules = [ "ahci" "xhci_pci" "usbhid" "usb_storage" "sd_mod" "sr_mod" ];
  boot.initrd.kernelModules = [ "nvidia" "nvidia_modeset" "nvidia_uvm" "nvidia_drm" ];
  boot.kernelModules = [ "kvm-amd" "iwlwifi" ];

  # LUKS encrypted root
  boot.initrd.luks.devices.luks_root = {
    device = "/dev/disk/by-uuid/628379d5-378d-41e7-82f5-b0a3c4d1468b";
    preLVM = true;
  };

  # Swap on zram
  zramSwap.enable = true;

  # Filesystems
  fileSystems."/" = {
    device = "/dev/mapper/luks-628379d5-378d-41e7-82f5-b0a3c4d1468b"; # Note: device name usually follows luks name
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/A615-8E51";
    fsType = "vfat";
  };

  fileSystems."/home/ghost/data" = {
    device = "/dev/disk/by-uuid/07d457b4-dd7d-4719-9409-67209c52d70e";
    fsType = "ext4";
  };

  fileSystems."/nix" = {
    device = "/dev/disk/by-uuid/5c298be4-a280-4302-bc1a-c84371be7718";
    fsType = "ext4";
  };

  # NVIDIA hybrid graphics (PRIME offload)
  hardware.nvidia.prime = {
    offload.enable = true;
    nvidiaBusId = "PCI:1:0:0";
    amdgpuBusId = "PCI:66:0:0"; # Corrected for AMD
  };

  # AMD integrated graphics (enabled by default on AMD hardware)

  # CPU power management (handled automatically)

  # Audio
  hardware.pulseaudio.enable = false;
  services.pipewire.enable = true;

  # Enable Graphics
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # Enable VAAPI for NVIDIA and AMD
  hardware.graphics.extraPackages = with pkgs; [
    libva-vdpau-driver
    libvdpau-va-gl
    libva
    libva-utils
    nvidia-vaapi-driver
  ];

  # Network interfaces
  networking.interfaces.enp6s0.useDHCP = true;
  networking.interfaces.wlp7s0.useDHCP = true;

  # Bluetooth
  hardware.bluetooth.enable = true;

  # SSD TRIM
  services.fstrim.enable = true;

  # Power management
  powerManagement.cpuFreqGovernor = "powersave";

  # Keyboard - required for XKB settings
  services.xserver.xkb = {
    layout = "us";
    variant = "";
    options = "ctrl:swapcaps";
  };

  # Kernel parameters
  boot.kernelParams = [
    "zswap.enabled=0"
    "nvidia-drm.modeset=1"
  ];
}
