# nix-darwin module: runs macos-hotkey-app-switcher as a launchd user agent in the GUI session.
# Bindings: ~/.config/macos-hotkey-app-switcher/hotkeys.conf, reloaded on save.
# Log: ~/Library/Logs/macos-hotkey-app-switcher/current. Force a reload:
#   launchctl kill HUP gui/$(id -u)/org.nixos.macos-hotkey-app-switcher
self:
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.macos-hotkey-app-switcher;
  homeDir = "/Users/${config.system.primaryUser}";
  logDir = "${homeDir}/Library/Logs/macos-hotkey-app-switcher";
in
{
  options.services.macos-hotkey-app-switcher = {
    enable = lib.mkEnableOption "macos-hotkey-app-switcher, global hotkeys that bring an app to the front";

    package = lib.mkOption {
      type = lib.types.package;
      default = self.packages.${pkgs.stdenv.hostPlatform.system}.default;
      defaultText = lib.literalExpression "macos-hotkey-app-switcher.packages.\${system}.default";
      description = "The macos-hotkey-app-switcher package to run.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];

    launchd.user.agents.macos-hotkey-app-switcher = {
      script = ''
        # s6-log rotates the log (1 MB, 3 old files); exec keeps macos-hotkey-app-switcher as the job's process
        exec ${lib.getExe cfg.package} 2> >(exec ${pkgs.s6}/bin/s6-log n3 s1000000 ${logDir})
      '';
      serviceConfig = {
        RunAtLoad = true;
        KeepAlive = true;
        ThrottleInterval = 5;
        # Hotkeys need the GUI session; Interactive keeps launchd from throttling the response
        LimitLoadToSessionType = "Aqua";
        ProcessType = "Interactive";
        WorkingDirectory = homeDir;
      };
    };
  };
}
