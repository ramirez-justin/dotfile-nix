# home-manager/modules/claude/default.nix
#
# Claude Code Configuration Management
#
# Purpose:
# - Manages Claude Code statusline script
# - Links statusline script to ~/.claude/
# - Configures Claude Code settings.json with 1Password secret references
#
# Integration:
# - Links statusline.sh
# - Uses Home Manager file management
# - Claude Code resolves op:// URIs at runtime via 1Password CLI
#
# 1Password Configuration:
# - Secrets are referenced using op:// URIs (not fetched at build time)
# - Claude Code resolves these at runtime when 1Password CLI is authenticated
# - To customize, modify the op:// paths below to match your vault/item names
#
# Note:
# - Requires 1Password CLI to be installed and authenticated
# - Secrets are only available when signed into 1Password

{ config, lib, pkgs, ... }:

{
  # Write settings.json with 1Password secret references
  # Claude Code resolves op:// URIs at runtime
  home.file.".claude/settings.json" = {
    force = true;  # Overwrite existing file
    text = builtins.toJSON {
      env = {
        # Trello integration
        TRELLO_API_KEY = "op://Telophase QS/Trello API key/API key";
        TRELLO_TOKEN = "op://Telophase QS/Trello API key/Trello Token";
        TRELLO_BOARD_ID = "DyXW6UrW";

        # Alpaca trading API (paper trading)
        ALPACA_API_KEY = "op://Private/Alpaca Paper Trading/Key";
        ALPACA_API_SECRET = "op://Private/Alpaca Paper Trading/Secret";
        ALPACA_PAPER = "true";

        # Enable LSP tool
        ENABLE_LSP_TOOL = "1";
      };
      statusLine = {
        type = "command";
        command = "./statusline.sh";
      };
    };
  };

  # Link statusline script to Claude's expected location
  home.file.".claude/statusline.sh" = {
    source = ./statusline.sh;
    force = true;  # Overwrite existing file
  };
}
