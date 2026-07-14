# Nix (home-manager) 移行 — 引き継ぎドキュメント

作成: 2026-07-05（Claude Code セットアップ監査セッションにて）
ステータス: **全4台で移行完了（2026-07-12）。** Mac（#1）、自宅サーバー x86_64 / thinkstation aarch64（#1）、会社機（#7）。settings.json の会社/個人プロファイル分離も完了（#4）。

## 運用メモ（移行完了後）

- 適用: 各マシンで `./setup.sh`。**会社機のみ** uname で判別できないため `./setup.sh hiroki-iida@work-linux` と明示指定
- settings.json は生成物（untracked）。変更は `settings.base.json` か `settings.{personal,work}.json` を編集して switch
- linux.nix の温存設定（JAVA_HOME/krew/JetBrains/aqua/keychain/alias 群）は会社機で全行使用中と確認済み（2026-07-12）。自宅サーバーでは空振りするが無害
- 旧 curl 版バイナリは 2026-07-12 に整理開始（~/.local/bin.old/ へ退避方式）。~/.local/share/mise はランタイム実体なので消さないこと

## 移行結果サマリ（2026-07-07）

- flake.nix + home/{common,darwin,linux}.nix + home/files/ を追加。Stow パッケージ bash/tmux/git/starship は削除、claude/agents/gemini は mkOutOfStoreSymlink の実体として存続
- setup.sh は「Nix 案内 + home-manager switch + AI CLI インストーラ」のみに縮小
- 適用コマンド: `nix run home-manager -- switch --flake ~/dotfiles#hiroki-iida@mac`(または `./setup.sh`)

### Mac 側の注意点

- tmux 設定は `~/.tmux.conf` から `~/.config/tmux/tmux.conf` に移動(home-manager 標準)
- macOS の /bin/bash(3.2) 非互換のため darwin では bash completion 無効(旧構成と等価)
- 旧 curl 版バイナリ(`~/.local/bin` の starship/zoxide/mise/uv、`~/.fzf`)は削除していない。PATH では `~/.local/bin` が nix-profile より先のため**当面 curl 版が優先される**。整理する場合は手動削除(要ユーザー判断)

### Phase 5(Linux 実機)の手順

1. `git remote set-url origin git@github.com:meshidenn/dotfiles.git` + ディレクトリ名を `~/dotfiles` に揃える(stow -D 全解除 → mv → clone し直しでも可)
2. flake.nix の `hiroki-iida@linux` の arch と homeDirectory を実機に合わせて修正
3. Determinate Nix インストール → `stow -D` 全解除 → `./setup.sh`
4. home/linux.nix の `TODO(Phase 5)` 各行(keychain/aqua/JAVA_HOME/krew/JetBrains/alias 群)を実機で取捨選択
5. 検証: 通知 hook(notify-send)、bash 起動エラーなし、PATH に他マシンの残骸がないこと

---

以下は移行前の計画資料(経緯の記録として保持)。

## ゴール

現在の GNU Stow + `setup.sh` による dotfiles 管理を **home-manager（standalone, flake）** に置き換え、macOS / Linux の2環境を宣言的に管理する。nix-darwin へは進まない（第1段階のスコープ外）。

## 背景（なぜやるか）

- この dotfiles は **macOS と Linux の両方**で使われている
- 2026-07 の監査で「OS 差分の手動管理」起因の実害が2件見つかった:
  1. 旧 Linux 機の `env.PATH`（`/home/hiroki/...`）が `claude/.claude/settings.json` に混入したまま Mac で使われていた
  2. 通知 hook が `notify-send`（Linux）前提で Mac では一度も動いていなかった → 現在は `command -v` による実行時分岐で暫定対応中（`settings.json` の hooks 参照）。home-manager なら OS 別モジュールで宣言的に出し分けできる

## 現状インベントリ（2026-07-05 時点）

### リポジトリ構成（Stow パッケージ）

```
dotfiles/            # 旧 setting_backup。GitHub も meshidenn/dotfiles にリネーム済み（2026-07-05）
├── agents/.agents/          # ★クロスエージェント正本: AGENTS.md + skills/(deep-research, git-issue-flow, retrospect)
├── claude/.claude/          # CLAUDE.md(→AGENTS.mdへのsymlink), settings.json, skills(→agents/skillsへのsymlink)
├── bash/                    # .bashrc, .bash_profile, .profile
├── tmux/.tmux.conf
├── git/.config/git/         # config, ignore
├── starship/.config/starship.toml
├── gemini/.gemini/          # ⚠️ 大半はランタイム状態。.gitignore で antigravity*/config/extensions を除外済み
├── setup.sh                 # ツール一括インストール + stow 実行 + ~/.codex/AGENTS.md symlink
└── docs/nix-migration.md    # 本ドキュメント
```

### ホーム側 symlink（Stow が張っているもの、計9本 + setup.sh 由来1本）

```
~/.agents            -> dotfiles/agents/.agents
~/.bash_profile      -> dotfiles/bash/.bash_profile
~/.bashrc            -> dotfiles/bash/.bashrc
~/.claude            -> dotfiles/claude/.claude
~/.gemini            -> dotfiles/gemini/.gemini
~/.profile           -> dotfiles/bash/.profile
~/.tmux.conf         -> dotfiles/tmux/.tmux.conf
~/.config/git        -> ../dotfiles/git/.config/git
~/.config/starship.toml -> ../dotfiles/starship/.config/starship.toml
~/.codex/AGENTS.md   -> ~/.agents/AGENTS.md   # setup.sh が作成（Stow 外）
```

### setup.sh がインストールしているツール（→ home.packages 化の対象）

stow, mise, starship, fzf, zoxide, uv, bun, gh(暗黙依存), jq(hookが依存, macOSは標準)
※ Claude Code / gemini-cli / kubectl(コメントアウト中) はインストーラ経由。Nix 化するかは判断に委ねる

### 守るべき設計原則（このリポジトリの不変条件）

1. **AGENTS.md 正本原則**: エージェント指示の正本は `.agents/AGENTS.md` の1ファイルのみ。`CLAUDE.md`・`~/.codex/AGENTS.md` 等はすべて symlink。移行後もこの構造を壊さない
2. **共通 skills** は `agents/.agents/skills/` が正本、`claude/.claude/skills` は symlink
3. `claude/` の .gitignore は whitelist 方式（`claude/**` を除外し CLAUDE.md / settings.json / skills のみ追跡）

## ⚠️ 最重要の落とし穴: 「書き込み可能であるべきディレクトリ」

home-manager の `home.file` は **nix store への read-only symlink** を張る。しかし以下は**実行時に書き込みが発生する**ため、store symlink にしてはいけない:

- `~/.claude` — Claude Code がセッションデータ（projects/, history.jsonl, shell-snapshots/ 等）を**この中に書き込む**。現状、これらは repo ディレクトリ内に実在し .gitignore で除外されている。丸ごと store 化すると Claude Code が壊れる
- `~/.gemini` — 同様にランタイム状態が書き込まれる
- `~/.agents` — skills を随時追加・編集する運用

**対処**: これらは `config.lib.file.mkOutOfStoreSymlink` で「repo 実体への書き込み可能 symlink」として張る（現在の Stow と同じ挙動を維持）。一方、`bashrc` / `tmux.conf` / `starship.toml` / `git config` は immutable でよいので通常の `home.file` / `programs.*` で管理してよい。

## 推奨ターゲット構成

```
flake.nix
  homeConfigurations."hiroki-iida@mac"    (aarch64-darwin)
  homeConfigurations."hiroki-iida@linux"  (x86_64-linux)  # 実機のarch要確認
home/
  common.nix     # packages, bash, tmux, starship, git, mkOutOfStoreSymlink群
  darwin.nix     # osascript 通知等の macOS 差分
  linux.nix      # notify-send 等の Linux 差分
```

- **mise は第1段階では残す**（Node/Python ランタイム管理の Nix 移行は第2段階）。`home.packages` と衝突しないよう、mise 管理のものを nix 側に入れない
- `claude/.claude/settings.json` の通知 hook: OS 別モジュールで文字列を出し分けて生成するか、現行の `command -v` 分岐のまま単一ファイルとして out-of-store 管理するか選択（後者が楽）
- bash 設定には旧 Linux 機の残骸（miniconda / JetBrains / krew / JAVA_HOME 等のパス）が残っている。移行時に **Linux 実機で必要なものだけ** `linux.nix` に移し、残りは捨てる好機

## 移行手順（推奨フェーズ）

1. **Phase 1**: flake + home-manager 導入（Mac 側）。Stow と並行稼働（home-manager はまず新規ファイルのみ管理し、既存 symlink と衝突させない）
2. **Phase 2**: immutable 系（bash/tmux/starship/git）を home-manager に移し、該当 Stow パッケージを `stow -D`
3. **Phase 3**: mutable 系（.claude/.agents/.gemini/.codex/AGENTS.md）を mkOutOfStoreSymlink 化。**Claude Code を起動してセッションデータ書き込み・skills 発火・hooks 動作を必ず確認**
4. **Phase 4**: setup.sh のツール群を home.packages へ。setup.sh は「nix + home-manager のブートストラップ」だけに縮小
5. **Phase 5**: Linux 実機で `hiroki-iida@linux` を適用し、通知 hook・PATH を検証。完了後 Stow / setup.sh の残骸を削除

## 検証チェックリスト

- [ ] `home-manager switch` 後、上記 symlink 10本がすべて正しい先を指す
- [ ] Claude Code: 新セッション起動 → skill 一覧に deep-research / git-issue-flow / retrospect が出る
- [ ] Claude Code: `.py` を Write すると ruff が走る／通知が出る（Mac: 通知センター、Linux: notify-send）
- [ ] `~/.claude/projects/` への書き込みができる（read-only になっていない）
- [ ] Codex: `~/.codex/AGENTS.md` から共通指示が読める
- [ ] Linux 側: bash 起動エラーなし、starship/zoxide/fzf/mise が動く

## 関連コンテキスト

- 監査時のプラン全文: `~/.claude/plans/claude-code-pc-jiggly-seahorse.md`
- Claude Code の memory にも構成メモあり（agents-md-single-source / dotfiles-stow-layout）
- Linux 機ではリモート URL の更新が必要: `git remote set-url origin git@github.com:meshidenn/dotfiles.git`（旧 URL もリダイレクトで当面は動く）。ローカルディレクトリ名も `~/dotfiles` に揃えるなら「stow -D 全解除 → mv → 再 stow」の順で
