{

  description = "";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    flake-utils.url = "github:numtide/flake-utils";
    agenix.url = "github:ryantm/agenix";
    agenix-rekey.url = "github:oddlama/agenix-rekey";
    agenix-rekey.inputs.nixpkgs.follows = "nixpkgs";

    fizzy-control-server.url = "github:fizzyapple12/connect-4-server?dir=control-server";

  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-unstable,
      flake-utils,
      agenix,
      agenix-rekey,
      fizzy-control-server,
      ...
    }@inputs:
    let
      mkNixosSystem =
        {
          hostname,
          configDir,
          system ? "x86_64-linux",
          lib ? nixpkgs.lib,
          pkgs ? inputs.nixos.legacyPackages.${system},
          specialArgs ? { },
          modules ? [ ],
        }:
        lib.nixosSystem {
          inherit system;

          specialArgs = {
            inherit
              inputs
              hostname
              configDir
              system
              ;
          }
          // specialArgs;

          modules = [
            "${toString configDir}"
            agenix.nixosModules.default
            agenix-rekey.nixosModules.default
            ({
              nixpkgs.overlays = [
                (final: _prev: {
                  unstable = import inputs.nixpkgs-unstable {
                    system = final.system;
                  };
                })
              ];
            })
          ]
          ++ modules;
        };
    in
    {
      nixosConfigurations = {
        "c4-server" = mkNixosSystem {
          hostname = "c4-server"; # System Hostname
          configDir = ./flake-configuration.nix; # Path to Machine Configuration
          modules = [
            fizzy-control-server.nixosModules.default
            ({ nixpkgs.overlays = [ fizzy-control-server.overlays.default ]; })
          ];
        };
      };

      agenix-rekey = agenix-rekey.configure {
        userFlake = self;
        nixosConfigurations = self.nixosConfigurations;
      };

    }
    // flake-utils.lib.eachDefaultSystem (system: {
      pkgs = import nixpkgs {
        inherit system;
        overlays = [ agenix-rekey.overlays.default ];
      };
    });
}
