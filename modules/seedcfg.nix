{ lib, ... }:
let
  inherit (lib) types mkOption;

  runnerType = types.submodule {
    options = {
      name = mkOption {
        description = "Provider runner label.";
        type = types.str;
      };
      cpu = mkOption {
        description = "CPU manufacturer.";
        type = types.enum [
          "amd"
          "ampere"
          "apple"
          "graviton"
          "intel"
        ];
      };
      motherboard = mkOption {
        description = "Platform abstraction.";
        type = types.enum [
          "mac_mini"
          "virtual"
        ];
      };
      os = mkOption {
        description = "Operating system details.";
        type = types.submodule {
          options = {
            name = mkOption {
              description = "OS name.";
              type = types.enum [
                "linux"
                "macos"
                "ubuntu"
              ];
            };
            release = mkOption {
              description = "OS release version.";
              type = types.str;
            };
            kernel = mkOption {
              description = "Kernel details.";
              type = types.submodule {
                options = {
                  name = mkOption {
                    description = "Kernel name.";
                    type = types.enum [
                      "darwin"
                      "linux"
                    ];
                  };

                  version = mkOption {
                    description = "Kernel version.";
                    default = "unknown";
                    type = types.str;
                  };
                };
              };
            };
          };
        };
      };
      ossFree = mkOption {
        description = "Whether the runner is free for open source, overrides the provider level.";
        default = null;
        type = types.nullOr types.bool;
      };
      ram = mkOption {
        description = "Memory abstraction.";
        type = types.enum [
          "physical"
          "virtual"
        ];
      };
      storage = mkOption {
        description = "Disk type.";
        type = types.enum [
          "nvme"
          "ssd"
          "virtual"
        ];
      };
      virtualization = mkOption {
        description = "Environment type.";
        type = types.enum [
          "bare_metal"
          "vm"
        ];
      };
    };
  };

  cloudType = types.submodule {
    options = {
      provider = mkOption {
        description = "Underlying cloud provider, if known/applicable.";
        type = types.enum [
          "Alibaba Cloud"
          "AppVeyor"
          "AWS"
          "Azure"
          "Fly.io"
          "GCP"
          "MacStadium"
          "Scaleway"
        ];
      };
      geo = mkOption {
        description = "Geographical presence and legal isolation.";
        type = types.submodule {
          options = {
            strictSovereignty = mkOption {
              description = "Whether there is a strict legal firewall between regions.";
              type = types.bool;
            };
            jurisdiction = mkOption {
              description = "Applicable jurisdictions.";
              type = types.listOf types.str;
            };
            regions = mkOption {
              description = "List of Continent Alpha-2 codes.";
              type = types.listOf (
                types.enum [
                  "AS"
                  "EU"
                  "NA"
                  "OC"
                  "SA"
                ]
              );
            };
            subregions = mkOption {
              description = "Provider-specific region identifiers (e.g. us-east-1).";
              default = [ ];
              type = types.listOf types.str;
            };
          };
        };
      };
      kms = mkOption {
        description = "KMS signing URL or ARN.";
        default = null;
        type = types.nullOr types.str;
      };
      oidcIssuer = mkOption {
        description = "OIDC issuer URL.";
        default = null;
        type = types.nullOr types.str;
      };
      ossFree = mkOption {
        description = "Whether free for open source, can be true, false, or 'partial'.";
        type = types.either types.bool (types.enum [ "partial" ]);
      };
      registry = mkOption {
        description = "Container registry URL/hostname.";
        default = null;
        type = types.nullOr types.str;
      };
      systems = mkOption {
        description = "Hardware details for SaaS runners, keyed by system triple.";
        default = { };
        type = types.attrsOf (types.listOf runnerType);
      };

    };
  };

  hostedRegionType = types.submodule {
    options = {
      geo = mkOption {
        description = "Geographical presence for this region.";
        type = types.submodule {
          options = {
            jurisdiction = mkOption {
              description = "Applicable jurisdictions for this region.";
              type = types.listOf types.str;
            };

            regions = mkOption {
              description = "Applicable continent codes for this region.";
              type = types.listOf (
                types.enum [
                  "AS"
                  "EU"
                  "NA"
                  "OC"
                  "SA"
                ]
              );
            };
            subregions = mkOption {
              description = "Provider-specific region identifiers (e.g. us-east-1).";
              default = [ ];
              type = types.listOf types.str;
            };
          };
        };
      };
      provider = mkOption {
        description = "Underlying infrastructure operator.";
        type = types.str;
      };
      strictSovereignty = mkOption {
        description = "Strict legal boundary for this hosted region.";
        type = types.bool;
      };
      systems = mkOption {
        description = "Hardware details for self-hosted runners in this region, keyed by system triple.";
        default = { };
        type = types.attrsOf (types.listOf runnerType);
      };
    };
  };

  providerType = types.submodule {
    options = {
      master = mkOption {
        type = types.bool;
        default = false;
        # TODO: enforce single master
        description = "Whether this provider is the primary source of truth.";
      };
      cloud = mkOption {
        type = types.nullOr cloudType;
        default = null;
        description = "Configuration for public SaaS cloud runners.";
      };
      corporateParent = mkOption {
        description = "Legal entity operating the CI platform.";
        type = types.str;
      };
      hosted = mkOption {
        type = types.attrsOf hostedRegionType;
        default = { };
        description = "Configurations for self-hosted runners, keyed by region name.";
      };
    };
  };

in
{

  options.flake.seedCfg = {

    builders = mkOption {
      type = types.attrsOf providerType;
      description = "CI/CD builder platforms.";
    };

    fallbackRegistry = mkOption {
      default = "ghcr.io";
      type = types.str;
      description = "Fallback registry to use if a builder doesn't specify one.";
    };

    rekor = mkOption {
      description = "Rekor configuration.";
      default = { };
      type = types.submodule {
        options = {
          url = mkOption {
            default = "https://rekor.sigstore.dev";
            type = types.str;
            description = "URL of the Rekor transparency log.";
          };
          quorum = mkOption {
            default = null;
            type = with types; nullOr int;
            description = "Number of required signers for a quorum. Null means unanimous.";
          };
          deadline = mkOption {
            default = "30m";
            type = types.str;
            description = "Deadline duration for the request.";
          };
        };
      };
    };

  };

}
