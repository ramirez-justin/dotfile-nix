# Nix → Stow Dotfiles Migration (personal Mac, `main` branch)

**Date:** 2026-04-26
**Source:** `~/dev/dotfile` (nix-darwin + home-manager + Homebrew)
**Target:** `ramirez-justin/dotfiles` `main` branch (GNU Stow + mise + Homebrew + 1Password CLI), cloned to `~/dev/dotfiles`
**Scope:** Personal Mac (`Macmini-localdomain`). Work machine uses `gametime` branch — out of scope but its safety must be preserved when curating `main`.

## Goal

Replace the Nix-managed home environment on this machine with the stow-based dotfiles, while:

1. Keeping every behavior the user actually relies on today (custom keybindings, aliases, prompts, prompts).
2. Curating the `main` branch so it is genuinely personal-only — no Snowflake/Terragrunt/DBT/gametime/Jira/work email content.
3. Adopting the new tooling target offers (richer tmux, gh-dash, eza-themes, 1Password-driven secrets, marimo).
4. Pushing the curated `main` to GitHub so the convention holds for future personal machines.

## Non-goals

- Migrating the work machine. `gametime` branch stays untouched.
- Re-platforming to a non-stow scheme.
- Refactoring the target repo's structure beyond adding new topics and curating files.

## Migration sequence (staged, then swap)

1. **Stage** — clone target to `~/dev/dotfiles`, create branch `migrate-personal` off `main`. Curate, add new topics, validate via inspection. No symlinks yet.
2. **Brewfile reconciliation** — diff current `darwin/homebrew.nix` against target `Brewfile`; everything Nix-installed today (eza, fd, ripgrep, fzf, mise, neovim, tmux, zoxide, lazygit, etc.) must be present in `Brewfile` after Nix is gone. Add missing entries. Run `mise run brew-install` (additive — does not conflict with Nix yet).
3. **1Password bootstrap** — `op account add`; verify `op read` works against the relevant vaults. Run `mise run inject-secrets`.
4. **Cutover (single sitting)** — run `~/dev/dotfile/uninstall.sh`. The script asks `Do you want to remove Homebrew? (y/n)` — **answer `n`** so Homebrew, mise, and the Brewfile-installed tools survive. The script removes nix-darwin, home-manager, the nix store, and the symlinks/files written by Nix activation (`~/.config/mise/config.toml`, `~/.default-python-packages`, `~/.claude/`, `~/.config/lazygit/config.yml`, `~/Library/Application Support/Rectangle/RectangleConfig.json`, `~/.tmux.conf`, etc.) — that's intentional, since stow will replace them. Then `mise run link`. Open a fresh shell. Smoke-test shell, prompt, tmux, git identity, nvim, claude, gcloud, aws, lazygit.
5. **Cleanup** — once the machine is happy, delete `~/dev/dotfile`. Merge `migrate-personal` → `main` locally, push `main`. Confirm `gametime` still has all the work-specific content it needs (see "Branch hygiene" below).

## Per-tool decisions

### Tools where target wins outright

- **tmux** — adopt `tmux/.config/tmux/tmux.conf` from target. Adds sessionx, floax, tmux-thumbs, tmux-fzf-url, fzf integrations, status-position top, prefix `C-Space`, history-limit 1M, renumber-windows. Requires the `tmux.reset.conf` companion file to exist. Drop the Nix `tmux2k`/older config.
- **ghostty** — adopt target's config. Same fonts/Rose Pine, but with palette tweaks (`#31748f`, `#9ccfd8`), `background-opacity = 0.9`, `selection-background = #403d52`. Note target uses `\` for `new_split:right` (current uses `/`); accept target's mapping.
- **eza** — adopt the topic and the eza-themes git submodule. Set `EZA_CONFIG_DIR=~/.config/eza` in zshrc.
- **gh-dash** — adopt as-is.
- **marimo** — adopt as-is (user uses it).

### Tools where structure is target's, content is curated

- **zsh** — start from target's `zsh/.zshrc`/`.zshenv`/`.zprofile`. On `migrate-personal`:
  - Remove: Snowflake helpers (`set_snowflake_creds`, all `tg*_staging`/`tg*_prod`, `snowsql_*`), DBT aliases (`setup_dbt`, `defer_dbt_*`), `resync_airflow_*`, `aws-vault exec justin.ramirez`, `tg_clean_output`, ruby/rbenv lines, Julia path, `TENV_GITHUB_TOKEN` (or move to `~/.zshrc.local`).
  - Keep: spaceship, syntax-highlighting, autosuggestions sourcing; oh-my-zsh plugin list; `~/.zshrc.local` source line; mise/fzf/direnv/op/zoxide eval; eza/EZA_CONFIG_DIR.
  - Add (port from `home-manager/modules/zsh.nix`): `fzf-git-status` widget bound to `^G`, `fzf-cd-with-hidden` bound to `^[d`, ALT-f/b word nav, `^U` line clear, ALT-Up/Down dirhistory, `^[^?` ALT-backspace word delete, `code $(fzf)` on `^_`. Keep zoxide Claude-Code carve-out (`CLAUDECODE != 1`).
  - Path: place keybindings/widgets in `zsh/.config/zsh/keybindings.zsh`; source it from `.zshrc`. Keeps `.zshrc` readable.

- **git** — start from target's `git/.gitconfig`. On `migrate-personal`:
  - Replace `user.name = jramirez` / `user.email = justin.ramirez@gametime.co` with `Justin Ramirez` / `ramirez.justin@gmail.com`.
  - Add `init.defaultBranch = develop`.
  - Add `[alias]` block from `git.nix`: `st`, `ci`, `br`, `co`, `df`, `lg` (the formatted graph log).
  - Keep target's `push.autoSetupRemote`, `pull.rebase`, `core.editor = nvim`, `fetch.prune`.
  - Port shell aliases (`gp`, `gl`, `gs`, `gd`, `gpush`, `gpushf`, `gpushnew`, `gare`, `gre`, `gcan`, `gfa`, `gfap`, `lg = lazygit`) and the `gitdefaultbranch` function into the curated zsh aliases file.
  - Add `[core] excludesfile = ~/.config/git/ignore` and ship the global ignore list (`.DS_Store`, `*.swp`, `.env`, `.direnv`, `node_modules`, `.vscode`, `.idea`).

- **gh** — adopt target's `gh/.config/gh/` shape. Layer the personal hosts/auth in via `gh auth login` after install. Port the 17 functions/aliases from `github.nix` (`ghpr`, `ghprall`, `ghpropen`, `ghopr`, `ghprcheck`, `ghprco` and the `ghprcr`/`ghprv`/`ghprl`/`ghpro`/`ghprc`/`ghprch`/`ghrv`/`ghrc`/`ghrf`/`ghil`/`ghic`/`ghiv`/`ghrl`/`ghrw`/`ghrs`/`ghis`/`ghps` aliases) into the curated zsh aliases file.

- **claude** — start from target's `claude/.claude/`. Replace `settings.json` with the personal-curated version derived from `home-manager/modules/claude/default.nix`:
  - `model = "opus"`, `autoCompact = false`, `autoCompactEnabled = false`, `includeCoAuthoredBy = false`.
  - `env`: `CLAUDE_CODE_SUBAGENT_MODEL = "sonnet"`, `TRELLO_API_KEY` / `TRELLO_TOKEN` / `TRELLO_BOARD_ID`, `ALPACA_API_KEY` / `ALPACA_API_SECRET` / `ALPACA_PAPER`, `ENABLE_LSP_TOOL = 1`. **Remove** Jira/gametime entries from target.
  - `hooks.Stop = [{ hooks: [{ type: "command", command: "afplay /System/Library/Sounds/Submarine.aiff" }] }]`.
  - `statusLine = { type: "command", command: "$HOME/.claude/statusline.sh" }`.
  - `enabledPlugins`: union of target's set and current's set, minus anything Jira/gametime-specific (keep workflow, alpaca, ruff-lsp, bash-ls, docker-ls, markdown-oxide, vim-ls, yaml-ls, pyright-lsp, lua-lsp, code-review, skill-creator, superpowers, trello). Add target-only ones (Playwright, dbt LSP) only if user uses them on personal.
  - Keep target's `statusline.sh`; if it's identical to current's, no action needed; otherwise diff and pick.
  - **MCP servers** (`gmail`, `google-calendar`) currently merged into `~/.claude.json` by Nix activation. Replace with a `mise run inject-claude-mcp` task that runs `jq --argjson mcp '<json>' '.mcpServers = $mcp' ~/.claude.json`. Wire into the `bootstrap` and `link` flows.

- **mise** — start from target's `mise/.config/mise/config.toml`. Add `aqua:go-task/task = latest` to `[tools]`, and `default_packages_file = "~/.default-python-packages"` under `[settings.python]`. Keep target's `idiomatic_version_file_enable_tools`, `experimental`, `uv_venv_auto`.

- **python (default packages)** — add `python/.default-python-packages` topic (or place under `mise/`) with the list from `home-manager/modules/python.nix`: pynvim, pyright, ruff, mypy, isort, black, codespell, ipython, pip-tools, wheel, setuptools, pytest, pytest-cov, requests, click.

### New topics (port from current Nix)

- **aws** — new `aws/` topic. Stow the credential helper scripts to `~/.local/bin/`:
  - `aws_cred_copy` — writes env-var creds into `~/.aws/credentials` then unsets the env vars.
  - `copy_and_unset` — wrapper that just calls `aws_cred_copy`.
  - Aliases (`awsdef`, `awsprod`, `awsdev`) go into the curated zsh aliases file (each does `osascript -e 'tell application "System Events" to keystroke "k" using command down' && ~/.local/bin/copy_and_unset <profile>`).
  - Export `AWS_DEFAULT_REGION=us-west-2` and `AWS_REGION=us-west-2` from zshrc (or `~/.zshrc.local` if the value should be machine-specific).
  - Brewfile must include `awscli`, `aws-vault-binary`, `session-manager-plugin` (already there).

- **gcloud** — Brewfile already lacks Google Cloud SDK; add the `google-cloud-sdk` cask + run `gcloud components install gke-gcloud-auth-plugin` once after install (acceptable in Brew, blocked under Nix). Aliases go into curated zsh aliases:
  - `gauth`, `gauthuser`, `gauthapp` — these read from 1Password (`op read 'op://Telophase QS/GCP ADC OAuth Client …'`); confirm vault item still exists.
  - `gauthls`, `gauthinfo`, `gcl`, `gcs`, `gci`, `gpl`, `gps`.
  - Export `USE_GKE_GCLOUD_AUTH_PLUGIN=True`. Source `path.zsh.inc` from gcloud SDK install path: `source "$(brew --prefix)/share/google-cloud-sdk/path.zsh.inc"`.

- **lazygit** — new `lazygit/.config/lazygit/config.yml` topic, port the YAML from `home-manager/modules/lazygit.nix` verbatim (theme, gui.showFileTree, mouseEvents, autoFetch, autoRefresh, custom keybindings `C`/`P`/`p`/`R`/`q`, `commits.copyCommitHash = y`).

- **rectangle** — new `rectangle/Library/Application Support/Rectangle/RectangleConfig.json` topic. Stow links it into `~/Library/Application Support/Rectangle/`. Content is the JSON from `home-manager/modules/rectangle.nix` verbatim. Brewfile must include `rectangle` cask.

### Aliases

User wants to **curate during port**. We will:

1. Read `home-manager/aliases.nix` (~19k) end to end.
2. Group into: System (rebuild/update/cleanup — drop, replaced by `mise run *`), Navigation (eza/bat/fd/zoxide — keep), Dev tools (nv, lg, tf, d, dc — keep), AWS (covered above), GCloud (covered above), Git/Github (covered above), and Misc.
3. Write the kept ones to `zsh/.config/zsh/aliases.zsh`. Source from `.zshrc`.
4. Anything machine-specific (e.g., AWS account-specific ECR login) goes into `~/.zshrc.local` — out of repo.

### Tools dropped

- **karabiner** — user no longer uses.

## Brewfile reconciliation

To enumerate during implementation. Approach:

```bash
diff <(brew list --formula | sort) <(grep '^brew' ~/dev/dotfiles/Brewfile | sed 's/.*"\(.*\)".*/\1/' | sort)
```

Plus we explicitly need: `google-cloud-sdk` cask, `rectangle` cask, and any current Nix package that has no Brewfile entry. The exact delta is enumerated during the implementation plan after diffing `darwin/homebrew.nix` and `home-manager/default.nix` `home.packages` against the target `Brewfile`.

## Secrets / 1Password

- `~/.zshrc.local` is created post-link with machine-specific exports (e.g., AWS account-specific aliases).
- `mise run inject-secrets` writes 1Password-resolved values into Claude `settings.json`. We will keep the design that Claude settings reference `op://` URIs and Claude Code resolves at runtime — that path is already supported by current Nix config, so no change.
- Confirm vaults `Telophase QS`, `Private`, `employee` exist before bootstrap.

## Risks

1. **`gametime` branch divergence.** Curating `main` removes work-specific content. Before pushing curated `main`, verify `git -C ~/dev/dotfiles log gametime --not main` shows the work content already committed on `gametime` (Snowflake/Terragrunt/DBT/Jira env/work email/etc.). If anything lives only on `main`, cherry-pick to `gametime` first.
2. **gcloud parity.** Nix's `withExtraComponents` versus Brew + `gcloud components install gke-gcloud-auth-plugin`. Smoke-test with `gcloud container clusters get-credentials` before declaring done.
3. **Nix uninstall side effects.** `uninstall.sh` removes the Nix store, `~/.nix-defexpr`, etc. Open a new shell after; old shell will have stale paths. The script also prompts to remove Homebrew — we always answer `n`.
4. **Claude `~/.claude.json` MCP merge.** Without Nix activation hook, MCP servers must be re-injected via `mise run` task. Add this task or accept manual one-shot.
5. **Spaceship prompt.** Both setups use Homebrew's `spaceship`. After uninstalling Nix, the prompt sourcing in `.zshrc` (`source $(brew --prefix)/opt/spaceship/spaceship.zsh`) must still resolve. Verify spaceship is installed via Brewfile (it is — formula `spaceship` is listed).
6. **Path collisions during cutover.** Between `uninstall.sh` and `mise run link`, the shell may have neither config. Plan to do cutover from a known-good shell that has `mise` and `brew` on PATH (Homebrew is left intact by `uninstall.sh`).

## Acceptance criteria

After cutover and a fresh shell:

- `which zsh` returns the system shell, prompt is Spaceship.
- `git config user.email` returns `ramirez.justin@gmail.com`.
- `tmux` opens with sessionx/floax bindings working.
- `nv` (nvim) opens the `mothership.nvim` submodule config (LazyVim-derived).
- `lg` (lazygit) opens with custom theme.
- `aws --version` works; `awsdef`/`awsprod`/`awsdev` aliases exist.
- `gcloud --version` works; `gauthls` runs.
- `claude` reads `~/.claude/settings.json` and shows the curated plugins.
- `op read 'op://...'` succeeds for at least one item (verifies 1Password CLI auth).
- Custom keybindings work: `^G` (fzf-git-status), `^[d` (fzf-cd-with-hidden), ALT-f/b (word nav).
- Rectangle keybindings work (Cmd+Opt+Arrow halves, etc.).
- `~/dev/dotfile` is gone; `~/dev/dotfiles` is the only dotfiles repo.
- `git -C ~/dev/dotfiles status` is clean and on `main`. `gametime` branch unchanged on origin.

## Open questions deferred to implementation plan

- Exact Brewfile delta (requires running diff against current `nix-darwin` package list).
- Exact list of plugins to keep in `claude/settings.json` (union vs subset).
- Whether `~/.zshrc.local` template should be checked in as `~/.zshrc.local.template`.
