{
  config,
  pkgs,
  lib,
  ...
}:
with lib;
let
  cfg = config.services.control-server;
in
{
  options.services.control-server = {
    enable = mkEnableOption "Connect 4 Robot Control Server";

    package = mkOption {
      type = types.package;
      default = pkgs.control-server;
      defaultText = "pkgs.control-server";
      description = ''
        Package of the application to run, exposed for overriding purposes.
      '';
    };

    user = mkOption {
      type = types.str;
      default = "controlserver";
      description = ''
        The user that control-server will run under.

        If changed from default, you are responsible for making sure the user exists.
      '';
    };

    group = mkOption {
      type = types.str;
      default = "controlserver";
      description = ''
        The group that control-server will run under.

        If changed from default, you are responsible for making sure the user exists.
      '';
    };
  };

  config = mkIf cfg.enable (
    let
      command = "${getExe cfg.package}";
    in
    {
      systemd.services.control-server = {
        description = "Connect 4 Robot Control Server";
        wantedBy = [ "multi-user.target" ];

        serviceConfig = {
          Type = "simple";
          ExecStart = command;
          User = cfg.user;
          Group = cfg.group;
          Restart = "on-failure";
          RestartSec = "10s";
          StartLimitIntervalSec = "60s";
          StartLimitBurst = 120;
        };
      };

      users.groups.controlserver = lib.mkIf (
        cfg.user == "controlserver" && cfg.group == "controlserver"
      ) { };
      users.users.controlserver = lib.mkIf (cfg.user == "controlserver" && cfg.group == "controlserver") {
        description = "Service user for control-server";
        group = "controlserver";
        isSystemUser = true;
        extraGroups = [
          "dialout"
          "input"
          "plugdev"
        ];
      };
    }
  );
}
