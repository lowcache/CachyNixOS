{ config, pkgs, ... }: {
  home.username = "ghost";
  home.homeDirectory = "/home/ghost";
  home.stateVersion = "24.05"; # Use 24.05 for current stable, 26.05 was likely a typo or future-proofing

  targets.genericLinux.enable = (if pkgs.stdenv.isLinux && !(pkgs?isNixOS || false) then true else false); # Auto-detect

  xdg.configFile = {
      "hypr".source = config.lib.file.mkOutOfStoreSymlink "/home/ghost/.nix-config/hypr";
      "quickshell".source = config.lib.file.mkOutOfStoreSymlink "/home/ghost/.nix-config/quickshell";
      "illogical-impulse".source = config.lib.file.mkOutOfStoreSymlink "/home/ghost/.nix-config/illogical-impulse";
  };

  programs.fish = {
    enable = true;
    
    # Global Variables (The 'set' logic)
    shellInit = ''
      set -gx EDITOR micro
      set -gx BROWSER brave
      set -gx PATH $PATH $HOME/.local/bin $HOME/.cargo/bin $HOME/go/bin $HOME/.bin /usr/local/bin /var/lib/flatpak/exports/bin
    '';
  
    # Interactive Logic (The 'if/then' logic)
    interactiveShellInit = ''
      # Starship prompt
      if status is-interactive
          starship init fish | source
          
		# Custom terminal colors from quickshell
          if test -f ~/.local/state/quickshell/user/generated/terminal/sequences.txt
              cat ~/.local/state/quickshell/user/generated/terminal/sequences.txt
          end
      
          # No greeting
          set -g fish_greeting
      
          # --- Aliases ---
          alias clear "printf '\033[2J\033[3J\033[1;1H'"
          alias celar "clear"
          alias claer "clear"
          alias pamcan "pacman"
          alias q "qs -c ii"
          
          # Migrated from ZSH
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
      
          # Navigation
          alias ..='cd ..'
          alias ...='cd ../..'
          alias ....='cd ../../..'
      
          # LS / Eza
          if command -v eza > /dev/null
              set -g lo -axG@ --icons --group-directories-first --color=always --octal-permissions 
              alias ls="eza $lo"
              alias ll='ls -1l'
              alias lr='ls -R'
              alias lt='ls -T'
              alias la='ls --absolute'
          end
      
          # Fastfetch on startup
          if command -v fastfetch > /dev/null
              fastfetch
          end
      
          # Auto LS function (interactive only)
          function auto_ls --on-variable PWD
              if status is-interactive
                  ls
              end
          end
      end
      
      # Better CD - defined as a function named 'cd' to override builtin
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
      
      # Direnv integration
      direnv hook fish | source
    '';
    # extra aliases not added above
		
    shellAliases = {
		   clear = "printf '\033[2J\033[3J\033[1;1H'";
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
			fooocus = ''
				function fooocus --description "Manage Fooocus Docker container"
				     set -l action $argv[1]
				     
				     switch "$action"
				         case "on" "start"
				             echo "Starting Fooocus AI server..."
				             docker start fooocus
				             echo "Fooocus is starting. It will be available at http://localhost:7865"
				         case "off" "stop"
				             echo "Stopping Fooocus AI server to free up RAM..."
				             docker stop fooocus
				             echo "Fooocus stopped. 5GB RAM reclaimed!"
				         case "status"
				             docker ps -a --filter "name=fooocus"
				         case "*"
				             echo "Usage: fooocus [on|off|status]"
				             echo "  on/start : Starts the Fooocus container"
				             echo "  off/stop : Stops the Fooocus container"
				             echo "  status   : Shows the current status of the container"
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
				# Fish-compatible function to create a GPG key for GitHub with armored output
				 # Save this in ~/.config/fish/functions/gpgkey.fish
				 
				 function gpgkey
				     # Ensure GPG_TTY is set (important for Arch Linux with GUI)
				     set -x GPG_TTY (tty)
				 
				     # Prompt for user details
				     read -P "Enter your full name: " user_name
				     read -P "Enter your email address: " user_email
				     read -P "Enter a comment (optional, e.g., 'GitHub Signing'): " user_comment
				     read -S -P "Enter a passphrase for your GPG key: " key_passphrase
				     echo
				 
				     # Create a temporary file for GPG key generation parameters
				     set temp_batch_file (mktemp)
				 
				     # Write GPG batch config using echo commands (Fish-compatible)
				     echo "%echo Generating GPG key for GitHub" > $temp_batch_file
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
				 
				     # Generate the GPG key
				     echo "Generating GPG key..."
				     gpg --batch --gen-key $temp_batch_file
				 
				     if test $status -ne 0
				         echo "Error: GPG key generation failed."
				         rm -f $temp_batch_file
				         return 1
				     end
				 
				     # Get the key fingerprint (long format for GitHub)
				     set key_fingerprint (gpg --list-keys --with-colons $user_email | grep '^fpr' | tail -n 1 | cut -d':' -f10)
				     set key_id (echo $key_fingerprint | cut -c1-8)
				 
				     if test -z "$key_id"
				         echo "Error: Could not find key ID. Generation may have failed."
				         rm -f $temp_batch_file
				         return 1
				     end
				 
				     echo ""
				     echo "GPG key created successfully!"
				     echo "Key ID (short): $key_id"
				     echo "Key Fingerprint: $key_fingerprint"
				     echo ""
				 
				     # Export the key in armored format
				     set safe_email (echo $user_email | tr -d ' ')
				     set armored_output_file "./$safe_email.gpg.asc"
				     gpg --armor --export $user_email > $armored_output_file
				 
				     if test $status -ne 0
				         echo "Error: Failed to export GPG key."
				         rm -f $temp_batch_file
				         return 1
				     end
				 
				     echo "Armored public key exported to: $armored_output_file"
				     echo ""
				     echo "Next steps:"
				     echo "1. Copy the contents of $armored_output_file:"
				     echo "   cat $armored_output_file"
				     echo ""
				     echo "2. Go to GitHub Settings → SSH and GPG keys → New GPG key"
				     echo "3. Paste the contents and save"
				     echo ""
				     echo "4. Configure Git to use this key:"
				     echo "   git config --global user.signingkey $key_fingerprint"
				     echo "   git config --global commit.gpgsign true"
				     echo ""
				     echo "5. (Optional) Upload private key backup securely:"
				     echo "   gpg --armor --export-secret-keys $user_email > ./$safe_email.secret.gpg.asc"
				     echo ""
				 
				     # Display the armored key content
				     read -P "Do you want to display the armored public key now? (y/n) " display_key
				     if test "$display_key" = "y" -o "$display_key" = "Y"
				         echo ""
				         echo "===== ARMORED PUBLIC KEY START ====="
				         cat $armored_output_file
				         echo "===== ARMORED PUBLIC KEY END ====="
				         echo ""
				     end
				 
				     # Clean up temp file
				     rm -f $temp_batch_file
				 
				     echo "Done! Your GPG key is ready for GitHub on Arch Linux."
				 end
			'';
			rmspcs = ''
				function rmspcs --description 'Remove spaces from all filenames in a directory'
				     set -l target_dir .
				     if count $argv > /dev/null
				         set target_dir $argv[1]
				     end
				 
				     if not test -d $target_dir
				         echo "Error: '$target_dir' is not a directory."
				         return 1
				     end
				 
				     # Use find to find files with spaces and rename them
				     # -depth ensures we rename files before their parent directories
				     find $target_dir -depth -name '* *' | while read -l file
				         set -l dir (dirname "$file")
				         set -l old_name (basename "$file")
				         set -l new_name (string replace -a ' ' '_' "$old_name")
				         
				         echo "Renaming: $old_name -> $new_name"
				         mv "$file" "$dir/$new_name"
				     end
				 end
			'';
			rng = ''
				function rng --description "Generate random numbers indefinitely"
				     echo "Starting Random Number Generator... (Press Ctrl+C to stop)"
				     while true
				         echo (random)
				         sleep 0.1
				     end
				 end
			'';
	 	};			
	};
	
  home.packages = with pkgs; [
    		fish git fzf starship eza bat ripgrep micro
    		python3 flatpak gedit feh waypaper 
    		hypridle hyprlock fd brave tor
  ];

}
