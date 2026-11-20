# dotfiles

home-manager (standalone flake) を使った dotfiles 管理(macOS / Linux 両対応)

## セットアップ

```bash
# 1. Nix (Determinate Systems 版) — admin 権限が必要
curl -fsSL https://install.determinate.systems/nix | sh -s -- install

# 2. clone して適用
git clone git@github.com:meshidenn/dotfiles.git ~/dotfiles
cd ~/dotfiles
./setup.sh   # home-manager switch + AI CLI 群のインストール
```

## 構成

```
dotfiles/
├── flake.nix          # homeConfigurations: hiroki-iida@mac / hiroki-iida@linux
├── home/
│   ├── common.nix     # packages, bash, tmux, starship, git, mutable symlink 群
│   ├── darwin.nix     # macOS 差分
│   ├── linux.nix      # Linux 差分(Phase 5 で実機検証予定)
│   └── files/         # starship.toml, git ignore などの素材
├── agents/.agents/    # クロスエージェント正本: AGENTS.md + 共通 skills
├── claude/.claude/    # Claude Code 設定(~/.claude の実体)
├── gemini/.gemini/    # Gemini CLI 設定(~/.gemini の実体)
└── docs/              # nix-migration.md(移行の経緯と Linux 側手順)
```

- **設定変更は `home/*.nix` を編集して switch**(~/.bashrc 等の直接編集は不可。store 管理のため)
- `~/.claude` `~/.agents` `~/.gemini` は書き込み可能な out-of-store symlink(store symlink 化は厳禁)

## 手動で switch する場合

```bash
nix run home-manager -- switch --flake ~/dotfiles#hiroki-iida@mac    # Mac
nix run home-manager -- switch --flake ~/dotfiles#hiroki-iida@linux  # Linux
```

## 管理されるツール

| ツール | 管理 |
|--------|------|
| [mise](https://mise.jdx.dev/) / [starship](https://starship.rs/) / [fzf](https://github.com/junegunn/fzf) / [zoxide](https://github.com/ajeetdsouza/zoxide) / [uv](https://github.com/astral-sh/uv) / bun / gh / jq | home-manager (`home/common.nix`) |
| [Claude Code](https://claude.ai/claude-code) / Codex / Antigravity CLI | setup.sh(自己アップデート機構があるため Nix 管理外) |
| Claude Code plugins([anthropics/skills](https://github.com/anthropics/skills) / [anthropics/knowledge-work-plugins](https://github.com/anthropics/knowledge-work-plugins) 等の marketplace) | `claude/.claude/settings.base.json` の `extraKnownMarketplaces` / `enabledPlugins` |
