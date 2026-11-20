{
  lib,
  swift,
  swiftPackages,
}:

# Built with nixpkgs' Swift against nixpkgs' macOS SDK, so no Xcode is needed. Hotkeys need no
# Accessibility or Input Monitoring permission. Opt-in reopen may need Automation approval.
swiftPackages.stdenv.mkDerivation {
  pname = "macos-hotkey-app-switcher";
  version = "0.3.0";
  src = ./macos-hotkey-app-switcher.swift;
  dontUnpack = true;
  nativeBuildInputs = [ swift ];
  buildPhase = ''
    swiftc -O -module-name MacosHotkeyAppSwitcher -framework AppKit -framework Carbon $src -o macos-hotkey-app-switcher
  '';
  installPhase = ''
    install -Dm755 macos-hotkey-app-switcher $out/bin/macos-hotkey-app-switcher
  '';
  meta = {
    description = "Global macOS hotkeys that bring an app to the front, read from a plain text file";
    homepage = "https://github.com/basnijholt/macos-hotkey-app-switcher";
    license = lib.licenses.mit;
    platforms = lib.platforms.darwin;
    mainProgram = "macos-hotkey-app-switcher";
  };
}
