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
          nativeBuildInputs = with pkgs; [
            cmake
          ];
          buildInputs = with pkgs; [
            clang
            llvmPackages.bintools
            bash
          ];

          LIBCLANG_PATH = pkgs.lib.makeLibraryPath [ pkgs.llvmPackages_latest.libclang.lib ];

          LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath (buildInputs ++ nativeBuildInputs);
        };

        packages.default = pkgs.pkgsCross.arm-embedded.stdenv.mkDerivation (finalAttrs: rec {
          pname = "desk-firmware";
          version = "1.0.0";

          srcs = [
            (pkgs.lib.fileset.toSource {
              root = ./.;
              fileset = ./.;
            })
            (pkgs.fetchFromGitHub {
              name = "pico-sdk";
              owner = "raspberrypi";
              repo = "pico-sdk";
              rev = "a1438dff1d38bd9c65dbd693f0e5db4b9ae91779";
              sha256 = "sha256-wfe1tRaURH8aP5nBYLrzT3vqQcUV5CT9bQD0gulEe9o=";
              deepClone = true;
            })
          ];

          sourceRoot = "source";

          nativeBuildInputs = with pkgs; [
            git
            pkgsCross.arm-embedded.cmake
            gcc-arm-embedded
            python3
            picotool
          ];

          cmakeFlags = [
            "-DPICO_SDK_PATH=/build/pico-sdk"
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
