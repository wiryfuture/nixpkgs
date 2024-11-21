{ config, lib, pkgs, ... }:
let
  cfg = config.services.soft-serve;
  configFile = format.generate "config.yaml" cfg.settings;
  format = pkgs.formats.yaml { };
  docUrl = "https://charm.sh/blog/self-hosted-soft-serve/";

  hookTypes = lib.types.enum [ "post-receive" "post-update" "pre-receive" "update" ];
  hookFormat = lib.types.nullOr lib.types.attrsOf lib.types.submodule {
    options = lib.mkMerge (map (hookType: lib.attrSets.nameValuePair hookType (lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "List of hooks to add for the repo";
    })) hookTypes);
  };

  # L path/path(.d)/(storename) 700 soft-serve - - (storename)
  # Need to flatten the attrset:attrset:list into one list
  createHookFiles = mapAttrs (repoName: hooks:
    mapAttrs ( hookType: hookContents:
      map (content: "L ${cfg.stateDir}/${repoName}/hooks/${hooktype}.d/(somename) 700 soft-serve - - ${pkgs.writeText "" ${content}}") hookContents
    ) hooks
  ) cfg.ensureRepoHooks;
in {
  options = {
    services.soft-serve = {
      enable = lib.mkEnableOption "soft-serve";

      package = lib.mkPackageOption pkgs "soft-serve" { };

      ensureRepoHooks = lib.mkOption {
        type = hookFormat;
        default = null;
        description = ''
          Declarative assignment of hooks to repos.
          The attrName is the name of the repo, which is used relative to ``${cfg.stateDir}``, and the value is an attrSet of your hooks, which can be of types ``${hooks}``, defined as lists of str.
        '';
      };

      settings = lib.mkOption {
        type = format.type;
        default = { };
        description = ''
          The contents of the configuration file for soft-serve.

          See <${docUrl}>.
        '';
        example = lib.literalExpression ''
          {
            name = "dadada's repos";
            log_format = "text";
            ssh = {
              listen_addr = ":23231";
              public_url = "ssh://localhost:23231";
              max_timeout = 30;
              idle_timeout = 120;
            };
            stats.listen_addr = ":23233";
          }
        '';
      };

      stateDir = lib.mkOption {
        type = lib.types.str;
        default = "/var/lib/soft-serve";
        description = ''
          Location for soft-serve to store repos, hooks etc.
        '';
        example = "/mnt/soft-serve";
      };
    };
  };

  config = lib.mkIf cfg.enable {

    systemd.tmpfiles.rules = [
      # The config file has to be inside the state dir
      "L+ ${cfg.stateDir}/config.yaml - - - - ${configFile}"
    ] ++ lib.mkIf !cfg.ensureRepoHooks (createHookFiles cfg.ensureRepoHooks);

    systemd.services.soft-serve = {
      description = "Soft Serve git server";
      documentation = [ docUrl ];
      requires = [ "network-online.target" ];
      after = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];

      environment.SOFT_SERVE_DATA_PATH = cfg.stateDir;

      serviceConfig = {
        Type = "simple";
        DynamicUser = true;
        Restart = "always";
        ExecStart = "${getExe cfg.package} serve";
        StateDirectory = "soft-serve";
        WorkingDirectory = cfg.stateDir;
        RuntimeDirectory = "soft-serve";
        RuntimeDirectoryMode = "0750";
        ProcSubset = "pid";
        ProtectProc = "invisible";
        UMask = "0027";
        CapabilityBoundingSet = "";
        ProtectHome = true;
        PrivateDevices = true;
        PrivateUsers = true;
        ProtectHostname = true;
        ProtectClock = true;
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectKernelLogs = true;
        ProtectControlGroups = true;
        RestrictAddressFamilies = [ "AF_UNIX" "AF_INET" "AF_INET6" ];
        RestrictNamespaces = true;
        LockPersonality = true;
        MemoryDenyWriteExecute = true;
        RestrictRealtime = true;
        RemoveIPC = true;
        PrivateMounts = true;
        SystemCallArchitectures = "native";
        SystemCallFilter = [
          "@system-service"
          "~@cpu-emulation @debug @keyring @module @mount @obsolete @privileged @raw-io @reboot @setuid @swap"
        ];
      };
    };
  };

  meta.maintainers = [ maintainers.dadada ];
}
