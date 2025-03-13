# home-manager/modules/ghostty/default.nix
#
# Ghostty Theme Management
#
# Purpose:
# - Manages Ghostty themes
# - Links configuration file
#
# Integration:
# - Links config file
# - Uses Home Manager activation
#
# Note:
# - Package from Homebrew
# - Config in config file

{ config, lib, pkgs, ... }:

{
  # Set up additional Ghostty configuration
  # This runs after configuration files are written
  home.activation.ghosttySetup = lib.hm.dag.entryAfter ["writeBoundary"] ''
    # Create Ghostty config directory if it doesn't exist
    mkdir -p "$HOME/.config/ghostty"

    # Link our configuration file to Ghostty's expected location
    # Using symlink to maintain single source of truth
    ln -sf "${toString ./config.toml}" "$HOME/.config/ghostty/config"
  '';
}

