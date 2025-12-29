# home-manager/modules/mise.nix
#
# Mise (formerly rtx) configuration
#
# Purpose:
# - Manages mise configuration declaratively via Nix
# - Ensures settings are in place before tools are installed
#
# Features:
# - Default Python packages configuration
# - UV venv auto-creation for Python projects
# - Experimental features enabled
#
# Integration:
# - Works with python.nix for default packages file
# - Activated in zsh.nix via `eval "$(mise activate zsh)"`
#
# Note:
# - mise is installed via Homebrew (darwin/homebrew.nix)
# - This module only manages configuration, not installation

{ config, lib, ... }:

let
  # TOML format for mise config
  miseConfig = ''
    [tools]
    "aqua:go-task/task" = "latest"
    python = "3.12"

    [settings]
    experimental = true
    python_default_packages_file = "~/.default-python-packages"

    [settings.python]
    uv_venv_auto = true
  '';
in
{
  # Create mise config directory and file
  home.file.".config/mise/config.toml" = {
    text = miseConfig;
  };
}
