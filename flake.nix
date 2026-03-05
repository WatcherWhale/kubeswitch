{
  outputs =
    {
      self,
      nixpkgs,
      flake-parts,
      devenv,
      gomod2nix,
      ...
    }@inputs:
    flake-parts.lib.mkFlake { inherit inputs; } (
      { ... }:
      {
        imports = [
          flake-parts.flakeModules.easyOverlay
          devenv.flakeModule
        ];

        systems = nixpkgs.lib.systems.flakeExposed;

        perSystem =
          {
            config,
            pkgs,
            system,
            ...
          }:
          {
            overlayAttrs = {
              inherit (config.packages) kubeswitch;
            };

            packages.default = config.packages.kubeswitch;

            packages.kubeswitch = gomod2nix.legacyPackages."${system}".buildGoApplication {
              pname = "kubeswitch";
              version = "0.0.0";

              src = "${self}";
              pwd = "${self}";
              modules = "${self}/gomod2nix.toml";

              meta = {
                mainProgram = "kubeswitch";
              };

              ldflags = [
                "-w"
                "-s"
              ];

              subPackages = [ "cmd" ];
              nativeBuildInputs = [ pkgs.installShellFiles ];

              postInstall = ''
                mv $out/bin/cmd $out/bin/switcher
                for shell in bash zsh fish; do
                  $out/bin/switcher --cmd switcher completion $shell > switcher.$shell
                  installShellCompletion --$shell switcher.$shell
                done
              '';

            };

            devenv.shells.default = {
              packages = with pkgs; [
                go
                gotools
                golangci-lint
                gnumake
                gomod2nix.packages."${system}".default
              ];
            };
          };
      }
    );

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";

    flake-parts = {
      url = "github:hercules-ci/flake-parts";
    };

    devenv = {
      url = "github:cachix/devenv";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    gomod2nix = {
      url = "github:nix-community/gomod2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

}
