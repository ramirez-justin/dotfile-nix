# Nix Darwin System Configuration

A modular, reproducible system configuration for macOS using Nix, nix-darwin, and home-manager.

## What is Nix?

Nix is a powerful package manager and system configuration tool that takes a unique approach to package management and system configuration. It ensures that installing or upgrading one package cannot break other packages, enables multiple versions of a package to coexist, and makes it easy to roll back to previous versions.

### Key Features

- **Declarative Configuration**
  - Your entire system defined as code
  - Reproducible environments
  - Safe, atomic updates

### Why Use Nix?

- **For Developers**
  - Consistent development environments
  - Project-specific package versions
  - Easy sharing of development setups

- **For System Configuration**
  - Version control your entire system
  - Test changes safely
  - Roll back when needed

### Learn More

- 📘 [Nix Package Manager Guide](https://nixos.org/manual/nix/stable/)
- 🎓 [Nix Pills Tutorial](https://nixos.org/guides/nix-pills/)
- 💡 [Home Manager Manual](https://nix-community.github.io/home-manager/)
- 🔧 [Nix Darwin Documentation](https://github.com/LnL7/nix-darwin)

## Core Components

Each component serves a specific purpose in creating a reproducible system:

- **nix-darwin**: System-level macOS configuration
  - Manages macOS settings and preferences
  - Handles system-level packages
  - Controls system defaults and security

- **Home Manager**: User environment management
  - Manages user-specific configurations
  - Handles dotfiles and program settings
  - Ensures consistent user environment

- **Homebrew**: macOS package management
  - Manages GUI applications
  - Handles macOS-specific packages
  - Provides quick updates for certain tools

## Design Decisions

### Why Nix?

1. **Reproducibility**
    - Exact same setup across machines
    - Version-controlled configuration
    - Declarative system definition

2. **Modularity**
    - Separate system and user config
    - Easy to enable/disable features
    - Reusable configuration modules

3. **Reliability**
    - Atomic updates
    - Rollback capability
    - Consistent state management

### File Structure

The repository is organized into logical components:

- `darwin/` - System configuration
  - Separates macOS-specific settings
  - Manages system-wide packages
  - Controls security policies

- `home-manager/` - User environment
  - Modular program configurations
  - Personal preferences and tools
  - Shell and terminal setup

- `nix/` - Core Nix setup
  - Basic Nix configuration
  - Shell integration
  - Dynamic configurations

## Prerequisites

- macOS (Apple Silicon - M*)
- Administrative access
- Basic terminal knowledge

## Initial Setup

1. **Install Command Line Tools**

     ```bash
     xcode-select --install
     ```

2. **Clone Configuration**

     ```bash
     mkdir -p ~/dev
     cd ~/dev
     git clone <your-repo-url> dotfile
     cd dotfile
     ```

3. **Configure User Settings**

     ```bash
     cp user-config.template.nix user-config.nix
     ```

     Edit `user-config.nix` with your information:

     ```nix
     {
       username = "your-macos-username";  # Must match your macOS login
       fullName = "Your Full Name";
       email = "your.email@example.com";
       githubUsername = "your-github-username";
       hostname = "your-hostname";  # e.g., macbook-pro
     }
     ```

4. **Run Installation**

     ```bash
     ./pre-nix-installation.sh
     ```

## Directory Structure

```bash
.
├── darwin/                      # macOS system configuration
│   ├── configuration.nix        # Core system settings
│   └── homebrew.nix             # Homebrew package management
├── flake.lock                   # Lock file for dependencies
├── flake.nix                    # System definition
├── home-manager/                # User environment
│   ├── aliases.nix              # Shell aliases
│   ├── default.nix              # Main user configuration
│   ├── modules/                 # Configuration modules
│   │   ├── aws/                 # AWS CLI and credentials
│   │   │   └── default.nix      # Combined AWS module
│   │   ├── claude/              # Claude Code configuration
│   │   │   ├── default.nix      # Module definition
│   │   │   └── statusline.sh    # Statusline script
│   │   ├── gcloud.nix           # Google Cloud SDK setup
│   │   ├── ghostty/             # Terminal emulator
│   │   │   ├── config.toml      # Ghostty configuration
│   │   │   └── default.nix      # Module definition
│   │   ├── git.nix              # Git configuration
│   │   ├── github.nix           # GitHub CLI setup
│   │   ├── karabiner/           # Keyboard customization
│   │   │   └── default.nix      # Module definition
│   │   ├── lazygit.nix          # Git TUI configuration
│   │   ├── tmux.nix             # Terminal multiplexer
│   │   └── zsh.nix              # Shell configuration
│   └── shell.nix                # Shell environment
├── nix/                         # Nix configuration
│   ├── dynamic-config.zsh       # Dynamic shell config
│   ├── nix.conf                 # Nix settings
│   └── zshrc                    # ZSH configuration
├── pre-nix-installation.sh      # Installation script
├── uninstall.sh                 # Uninstallation script
├── user-config.nix              # User settings
└── user-config.template.nix     # Template for user settings
```

## Quick Reference

### System Commands

```bash
rebuild   # Rebuild system
update    # Update and rebuild
cleanup   # Clean old generations
```

### Common Tools

```bash
# Git
gs        # Status
gp        # Push
gl        # Pull
lg        # LazyGit TUI

# GitHub
ghprc     # Checkout PR
ghprl     # List PRs

# Cloud
awsp      # Switch AWS profile
gcs       # Switch GCloud config
```

## Documentation

Comprehensive documentation is organized into the following sections:

### Core Guides

- [Installation Guide](docs/core/installation.md) - Complete setup instructions
- [Configuration Guide](docs/core/configuration.md) - System configuration
- [Troubleshooting Guide](docs/core/troubleshooting.md) - Common issues and solutions

### Tool Configuration

- [Git & GitHub](docs/git.md)
- [Cloud Tools](docs/cloud.md)
- [Terminal Tools](docs/terminal.md)

### Customization

- [Package Management](docs/customization/packages.md) - Adding and managing packages
- [Module System](docs/customization/modules.md) - Working with modules
- [Theme Configuration](docs/customization/themes.md) - Visual customization

Each guide contains detailed examples and best practices for its respective area.

## Uninstallation

```bash
./uninstall.sh
```

## Acknowledgments

This configuration was developed with the assistance of [Cursor](https://cursor.sh), an AI-powered code editor that helped:

- Generate and structure configuration files
- Debug Nix expressions
- Create comprehensive documentation
- Maintain consistent code style
