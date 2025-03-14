# home-manager/modules/starship.nix
#
# Starship Prompt Theme
#
# Purpose:
# - Sets up shell prompt
# - Configures Rose Pine theme
#
# Integration:
# - Works with ZSH
# - Uses Nerd Font icons
#
# Note:
# - Requires Nerd Font
# - Uses Rose Pine colors

{ config, pkgs, ... }: {
  programs.starship = {
    enable = true;
    settings = {
      "$schema" = "https://starship.rs/config-schema.json";

      format = ''
        [](color_dwn_rose)$os$username[](bg:color_dwn_pine fg:color_dwn_rose)$directory[](fg:color_dwn_pine bg:color_dwn_gold)$git_branch$git_status[](fg:color_dwn_gold bg:color_dwn_iris)$c$rust$golang$nodejs$php$java$kotlin$haskell$python[](fg:color_dwn_iris bg:color_dwn_foam)$docker_context$conda[](fg:color_dwn_foam bg:color_dwn_rosee)[ ](fg:color_surface)$line_break$character'';

      palette = "rose_pine";

      palettes = {
        rose_pine = {
          color_text = "#e0def4";      # Text
          color_surface = "#191724";   # Surface
          color_overlay = "#26233a";   # Overlay
          color_rose = "#ebbcba";      # Rose
          color_dwn_rose = "#d7827e";  # Dawn Rose
          color_foam = "#9ccfd8";      # Foam
          color_dwn_foam = "#56949f";   # Dawn Foam
          color_pine = "#31748f";      # Pine
          color_dwn_pine = "#286983";  # Dawn Pine
          color_gold = "#f6c177";      # Gold
          color_dwn_gold = "#ea9d34";  # Dawn Gold
          color_iris = "#c4a7e7";      # Iris
          color_dwn_iris = "#907aa9";  # Dawn Iris
          color_love = "#eb6f92";      # Love
        };
      };

      os = {
        disabled = false;
        style = "bg:color_dwn_rose fg:color_text";
        symbols = {
          Windows = "󰍲";
          Ubuntu = "󰕈";
          SUSE = "";
          Raspbian = "󰐿";
          Mint = "󰣭";
          Macos = "󰀵";
          Manjaro = "";
          Linux = "󰌽";
          Gentoo = "󰣨";
          Fedora = "󰣛";
          Alpine = "";
          Amazon = "";
          Android = "";
          Arch = "󰣇";
          Artix = "󰣇";
          EndeavourOS = "";
          CentOS = "";
          Debian = "󰣚";
          Redhat = "󱄛";
          RedHatEnterprise = "󱄛";
          Pop = "";
        };
      };

      username = {
        show_always = true;
        style_user = "bg:color_dwn_rose fg:color_text";  # Rose Pine Gold
        style_root = "bg:color_dwn_rose fg:color_text";  # Rose Pine Gold
        format = "[ $user ]($style)";
      };

      directory = {
        style = "fg:color_text bg:color_dwn_pine";
        format = "[ $path ]($style)";
        truncation_length = 3;
        truncation_symbol = "…/";
        substitutions = {
          "Documents" = "󰈙 ";
          "Downloads" = " ";
          "Music" = "󰝚 ";
          "Pictures" = " ";
          "Developer" = "󰲋 ";
        };
      };

      git_branch = {
        symbol = "";
        style = "bg:color_dwn_gold";
        format = "[[ $symbol $branch ](fg:color_text bg:color_dwn_gold)]($style)";
      };

      git_status = {
        style = "bg:color_dwn_gold";
        format = "[[($all_status$ahead_behind )](fg:color_text bg:color_dwn_gold)]($style)";
      };

      nodejs = {
        symbol = "";
        style = "bg:color_dwn_iris";
        format = "[[ $symbol( $version) ](fg:color_text bg:color_dwn_iris)]($style)";
      };

      c = {
        symbol = "";
        style = "bg:color_dwn_iris"; # Rose Pine Pine
        format = "[[ $symbol( $version) ](fg:color_text bg:color_dwn_iris)]($style)";
      };

      rust = {
        symbol = "";
        style = "bg:color_dwn_iris";  # Rose Pine Pine
        format = "[[ $symbol( $version) ](fg:color_text bg:color_dwn_iris)]($style)";
      };

      golang = {
        symbol = "";
        style = "bg:color_dwn_iris";  # Rose Pine Pine
        format = "[[ $symbol( $version) ](fg:color_text bg:color_dwn_iris)]($style)";
      };

      php = {
        symbol = "";
        style = "bg:color_dwn_iris";  # Rose Pine Pine
        format = "[[ $symbol( $version) ](fg:color_text bg:color_dwn_iris)]($style)";
      };

      java = {
        symbol = "";
        style = "bg:color_dwn_iris";  # Rose Pine Pine
        format = "[[ $symbol( $version) ](fg:color_text bg:color_dwn_iris)]($style)";
      };

      kotlin = {
        symbol = "";
        style = "bg:color_dwn_iris";  # Rose Pine Pine
        format = "[[ $symbol( $version) ](fg:color_text bg:color_dwn_iris)]($style)";
      };

      haskell = {
        symbol = "";
        style = "bg:color_dwn_iris"; # Rose Pine Pine
        format = "[[ $symbol( $version) ](fg:color_text bg:color_dwn_iris)]($style)";
      };

      python = {
        symbol = "";
        style = "bg:color_dwn_iris";  # Rose Pine Pine
        format = "[[ $symbol( $version) ](fg:color_text bg:color_dwn_iris)]($style)";
      };

      docker_context = {
        symbol = "";
        style = "bg:color_dwn_iris";  # Rose Pine Overlay
        format = "[[ $symbol( $context) ](fg:#83a598 bg:color_dwn_iris)]($style)";
      };

      conda = {
        style = "bg:color_dwn_iris";  # Rose Pine Overlay
        format = "[[ $symbol( $environment) ](fg:color_text bg:color_dwn_iris)]($style)";
      };

      time = {
        disabled = false;
        time_format = "%R";
        style = "bg:color_dwn_gold";  # Rose Pine Surface
        format = "[[  $time ](fg:color_text bg:color_dwn_gold)]($style)";
      };

      line_break = {
        disabled = false;
      };

      character = {
        disabled = false;
        success_symbol = "[](bold fg:color_pine)";  # Rose Pine Rose
        error_symbol = "[](bold fg:color_love)";  # Rose Pine Love
        vimcmd_symbol = "[](bold fg:color_pine)";  # Rose Pine Rose
        vimcmd_replace_one_symbol = "[](bold fg:color_iris)";  # Rose Pine Iris
        vimcmd_replace_symbol = "[](bold fg:color_iris)";  # Rose Pine Iris
        vimcmd_visual_symbol = "[](bold fg:color_gold)";  # Rose Pine Gold
      };
    };
  };
}
