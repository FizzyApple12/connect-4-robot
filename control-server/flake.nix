{
  description = "Full development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      ...
    }:
    {
      nixosModules.default = nix/module.nix;
      overlays.default = final: prev: {
        control-server = final.callPackage nix/package.nix { };
      };
    }
    // flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        devShells.default = pkgs.mkShell rec {
          nativeBuildInputs = with pkgs; [
            pkg-config
            systemd
            openssl
            cmake
            clang
            llvmPackages.bintools
            rustup
            yaml-language-server
            fontconfig
            vulkan-loader
            libxkbcommon
            xorg.libxcb
            xorg.libX11
            xorg.libXcursor
            xorg.libXi
            xorg.libXrandr
            xorg.libXxf86vm
            wayland
            wayland-protocols
            wayland-scanner
          ];

          RUSTC_VERSION = "nightly";

          LIBCLANG_PATH = pkgs.lib.makeLibraryPath [ pkgs.llvmPackages_latest.libclang.lib ];

          shellHook = ''
            export PATH=$PATH:''${CARGO_HOME:-~/.cargo}/bin
            export PATH=$PATH:''${RUSTUP_HOME:-~/.rustup}/toolchains/$RUSTC_VERSION-x86_64-unknown-linux-gnu/bin/
          '';

          LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath nativeBuildInputs;
        };

        packages.default = pkgs.rustPlatform.buildRustPackage {
          pname = "control-server";
          version = "1.0.0";
          cargoLock.lockFile = ./Cargo.lock;
          src = pkgs.lib.cleanSource ./.;

          meta = {
            description = "Control Server for the Connect 4 Robot";
            homepage = "https://github.com/fizzyapple12/connect-4-robot";
            maintainers = with pkgs.lib.maintainers; [ fizzyapple12 ];
            mainProgram = "control-server";
            platforms = pkgs.lib.platforms.all;
          };
        };
      }
    );
}
