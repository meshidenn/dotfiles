{ pkgs, ... }:

{
  # ============================================================
  # 旧 Linux 機の .bashrc から移植した会社機向け設定(2026-07-12 全行使用中と確認済み)。
  # 旧 .bashrc のハードコード PATH(miniconda / /home/hiroki/... 直書き)は
  # 復元せず削除済み。必要なら git 履歴(bash/.bashrc)から辿れる。
  # ============================================================

  # keychain による ssh-agent 共有(会社機で使用)
  home.packages = with pkgs; [ keychain ];

  programs.bash = {
    shellAliases = {
      # 会社機で使用中の alias
      idea = "intellij-idea-ultimate";
      alert = "notify-send --urgency=low -i \"$([ $? = 0 ] && echo terminal || echo error)\" \"$(history|tail -n1|sed -e 's/^\\s*[0-9]\\+\\s*//;s/[;&|]\\s*alert$//')\"";
      login01 = "gcloud compute ssh bastion --project speeda-193900 --zone asia-northeast1-a";
    };
    initExtra = ''
      # 以下はすべて会社機で使用中(2026-07-12 確認済み)。自宅サーバーでは空振りするが無害

      # aqua グローバル設定(skaffold など)
      export AQUA_GLOBAL_CONFIG="''${XDG_CONFIG_HOME:-$HOME/.config}/aquaproj-aqua/aqua.yaml"
      export PATH="''${AQUA_ROOT_DIR:-''${XDG_DATA_HOME:-$HOME/.local/share}/aquaproj-aqua}/bin:$PATH"

      # SSH agent (keychain) — 1回パスフレーズを入れたら使い回す
      # 鍵がこのマシンに存在するときだけ動かす(ホームサーバー等には鍵がない)
      if [ -f ~/.ssh/id_ub_ed25519 ] && command -v keychain &>/dev/null; then
          eval "$(keychain --eval --quiet ~/.ssh/id_ub_ed25519)"
      fi

      # Java / krew / JetBrains Toolbox
      export JAVA_HOME="$HOME/.jdks/corretto-21.0.3"
      export PATH="''${KREW_ROOT:-$HOME/.krew}/bin:''${JAVA_HOME}/bin:$PATH"
      export PATH="''${HOME}/.local/share/JetBrains/Toolbox/scripts:$PATH"

      # kubectl / skaffold の補完
      command -v skaffold &>/dev/null && source <(skaffold completion bash)
      command -v kubectl &>/dev/null && source <(kubectl completion bash) && complete -o default -F __start_kubectl k
    '';
  };
}
