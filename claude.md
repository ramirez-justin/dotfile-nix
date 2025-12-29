# Claude.md - Dotfiles Development Guide

This document provides essential context for AI assistants (particularly Claude Code) working with this Nix-based dotfiles repository. It covers the system architecture, common workflows, and important conventions.

## Repository Overview

This is a **Nix-based macOS dotfiles repository** using:
- **nix-darwin**: System-level macOS configuration
- **home-manager**: User environment management
- **Homebrew**: GUI applications and some CLI tools
- **Flakes**: Declarative dependency management

**Location**: `~/dev/dotfile` (hardcoded in many configs)

## Critical Build/Deploy Commands

These commands are defined in `home-manager/aliases.nix` and should be used when making changes:

### Primary Commands

```bash
rebuild    # Rebuild system after making changes (does NOT update flake.lock)
           # Defined as: cd ~/dev/dotfile && sudo darwin-rebuild switch --flake .#"$(hostname)" --option max-jobs auto && cd $HOME

update     # Update flake.lock AND rebuild system
           # Steps: 1) Updates flake, 2) Runs rebuild, 3) Reports completion

cleanup    # Garbage collection and system cleanup
           # Cleans: Nix store, Homebrew cache, npm cache, logs, temp files
```

### Important Notes

1. **Always use `rebuild`** after making configuration changes (editing .nix files)
2. **Use `update`** when you want to update package versions
3. **hostname** must match the value in `user-config.nix` (currently: `Macmini-localdomain`)
4. Changes to `.nix` files require `rebuild` to take effect
5. The flake configuration is at `flake.nix` in the repository root

## Architecture & File Structure

```
dotfile/
├── flake.nix                    # Main system definition, inputs, and outputs
├── flake.lock                   # Lock file for reproducible builds
├── user-config.nix              # User-specific settings (username, email, hostname, etc.)
│
├── darwin/                      # System-level macOS configuration
│   ├── configuration.nix        # Core system settings
│   └── homebrew.nix             # Homebrew package management
│
├── home-manager/                # User environment configuration
│   ├── default.nix              # Main entry point, imports all modules
│   ├── aliases.nix              # Shell aliases and functions
│   ├── shell.nix                # Shell environment setup
│   ├── neovim.nix               # Neovim configuration
│   │
│   └── modules/                 # Modular configurations
│       ├── aws/                 # AWS CLI and credentials (merged module)
│       ├── claude/              # Claude Code configuration
│       ├── gcloud.nix           # Google Cloud SDK setup
│       ├── ghostty/             # Ghostty terminal emulator
│       ├── git.nix              # Git configuration
│       ├── github.nix           # GitHub CLI setup
│       ├── karabiner/           # Keyboard customization
│       ├── lazygit.nix          # LazyGit TUI configuration
│       ├── python.nix           # Python environment
│       ├── tmux.nix             # Terminal multiplexer
│       └── zsh.nix              # ZSH configuration
│
├── nix/                         # Core Nix setup
│   ├── dynamic-config.zsh       # Dynamic shell config
│   ├── nix.conf                 # Nix settings
│   └── zshrc                    # ZSH configuration
│
└── docs/                        # Documentation
    ├── cloud.md                 # Cloud platform tools
    ├── git.md                   # Git & GitHub
    ├── terminal.md              # Terminal tools
    └── core/                    # Core guides
        ├── installation.md
        ├── configuration.md
        └── troubleshooting.md
```

## Key Configuration Files

### User Configuration (`user-config.nix`)

Contains user-specific settings that are referenced throughout the system:

```nix
{
  username = "justinramirez";           # macOS username
  fullName = "Justin Ramirez";
  email = "ramirez.justin@gmail.com";
  githubUsername = "ramirez-justin";
  hostname = "Macmini-localdomain";     # Used in flake reference
  terminal = "ghostty";                 # Terminal emulator
  awsRegion = "us-west-2";              # Default AWS region
}
```

### Flake Configuration (`flake.nix`)

- Defines all inputs (dependencies)
- Configures darwin system for hostname from `user-config.nix`
- Integrates home-manager, nix-homebrew, and other modules
- System is built for: `aarch64-darwin` (Apple Silicon)

### Home Manager (`home-manager/default.nix`)

- Central configuration for user environment
- Imports all module configurations
- Defines shell aliases from `aliases.nix`
- Configures fzf, zsh, and core packages

## Common Development Workflows

### Adding a New Package

#### Via Nix (Preferred for CLI tools)

1. **Find the package**: Search at https://search.nixos.org/packages
2. **Add to appropriate location**:
   - System packages: `darwin/configuration.nix`
   - User packages: `home-manager/default.nix` or specific module
3. **Rebuild**: Run `rebuild`

Example:
```nix
home.packages = with pkgs; [
  ripgrep    # Add new package here
];
```

#### Via Homebrew (For GUI apps or macOS-specific tools)

1. **Add to `darwin/homebrew.nix`**:
   - CLI tools: `brews = [ ... ]`
   - GUI apps: `casks = [ ... ]`
2. **Rebuild**: Run `rebuild`

Example:
```nix
brews = [
  "package-name"
];

casks = [
  "app-name"
];
```

### Adding a New Module

1. **Create module file**: `home-manager/modules/tool-name.nix`
2. **Import in `home-manager/default.nix`**:
   ```nix
   imports = [
     ./modules/tool-name.nix
   ];
   ```
3. **Rebuild**: Run `rebuild`

### Modifying Existing Configuration

1. **Edit the appropriate `.nix` file**
2. **Run `rebuild`** to apply changes
3. **Test the changes**
4. **Rollback if needed**: Use `rollback` alias (interactive generation selector)

### Managing Google Cloud SDK Components

The gcloud SDK is managed via Nix with custom components:

```nix
# In home-manager/modules/gcloud.nix
let
  gdk = pkgs.google-cloud-sdk.withExtraComponents(
    with pkgs.google-cloud-sdk.components; [
      gke-gcloud-auth-plugin    # Add components here
    ]
  );
in
{
  home.packages = [ gdk ];
}
```

**Important**: Components cannot be installed via `gcloud components install` when using Nix. Always add them to the Nix configuration.

## Alias Reference

The system includes extensive aliases defined in `home-manager/aliases.nix`. Key categories:

### System Management
```bash
rebuild      # Rebuild system
update       # Update flake and rebuild
cleanup      # System cleanup and garbage collection
rollback     # Interactive generation rollback
reload       # Reload shell config
restart      # Start new shell
```

### File Navigation
```bash
dotfile      # cd ~/dev/dotfile
ls           # eza -l (modern ls)
cat          # bat (modern cat with syntax highlighting)
find         # fd (modern find)
cd           # z (zoxide smart directory jumping)
```

### Development Tools
```bash
nv           # nvim
lg           # lazygit
tf           # terraform
d            # docker
dc           # docker-compose
```

### Cloud Platforms
```bash
# AWS
awsp         # Switch AWS profile
awsw         # Show current AWS profile
awsl         # List available profiles

# GCloud Authentication
gauth        # Full authentication (user + application-default)
gauthuser    # User authentication only
gauthapp     # Application default credentials only
gauthls      # List authenticated accounts
gauthinfo    # Show current auth info

# GCloud Configuration
gcl          # List configurations
gcs          # Switch configuration
gci          # Show current config info

# GCloud Projects
gpl          # List projects
gps          # Set current project
```

### Git
```bash
gs           # git status
gp           # git push
gl           # git pull
gcb          # Interactive branch switcher (fzf)
```

## Important Conventions

### When Making Changes

1. **Read first**: Always read files before editing (especially important for AI assistants)
2. **Test locally**: Use `rebuild` to test changes
3. **Document**: Update relevant docs if adding features
4. **Rollback available**: Use `rollback` alias if something breaks

### When Adding Features

1. **Check existing**: Look for similar configurations first
2. **Modular approach**: Create separate modules for distinct features
3. **Comment well**: Follow existing comment patterns (see any .nix file)
4. **Cross-reference**: Update this file (claude.md) if adding significant features

### Nix-Specific Notes

1. **Avoid `gcloud components install`**: Use Nix configuration instead
2. **Avoid Homebrew for Nix-available packages**: Prefer Nix when possible
3. **Use Homebrew for**: GUI apps, macOS-specific tools, packages with better Homebrew integration
4. **Flake inputs**: Defined in `flake.nix`, locked in `flake.lock`
5. **Home Manager state**: Stored in `~/.local/state/home-manager/`

## Troubleshooting

### Build Failures

```bash
# Check flake
nix flake check

# Verbose rebuild
sudo darwin-rebuild switch --flake .#"$(hostname)" --show-trace

# Roll back to previous generation
rollback
```

### Shell Issues

```bash
reload       # Reload configuration
restart      # Start new shell
```

### Package Conflicts

- Check if package is defined in both Nix and Homebrew
- Prefer Nix for CLI tools, Homebrew for GUI apps
- Use `which <command>` to check which version is active

## Git Workflow

Current branch: `personal-alterations`
Main branch: `main`

When creating PRs, target the `main` branch.

## Current System State (Snapshot)

- **Platform**: macOS (Apple Silicon - aarch64-darwin)
- **Terminal**: Ghostty (configurable in `user-config.nix`)
- **Shell**: ZSH with Spaceship prompt
- **Editor**: Neovim (with nightly builds)
- **Git UI**: LazyGit
- **Cloud SDKs**: AWS CLI, Google Cloud SDK (with gke-gcloud-auth-plugin)

## Resources

- Main README: `README.md`
- Cloud tools: `docs/cloud.md`
- Git setup: `docs/git.md`
- Terminal tools: `docs/terminal.md`
- Package management: `docs/customization/packages.md`
- Module system: `docs/customization/modules.md`

## For AI Assistants

### Before Making Changes

1. **Read the relevant files first** - Don't guess at file contents
2. **Check `aliases.nix`** - The user has extensive aliases defined
3. **Use proper rebuild commands** - Always use `rebuild`, never suggest manual `darwin-rebuild` commands
4. **Understand the user's workflow** - They use aliases extensively

### After Making Changes

1. **Tell the user to run `rebuild`** - Don't suggest other commands
2. **Explain what changed** - Reference file paths and line numbers
3. **Note any side effects** - E.g., "This will also update X"

### Common Mistakes to Avoid

1. ❌ Don't suggest `gcloud components install` - Use Nix configuration
2. ❌ Don't mix Homebrew and Nix for the same package
3. ❌ Don't forget to import new modules in `home-manager/default.nix`
4. ❌ Don't suggest complex manual commands when aliases exist
5. ❌ Don't use `darwin-rebuild` directly - use the `rebuild` alias
6. ✅ Do check existing aliases before suggesting commands
7. ✅ Do read files before editing them
8. ✅ Do explain changes with file paths and line numbers

## Version Information

- **home-manager state version**: 23.11
- **darwin system state version**: 5
- **nixpkgs**: nixpkgs-unstable (see `flake.lock` for exact revision)
