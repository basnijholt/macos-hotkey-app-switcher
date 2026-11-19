# nix-darwin module: runs app-hotkeys as a launchd user agent in the GUI session.
# Bindings: ~/.config/app-hotkeys/hotkeys.conf, reloaded on save.
# Log: ~/Library/Logs/app-hotkeys/current. Force a reload:
#   launchctl kill HUP gui/$(id -u)/org.nixos.app-hotkeys
self:
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.app-hotkeys;
  homeDir = "/Users/${config.system.primaryUser}";
  logDir = "${homeDir}/Library/Logs/app-hotkeys";
in
{
  options.services.app-hotkeys = {
    enable = lib.mkEnableOption "app-hotkeys, global hotkeys that bring an app to the front";

    package = lib.mkOption {
      type = lib.types.package;
      default = self.packages.${pkgs.stdenv.hostPlatform.system}.default;
      defaultText = lib.literalExpression "app-hotkeys.packages.\${system}.default";
      description = "The app-hotkeys package to run.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];

    launchd.user.agents.app-hotkeys = {
      script = ''
        # s6-log rotates the log (1 MB, 3 old files); exec keeps app-hotkeys as the job's process
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
