# Theme Customization

Guide to customizing the visual appearance of your system and applications.

## Terminal Appearance

### Ghostty Terminal

Ghostty configuration is managed in `home-manager/modules/ghostty/`:

```toml
# home-manager/modules/ghostty/config.toml
# Font configuration
font-family = "JetBrainsMono Nerd Font"
font-size = 14

# Window appearance
window-padding-x = 10
window-padding-y = 10
background-opacity = 0.95

# Theme (uses built-in themes)
theme = "rose-pine"
```

### Spaceship Prompt

The shell prompt is configured using Spaceship, installed via Homebrew and initialized in `flake.nix`:

```nix
# darwin/homebrew.nix
brews = [
  "spaceship"  # minimalistic, powerful and extremely customizable Zsh prompt
];
```

Spaceship is auto-initialized via the shell configuration.

## Shell Customization

### ZSH Theme

```nix
# home-manager/modules/zsh.nix
{
  programs.zsh = {
    enable = true;
    enableAutosuggestions = true;
    enableSyntaxHighlighting = true;

    initContent = ''
      # Shell appearance settings
      export TERM="xterm-256color"

      # History appearance
      export HISTSIZE=10000
      export SAVEHIST=10000
    '';
  };
}
```

## Application Themes

### Tmux Theme

Tmux uses the Rose Pine theme:

```nix
# home-manager/modules/tmux.nix
{
  programs.tmux = {
    extraConfig = ''
      set -g @plugin 'rose-pine/tmux'
    '';
  };
}
```

### LazyGit Theme

```nix
# home-manager/modules/lazygit.nix
{
  programs.lazygit = {
    enable = true;
    settings = {
      gui = {
        theme = {
          lightTheme = false;
          activeBorderColor = ["green" "bold"];
          inactiveBorderColor = ["white"];
          selectedLineBgColor = ["default"];
        };
      };
    };
  };
}
```

## System Appearance

### macOS Theme Settings

```nix
# darwin/configuration.nix
{
  system.defaults = {
    NSGlobalDomain = {
      AppleInterfaceStyle = "Dark";  # Dark mode
      AppleHighlightColor = "0.847059 0.847059 0.862745";
    };

    dock = {
      autohide = true;
      orientation = "bottom";
      tilesize = 48;
    };

    finder = {
      AppleShowAllFiles = true;
      ShowPathbar = true;
      ShowStatusBar = true;
    };
  };
}
```

## Font Configuration

### System Fonts

Fonts are installed via Homebrew casks:

```nix
# darwin/homebrew.nix
casks = [
  "font-space-mono-nerd-font"
  "font-fira-code-nerd-font"
  "font-maple-mono"
];
```

## Best Practices

1. **Color Schemes**
   - Use consistent colors across applications
   - Consider light/dark mode compatibility
   - Document color values for reference

2. **Font Management**
   - Use Nerd Fonts for icons support
   - Maintain consistent font sizes
   - Consider font fallbacks

3. **Theme Organization**
   - Group related theme settings
   - Use variables for common values
   - Document theme dependencies
