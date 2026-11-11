# Agent Instructions
<!-- 正本: ~/.agents/AGENTS.md（dotfiles: agents/.agents/AGENTS.md）
     ~/.claude/CLAUDE.md や ~/.codex/AGENTS.md はこのファイルへの symlink。編集は必ずここで行う。 -->
# Claude Code, OpenAI Codex, Gemini CLI など複数のAIエージェントで共通の指示

## Communication
- Always respond in Japanese
- Write code comments in Japanese
- Technical terms can remain in English

## Coding Style
- Follow existing code style when modifying existing code
- For new or early-stage projects: write readable code with proper hierarchy, naming, and separation of concerns
- Primary language: Python

## Commit Granularity
- One commit per logical unit: "one reason to change" = one commit
- Split unrelated changes: bug fix + new feature → 2 commits, script + unrelated config → 2 commits

## Git Rules
- Commit message format: `#<issue_number> <type>:<descriptive_words>`
  - type: fix, add, del, update, refactor, etc.（例: `#12 add:max_retries_param`）
- Branch naming: `{project_name or feature/exp}/<issue_number>-<descriptive-words>`
  - 例: `feature/12-add-retry-logic`。既存リポジトリに規約があればそちらを優先
- Issue が不要な作業でブランチやコミットを作る場合は、issue number を省略する。コミットメッセージは `<type>:<descriptive_words>`（例: `update:review_metadata`）、ブランチ名は `{project_name or feature/exp}/<descriptive-words>`（例: `dso-knowledge-base/review-paper`）とする。

## Strict Rules (MUST follow)
- NEVER push without explicit approval
- Refactoring: only when instructed, or propose and wait for approval
- Always run tests and verify behavior (except physically impossible cases like LLM inference)
- ALWAYS present a Plan before implementation, get approval, then execute in Phases

## Forbidden File Operations
- NEVER commit or edit `.env` files
- NEVER delete large data directories (`outputs/`, `containers/`, `dataset/`) without explicit approval
