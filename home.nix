{ config, pkgs, lib, ... }: {
  home.username = "ghost";
  home.homeDirectory = "/home/ghost";
  home.stateVersion = "24.05";

  targets.genericLinux.enable = (if pkgs.stdenv.isLinux && !(pkgs?isNixOS || false) then true else false);

  xdg.configFile = {
    # Main configs (symlinked)
    "hypr".source = config.lib.file.mkOutOfStoreSymlink "/home/ghost/.nix-config/hypr";
    "quickshell".source = config.lib.file.mkOutOfStoreSymlink "/home/ghost/.nix-config/quickshell";
    "illogical-impulse".source = config.lib.file.mkOutOfStoreSymlink "/home/ghost/.nix-config/illogical-impulse";
	"kitty".source = config.lib.file.mkOutOfStoreSymlink "/home/ghost/.nix-config/kitty";
	
    # Migrated configs
    "fastfetch" = { source = ./fastfetch; recursive = true; };
    "htop" = { source = ./htop; recursive = true; };
    "cava" = { source = ./cava; recursive = true; };
    "fuzzel" = { source = ./fuzzel; recursive = true; };
    "wlogout" = { source = ./wlogout; recursive = true; };
  };

  programs.fish = {
    enable = true;

    shellInit = ''
      set -gx EDITOR micro
      set -gx BROWSER brave
      set -gx PATH $PATH $HOME/.local/bin $HOME/.cargo/bin $HOME/go/bin $HOME/.bin /usr/local/bin /var/lib/flatpak/exports/bin
    '';

    interactiveShellInit = ''
      if status is-interactive
          if test -f ~/.local/state/quickshell/user/generated/terminal/sequences.txt
              cat ~/.local/state/quickshell/user/generated/terminal/sequences.txt
          end

          set -g fish_greeting

          alias clear "printf '\033[2J\033[3J\033[1;1H'"
          alias celar "clear"
          alias claer "clear"
          alias pamcan "pacman"
          alias q "qs -c ii"

          alias c='clear'
          alias nf='fastfetch'
          alias pf='fastfetch'
          alias ff='fastfetch'
          alias shutdown='systemctl poweroff'
          alias ts='snapshot.sh'
          alias wifi='nmtui'
          alias cleanup='arch-cleanup.sh'
          alias ascii='figlet.sh'
          alias update-grub='sudo grub-mkconfig -o /boot/grub/grub.cfg'

          alias ..='cd ..'
          alias ...='cd ../..'
          alias ....='cd ../../..'

          if command -v eza > /dev/null
              set -g lo -axG@ --icons --group-directories-first --color=always --octal-permissions
              alias ls="eza $lo"
              alias ll='ls -1l'
              alias lr='ls -R'
              alias lt='ls -T'
              alias la='ls --absolute'
          end

          if command -v fastfetch > /dev/null
              fastfetch
          end

          function auto_ls --on-variable PWD
              if status is-interactive
                  ls
              end
          end
      end

      function cd --description "Change directory with file handling"
          if test (count $argv) -eq 0
              builtin cd
              return
          end
          set -l t $argv[1]
          if test -f "$t"
              set t (dirname "$t")
          end
          builtin cd "$t"
      end

      direnv hook fish | source
    '';

    shellAliases = {
      clear = "printf '\\033[2J\\033[3J\\033[1;1H'";
      celar = "clear";
      claer = "clear";
      pamcan = "pacman";
      q = "qs -c ii";
      edit = "$EDITOR";
    };

    functions = {
      better_cd = ''
        function better_cd
          set -l t $argv[1]
          if test -z "$t"
            builtin cd
            return
          end
          if test -f "$t"
            set t (dirname "$t")
          end
          builtin cd "$t"
        end
      '';
      extract = ''
        function extract --description "Expand/extract archives"
          for file in $argv
            if test -f "$file"
              switch "$file"
                case "*.tar.bz2" "*.tbz2" "*.tbz"
                  tar xvjf "$file"
                case "*.tar.gz" "*.tgz"
                  tar xvzf "$file"
                case "*.tar.xz" "*.txz" "*.tar.lzma"
                  tar xvJf "$file"
                case "*.tar.zst"
                  tar --zstd -xvf "$file"
                case "*.tar"
                  tar xvf "$file"
                case "*.zip" "*.jar"
                  unzip "$file"
                case "*.deb"
                  ar -x "$file"
                case "*.bz2"
                  bunzip2 "$file"
                case "*.gz"
                  gunzip "$file"
                case "*.xz" "*.lzma"
                  unxz "$file"
                case "*.zst"
                  unzstd "$file"
                case "*"
                  echo "'$file' cannot be extracted via extract"
              end
            else
              echo "'$file' is not a valid file"
            end
          end
        end
      '';
      setwall = ''
        function setwall --description "Set wallpaper for a specific monitor or globally"
          set -l script ~/.config/quickshell/ii/scripts/colors/switchwall.sh

          if test (count $argv) -eq 0
            echo "Usage: setwall <image_path> [monitor_name]"
            echo "Example: setwall ~/Pictures/wall.png DP-1"
            return 1
          end

          set -l img $argv[1]
          set -l mon $argv[2]

          if test -n "$mon"
            echo "Setting wallpaper for $mon..."
            $script --monitor $mon --image $img
          else
            echo "Setting wallpaper globally..."
            $script --image $img
          end
        end
      '';
      gpgkey = ''
        function gpgkey
          set -x GPG_TTY (tty)
          read -P "Enter your full name: " user_name
          read -P "Enter your email address: " user_email
          read -P "Enter a comment (optional): " user_comment
          read -S -P "Enter a passphrase: " key_passphrase
          echo

          set temp_batch_file (mktemp)
          echo "%echo Generating GPG key" > $temp_batch_file
          echo "Key-Type: RSA" >> $temp_batch_file
          echo "Key-Length: 4096" >> $temp_batch_file
          echo "Key-Usage: sign,encrypt" >> $temp_batch_file
          echo "Name-Real: $user_name" >> $temp_batch_file
          echo "Name-Email: $user_email" >> $temp_batch_file
          if test -n "$user_comment"
            echo "Name-Comment: $user_comment" >> $temp_batch_file
          end
          echo "Expire-Date: 0" >> $temp_batch_file
          echo "Passphrase: $key_passphrase" >> $temp_batch_file
          echo "%commit" >> $temp_batch_file
          echo "%echo Done" >> $temp_batch_file

          echo "Generating GPG key..."
          gpg --batch --gen-key $temp_batch_file

          if test $status -ne 0
            echo "Error: GPG key generation failed."
            rm -f $temp_batch_file
            return 1
          end

          set key_fingerprint (gpg --list-keys --with-colons $user_email | grep '^fpr' | tail -n 1 | cut -d':' -f10)
          set safe_email (echo $user_email | tr -d ' ')
          gpg --armor --export $user_email > "./$safe_email.gpg.asc"

          echo "GPG key created! Key Fingerprint: $key_fingerprint"
          echo "Armored public key exported to: ./$safe_email.gpg.asc"
          rm -f $temp_batch_file
        end
      '';
      rmspcs = ''
        function rmspcs --description "Remove spaces from filenames"
          set -l target_dir .
          if count $argv > /dev/null
            set target_dir $argv[1]
          end
          if not test -d $target_dir
            echo "Error: '$target_dir' is not a directory."
            return 1
          end
          find $target_dir -depth -name "* *" | while read -l file
            set -l dir (dirname "$file")
            set -l old_name (basename "$file")
            set -l new_name (string replace -a " " "_" "$old_name")
            echo "Renaming: $old_name -> $new_name"
            mv "$file" "$dir/$new_name"
          end
        end
      '';
    };
  };

  programs.starship = {
    enable = true;
    settings = lib.importTOML ./starship/starship.toml;
  };

  programs.micro = {
    enable = true;
    settings = {
      autosu = true;
      colorscheme = "dracula-tc";
      fastdirty = true;
      filemanager = false;
      linter = false;
      multitab = "hsplit";
      parsecursor = true;
      saveundo = true;
      scrollbar = true;
      scrollbarchar = "[]";
    };
  };

  home.packages = with pkgs; [
    fish git fzf starship eza bat ripgrep
    python3 flatpak gedit feh waypaper
    hypridle hyprlock fd tor
    micro fuzzel wlogout
    fastfetch htop
  ];
}
