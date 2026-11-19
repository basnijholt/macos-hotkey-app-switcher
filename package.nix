{
  lib,
  swift,
  swiftPackages,
}:

# Built with nixpkgs' Swift against nixpkgs' macOS SDK, so no Xcode is needed. It needs no
# TCC permission (no event tap, no Accessibility), so a new /nix/store path after a rebuild is fine.
swiftPackages.stdenv.mkDerivation {
  pname = "app-hotkeys";
  version = "0.1.1";
  src = ./app-hotkeys.swift;
  dontUnpack = true;
  nativeBuildInputs = [ swift ];
  buildPhase = ''
    swiftc -O -module-name AppHotkeys -framework AppKit -framework Carbon $src -o app-hotkeys
  '';
  installPhase = ''
    install -Dm755 app-hotkeys $out/bin/app-hotkeys
  '';
  meta = {
    description = "Global macOS hotkeys that bring an app to the front, read from a plain text file";
    homepage = "https://github.com/basnijholt/app-hotkeys";
    license = lib.licenses.mit;
    platforms = lib.platforms.darwin;
    mainProgram = "app-hotkeys";
  };
}
