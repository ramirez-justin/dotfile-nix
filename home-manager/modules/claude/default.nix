# home-manager/modules/claude/default.nix
#
# Claude Code Configuration Management
#
# Purpose:
# - Manages Claude Code statusline script
# - Links statusline script to ~/.claude/
# - Configures Claude Code settings.json with 1Password secret references
# - Merges MCP servers into ~/.claude.json (Claude Code's global config)
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

let
  # MCP servers configuration (used in activation script)
  mcpServersJson = builtins.toJSON {
    gmail = {
      command = "npx";
      args = ["@gongrzhe/server-gmail-autoauth-mcp"];
    };
    google-calendar = {
      command = "npx";
      args = ["@cocal/google-calendar-mcp"];
      env = {
        GOOGLE_OAUTH_CREDENTIALS = "${config.home.homeDirectory}/.gmail-mcp/gcp-oauth.keys.json";
      };
    };
  };
in
{
  # Merge MCP servers into ~/.claude.json on activation
  # This preserves Claude Code's runtime state while adding our MCP config
  home.activation.claudeMcpServers = lib.hm.dag.entryAfter ["writeBoundary"] ''
    CLAUDE_JSON="${config.home.homeDirectory}/.claude.json"
    if [ -f "$CLAUDE_JSON" ]; then
      # Merge mcpServers into existing config
      ${pkgs.jq}/bin/jq --argjson mcp '${mcpServersJson}' '.mcpServers = $mcp' "$CLAUDE_JSON" > "$CLAUDE_JSON.tmp" && mv "$CLAUDE_JSON.tmp" "$CLAUDE_JSON"
    else
      # Create new file with just mcpServers
      echo '${builtins.toJSON { mcpServers = builtins.fromJSON mcpServersJson; }}' > "$CLAUDE_JSON"
    fi
  '';

  # Write settings.json with 1Password secret references
  # Claude Code resolves op:// URIs at runtime
  # Note: mcpServers moved to ~/.claude.json via activation script above
  home.file.".claude/settings.json" = {
    force = true;  # Overwrite existing file
    text = builtins.toJSON {
      # Disable automatic context compaction
      autoCompact = false;
      autoCompactEnabled = false;
      includeCoAuthoredBy = false;
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
        ENABLE_LSP_TOOL = 1;
      };
      hooks = {
        Stop = [
          {
            hooks = [
              {
                type = "command";
                command = "afplay /System/Library/Sounds/Submarine.aiff";
              }
            ];
          }
        ];
      };
      statusLine = {
        type = "command";
        command = "${config.home.homeDirectory}/.claude/statusline.sh";
      };
      enabledPlugins = {
        "workflow@productivity-plugins" = true;
        "alpaca@productivity-plugins" = true;
        "ruff-lsp@productivity-plugins" = true;
        "bash-ls@productivity-plugins" = true;
        "docker-ls@productivity-plugins" = true;
        "markdown-oxide@productivity-plugins" = true;
        "vim-ls@productivity-plugins" = true;
        "yaml-ls@productivity-plugins" = true;
        "pyright-lsp@claude-plugins-official" = true;
        "lua-lsp@claude-plugins-official" = true;
        "code-review@claude-plugins-official" = true;
        "superpowers@superpowers-marketplace" = true;
        "trello@productivity-plugins" = true;
      };
    };
  };

  # Link statusline script to Claude's expected location
  home.file.".claude/statusline.sh" = {
    source = ./statusline.sh;
    executable = true;  # Make script executable
    force = true;  # Overwrite existing file
  };
}
