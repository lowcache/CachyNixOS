# System-wide configuration for ghost's CachyOS/Nix hybrid
# This will eventually replace the base system

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Bootloader (placeholder - will be configured later)
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/nvme1n1";
  boot.loader.grub.useOSProber = true;

  # Networking
  networking.hostName = "ghost-laptop";
  networking.networkmanager.enable = true;

  # Timezone and Locale
  time.timeZone = "America/New_York";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.supportedLocales = [ "en_US.UTF-8/UTF-8" ];

  # Language
  i18n.extraLocaleSettings = {
    LC_ALL = "en_US.UTF-8";
  };

  # User
  users.users.ghost = {
    isNormalUser = true;
    description = "ghost";
    extraGroups = [
      "wheel"
      "docker"
      "bluetooth"
      "lp"
      "networkmanager"
      "video"
      "audio"
    ];
  };

  # Packages
  environment.systemPackages = with pkgs; [
    # CLI Utilities (easy to migrate)
    git
    fastfetch
    bat
    btop
    htop
    duf
    ncdu
    tree
    dupeguru
    less
    unzip
    unrar
    p7zip
    ripgrep
    fd
    fzf
    zoxide
    yazi
    eza
    bottom

    # Development
    curl
    wget
    openssh
    gnumake
    gcc
    gnumake
    cmake
    ninja
    python3
    python3Packages.pip
    go
    rustup
    cargo
    nodejs_22
    ruby
    perl

    # System tools
    hwinfo
    dmidecode
    lshw
    smartmontools
    nvme-cli
    lm_sensors
    udisks2
    polkit
    libsecret
    keychain
    pass
    android-tools

    # Hyprland ecosystem
    hyprland
    waybar
    dunst
    mako
    swaynotificationcenter
    wl-clipboard
    wdisplays
    wlogout
    grim
    slurp
    swappy
    cliphist
    rofi
    wofi
    fuzzel

    # Fonts (moved to fonts.packages)
    fira-code
    jetbrains-mono

    # Media
    ffmpeg
    mpv
    mediainfo
    imagemagick
    libheif
    webp-pixbuf-loader

    # Optional but common
    flatpak
    docker
    distrobox
    podman
    containerd
  ];

    # Services
    services = {
      # Printing
      printing.enable = true;
  
          # Pipewire (audio)
          pipewire = {
            enable = true;
            audio.enable = true;
            alsa.enable = true;
            alsa.support32Bit = true;
            pulse.enable = true;
          };  
      # Samba (optional - for file sharing)
      samba.enable = false;
  
      # Tailscale VPN
      tailscale.enable = false;
  
      # Ollama
      ollama.enable = false;
  
      # Tor
      tor.enable = false;
  
      # i2pd (I2P router)
      i2pd.enable = false;
  
      # Automatic TRIM
      fstrim.enable = true;
    };
  
    # Virtualisation
    virtualisation = {
      docker = {
        enable = true;
      };
    };
  
    users.groups.docker = {};
  
    # Hardware - NVIDIA Optimus (hybrid graphics) - handled in hardware-configuration.nix
    # Keep only if specific settings needed here
  
    # Wayland/Hyprland specific
    programs = {
      hyprland = {
        enable = true;
        package = pkgs.hyprland;
      };

    firefox = {
      enable = true;
    };

    # adb is now handled by systemd 258+ and pkgs.android-tools
    # adding android-tools to environment.systemPackages if not present

    git = {
      enable = true;
      config = {
        user.name = "ghost";
        user.email = "ghost@localhost";
        core.editor = "micro";
        delta = {
          enable = true;
        };
      };
    };

    fish = {
      enable = true;
    };

    starship = {
      enable = true;
    };

    zsh = {
      enable = false; # Using fish
    };
  };

  # Environment variables
  environment.sessionVariables = {
    EDITOR = "micro";
    BROWSER = "brave";
    NIXOS_OZONE_WL = "1";
    MOZ_ENABLE_WAYLAND = "1";
    WAYLAND_DISPLAY = "wayland-1";
    XDG_CURRENT_DESKTOP = "Hyprland";
    XDG_SESSION_TYPE = "wayland";
    XDG_SESSION_DESKTOP = "Hyprland";
  };

  # Nix
  nix.settings = {
    experimental-features = [ "nix-commands" "flakes" "repl-flake" ];
    auto-optimise-store = true;
    tracediff = true;
  };

  nixpkgs.config.allowUnfree = true;

  # Fonts
  fonts.packages = with pkgs; [
    fira-code
    fira-code-symbols
    jetbrains-mono
    (nerdfonts.override { fonts = [ "FiraCode" "JetBrainsMono" "NerdFontsSymbolsOnly" ]; })
  ];

  # This value determines the NixOS release with which your system is affiliated.
  system.stateVersion = "24.05";
}
