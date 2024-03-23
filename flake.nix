{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    ...
  } @ inputs:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = nixpkgs.legacyPackages.${system};

      commonPackages = [
        pkgs.mdbtools
        pkgs.vips.bin
        pkgs.vips.dev
        pkgs.vips.devdoc
        pkgs.vips.out
        pkgs.vips.man
        pkgs.pkg-config

        pkgs.gnumake
        pkgs.python311
        pkgs.clang_9
        pkgs.glibc
        pkgs.gcc

      ];
    in {
      devShells.default = pkgs.mkShell {
        buildInputs = with pkgs; [
          alejandra
        ];
      };

      devShells.node = pkgs.mkShell {
        buildInputs = with pkgs; [
          nodejs
        ] ++ commonPackages;
        nativeBuildInputs = with pkgs; [
          pkg-config
        ] ++ commonPackages;
      };

      packages.recipesage = pkgs.buildNpmPackage {
        pname = "recipesage";
        version = "0.1.0";

      APPEND_LIBRARY_PATH = "${pkgs.lib.makeLibraryPath [ pkgs.libuuid.out ]}";
      shellHook = ''
        export LD_LIBRARY_PATH="$APPEND_LIBRARY_PATH:$LD_LIBRARY_PATH"
      '';

        npmDepsHash = "sha256-ZCem3Fu0PeRdtRRdRQBqfY4XTqcSivz5LDjbwc/9cyY=";
        
        src = ./.;
        buildInputs = [
        ] ++ commonPackages;
        nativeBuildInputs = [
        ] ++ commonPackages;
      };

      packages.default = pkgs.dockerTools.buildLayeredImage {
        name = "recipesage";
        tag = "latest";
        contents = with pkgs;
          [
            bashInteractive
          ]
          ++ commonPackages;
      };
    });
}
