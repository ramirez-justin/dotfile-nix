# home-manager/modules/claude/default.nix
#
# Claude Code Configuration Management
#
# Purpose:
# - Manages Claude Code statusline script
# - Links statusline script to ~/.claude/
#
# Integration:
# - Links statusline.sh
# - Uses Home Manager activation
#
# Note:
# - Script sourced from dotfiles
# - Maintains single source of truth

{ config, lib, pkgs, ... }:

{
  # Set up Claude Code statusline script
  # This runs after configuration files are written
  home.activation.claudeStatusline = lib.hm.dag.entryAfter ["writeBoundary"] ''
    # Ensure ~/.claude directory exists
    mkdir -p "$HOME/.claude"

    # Link our statusline script to Claude's expected location
    # Using symlink to maintain single source of truth
    ln -sf "${toString ./statusline.sh}" "$HOME/.claude/statusline.sh"

  '';
}
