{
  description = "Development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      nixpkgs,
      flake-utils,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        pico-sdk = (pkgs.callPackage ./pico-sdk.nix {});
        picotool = pkgs.picotool.overrideDerivation (oldAttrs: {
          version = "2.2.0-a4";
          src = pkgs.fetchFromGitHub {
            owner = "raspberrypi";
            repo = "picotool";
            rev = "25aa087b2c517b4901874a99536e869d4d27b678";
            hash = "sha256-kIB/ODAvwWWoAQDq2cMiFuNWjzzLgPuRQv0NluWYU+Y=";
          };
        });
      in
      {
        devShells.default = pkgs.mkShell rec {
          nativeBuildInputs = [
            pkgs.git
            pkgs.cmake
            pkgs.gcc-arm-embedded
            pkgs.python3
            pkgs.minicom
            picotool
            pico-sdk
          ];

          LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath nativeBuildInputs;
        };

        packages.default = pkgs.pkgsCross.arm-embedded.stdenv.mkDerivation (finalAttrs: {
          pname = "desk-firmware";
          version = "1.0.0";

          srcs = [
            (pkgs.lib.fileset.toSource {
              root = ./.;
              fileset = ./.;
            })
          ];

          sourceRoot = "source";

          nativeBuildInputs = [
            pkgs.git
            pkgs.pkgsCross.arm-embedded.cmake
            pkgs.gcc-arm-embedded
            pkgs.python3
            picotool
            pico-sdk
          ];

          cmakeFlags = [
            "-DPICO_SDK_PATH=${pico-sdk}/lib/pico-sdk"
            "-DCMAKE_C_COMPILER=${pkgs.gcc-arm-embedded}/bin/arm-none-eabi-gcc"
            "-DCMAKE_CXX_COMPILER=${pkgs.gcc-arm-embedded}/bin/arm-none-eabi-g++"
          ];

          buildPhase = ''
            cmake --build . --target desk_firmware
          '';

          installPhase = ''
            mkdir -p $out
            cp /build/source/build/* -r $out
          '';

          meta = {
            description = "Firmware for the Connect 4 Desk";
            homepage = "https://github.com/fizzyapple12/connect-4-robot";
            maintainers = with pkgs.lib.maintainers; [ fizzyapple12 ];
            mainProgram = "desk_firmware.uf2";
            platforms = pkgs.lib.platforms.all;
          };
        });
      }
    );
}
