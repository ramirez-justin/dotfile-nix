# Nix → Stow Dotfiles Migration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Migrate this personal Mac from `~/dev/dotfile` (nix-darwin + home-manager + Homebrew) to `~/dev/dotfiles` (a clone of `ramirez-justin/dotfiles` `main` branch using GNU Stow + mise + Homebrew + 1Password CLI), curating `main` as truly personal-only, while preserving every behavior the user relies on today.

**Architecture:** Stage the new repo on a `migrate-personal` branch, port/curate per-tool configs, validate Brewfile coverage *before* removing Nix, then cut over in a single sitting (uninstall.sh → `mise run link` → smoke tests) and push the curated `main`. Work-machine `gametime` branch is preserved untouched.

**Tech Stack:** GNU Stow, mise (task runner), Homebrew, 1Password CLI (`op`), zsh + oh-my-zsh + spaceship, tmux + TPM, Neovim (mothership.nvim submodule), git, gh, lazygit, Rectangle, Ghostty, Claude Code, AWS CLI, Google Cloud SDK.

**Spec:** `docs/superpowers/specs/2026-04-26-nix-to-stow-dotfiles-migration-design.md`

---

## Glossary of paths

| Symbol | Path |
|---|---|
| `$NIX_REPO` | `~/dev/dotfile` (the OLD Nix repo, kept until cleanup) |
| `$NEW_REPO` | `~/dev/dotfiles` (the NEW stow repo, cloned in Task 1.1) |
| `$BR` | `migrate-personal` (working branch) |

---

## Phase 0 — Pre-flight: protect `gametime`

Curating `main` will delete work-specific content (Snowflake/Terragrunt/DBT/gametime-airflow/Jira/work-email). We must verify all of that already lives on `gametime` before we strip it from `main`. If anything lives ONLY on `main`, we cherry-pick it onto `gametime` first.

### Task 0.1: Audit `gametime` for work content already committed

**Files:** none (read-only inspection)

- [ ] **Step 1: Clone the target read-only first to a scratch path so we can inspect both branches without committing**

```bash
git clone --recurse-submodules https://github.com/ramirez-justin/dotfiles.git /tmp/dotfiles-audit
cd /tmp/dotfiles-audit
git fetch origin gametime:gametime
git fetch origin main:main
```

Expected: two local branches, both up to date with origin.

- [ ] **Step 2: Diff `main..gametime` to see what gametime adds beyond main**

```bash
cd /tmp/dotfiles-audit
git log --oneline main..gametime
git diff --stat main..gametime
```

Expected output: a list of commits and changed files unique to `gametime`. **Capture this output** — paste into the plan execution log.

- [ ] **Step 3: Verify each work-specific marker exists on `gametime`**

```bash
cd /tmp/dotfiles-audit
git checkout gametime -- zsh/.zshrc git/.gitconfig claude/.claude/settings.json 2>/dev/null
grep -l 'set_snowflake_creds\|tg_clean_output\|defer_dbt\|gametime-airflow\|justin.ramirez@gametime.co\|aws-vault exec justin.ramirez\|TENV_GITHUB_TOKEN\|gametime.atlassian.net' zsh/.zshrc git/.gitconfig claude/.claude/settings.json 2>/dev/null
git checkout main -- zsh/.zshrc git/.gitconfig claude/.claude/settings.json
```

Expected: `gametime` versions contain those markers. If a marker is missing on `gametime`, that's a problem — we must add it on `gametime` before curating `main`.

- [ ] **Step 4: Decide go/no-go**

If all markers are on `gametime` → proceed. If any are missing → STOP and resolve by either (a) cherry-picking the work-specific content onto `gametime` from `main` first, or (b) accepting the loss explicitly. Document the decision in the plan execution log.

- [ ] **Step 5: Clean up the scratch clone**

```bash
rm -rf /tmp/dotfiles-audit
```

Expected: `/tmp/dotfiles-audit` no longer exists.

---

## Phase 1 — Stage the new repo

### Task 1.1: Clone target dotfiles to `~/dev/dotfiles`

**Files:**
- Create directory: `~/dev/dotfiles/`

- [ ] **Step 1: Verify the path is free**

```bash
test -e ~/dev/dotfiles && echo "EXISTS, abort" || echo "free"
```

Expected: `free`. If `EXISTS, abort`, stop and reconcile with the user.

- [ ] **Step 2: Clone with submodules**

```bash
git clone --recurse-submodules git@github.com:ramirez-justin/dotfiles.git ~/dev/dotfiles
```

Expected: clone succeeds; `~/dev/dotfiles/nvim/.config/nvim/` and `~/dev/dotfiles/eza/.config/eza/eza-themes/` are populated.

- [ ] **Step 3: Verify submodule state**

```bash
git -C ~/dev/dotfiles submodule status
```

Expected: two submodules listed (mothership.nvim and eza-themes), each with a commit hash and no leading `-` or `+` (which would indicate uninitialized or modified).

### Task 1.2: Create `migrate-personal` working branch

- [ ] **Step 1: Branch off main**

```bash
git -C ~/dev/dotfiles checkout main
git -C ~/dev/dotfiles checkout -b migrate-personal
git -C ~/dev/dotfiles status
```

Expected: on `migrate-personal`, working tree clean.

### Task 1.3: Confirm repo metadata

- [ ] **Step 1: Inspect `.stow-global-ignore`**

```bash
cat ~/dev/dotfiles/.stow-global-ignore
```

Expected output:

```
.git
.gitignore
docs
README.md
mise.toml
Brewfile
```

If contents differ, note it but don't change unless a later task requires it.

- [ ] **Step 2: Inspect `mise.toml` tasks**

```bash
mise tasks --cwd ~/dev/dotfiles
```

Expected: tasks `bootstrap`, `brew-install`, `link`, `unlink`, `update`, `brew-dump`, `submodule-update`, `nvim-update`, `inject-secrets` exist.

---

## Phase 2 — Brewfile reconciliation

The current Nix system installs many tools via Nix that the new system needs in Brewfile. Before uninstalling Nix, ensure every tool the user relies on is brew-installed.

### Task 2.1: Diff current package set against target Brewfile

**Files:** none (read-only)

- [ ] **Step 1: List all current Brewfile entries**

```bash
grep -E '^(brew|cask|tap)' ~/dev/dotfiles/Brewfile | sort -u > /tmp/brewfile-current.txt
wc -l /tmp/brewfile-current.txt
```

Expected: a sorted list of current Brewfile lines. Roughly 70+ entries.

- [ ] **Step 2: List currently-installed brew formulae and casks**

```bash
brew list --formula | sort > /tmp/brew-installed-formulae.txt
brew list --cask | sort > /tmp/brew-installed-casks.txt
```

Expected: two sorted lists. The formulae list will include things Nix-bundled Homebrew has installed (since `nix-homebrew` manages a real Homebrew under the hood).

- [ ] **Step 3: Identify formulae missing from target Brewfile that are needed**

The migration spec calls out these specific tools that must be brew-installed (each is currently in `darwin/homebrew.nix`):

```
1password-cli, age, awscli, bash-language-server, bat, bottom, btop, cmake,
composer, coreutils, deno, dockerfile-language-server, duf, dust, eza, fd,
fzf, gh, git, git-lfs, glow, gnupg, go, hashicorp/tap/terraform-ls, jq,
julia, lazygit, lua, luarocks, markdown-oxide, mas, mise, neofetch, neovim,
node, php, pkg-config, pre-commit, ripgrep, ruby, rustup, shellcheck, shfmt,
sops, spaceship, stow, terraform-docs, tflint, tldr, tmux, trivy, uv,
yaml-language-server, yq, zoxide, gmailctl, checkov, tenv
```

Run:

```bash
for f in 1password-cli age awscli bash-language-server bat bottom btop cmake composer coreutils deno dockerfile-language-server duf dust eza fd fzf gh git git-lfs glow gnupg go jq julia lazygit lua luarocks markdown-oxide mas mise neofetch neovim node php pkg-config pre-commit ripgrep ruby rustup shellcheck shfmt sops spaceship stow terraform-docs tflint tldr tmux trivy uv yaml-language-server yq zoxide gmailctl checkov tenv; do
  grep -q "\"$f\"" ~/dev/dotfiles/Brewfile || echo "MISSING: $f"
done
```

Expected: a list of formulae names not yet in the Brewfile. **Capture this list** — Task 2.2 adds them.

- [ ] **Step 4: Check casks**

The migration must add: `rectangle`, `google-cloud-sdk`. Plus user uses: `1password`, `claude`, `discord`, `docker-desktop`, `font-fira-code-nerd-font`, `font-maple-mono`, `font-space-mono-nerd-font`, `ghostty`, `google-chrome`, `insync`, `postman`, `slack`, `spotify`, `the-unarchiver`, `vlc`.

```bash
for c in rectangle google-cloud-sdk 1password claude discord docker-desktop font-fira-code-nerd-font font-maple-mono font-space-mono-nerd-font ghostty google-chrome insync postman slack spotify the-unarchiver vlc; do
  grep -q "\"$c\"" ~/dev/dotfiles/Brewfile || echo "MISSING-CASK: $c"
done
```

Expected: a list of casks to add. **Capture this list.**

### Task 2.2: Add missing brew/cask entries

**Files:**
- Modify: `~/dev/dotfiles/Brewfile`

- [ ] **Step 1: Open the Brewfile**

```bash
nvim ~/dev/dotfiles/Brewfile
```

- [ ] **Step 2: Add each missing formula** captured in Task 2.1 Step 3 to the `brew "..."` section. Group them by category if existing structure shows categories; otherwise append at the end. One formula per line in the format `brew "name"`.

- [ ] **Step 3: Add each missing cask** captured in Task 2.1 Step 4 in the same way: `cask "name"`.

- [ ] **Step 4: Verify Brewfile still parses**

```bash
brew bundle list --file=~/dev/dotfiles/Brewfile | head
```

Expected: prints package names without errors. If `brew` rejects the syntax, fix and retry.

- [ ] **Step 5: Commit**

```bash
git -C ~/dev/dotfiles add Brewfile
git -C ~/dev/dotfiles commit -m "Brewfile: add packages currently managed by Nix on personal Mac"
```

### Task 2.3: Run `brew bundle` (additive, doesn't conflict with Nix)

- [ ] **Step 1: Run brew-install task**

```bash
cd ~/dev/dotfiles && mise run brew-install
```

Expected: each missing package installs; already-installed packages skip. Final line `Homebrew Bundle complete!`. No errors.

- [ ] **Step 2: Verify critical tools resolve**

```bash
for cmd in stow mise op zsh bat eza fd fzf gh git lazygit nvim ripgrep tmux zoxide spaceship rg; do
  command -v "$cmd" >/dev/null 2>&1 && echo "OK: $cmd" || echo "MISSING: $cmd"
done
```

Expected: every line `OK:` (note: `spaceship` resolves under `$(brew --prefix)/opt/spaceship/spaceship.zsh`, not as a binary, so check via `test -f "$(brew --prefix)/opt/spaceship/spaceship.zsh"` instead — adjust if it shows MISSING).

- [ ] **Step 3: Install gke-gcloud-auth-plugin**

```bash
gcloud components install gke-gcloud-auth-plugin --quiet
```

Expected: install succeeds (or already-installed message).

---

## Phase 3 — Curate `main` content

All edits in this phase land on the `migrate-personal` branch in `~/dev/dotfiles`.

### Task 3a: zsh — strip work cruft, add custom keybindings, add curated aliases

**Files:**
- Modify: `~/dev/dotfiles/zsh/.zshrc`
- Create: `~/dev/dotfiles/zsh/.config/zsh/keybindings.zsh`
- Create: `~/dev/dotfiles/zsh/.config/zsh/aliases.zsh`

#### Task 3a.1: Edit `.zshrc` — remove work-specific content

- [ ] **Step 1: Read the current file to confirm line ranges**

```bash
nl -ba ~/dev/dotfiles/zsh/.zshrc | sed -n '1,200p'
```

- [ ] **Step 2: Open and edit `~/dev/dotfiles/zsh/.zshrc`**

Delete every block matching the items below. Use search-and-delete in nvim or the line-deletion tool of choice.

**Delete:**

1. The `TENV_GITHUB_TOKEN` export line (depends on `op read` at shell-init time, which fails offline).
2. `aws-vault` aliases:
   - `alias av="aws-vault"`
   - `alias aws-me="aws-vault exec justin.ramirez --duration=8h"`
   - The line referencing `aws-ecr-login` (it says it's in `~/.zshrc.local`, so removing the comment only).
3. The `set_snowflake_creds` function (full multi-line function).
4. All terragrunt/terraform aliases that depend on Snowflake credentials:
   - `alias tg=terragrunt`, `alias tgp=...`, `alias tga=...`, `alias tgi=...`
   - `tg_clean_output` function
   - `alias tgp_file=...`, `alias tgp_staging_file=...`, `alias tgp_prod_file=...`
   - All `tga_staging`, `tgc_staging`, `tgo_staging`, `tgp_staging`, `tgs_staging`, `tgsh_staging`
   - All `tga_prod`, `tgc_prod`, `tgo_prod`, `tgp_prod`, `tgs_prod`, `tgsh_prod`
5. `alias resync_airflow_staging=...`
6. DBT aliases:
   - `alias setup_dbt=...`
   - `alias defer_dbt_run=...`, `alias defer_dbt_test=...`, `alias defer_dbt_build=...`
7. `eval "$(rbenv init - zsh)"` and the line `export PATH="/opt/homebrew/opt/ruby/bin:$PATH"` (drop ruby/rbenv).
8. The `complete -o nospace -C /opt/homebrew/bin/terragrunt terragrunt` line.
9. The Julia path line `export PATH="/Applications/Julia-1.9.app/Contents/Resources/julia/bin:$PATH"` (drop unless user actively uses Julia — confirm during execution).
10. The Snowflake commented-out function block (cleanup).
11. The dbt installer block (`# Added by dbt installer`, `export PATH="$PATH:/Users/justin/.local/bin"`, `alias dbtf=...`).

**Edit:**

12. Change `alias dots="cd ~/Repositories/dotfiles"` to `alias dots="cd ~/dev/dotfiles"`.
13. Change the line `export EZA_CONFIG_DIR="~/.config/eza"` to `export EZA_CONFIG_DIR="$HOME/.config/eza"` (the literal `~` doesn't expand inside double quotes).

**Add (right before the final `[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local` line):**

```zsh
# Custom keybindings and widgets (ported from Nix home-manager)
[[ -f $HOME/.config/zsh/keybindings.zsh ]] && source $HOME/.config/zsh/keybindings.zsh
# Curated personal aliases (ported from Nix home-manager)
[[ -f $HOME/.config/zsh/aliases.zsh ]] && source $HOME/.config/zsh/aliases.zsh
```

- [ ] **Step 3: Verify the file is syntactically valid zsh**

```bash
zsh -n ~/dev/dotfiles/zsh/.zshrc
echo "exit=$?"
```

Expected: `exit=0` and no error output.

- [ ] **Step 4: Sanity-grep for any work-cruft markers that should be gone**

```bash
grep -nE 'snowflake|terragrunt|gametime-airflow|defer_dbt|set_snowflake_creds|tg_clean_output|aws-vault exec justin\.ramirez|TENV_GITHUB_TOKEN|rbenv|dbtf' ~/dev/dotfiles/zsh/.zshrc || echo "CLEAN"
```

Expected: `CLEAN`. Any hits → revisit Step 2.

#### Task 3a.2: Create `keybindings.zsh`

- [ ] **Step 1: Create the file**

```bash
mkdir -p ~/dev/dotfiles/zsh/.config/zsh
```

Write `~/dev/dotfiles/zsh/.config/zsh/keybindings.zsh` with this exact content:

```zsh
# zsh keybindings + FZF widgets
# Ported from Nix home-manager/modules/zsh.nix

# Interactive git status with file preview
function fzf-git-status() {
    local selections=$(
        git status --porcelain | \
        fzf --ansi \
            --preview 'if [ -f {2} ]; then
                            bat --color=always --style=numbers {2}
                        elif [ -d {2} ]; then
                            tree -C {2}
                        fi' \
            --preview-window right:70% \
            --multi
    )
    if [ -n "$selections" ]; then
        LBUFFER+="$(echo "$selections" | awk '{print $2}' | tr '\n' ' ')"
    fi
    zle reset-prompt
}
zle -N fzf-git-status

# Directory navigation with hidden files
function fzf-cd-with-hidden() {
    local dir
    dir=$(find "${1:-$PWD}" -type d 2> /dev/null | fzf +m) && cd "$dir"
    zle reset-prompt
}
zle -N fzf-cd-with-hidden

# History and Directory Navigation
autoload -U up-line-or-beginning-search
autoload -U down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
zle -N dirhistory_zle_dirhistory_up
zle -N dirhistory_zle_dirhistory_down

# Word Navigation: ALT-Left/Right
bindkey "^[f" forward-word
bindkey "^[b" backward-word

# Word Deletion: CTRL-Delete / ALT-Backspace
bindkey "^[[3;5~" kill-word
bindkey "^H" backward-kill-word
bindkey "^[^?" backward-kill-word

# Line editing
bindkey "^U" backward-kill-line

# Cursor: CTRL-A/E
bindkey "^A" beginning-of-line
bindkey "^E" end-of-line

# Directory history: ALT-Up / ALT-Down
bindkey "^[[1;3A" dirhistory_zle_dirhistory_up
bindkey "^[[1;3B" dirhistory_zle_dirhistory_down

# FZF widgets
bindkey -s '^_' 'code $(fzf)^M'   # CTRL-_ : open fzf-selected file in VS Code
bindkey "^[d" fzf-cd-with-hidden  # ALT-d  : fzf cd
bindkey '^G' fzf-git-status       # CTRL-G : fzf git status
```

- [ ] **Step 2: Verify it parses**

```bash
zsh -n ~/dev/dotfiles/zsh/.config/zsh/keybindings.zsh && echo OK
```

Expected: `OK`.

#### Task 3a.3: Create `aliases.zsh`

- [ ] **Step 1: Write `~/dev/dotfiles/zsh/.config/zsh/aliases.zsh`** with this exact content:

```zsh
# Curated personal aliases
# Ported and curated from Nix home-manager/aliases.nix

# Shell management
alias reload="source $HOME/.zshrc && clear"
alias rl="reload"
alias restart="exec zsh"
alias re="restart"
alias zshconfig="nv ~/.zshrc"
alias ohmyzsh="cd ~/.oh-my-zsh"
alias ghosttyconfig="nv ~/.config/ghostty/config"

# Navigation
alias dl="cd ~/Downloads"
alias docs="cd ~/dev"
alias cdf='cd $(ls -d */ | fzf)'

# Modern CLI replacements
alias cat="bat"
alias find="fd"
alias top="btop"

# Editor
alias nv="nvim"
alias v="nvim"
alias vim="nvim"

# Safer / friendlier defaults
alias mkdir="mkdir -p"
alias cp="cp -r"
alias mv="mv -i"
# NOTE: deliberately not aliasing rm here — see ~/.zshrc.local if needed.

# eza variants (override `ls` only — base `ls` already aliased in .zshrc)
alias lsa="eza -la"
alias lst="eza -T"
alias lsta="eza -Ta"
alias lsr="eza -R"
alias lsg="eza -l --git"
alias lsm="eza -l --sort=modified"
alias lss="eza -l --sort=size"

# Terraform
alias tf="terraform"
alias tfin="terraform init"
alias tfp="terraform plan"
alias tfi="tfswitch -i"
alias tfu="tfswitch -u"
alias tfl="tfswitch -l"
# (Terragrunt aliases live on the gametime branch; not on personal)

# Docker
alias d="docker"
alias dc="docker-compose"

# Network
alias ipp="curl https://ipecho.net/plain; echo"

# System monitoring
alias htop="btop"
alias df="duf"
alias dfa="duf --all"
alias dfh="duf --hide-fs tmpfs,devtmpfs,efivarfs"
alias dfi="duf --only local,network"
alias bm="btm --basic"
alias bmp="btm --process_command"
alias bmt="btm --tree"
alias bmb="btm --battery"
alias cpu="btm --basic --cpu_left_legend"
alias mem="btm --basic --memory_legend none"
alias net="btm --basic --network_legend none"
alias sys="neofetch"
alias sysinfo="neofetch"
alias fetch="neofetch"

# Help / docs
alias h="tldr"
alias help="tldr"
alias rtfm="tldr"
alias cheat="tldr"
alias tldr-update="tldr --update"

# fd (find replacement) shortcuts
alias fdh="fd -H"
alias fa="fd -a"
alias ft="fd -tf --changed-within 1d"
alias fdir="fd -td"
alias ff="fd -tf"
alias fsym="fd -tl"
alias fpy="fd -e py"
alias fjs="fd -e js"
alias fsh="fd -e sh"
alias fmd="fd -e md"
alias fconf="fd -e conf -e config"

# Git (interactive)
alias gcb='git branch --all | grep -v HEAD | fzf --preview "git log --oneline --graph --date=short --color=always --pretty=\"%C(auto)%cd %h%d %s\" {1}" | sed "s/.* //" | xargs git checkout'

# Git basics (ported from git.nix shellAliases)
alias gp="git push"
alias gl="git pull"
alias gs="git status"
alias gd="git diff"
alias gpush='git add . && git commit -m'
alias gpushf='git add . && git commit --amend --no-edit && git push -f'
alias gpushnew='git push -u origin HEAD'
alias gare="git remote add upstream"
alias gre="git remote -v"
alias gcan='git add -A; git rm $(git ls-files --deleted) 2> /dev/null; git commit -v -a --no-edit --amend'
alias gfa="git fetch --all"
alias gfap="git fetch --all --prune"

# LazyGit
alias lg="lazygit"
alias lgc='lazygit -w $(pwd)'
alias lgf='lazygit -f $(find . -type d -name ".git" -exec dirname {} \; | fzf)'

# Git history (interactive)
alias fshow='git log --graph --color=always --format="%C(auto)%h%d %s %C(black)%C(bold)%cr" | fzf --ansi --preview "echo {} | grep -o \"[a-f0-9]\{7\}\" | head -1 | xargs -I % sh -c \"git show --color=always %\""'
alias fstash='git stash list | fzf --preview "echo {} | cut -d: -f1 | xargs -I % sh -c \"git stash show --color=always %\"" | cut -d: -f1 | xargs -I % sh -c "git stash apply %"'

# File / content navigation
alias fe='fzf --preview "bat --color=always --style=numbers --line-range=:500 {}" | xargs -r nano'
alias ffp='fzf --preview "bat --color=always --style=numbers --line-range=:500 {}"'
alias fcd='cd $(find . -type d -not -path "*/\.*" | fzf)'
alias fif='rg --color=always --line-number --no-heading --smart-case "" | fzf --ansi --preview "bat --color=always --style=numbers {1} --highlight-line {2}"'

# Process / memory
alias fkill="ps -ef | sed 1d | fzf -m | awk '{print \$2}' | xargs kill -9"
alias fmem="ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%mem | head -20 | fzf --header-lines=1"

# History / env
alias hist="history 0 | fzf --ansi --preview 'echo {}' | sed 's/ *[0-9]* *//'"
alias fenv="env | fzf --preview 'echo {}' | cut -d= -f2"

# Docker (interactive)
alias dsp='docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | fzf --header-lines=1 | awk "{print \$1}" | xargs -r docker stop'
alias drm='docker ps -a --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | fzf --header-lines=1 | awk "{print \$1}" | xargs -r docker rm'

# Markdown viewing
alias md="glow"
alias readme="glow README.md"
alias changes="glow CHANGELOG.md"

# tmux
alias tpi="tmux run-shell $HOME/.tmux/plugins/tpm/bindings/install_plugins"
alias tpu="tmux run-shell $HOME/.tmux/plugins/tpm/bindings/update_plugins"
alias tpU="tmux run-shell $HOME/.tmux/plugins/tpm/bindings/clean_plugins"
alias tn="tmux new -s"
alias ta="tmux attach -t"
alias tl="tmux list-sessions"
alias tk="tmux kill-session -t"
alias t="tmux new-session -A -s main"

# Smart editor for dotfiles
codedot() {
    if command -v cursor &> /dev/null; then
        cursor "$HOME/dev/dotfiles"
    else
        code "$HOME/dev/dotfiles"
    fi
}

# Jupyter
alias jlab="jupyter lab"

# macOS Finder controls
alias show="defaults write com.apple.finder AppleShowAllFiles -bool true && killall Finder"
alias hide="defaults write com.apple.finder AppleShowAllFiles -bool false && killall Finder"
alias hidedesktop="defaults write com.apple.finder CreateDesktop -bool false && killall Finder"
alias showdesktop="defaults write com.apple.finder CreateDesktop -bool true && killall Finder"

# macOS volume / lock
alias stfu="osascript -e 'set volume output muted true'"
alias pumpitup="osascript -e 'set volume output volume 100'"
alias afk='osascript -e "tell application \"System Events\" to keystroke \"q\" using {command down,control down}"'

# AWS profile switching (paired with aws/.local/bin/copy_and_unset, see Task 4a)
alias awsdef='osascript -e "tell application \"System Events\" to keystroke \"k\" using command down" && $HOME/.local/bin/copy_and_unset default'
alias awsprod='osascript -e "tell application \"System Events\" to keystroke \"k\" using command down" && $HOME/.local/bin/copy_and_unset production'
alias awsdev='osascript -e "tell application \"System Events\" to keystroke \"k\" using command down" && $HOME/.local/bin/copy_and_unset development'
export AWS_DEFAULT_REGION=us-west-2
export AWS_REGION=us-west-2

# Google Cloud
alias gauth='op read "op://Telophase QS/GCP ADC OAuth Client - tqs-dev/client_secret_821909658093-llr9utmgsb7u97nk4kv5679mtv2a2e60.apps.googleusercontent.com.json" > /tmp/adc_client_secret.json && gcloud auth login && gcloud auth application-default login --client-id-file=/tmp/adc_client_secret.json'
alias gauthuser="gcloud auth login"
alias gauthapp='op read "op://Telophase QS/GCP ADC OAuth Client - tqs-dev/client_secret_821909658093-llr9utmgsb7u97nk4kv5679mtv2a2e60.apps.googleusercontent.com.json" > /tmp/adc_client_secret.json && gcloud auth application-default login --client-id-file=/tmp/adc_client_secret.json'
alias gauthls="gcloud auth list"
alias gauthinfo="gcloud config list"
alias gcl="gcloud config configurations list"
alias gcs="gcloud config configurations activate"
alias gci="gcloud config list"
alias gpl="gcloud projects list"
alias gps="gcloud config set project"
export USE_GKE_GCLOUD_AUTH_PLUGIN=True
# Source gcloud completion if installed via Brew cask
if [ -f "$(brew --prefix)/share/google-cloud-sdk/path.zsh.inc" ]; then
    source "$(brew --prefix)/share/google-cloud-sdk/path.zsh.inc"
fi

# gh — interactive functions and aliases (ported from github.nix)
function ghpr()       { gh pr list --state "$1" --limit 1000 | fzf; }
function ghprall()    { gh pr list --state all  --limit 1000 | fzf; }
function ghpropen()   { gh pr list --state open --limit 1000 | fzf; }
function ghopr()      { id="$(ghprall | cut -f1)"; [ -n "$id" ] && gh pr view "$id" --web; }
function ghprcheck()  { id="$(ghpropen | cut -f1)"; [ -n "$id" ] && gh pr checks "$id"; }
function ghprco() {
    if [ $# -eq 0 ]; then
        local PR_NUM=$(gh pr list --state open | fzf | cut -f1)
        [ -n "$PR_NUM" ] && gh pr checkout "$PR_NUM"
    else
        case "$1" in
            -f|--force)  gh pr checkout "$2" --force  ;;
            -d|--detach) gh pr checkout "$2" --detach ;;
            *)           gh pr checkout "$1"           ;;
        esac
    fi
}
alias ghprcr="gh pr create --web"
alias ghprv="ghopr"
alias ghprl="ghprall"
alias ghpro="ghpropen"
alias ghprc="ghprco"
alias ghprch="ghprcheck"
alias ghrv="gh repo view --web"
alias ghrc="gh repo clone"
alias ghrf="gh repo fork"
alias ghil="gh issue list"
alias ghic="gh issue create --web"
alias ghiv="gh issue view --web"
alias ghrl="gh run list"
alias ghrw="gh run watch"
alias ghrs="gh repo search"
alias ghis="gh issue search"
alias ghps="gh pr search"

# Custom helper: print default branch
function gitdefaultbranch() {
    git remote show origin | grep 'HEAD' | cut -d':' -f2 | sed -e 's/^ *//g' -e 's/ *$//g'
}
```

- [ ] **Step 2: Verify it parses**

```bash
zsh -n ~/dev/dotfiles/zsh/.config/zsh/aliases.zsh && echo OK
```

Expected: `OK`.

#### Task 3a.4: Commit zsh changes

- [ ] **Step 1: Stage and commit**

```bash
git -C ~/dev/dotfiles add zsh/.zshrc zsh/.config/zsh/keybindings.zsh zsh/.config/zsh/aliases.zsh
git -C ~/dev/dotfiles commit -m "zsh: curate work-only content; port keybindings and aliases from Nix"
```

Expected: commit succeeds.

### Task 3b: git — set personal identity, port aliases, ignore patterns

**Files:**
- Modify: `~/dev/dotfiles/git/.gitconfig`
- Create: `~/dev/dotfiles/git/.config/git/ignore`

#### Task 3b.1: Replace `.gitconfig`

- [ ] **Step 1: Overwrite `~/dev/dotfiles/git/.gitconfig`** with:

```ini
[user]
	name = Justin Ramirez
	email = ramirez.justin@gmail.com
[init]
	defaultBranch = develop
[push]
	autoSetupRemote = true
[core]
	editor = nvim
	autocrlf = input
	excludesfile = ~/.config/git/ignore
[fetch]
	prune = true
[pull]
	rebase = true
[color]
	ui = true
[alias]
	st = status
	ci = commit
	br = branch
	co = checkout
	df = diff
	lg = log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit
```

#### Task 3b.2: Create global ignore file

- [ ] **Step 1: Create `~/dev/dotfiles/git/.config/git/ignore`** with:

```
.DS_Store
*.swp
.env
.direnv
node_modules
.vscode
.idea
```

#### Task 3b.3: Verify and commit

- [ ] **Step 1: Sanity-check rendered config**

```bash
GIT_CONFIG_GLOBAL=~/dev/dotfiles/git/.gitconfig git config --list --global | head -20
```

Expected: lists user.name=Justin Ramirez, user.email=ramirez.justin@gmail.com, init.defaultbranch=develop, alias.st=status, etc.

- [ ] **Step 2: Commit**

```bash
git -C ~/dev/dotfiles add git/.gitconfig git/.config/git/ignore
git -C ~/dev/dotfiles commit -m "git: personal identity, ported aliases, global ignore"
```

### Task 3c: claude — replace `settings.json` with personal-curated version

**Files:**
- Modify: `~/dev/dotfiles/claude/.claude/settings.json`

#### Task 3c.1: Write the curated `settings.json`

- [ ] **Step 1: Overwrite `~/dev/dotfiles/claude/.claude/settings.json`** with:

```json
{
  "model": "opus",
  "autoCompact": false,
  "autoCompactEnabled": false,
  "includeCoAuthoredBy": false,
  "env": {
    "CLAUDE_CODE_SUBAGENT_MODEL": "sonnet",
    "TRELLO_API_KEY": "op://Telophase QS/Trello API key/API key",
    "TRELLO_TOKEN": "op://Telophase QS/Trello API key/Trello Token",
    "TRELLO_BOARD_ID": "DyXW6UrW",
    "ALPACA_API_KEY": "op://Private/Alpaca Paper Trading/Key",
    "ALPACA_API_SECRET": "op://Private/Alpaca Paper Trading/Secret",
    "ALPACA_PAPER": "true",
    "ENABLE_LSP_TOOL": 1
  },
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "afplay /System/Library/Sounds/Submarine.aiff"
          }
        ]
      }
    ]
  },
  "statusLine": {
    "type": "command",
    "command": "/Users/justinramirez/.claude/statusline.sh"
  },
  "enabledPlugins": {
    "workflow@productivity-plugins": true,
    "alpaca@productivity-plugins": true,
    "ruff-lsp@productivity-plugins": true,
    "bash-ls@productivity-plugins": true,
    "docker-ls@productivity-plugins": true,
    "markdown-oxide@productivity-plugins": true,
    "vim-ls@productivity-plugins": true,
    "yaml-ls@productivity-plugins": true,
    "pyright-lsp@claude-plugins-official": true,
    "lua-lsp@claude-plugins-official": true,
    "code-review@claude-plugins-official": true,
    "skill-creator@claude-plugins-official": true,
    "superpowers@superpowers-marketplace": true,
    "trello@productivity-plugins": true
  }
}
```

- [ ] **Step 2: Validate JSON**

```bash
jq . ~/dev/dotfiles/claude/.claude/settings.json > /dev/null && echo OK
```

Expected: `OK`.

#### Task 3c.2: Verify statusline.sh exists and is executable

- [ ] **Step 1: Check**

```bash
ls -la ~/dev/dotfiles/claude/.claude/statusline.sh
```

Expected: file exists. If not executable, run `chmod +x ~/dev/dotfiles/claude/.claude/statusline.sh`.

- [ ] **Step 2: Diff against the Nix one to confirm equivalence (optional)**

```bash
diff ~/dev/dotfiles/claude/.claude/statusline.sh ~/dev/dotfile/home-manager/modules/claude/statusline.sh
```

If significantly different, prefer the target's version (already there). Note any deltas in the execution log.

#### Task 3c.3: Commit

- [ ] **Step 1: Commit**

```bash
git -C ~/dev/dotfiles add claude/.claude/settings.json
git -C ~/dev/dotfiles commit -m "claude: replace settings.json with personal config (Trello/Alpaca env, no Jira)"
```

### Task 3d: mise — add aqua go-task and python default packages reference

**Files:**
- Modify: `~/dev/dotfiles/mise/.config/mise/config.toml`
- Modify: `~/dev/dotfiles/mise.toml`

#### Task 3d.1: Update `mise/.config/mise/config.toml`

- [ ] **Step 1: Overwrite `~/dev/dotfiles/mise/.config/mise/config.toml`** with:

```toml
[tools]
"aqua:go-task/task" = "latest"
python = "3.12"

[settings]
idiomatic_version_file_enable_tools = ["python"]
experimental = true

[settings.python]
default_packages_file = "~/.default-python-packages"
uv_venv_auto = true
```

#### Task 3d.2: Add `inject-claude-mcp` task to root `mise.toml`

- [ ] **Step 1: Read current root mise.toml**

```bash
cat ~/dev/dotfiles/mise.toml
```

- [ ] **Step 2: Append a new task block** at the end of `~/dev/dotfiles/mise.toml`:

```toml
[tasks.inject-claude-mcp]
description = "Merge MCP servers (gmail, google-calendar) into ~/.claude.json"
run = """
set -e
CLAUDE_JSON="$HOME/.claude.json"
MCP_JSON='{"gmail":{"command":"npx","args":["@gongrzhe/server-gmail-autoauth-mcp"]},"google-calendar":{"command":"npx","args":["@cocal/google-calendar-mcp"],"env":{"GOOGLE_OAUTH_CREDENTIALS":"'"$HOME"'/.gmail-mcp/gcp-oauth.keys.json"}}}'
if [ -f "$CLAUDE_JSON" ]; then
    jq --argjson mcp "$MCP_JSON" '.mcpServers = $mcp' "$CLAUDE_JSON" > "$CLAUDE_JSON.tmp" && mv "$CLAUDE_JSON.tmp" "$CLAUDE_JSON"
else
    jq -n --argjson mcp "$MCP_JSON" '{"mcpServers": $mcp}' > "$CLAUDE_JSON"
fi
echo "MCP servers injected into $CLAUDE_JSON"
"""
```

- [ ] **Step 3: Verify mise sees the task**

```bash
mise tasks --cwd ~/dev/dotfiles | grep inject-claude-mcp
```

Expected: a line containing `inject-claude-mcp`.

#### Task 3d.3: Commit

- [ ] **Step 1: Commit**

```bash
git -C ~/dev/dotfiles add mise/.config/mise/config.toml mise.toml
git -C ~/dev/dotfiles commit -m "mise: add aqua go-task, default_packages_file, and inject-claude-mcp task"
```

### Task 3e: python — port `.default-python-packages`

**Files:**
- Create: `~/dev/dotfiles/mise/.default-python-packages`

#### Task 3e.1: Add file under the `mise/` topic so stow links it to `$HOME/.default-python-packages`

- [ ] **Step 1: Create `~/dev/dotfiles/mise/.default-python-packages`** with:

```
# Neovim integration
pynvim

# lsp
pyright

# Code quality and formatting
ruff
mypy
isort
black
codespell

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
```

- [ ] **Step 2: Confirm stow doesn't ignore it**

```bash
grep -F '.default-python-packages' ~/dev/dotfiles/.stow-global-ignore
```

Expected: no output (i.e. file is NOT ignored). If found, that's a problem.

#### Task 3e.2: Commit

- [ ] **Step 1: Commit**

```bash
git -C ~/dev/dotfiles add mise/.default-python-packages
git -C ~/dev/dotfiles commit -m "mise: ship .default-python-packages alongside mise config"
```

---

## Phase 4 — Add new topics

### Task 4a: aws — credential helper scripts

**Files:**
- Create: `~/dev/dotfiles/aws/.local/bin/aws_cred_copy`
- Create: `~/dev/dotfiles/aws/.local/bin/copy_and_unset`

#### Task 4a.1: Create `aws_cred_copy`

- [ ] **Step 1: Write `~/dev/dotfiles/aws/.local/bin/aws_cred_copy`** with:

```bash
#!/bin/bash
mkdir -p ~/.aws
echo "[default]" > ~/.aws/credentials
echo "aws_access_key_id = $AWS_ACCESS_KEY_ID" >> ~/.aws/credentials
echo "aws_secret_access_key = $AWS_SECRET_ACCESS_KEY" >> ~/.aws/credentials
echo "aws_session_token = $AWS_SESSION_TOKEN" >> ~/.aws/credentials
unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN
```

- [ ] **Step 2: Mark executable**

```bash
chmod +x ~/dev/dotfiles/aws/.local/bin/aws_cred_copy
```

#### Task 4a.2: Create `copy_and_unset`

- [ ] **Step 1: Write `~/dev/dotfiles/aws/.local/bin/copy_and_unset`** with:

```bash
#!/bin/bash
~/.local/bin/aws_cred_copy
```

- [ ] **Step 2: Mark executable**

```bash
chmod +x ~/dev/dotfiles/aws/.local/bin/copy_and_unset
```

#### Task 4a.3: Wire the topic into `mise.toml` link/unlink

- [ ] **Step 1: Read current link task**

```bash
grep -nA 20 '\[tasks.link\]' ~/dev/dotfiles/mise.toml
```

Expected: a `run = "stow -R ..."` (or similar) listing every topic. **Capture the current list of topics.**

- [ ] **Step 2: Add `aws` to the topic list** in both `link` and `unlink` task `run` blocks (whatever syntax the task currently uses — typically `stow zsh nvim tmux ...`).

- [ ] **Step 3: Verify**

```bash
grep -F 'aws' ~/dev/dotfiles/mise.toml
```

Expected: at least one match.

#### Task 4a.4: Commit

- [ ] **Step 1: Commit**

```bash
git -C ~/dev/dotfiles add aws/.local/bin/aws_cred_copy aws/.local/bin/copy_and_unset mise.toml
git -C ~/dev/dotfiles commit -m "aws: new topic with credential-copy scripts; wire into mise tasks"
```

### Task 4b: lazygit — config

**Files:**
- Create: `~/dev/dotfiles/lazygit/.config/lazygit/config.yml`

#### Task 4b.1: Add config

- [ ] **Step 1: Write `~/dev/dotfiles/lazygit/.config/lazygit/config.yml`** with:

```yaml
gui:
  showFileTree: true
  mouseEvents: true
  showRandomTip: false
  theme:
    lightTheme: false
    activeBorderColor:
      - green
      - bold
    inactiveBorderColor:
      - white
    selectedLineBgColor:
      - blue
git:
  autoFetch: true
  autoRefresh: true
  commitLength:
    show: true
keybinding:
  universal:
    commitChanges: "C"
    pushFiles: "P"
    pullFiles: "p"
    refresh: "R"
    quit: "q"
  commits:
    copyCommitHash: "y"
```

#### Task 4b.2: Wire `lazygit` into mise link/unlink tasks

- [ ] **Step 1: Add `lazygit` to the topic list** in `mise.toml` (same edit pattern as Task 4a.3).

- [ ] **Step 2: Verify**

```bash
grep -F 'lazygit' ~/dev/dotfiles/mise.toml
```

Expected: at least one match.

#### Task 4b.3: Commit

- [ ] **Step 1: Commit**

```bash
git -C ~/dev/dotfiles add lazygit/.config/lazygit/config.yml mise.toml
git -C ~/dev/dotfiles commit -m "lazygit: new topic with custom theme + keybindings"
```

### Task 4c: rectangle — window manager config

**Files:**
- Create: `~/dev/dotfiles/rectangle/Library/Application Support/Rectangle/RectangleConfig.json`

#### Task 4c.1: Add Rectangle config

- [ ] **Step 1: Make the directory**

```bash
mkdir -p "$HOME/dev/dotfiles/rectangle/Library/Application Support/Rectangle"
```

- [ ] **Step 2: Write the config file** at `~/dev/dotfiles/rectangle/Library/Application Support/Rectangle/RectangleConfig.json` with:

```json
{
  "bundleId": "com.knollsoft.Rectangle",
  "defaults": {
    "SUEnableAutomaticChecks": { "bool": false },
    "allowAnyShortcut": { "bool": true },
    "alternateDefaultShortcuts": { "bool": true },
    "enhancedUI": { "int": 1 },
    "launchOnLogin": { "bool": true },
    "subsequentExecutionMode": { "int": 1 }
  },
  "shortcuts": {
    "bottomHalf":      { "keyCode": 125, "modifierFlags": 786432 },
    "bottomLeft":      { "keyCode": 38,  "modifierFlags": 786432 },
    "bottomRight":     { "keyCode": 40,  "modifierFlags": 786432 },
    "center":          { "keyCode": 8,   "modifierFlags": 786432 },
    "centerThird":     { "keyCode": 3,   "modifierFlags": 786432 },
    "firstThird":      { "keyCode": 2,   "modifierFlags": 786432 },
    "firstTwoThirds":  { "keyCode": 14,  "modifierFlags": 786432 },
    "larger":          { "keyCode": 24,  "modifierFlags": 786432 },
    "lastThird":       { "keyCode": 5,   "modifierFlags": 786432 },
    "lastTwoThirds":   { "keyCode": 17,  "modifierFlags": 786432 },
    "leftHalf":        { "keyCode": 123, "modifierFlags": 786432 },
    "maximize":        { "keyCode": 36,  "modifierFlags": 786432 },
    "maximizeHeight":  { "keyCode": 126, "modifierFlags": 917504 },
    "nextDisplay":     { "keyCode": 124, "modifierFlags": 1835008 },
    "previousDisplay": { "keyCode": 123, "modifierFlags": 1835008 },
    "rightHalf":       { "keyCode": 124, "modifierFlags": 786432 },
    "smaller":         { "keyCode": 27,  "modifierFlags": 786432 },
    "topHalf":         { "keyCode": 126, "modifierFlags": 786432 },
    "topLeft":         { "keyCode": 32,  "modifierFlags": 786432 },
    "topRight":        { "keyCode": 34,  "modifierFlags": 786432 }
  },
  "version": "92"
}
```

- [ ] **Step 3: Validate JSON**

```bash
jq . "$HOME/dev/dotfiles/rectangle/Library/Application Support/Rectangle/RectangleConfig.json" > /dev/null && echo OK
```

Expected: `OK`.

#### Task 4c.2: Wire `rectangle` into mise link/unlink

- [ ] **Step 1: Add `rectangle` to the topic list in `mise.toml`** (same pattern as Task 4a.3).

- [ ] **Step 2: Verify**

```bash
grep -F 'rectangle' ~/dev/dotfiles/mise.toml
```

Expected: at least one match.

#### Task 4c.3: Commit

- [ ] **Step 1: Commit**

```bash
git -C ~/dev/dotfiles add 'rectangle/Library/Application Support/Rectangle/RectangleConfig.json' mise.toml
git -C ~/dev/dotfiles commit -m "rectangle: new topic with halves/thirds/corner shortcuts"
```

---

## Phase 5 — 1Password and pre-cutover validation

### Task 5.1: 1Password authentication

- [ ] **Step 1: Confirm op CLI is on PATH**

```bash
command -v op && op --version
```

Expected: prints path and version.

- [ ] **Step 2: Add the user's account (interactive)**

```bash
op account add
```

The user enters their sign-in URL, email, secret key, and master password. Expected: `Account added.`

- [ ] **Step 3: Authenticate the session**

```bash
eval $(op signin)
```

Expected: shell exports `OP_SESSION_*` env vars; subsequent `op` commands work without password.

- [ ] **Step 4: Smoke test reads against required vaults**

```bash
op read 'op://Telophase QS/Trello API key/API key' >/dev/null && echo "TRELLO OK"
op read 'op://Private/Alpaca Paper Trading/Key' >/dev/null && echo "ALPACA OK"
op read 'op://Telophase QS/GCP ADC OAuth Client - tqs-dev/client_secret_821909658093-llr9utmgsb7u97nk4kv5679mtv2a2e60.apps.googleusercontent.com.json' >/dev/null && echo "GCLOUD OK"
```

Expected: three `OK` lines. If any fails, fix the vault item / path before continuing — the curated `aliases.zsh` and `claude/settings.json` reference these.

### Task 5.2: Snapshot environment for rollback evidence

- [ ] **Step 1: Snapshot installed brew packages**

```bash
brew list --formula | sort > /tmp/pre-cutover-formulae.txt
brew list --cask    | sort > /tmp/pre-cutover-casks.txt
wc -l /tmp/pre-cutover-formulae.txt /tmp/pre-cutover-casks.txt
```

Expected: both files non-empty.

- [ ] **Step 2: Snapshot key dotfiles**

```bash
mkdir -p /tmp/pre-cutover-snapshot
for f in ~/.zshrc ~/.zprofile ~/.zshenv ~/.tmux.conf ~/.gitconfig ~/.config/ghostty/config ~/.config/lazygit/config.yml ~/.config/mise/config.toml ~/.default-python-packages "$HOME/Library/Application Support/Rectangle/RectangleConfig.json"; do
  if [ -e "$f" ]; then cp -L "$f" /tmp/pre-cutover-snapshot/$(echo "$f" | tr '/' '_'); fi
done
ls /tmp/pre-cutover-snapshot/
```

Expected: a list of backed-up files. Used for diffing post-cutover if anything looks off.

### Task 5.3: Push `migrate-personal` to remote (review before merge)

- [ ] **Step 1: Push the working branch**

```bash
git -C ~/dev/dotfiles push -u origin migrate-personal
```

Expected: branch published. User can review the curation diff against `main` on GitHub before the cutover commits to it locally.

---

## Phase 6 — Cutover (single sitting)

The phase that actually replaces Nix with stow on this machine. Reserve time to do it without interruption — between Steps 6.1 and 6.4 the shell is in flux.

### Task 6.1: Pre-cutover sanity

- [ ] **Step 1: Confirm we're on the right branch and clean**

```bash
git -C ~/dev/dotfiles status
git -C ~/dev/dotfiles branch --show-current
```

Expected: clean tree, branch `migrate-personal`.

- [ ] **Step 2: Confirm `mise run brew-install` is idempotent (re-run, expect no install)**

```bash
cd ~/dev/dotfiles && mise run brew-install
```

Expected: `Homebrew Bundle complete!` with zero new installs.

### Task 6.2: Run Nix uninstall (answer `n` to "remove Homebrew?")

- [ ] **Step 1: Open a fresh Terminal/Ghostty window** (so you have a stable shell that already has `brew`, `mise`, `op` on PATH from the existing setup).

- [ ] **Step 2: Run the uninstall script**

```bash
bash ~/dev/dotfile/uninstall.sh
```

When prompted `Do you want to remove Homebrew? (y/n)` answer `n`. Read other prompts carefully; answer `y` to remove nix-darwin and home-manager symlinks.

Expected: script removes `~/.nix-defexpr`, the nix-darwin profile, the symlinks under `~/.config` that Nix activated, and `~/.zshrc`/`~/.tmux.conf` (replaced by stow next). Homebrew survives.

- [ ] **Step 3: Verify the nix store is gone but brew lives**

```bash
test -d /nix && echo "nix STILL PRESENT (problem)" || echo "nix removed"
command -v brew && command -v mise && command -v op
```

Expected: `nix removed`, plus three paths printed for brew/mise/op.

### Task 6.3: Stow-link the new dotfiles

- [ ] **Step 1: Run mise link task**

```bash
cd ~/dev/dotfiles && mise run link
```

Expected: per-topic stow output without conflicts. If a "would conflict with existing file" error appears for any path the user wants kept, manually move that file aside (e.g., `mv ~/.zshrc ~/.zshrc.preserved`) and rerun.

- [ ] **Step 2: Verify symlinks exist for each topic**

```bash
for f in ~/.zshrc ~/.tmux.conf ~/.gitconfig ~/.config/lazygit/config.yml ~/.config/mise/config.toml ~/.default-python-packages ~/.local/bin/aws_cred_copy ~/.local/bin/copy_and_unset ~/.config/ghostty/config ~/.claude/settings.json "$HOME/Library/Application Support/Rectangle/RectangleConfig.json" ~/.config/zsh/keybindings.zsh ~/.config/zsh/aliases.zsh; do
  if [ -L "$f" ]; then echo "LINK: $f"; elif [ -e "$f" ]; then echo "FILE (not link): $f"; else echo "MISSING: $f"; fi
done
```

Expected: every line `LINK:` (target file is a symlink into `~/dev/dotfiles/...`). Any `FILE (not link)` or `MISSING:` is a stow problem; resolve before proceeding.

### Task 6.4: Inject Claude MCP servers into `~/.claude.json`

- [ ] **Step 1: Run the new mise task**

```bash
cd ~/dev/dotfiles && mise run inject-claude-mcp
```

Expected: prints `MCP servers injected into /Users/justinramirez/.claude.json`.

- [ ] **Step 2: Verify**

```bash
jq '.mcpServers | keys' ~/.claude.json
```

Expected: `["gmail","google-calendar"]` (or similar — both keys present).

### Task 6.5: Inject 1Password secrets into Claude settings

- [ ] **Step 1: Run inject-secrets**

```bash
cd ~/dev/dotfiles && mise run inject-secrets
```

Expected: task completes without error. Note: this writes 1Password-resolved values into the live Claude settings; we already use `op://` URIs in the curated `settings.json`, so this primarily resolves any tokens the task is hardcoded to inject (e.g., Jira if applicable). Inspect the task definition if the output is unexpected.

---

## Phase 7 — Smoke tests / acceptance

Each step here corresponds to an item in the spec's "Acceptance criteria" section.

### Task 7.1: Acceptance smoke tests

- [ ] **Step 1: Open a brand-new shell (fresh ghostty window)** so all stow-linked configs load from scratch.

- [ ] **Step 2: Verify shell + prompt**

```bash
echo "$SHELL"
type spaceship_prompt 2>/dev/null | head -1
```

Expected: `/bin/zsh` (or whatever your login shell is); spaceship function defined.

- [ ] **Step 3: Verify git identity**

```bash
git config --global user.name
git config --global user.email
git config --global init.defaultBranch
```

Expected: `Justin Ramirez`, `ramirez.justin@gmail.com`, `develop`.

- [ ] **Step 4: Verify tmux opens cleanly**

```bash
tmux new -d -s smoke && tmux ls && tmux kill-session -t smoke
```

Expected: a session is created, listed, killed.

- [ ] **Step 5: Verify nvim opens with mothership.nvim**

```bash
nvim --headless +'echo g:colors_name' +qa 2>&1 | head
```

Expected: prints colorscheme name (any non-error output is acceptable here; specific behavior depends on mothership.nvim).

- [ ] **Step 6: Verify lazygit opens with custom theme** (interactive — quick visual check)

```bash
lazygit --version
```

Expected: prints lazygit version. Then open `lazygit` in a project, confirm the green-bold active border. Press `q` to quit.

- [ ] **Step 7: Verify aws + alias scripts**

```bash
aws --version
ls -la ~/.local/bin/aws_cred_copy ~/.local/bin/copy_and_unset
type awsdef awsprod awsdev | head
```

Expected: aws CLI version printed; both helper scripts exist as symlinks; aliases are defined.

- [ ] **Step 8: Verify gcloud and gke plugin**

```bash
gcloud --version
gcloud components list --format='value(id,state.name)' | grep gke-gcloud-auth-plugin
```

Expected: gcloud version printed; `gke-gcloud-auth-plugin Installed`.

- [ ] **Step 9: Verify Claude settings**

```bash
jq '.model, .env.TRELLO_BOARD_ID, .enabledPlugins | keys | length' ~/.claude/settings.json
```

Expected: `"opus"`, `"DyXW6UrW"`, and an integer count (14 for the curated set).

- [ ] **Step 10: Verify custom keybindings file is sourced**

```bash
zsh -i -c 'bindkey "^G"; bindkey "^[d"; bindkey "^[f"' 2>/dev/null
```

Expected: lines like `"^G" fzf-git-status`, `"^[d" fzf-cd-with-hidden`, `"^[f" forward-word`.

- [ ] **Step 11: Verify Rectangle config is in place**

```bash
ls -la "$HOME/Library/Application Support/Rectangle/RectangleConfig.json"
```

Expected: symlink. Then in Rectangle's Preferences → Shortcuts UI, confirm the J/K/U/I corner bindings are loaded. (Rectangle reads the JSON on launch; you may need to relaunch the app.)

- [ ] **Step 12: Verify ghostty config**

```bash
grep -E 'theme|background-opacity|palette' ~/.config/ghostty/config | head
```

Expected: shows `theme = Rose Pine`, `background-opacity = 0.9`, palette overrides.

- [ ] **Step 13: Verify 1Password reads still work in this session**

```bash
op read 'op://Telophase QS/Trello API key/API key' >/dev/null && echo OK
```

Expected: `OK`. If session expired, run `eval $(op signin)`.

- [ ] **Step 14: If anything failed**, rollback option: the original `~/dev/dotfile` directory is still on disk (we delete it in Phase 8). Re-running `~/dev/dotfile/install.sh` (or however the user originally installed Nix) is the rollback path. Document the failure, fix in `migrate-personal` or in a follow-up branch, push to remote, and rerun the relevant `mise run link` after `mise run unlink`.

---

## Phase 8 — Push and cleanup

### Task 8.1: Final gametime hygiene check

- [ ] **Step 1: Re-verify gametime branch**

```bash
git -C ~/dev/dotfiles fetch origin gametime:gametime
git -C ~/dev/dotfiles log --oneline gametime --not migrate-personal | head
```

Expected: a list of gametime-only commits (the work-specific content). If empty, `gametime` would be a strict subset of `migrate-personal` — that's a problem and means work content was lost. Investigate before merging to main.

### Task 8.2: Merge `migrate-personal` → `main` and push

- [ ] **Step 1: Merge**

```bash
git -C ~/dev/dotfiles checkout main
git -C ~/dev/dotfiles merge --no-ff migrate-personal -m "Merge migrate-personal: curate main as personal-only; remove work-specific content"
```

Expected: a clean merge commit.

- [ ] **Step 2: Push main**

```bash
git -C ~/dev/dotfiles push origin main
```

Expected: push accepts.

- [ ] **Step 3: Delete the working branch (optional)**

```bash
git -C ~/dev/dotfiles branch -d migrate-personal
git -C ~/dev/dotfiles push origin --delete migrate-personal
```

Expected: branch removed locally and remotely.

### Task 8.3: Remove the old Nix repo

- [ ] **Step 1: Final sanity — confirm we don't still source anything from `~/dev/dotfile`**

```bash
grep -rE '/dev/dotfile($|/)' ~/.zshrc ~/.config/zsh/keybindings.zsh ~/.config/zsh/aliases.zsh 2>/dev/null || echo "CLEAN"
```

Expected: `CLEAN`. Any hits → fix the references first.

- [ ] **Step 2: Delete**

```bash
rm -rf ~/dev/dotfile
```

Expected: directory gone.

- [ ] **Step 3: Final state check**

```bash
ls ~/dev/ | grep -E '^dotfile?'
```

Expected: only `dotfiles` (plural). `dotfile` (singular) is gone.

### Task 8.4: Optional — populate `~/.zshrc.local`

- [ ] **Step 1: Create or edit** `~/.zshrc.local` with any machine-specific exports/aliases that don't belong in the repo. Examples:
  - account-specific AWS ECR login alias
  - SDKMAN_DIR if the user uses SDKMAN
  - any `op read` line tied to vaults that are personal-only

```bash
nv ~/.zshrc.local
```

If empty, leave the file out — `.zshrc` already guards the source with `[[ -f ~/.zshrc.local ]]`.

---

## Self-review

Spec coverage check (against `2026-04-26-nix-to-stow-dotfiles-migration-design.md`):

- [x] Goal 1 (preserve behavior) → Tasks 3a.2/3a.3 (keybindings + aliases ports), 3b (git aliases), 4a/4b/4c (new topics), 7.10 (verify keybindings).
- [x] Goal 2 (curate `main`) → Task 3a.1 (zsh strip), 3b.1 (git identity), 3c.1 (claude env), 0.1 (gametime safety check).
- [x] Goal 3 (adopt new tooling) → Task 1.1 (clone with submodules), Phase 5 (1Password), Task 3d.2 (inject-claude-mcp).
- [x] Goal 4 (push curated `main`) → Task 5.3 (push migrate-personal for review), 8.2 (merge + push main).
- [x] Per-tool: zsh (3a), tmux (adopted from target — Task 1.1, no edit), git (3b), gh (aliases inside 3a.3), claude (3c), ghostty (no edit, Task 7.12 verifies), mise (3d), python (3e), aws (4a), gcloud (aliases in 3a.3 + Task 2.3 Step 3 plugin install), lazygit (4b), rectangle (4c), eza/marimo/gh-dash (adopted — Task 1.1).
- [x] Risk #1 (gametime hygiene) → Tasks 0.1, 8.1.
- [x] Risk #2 (gcloud parity) → Task 2.3 Step 3, Task 7.8.
- [x] Risk #3 (Nix uninstall side effects) → Task 6.2 explicitly answers `n` to Homebrew removal; Task 6.1 opens a fresh shell pre-cutover.
- [x] Risk #4 (Claude MCP merge) → Task 3d.2 + Task 6.4.
- [x] Risk #5 (Spaceship) → Task 2.3 Step 2 verifies brew install; Task 7.2 verifies prompt loads.
- [x] Risk #6 (path collisions) → Task 6.2 Step 1 instructs to start from a fresh shell.
- [x] Acceptance criteria — every item maps to a Task 7.* step.

Placeholder scan — no `TBD`, `TODO`, or "implement later" tokens; every step has concrete commands or content.

Type/identifier consistency — `aws_cred_copy` / `copy_and_unset` referenced in Tasks 4a.1, 4a.2 and called from `aliases.zsh` in Task 3a.3; `inject-claude-mcp` defined in Task 3d.2 and invoked in Task 6.4; `migrate-personal` branch consistent throughout.
