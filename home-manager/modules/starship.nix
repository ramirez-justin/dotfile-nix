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
        [](color_orange)$os$username[](bg:color_yellow fg:color_orange)$directory[](fg:color_yellow bg:color_aqua)$git_branch$git_status[](fg:color_aqua bg:color_blue)$c$rust$golang$nodejs$php$java$kotlin$haskell$python[](fg:color_blue bg:color_bg3)$docker_context$conda[](fg:color_bg3 bg:color_bg1)[ ](fg:color_bg1)$line_break$character'';

      palette = "rose_pine";

      palettes = {
        rose_pine = {
          color_fg0 = "#e0def4";      # Text
          color_bg1 = "#1f1d2e";      # Surface
          color_bg3 = "#26233a";      # Overlay
          color_blue = "#31748f";     # Pine
          color_aqua = "#9ccfd8";     # Foam
          color_green = "#ebbcba";    # Rose
          color_orange = "#f6c177";   # Gold
          color_purple = "#c4a7e7";   # Iris
          color_red = "#eb6f92";      # Love
          color_yellow = "#f6c177";   # Gold
        };
      };

      os = {
        disabled = false;
        style = "bg:color_orange fg:color_fg0";
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
        style_user = "bg:color_orange fg:color_fg0";  # Rose Pine Gold
        style_root = "bg:color_orange fg:color_fg0";  # Rose Pine Gold
        format = "[ $user ]($style)";
      };

      directory = {
        style = "fg:color_fg0 bg:color_yellow";  # Rose Pine Gold
        format = "[ $path ]($style)";
        truncation_length = 3;
        truncation_symbol = "…/";
        substitutions = {  # Rose Pine substitutions for text to icons
          "Documents" = "󰈙 ";
          "Downloads" = " ";
          "Music" = "󰝚 ";
          "Pictures" = " ";
          "Developer" = "󰲋 ";
        };
      };

      git_branch = {
        symbol = "";
        style = "bg:color_aqua";  # Rose Pine Foam
        format = "[[ $symbol $branch ](fg:color_fg0 bg:color_aqua)]($style)";
      };

      git_status = {
        style = "bg:color_aqua"; # Rose Pine Foam
        format = "[[($all_status$ahead_behind )](fg:color_fg0 bg:color_aqua)]($style)";
      };

      nodejs = {
        symbol = "";
        style = "bg:color_blue"; # Rose Pine Pine
        format = "[[ $symbol( $version) ](fg:color_fg0 bg:color_blue)]($style)";
      };

      c = {
        symbol = "";
        style = "bg:color_blue"; # Rose Pine Pine
        format = "[[ $symbol( $version) ](fg:color_fg0 bg:color_blue)]($style)";
      };

      rust = {
        symbol = "";
        style = "bg:color_blue";  # Rose Pine Pine
        format = "[[ $symbol( $version) ](fg:color_fg0 bg:color_blue)]($style)";
      };

      golang = {
        symbol = "";
        style = "bg:color_blue";  # Rose Pine Pine
        format = "[[ $symbol( $version) ](fg:color_fg0 bg:color_blue)]($style)";
      };

      php = {
        symbol = "";
        style = "bg:color_blue";  # Rose Pine Pine
        format = "[[ $symbol( $version) ](fg:color_fg0 bg:color_blue)]($style)";
      };

      java = {
        symbol = "";
        style = "bg:color_blue";  # Rose Pine Pine
        format = "[[ $symbol( $version) ](fg:color_fg0 bg:color_blue)]($style)";
      };

      kotlin = {
        symbol = "";
        style = "bg:color_blue";  # Rose Pine Pine
        format = "[[ $symbol( $version) ](fg:color_fg0 bg:color_blue)]($style)";
      };

      haskell = {
        symbol = "";
        style = "bg:color_blue"; # Rose Pine Pine
        format = "[[ $symbol( $version) ](fg:color_fg0 bg:color_blue)]($style)";
      };

      python = {
        symbol = "";
        style = "bg:color_blue";  # Rose Pine Pine
        format = "[[ $symbol( $version) ](fg:color_fg0 bg:color_blue)]($style)";
      };

      docker_context = {
        symbol = "";
        style = "bg:color_bg3";  # Rose Pine Overlay
        format = "[[ $symbol( $context) ](fg:#83a598 bg:color_bg3)]($style)";
      };

      conda = {
        style = "bg:color_bg3";  # Rose Pine Overlay
        format = "[[ $symbol( $environment) ](fg:color_aqua bg:color_bg3)]($style)";
      };

      time = {
        disabled = false;
        time_format = "%R";
        style = "bg:color_bg1";  # Rose Pine Surface
        format = "[[  $time ](fg:color_fg0 bg:color_bg1)]($style)";
      };

      line_break = {
        disabled = false;
      };

      character = {
        disabled = false;
        success_symbol = "[](bold fg:color_green)";  # Rose Pine Rose
        error_symbol = "[](bold fg:color_red)";  # Rose Pine Love
        vimcmd_symbol = "[](bold fg:color_green)";  # Rose Pine Rose
        vimcmd_replace_one_symbol = "[](bold fg:color_purple)";  # Rose Pine Iris
        vimcmd_replace_symbol = "[](bold fg:color_purple)";  # Rose Pine Iris
        vimcmd_visual_symbol = "[](bold fg:color_yellow)";  # Rose Pine Gold
      };
    };
  };
}
