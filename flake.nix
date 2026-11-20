{
  description = "hiroki-iida dotfiles — home-manager (standalone flake)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Codex 用スキルの取得元(flake ではなくソースとして取り込み、flake.lock で版を固定)
    # 更新: nix flake update anthropic-skills knowledge-work-plugins
    anthropic-skills = {
      url = "github:anthropics/skills";
      flake = false;
    };
    knowledge-work-plugins = {
      url = "github:anthropics/knowledge-work-plugins";
      flake = false;
    };
  };

  outputs = inputs@{ nixpkgs, home-manager, ... }:
    let
      # ユーザー名・home ディレクトリ・OS 差分モジュールを環境ごとに指定する
      mkHome = { system, username, homeDirectory, modules }:
        home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.${system};
          # モジュールから flake input(スキル取得元)を参照できるようにする
          extraSpecialArgs = { inherit inputs; };
          modules = [
            {
              home.username = username;
              home.homeDirectory = homeDirectory;
            }
          ] ++ modules;
        };
    in
    {
      homeConfigurations."hiroki-iida@mac" = mkHome {
        system = "aarch64-darwin";
        username = "hiroki-iida";
        homeDirectory = "/Users/hiroki-iida";
        modules = [ ./home/common.nix ./home/darwin.nix ];
      };

      # Linux は arch 違いの実機が複数あるため両方定義(setup.sh が uname -m で自動選択)
      homeConfigurations."hiroki@linux" = mkHome {
        system = "x86_64-linux";
        username = "hiroki";
        homeDirectory = "/home/hiroki";
        modules = [ ./home/common.nix ./home/linux.nix ];
      };
      homeConfigurations."hiroki@linux-aarch64" = mkHome {
        system = "aarch64-linux";
        username = "hiroki";
        homeDirectory = "/home/hiroki";
        modules = [ ./home/common.nix ./home/linux.nix ];
      };

      # 会社 Linux 機。uname では個人サーバーと区別できないため
      # setup.sh の引数で明示指定する: ./setup.sh hiroki-iida@work-linux
      homeConfigurations."hiroki-iida@work-linux" = mkHome {
        system = "x86_64-linux";
        username = "hiroki-iida";
        homeDirectory = "/home/hiroki-iida";
        modules = [
          ./home/common.nix
          ./home/linux.nix
          { dotfiles.claudeSettingsProfile = "work"; }
        ];
      };
    };
}
