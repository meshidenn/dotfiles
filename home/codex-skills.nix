{ lib, inputs, ... }:

# Codex(OpenAI)向けに Anthropic 公式スキルを ~/.codex/skills へ配置する。
#
# Claude Code 側は marketplace(settings.base.json)で同じスキル群を有効化している。
# Codex 側でプラグインとして入れない理由:
#   - anthropics/skills は plugin の source がリポジトリ直下のため、Codex では全スキルが入ってしまう
#   - knowledge-work-plugins は .mcp.json を同梱しており、Codex 既存のコネクタ(slack/github 等)と重複する
# ~/.agents/skills は ~/.claude/skills と同一実体のため、Claude 側との重複を避けて Codex 専用の場所に置く。
# Codex は親ディレクトリ名で名前空間を付ける(例: productivity:task-management)。
let
  anthropicSkills = inputs.anthropic-skills;
  knowledgeWork = inputs.knowledge-work-plugins;

  # anthropics/skills から入れるもの(example-skills + claude-api 相当)
  # 除外: skill-creator(Codex system skill と重複), webapp-testing(browser/chrome プラグインと重複),
  #       docx/pdf/pptx/xlsx(documents/pdf/presentations/spreadsheets プラグインと重複)
  anthropicSkillNames = [
    "algorithmic-art"
    "brand-guidelines"
    "canvas-design"
    "doc-coauthoring"
    "frontend-design"
    "internal-comms"
    "mcp-builder"
    "slack-gif-creator"
    "theme-factory"
    "web-artifacts-builder"
    "claude-api"
  ];

  # engineering から入れるもの
  # 除外: code-review(Codex system skill の review-agent / codex review と重複)
  engineeringSkillNames = [
    "architecture"
    "debug"
    "deploy-checklist"
    "documentation"
    "incident-response"
    "standup"
    "system-design"
    "tech-debt"
    "testing-strategy"
  ];

  # スキル名の一覧から home.file の定義を作る
  linkSkills = targetDir: sourceDir: names:
    lib.listToAttrs (map
      (name: lib.nameValuePair ".codex/skills/${targetDir}/${name}" {
        source = "${sourceDir}/${name}";
      })
      names);
in
{
  home.file =
    linkSkills "anthropic" "${anthropicSkills}/skills" anthropicSkillNames
    // linkSkills "engineering" "${knowledgeWork}/engineering/skills" engineeringSkillNames
    // {
      # productivity / data は全スキルが重複なしのため skills ディレクトリごと置く
      # (productivity の start が参照する dashboard.html も同じ場所に入る)
      ".codex/skills/productivity".source = "${knowledgeWork}/productivity/skills";
      ".codex/skills/data".source = "${knowledgeWork}/data/skills";
    };
}
