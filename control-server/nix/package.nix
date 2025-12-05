{
  lib,
  rustPlatform,
  pkg-config,
  systemd,
  openssl,
  cmake,
  clang,
  llvmPackages,
  rustup,
  yaml-language-server,
  fontconfig,
  vulkan-loader,
  libxkbcommon,
  xorg,
  wayland,
  wayland-protocols,
  wayland-scanner,
  llvmPackages_latest,
}:

rustPlatform.buildRustPackage rec {
  pname = "control-server";
  version = "1.0.0";
  cargoLock.lockFile = ./Cargo.lock;
  src = lib.cleanSource ./.;

  nativeBuildInputs = [
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

  LIBCLANG_PATH = lib.makeLibraryPath [ llvmPackages_latest.libclang.lib ];

  shellHook = ''
    export PATH=$PATH:''${CARGO_HOME:-~/.cargo}/bin
    export PATH=$PATH:''${RUSTUP_HOME:-~/.rustup}/toolchains/$RUSTC_VERSION-x86_64-unknown-linux-gnu/bin/
  '';

  LD_LIBRARY_PATH = lib.makeLibraryPath nativeBuildInputs;

  meta = {
    description = "Control Server for the Connect 4 Robot";
    homepage = "https://github.com/fizzyapple12/connect-4-robot";
    maintainers = with lib.maintainers; [ fizzyapple12 ];
    mainProgram = "control_server";
    platforms = lib.platforms.all;
  };
}
