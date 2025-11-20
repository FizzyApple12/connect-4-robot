{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  nix-update-script,
  ...
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "pico-sdk";
  version = "2.2.0";

  src = fetchFromGitHub {
    owner = "raspberrypi";
    repo = "pico-sdk";
    rev = "a1438dff1d38bd9c65dbd693f0e5db4b9ae91779";
    fetchSubmodules = true;
    hash = "sha256-8ubZW6yQnUTYxQqYI6hi7s3kFVQhe5EaxVvHmo93vgk=";
  };

  cmakeFlags = [
    (lib.cmakeFeature "PIOASM_VERSION_STRING" finalAttrs.version)
  ];

  nativeBuildInputs = [ cmake ];

  # SDK contains libraries and build-system to develop projects for RP2040 chip
  # We only need to compile pioasm binary
  sourceRoot = "${finalAttrs.src.name}/tools/pioasm";

  installPhase = ''
    runHook preInstall
    mkdir -p $out/lib/pico-sdk
    cp -a ../../../* $out/lib/pico-sdk/
    chmod 755 $out/lib/pico-sdk/tools/pioasm/build/pioasm
    runHook postInstall
  '';

  passthru = {
    updateScript = nix-update-script { };
    tests = {
      withSubmodules = true;
    };
  };

  meta = {
    description = "SDK provides the headers, libraries and build system necessary to write programs for the RP2040-based devices";
    homepage = "https://github.com/raspberrypi/pico-sdk";
    changelog = "https://github.com/raspberrypi/pico-sdk/releases/tag/${finalAttrs.version}";
    license = lib.licenses.bsd3;
    maintainers = with lib.maintainers; [ muscaln ];
    platforms = lib.platforms.unix;
  };
})
