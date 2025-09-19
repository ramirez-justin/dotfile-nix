# home-manager/modules/python.nix
#
# Python development environment configuration for mise integration
#
# Purpose:
# - Manages default Python packages for mise installations
# - Ensures consistent Python environment across system rebuilds
# - Provides packages needed for Neovim and development tools
#
# Features:
# - Creates ~/.default-python-packages file for mise
# - Includes essential development tools
# - Neovim Python integration packages
# - Code quality and formatting tools
#
# Integration:
# - Works with mise for Python version management
# - Packages are auto-installed when mise installs new Python versions
# - Declaratively managed via Nix configuration

{ config, pkgs, lib, ... }: {

  # Create ~/.default-python-packages file for mise
  # This file is automatically read by mise when installing new Python versions
  home.file.".default-python-packages".text = ''
    # Neovim integration
    pynvim

    # Language Server Protocol
    python-lsp-server
    pylsp-mypy
    python-lsp-ruff

    # Code quality and formatting
    ruff
    mypy
    isort
    black

    # Development utilities
    ipython
    pip-tools
    wheel
    setuptools

    # Testing
    pytest
    pytest-cov

    # Common data science packages (optional)
    requests
    click
  '';

  # Optional: Set environment variables for Python development
  home.sessionVariables = {
    # Ensure mise Python is in PATH
    MISE_PYTHON_DEFAULT_PACKAGES_FILE = "$HOME/.default-python-packages";
  };

}
