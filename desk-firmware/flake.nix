{
  description = "Development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    nixpkgs,
    flake-utils,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = nixpkgs.legacyPackages.${system};
      in {
        devShells.default = pkgs.mkShell rec {
          nativeBuildInputs = with pkgs; [
            cmake
          ];
          buildInputs = with pkgs; [
            clang
            llvmPackages.bintools
            bash
          ];

          LIBCLANG_PATH = pkgs.lib.makeLibraryPath [pkgs.llvmPackages_latest.libclang.lib];

          LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath (buildInputs ++ nativeBuildInputs);
        };

        packages.default = pkgs.pkgsCross.arm-embedded.stdenv.mkDerivation (finalAttrs: rec {
          pname = "desk-firmware";
          version = "1.0.0";

          # set(PICO_SDK_FETCH_FROM_GIT on)
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
              sha256 = "sha256-q9epnsTclLrPjZxCIR6YGcCZyL5NN3ToIKmLSE5MXQM=";
              deepClone = true;
            })
          ];
          sourceRoot = "source";

          nativeBuildInputs = with pkgs; [
            git
            pkgsCross.arm-embedded.cmake
          ];

          cmakeFlags = [
            "-DPICO_SDK_PATH=/build/pico-sdk"
          ];

          # configurePhase = ''
          #   ls .. -al
          #   echo $PWD
          # '';

          buildPhase = ''
            # cmake -S . -B build

            cmake --build build --target desk_firmware
          '';

          # installPhase = ''

          # '';

          # src = pkgs.fetchurl {
          #   url = "mirror://gnu/hello/hello-${finalAttrs.version}.tar.gz";
          #   hash = "sha256-WpqZbcKSzCTc9BHO6H6S9qrluNE72caBm0x6nc4IGKs=";
          # };

          # env = pkgs.lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
          #   NIX_LDFLAGS = "-liconv";
          # };

          # Give hello some install checks for testing purpose.
          # postInstallCheck = ''
          #   stat "''${!outputBin}/bin/${finalAttrs.meta.mainProgram}"
          # '';

          # passthru.tests.run = pkgs.callPackage ./test.nix {hello = finalAttrs.finalPackage;};

          meta = {
            description = "Firmware for the Connect 4 Desk";
            homepage = "https://github.com/fizzyapple12/connect-4-robot";
            maintainers = with pkgs.lib.maintainers; [fizzyapple12];
            mainProgram = "desk_firmware.uf2";
            platforms = pkgs.lib.platforms.all;
          };
        });
      }
    );
}
