{
  config,
  pkgs,
  lib,
  ...
}:
with lib;
let
  cfg = config.services.control-server;
  externalStateDir = "/var/lib/control-server";
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

        environment = {
        };

        serviceConfig = {
          Type = "simple";
          ExecStart = command;
          # Hardening options
          User = cfg.user;
          Group = cfg.group;
          RuntimeDirectory = [ "control-server" ];
          RuntimeDirectoryMode = "0700";
          StateDirectory = [ "control-server" ];
          StateDirectoryMode = "0700";
          WorkingDirectory = externalStateDir;
          BindReadOnlyPaths = [
            "/nix/store"
            "-/etc/resolv.conf"
            "-/etc/nsswitch.conf"
            "-/etc/group"
            "-/etc/hosts"
            "-/etc/localtime"
          ];
          TemporaryFileSystem = "/:ro";
          PrivateTmp = true;
          PrivateDevices = true;
          ProtectKernelTunables = true;
          ProtectControlGroups = true;
          RestrictSUIDSGID = true;
          PrivateMounts = true;
          ProtectKernelModules = true;
          ProtectKernelLogs = true;
          ProtectHostname = true;
          ProtectClock = true;
          ProtectProc = "invisible";
          ProcSubset = "pid";
          RestrictNamespaces = true;
          RemoveIPC = true;
          UMask = "0077";
          NoNewPrivileges = true;
          LockPersonality = true;
          RestrictRealtime = true;
          MemoryDenyWriteExecute = true;
        };
      };

      users.groups.controlserver = lib.mkIf (
        cfg.user == "controlserver" && cfg.group == "controlserver"
      ) { };
      users.users.controlserver = lib.mkIf (cfg.user == "controlserver" && cfg.group == "controlserver") {
        description = "Service user for control-server";
        group = "controlserver";
        home = externalStateDir;
        isSystemUser = true;
      };
    }
  );
}
