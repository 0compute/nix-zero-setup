{
  config.flake.seedCfg.builders = {

    # Alibaba Cloud Flow: https://www.alibabacloud.com/help/en/yunxiao
    alibaba = {
      cloud = {
        provider = "Alibaba Cloud";
        geo = {
          strictSovereignty = true;
          jurisdiction = [ "CN" ];
          regions = [ "AS" ];
        };
        # supports KMS signing via sigstore KMS plugin:
        # https://github.com/mozillazg/sigstore-kms-plugin-alibaba-cloud
        kms = "alikms://<region>/<key-id>";
        ossFree = false;
        registry = "registry.cn-hangzhou.aliyuncs.com"; # example registry
        systems = {
          "x86_64-linux" = [
            {
              name = "ubuntu-22.04";
              cpu = "amd";
              motherboard = "virtual";
              os = {
                kernel = {
                  name = "linux";
                };
                name = "ubuntu";
                release = "22.04";
              };
              ram = "virtual";
              storage = "virtual";
              virtualization = "vm";
            }
            {
              name = "ubuntu-22.04";
              cpu = "intel";
              os = {
                kernel = {
                  name = "linux";
                };
                name = "ubuntu";
                release = "22.04";
              };
              ram = "virtual";
              storage = "virtual";
              virtualization = "vm";
            }
          ];
        };
      };
      corporateParent = "Alibaba Group";
    };

    # AppVeyor: https://www.appveyor.com/
    appveyor = {
      cloud = {
        provider = "AppVeyor";
        geo = {
          strictSovereignty = false;
          jurisdiction = [ "CA" ];
          regions = [
            "EU"
            "NA"
          ];
        };
        oidcIssuer = "https://oidc.appveyor.com";
        ossFree = "partial"; # limited free tier for OSS
        systems = {
          "x86_64-linux" = [
            {
              name = "ubuntu2204";
              cpu = "amd";
              motherboard = "virtual";
              os = {
                kernel = {
                  name = "linux";
                };
                name = "ubuntu";
                release = "22.04";
              };
              ram = "virtual";
              storage = "virtual";
              virtualization = "vm";
            }
            {
              name = "ubuntu2204";
              cpu = "intel";
              motherboard = "virtual";
              os = {
                kernel = {
                  name = "linux";
                };
                name = "ubuntu";
                release = "22.04";
              };
              ram = "virtual";
              storage = "virtual";
              virtualization = "vm";
            }
          ];
        };
      };
      corporateParent = "AppVeyor";
    };

    # AWS CodeBuild: https://aws.amazon.com/codebuild/
    aws = {
      cloud = {
        provider = "AWS";
        geo = {
          strictSovereignty = false;
          jurisdiction = [ "US" ];
          regions = [
            "AS"
            "EU"
            "NA"
            "OC"
            "SA"
          ];
        };
        # supports OIDC via IAM but often used with KMS
        kms = "arn:aws:kms:<region>:<account>:key/<id>";
        ossFree = "partial"; # limited free tier (usually 100 min/mo)
        registry = "public.ecr.aws";
        systems = {
          "aarch64-linux" = [
            {
              name = "standard:3.0";
              cpu = "graviton";
              motherboard = "virtual";
              os = {
                kernel = {
                  name = "linux";
                };
                name = "ubuntu";
                release = "22.04";
              };
              ram = "virtual";
              storage = "virtual";
              virtualization = "vm";
            }
          ];
          "x86_64-linux" = [
            {
              name = "standard:7.0";
              cpu = "amd";
              motherboard = "virtual";
              os = {
                kernel = {
                  name = "linux";
                };
                name = "ubuntu";
                release = "22.04";
              };
              ram = "virtual";
              storage = "virtual";
              virtualization = "vm";
            }
            {
              name = "standard:7.0";
              cpu = "intel";
              motherboard = "virtual";
              os = {
                kernel = {
                  name = "linux";
                };
                name = "ubuntu";
                release = "22.04";
              };
              ram = "virtual";
              storage = "virtual";
              virtualization = "vm";
            }
          ];
        };
      };
      corporateParent = "Amazon";
    };

    # Azure Pipelines: https://azure.microsoft.com/en-us/products/devops/pipelines
    azure = {
      cloud = {
        provider = "Azure";
        geo = {
          strictSovereignty = false;
          jurisdiction = [ "US" ];
          regions = [
            "AS"
            "EU"
            "NA"
            "OC"
            "SA"
          ];
        };
        # real issuer is org-scoped:
        # https://vstoken.dev.azure.com/<org-id>
        oidcIssuer = "https://vstoken.dev.azure.com";
        ossFree = true;
        registry = "mcr.microsoft.com";
        systems = {
          "aarch64-darwin" = [
            {
              name = "macOS-15";
              cpu = "apple";
              motherboard = "mac_mini";
              os = {
                kernel = {
                  name = "darwin";
                  version = "24.6";
                };
                name = "macos";
                release = "15";
              };
              ram = "physical";
              storage = "nvme";
              virtualization = "bare_metal";
            }
            {
              name = "macOS-15";
              cpu = "apple";
              motherboard = "virtual";
              os = {
                kernel = {
                  name = "darwin";
                  version = "24.6";
                };
                name = "macos";
                release = "15";
              };
              ram = "virtual";
              storage = "virtual";
              virtualization = "vm";
            }
          ];
          "x86_64-darwin" = [
            {
              name = "macOS-13";
              cpu = "intel";
              motherboard = "mac_mini";
              os = {
                kernel = {
                  name = "darwin";
                  version = "22.6";
                };
                name = "macos";
                release = "13";
              };
              ram = "physical";
              storage = "ssd";
              virtualization = "bare_metal";
            }
            {
              name = "macOS-13";
              cpu = "intel";
              motherboard = "virtual";
              os = {
                kernel = {
                  name = "darwin";
                  version = "22.6";
                };
                name = "macos";
                release = "13";
              };
              ram = "virtual";
              storage = "virtual";
              virtualization = "vm";
            }
          ];
          "x86_64-linux" = [
            {
              name = "ubuntu-24.04";
              cpu = "amd";
              motherboard = "virtual";
              os = {
                kernel = {
                  name = "linux";
                };
                name = "ubuntu";
                release = "24.04";
              };
              ram = "virtual";
              storage = "virtual";
              virtualization = "vm";
            }
            {
              name = "ubuntu-24.04";
              cpu = "intel";
              motherboard = "virtual";
              os = {
                kernel = {
                  name = "linux";
                };
                name = "ubuntu";
                release = "24.04";
              };
              ram = "virtual";
              storage = "virtual";
              virtualization = "vm";
            }
          ];
        };
      };
      corporateParent = "Microsoft";
    };

    # Bitbucket Pipelines: https://bitbucket.org/product/features/pipelines
    bitbucket = {
      cloud = {
        provider = "AWS";
        geo = {
          strictSovereignty = false;
          jurisdiction = [ "AU" ];
          regions = [
            "AS"
            "EU"
            "NA"
            "OC"
          ];
        };
        # workspace-scoped issuer in practice
        oidcIssuer = "https://api.bitbucket.org/2.0/workspaces";
        ossFree = "partial"; # 50 min/mo on free tier
        systems = {
          "aarch64-linux" = [
            {
              name = "arm64";
              cpu = "graviton";
              motherboard = "virtual";
              os = {
                kernel = {
                  name = "linux";
                };
                name = "ubuntu";
                release = "22.04";
              };
              ram = "virtual";
              storage = "virtual";
              virtualization = "vm";
            }
          ];
          "x86_64-linux" = [
            {
              name = "ubuntu-22.04";
              cpu = "amd";
              motherboard = "virtual";
              os = {
                kernel = {
                  name = "linux";
                };
                name = "ubuntu";
                release = "22.04";
              };
              ram = "virtual";
              storage = "virtual";
              virtualization = "vm";
            }
            {
              name = "ubuntu-22.04";
              cpu = "intel";
              motherboard = "virtual";
              os = {
                kernel = {
                  name = "linux";
                };
                name = "ubuntu";
                release = "22.04";
              };
              ram = "virtual";
              storage = "virtual";
              virtualization = "vm";
            }
          ];
        };
      };
      corporateParent = "Atlassian";
    };

    # Bitrise: https://bitrise.io/
    bitrise = {
      cloud = {
        provider = "GCP";
        geo = {
          strictSovereignty = false;
          jurisdiction = [
            "EU"
            "HU"
          ];
          regions = [
            "EU"
            "NA"
          ];
        };
        oidcIssuer = "https://oidc.bitrise.io";
        ossFree = "partial"; # credit-based free tier
        systems = {
          "aarch64-linux" = [
            {
              name = "ubuntu-22-04-arm64";
              cpu = "ampere";
              motherboard = "virtual";
              os = {
                kernel = {
                  name = "linux";
                };
                name = "ubuntu";
                release = "22.04";
              };
              ram = "virtual";
              storage = "virtual";
              virtualization = "vm";
            }
            {
              name = "ubuntu-22-04-arm64";
              cpu = "graviton";
              motherboard = "virtual";
              os = {
                kernel = {
                  name = "linux";
                };
                name = "ubuntu";
                release = "22.04";
              };
              ram = "virtual";
              storage = "virtual";
              virtualization = "vm";
            }
          ];
          "x86_64-linux" = [
            {
              name = "ubuntu-22-04-x86_64";
              cpu = "amd";
              motherboard = "virtual";
              os = {
                kernel = {
                  name = "linux";
                };
                name = "ubuntu";
                release = "22.04";
              };
              ram = "virtual";
              storage = "virtual";
              virtualization = "vm";
            }
            {
              name = "ubuntu-22-04-x86_64";
              cpu = "intel";
              motherboard = "virtual";
              os = {
                kernel = {
                  name = "linux";
                };
                name = "ubuntu";
                release = "22.04";
              };
              ram = "virtual";
              storage = "virtual";
              virtualization = "vm";
            }
          ];
        };
      };
      corporateParent = "Bitrise";
    };

    # Buddy: https://buddy.works/
    buddy = {
      cloud = {
        provider = "AWS";
        geo = {
          strictSovereignty = false;
          jurisdiction = [
            "EU"
            "PL"
          ];
          regions = [
            "EU"
            "NA"
          ];
        };
        # region-scoped issuer in practice:
        # https://[eu-]oidc.buddyusercontent.com
        oidcIssuer = "https://oidc.buddyusercontent.com";
        ossFree = "partial"; # limited free tier
        systems = {
          "x86_64-linux" = [
            {
              name = "ubuntu/22.04";
              cpu = "amd";
              motherboard = "virtual";
              os = {
                kernel = {
                  name = "linux";
                };
                name = "ubuntu";
                release = "22.04";
              };
              ram = "virtual";
              storage = "virtual";
              virtualization = "vm";
            }
            {
              name = "ubuntu/22.04";
              cpu = "intel";
              motherboard = "virtual";
              os = {
                kernel = {
                  name = "linux";
                };
                name = "ubuntu";
                release = "22.04";
              };
              ram = "virtual";
              storage = "virtual";
              virtualization = "vm";
            }
          ];
        };
      };
      corporateParent = "Buddy";
    };

    # Buildkite: https://buildkite.com/
    buildkite = {
      cloud = {
        provider = "AWS";
        geo = {
          strictSovereignty = false;
          jurisdiction = [ "AU" ];
          regions = [
            "EU"
            "NA"
            "OC"
          ];
        };
        oidcIssuer = "https://agent.buildkite.com";
        ossFree = false; # requires application/approval for open source plan
        systems = {
          "aarch64-linux" = [
            {
              name = "linux-arm64-instance-2";
              cpu = "graviton";
              motherboard = "virtual";
              os = {
                kernel = {
                  name = "linux";
                };
                name = "ubuntu";
                release = "22.04";
              };
              ram = "virtual";
              storage = "virtual";
              virtualization = "vm";
            }
          ];
          "x86_64-linux" = [
            {
              name = "linux-amd64-instance-2";
              cpu = "amd";
              motherboard = "virtual";
              os = {
                kernel = {
                  name = "linux";
                };
                name = "ubuntu";
                release = "22.04";
              };
              ram = "virtual";
              storage = "virtual";
              virtualization = "vm";
            }
            {
              name = "linux-amd64-instance-2";
              cpu = "intel";
              motherboard = "virtual";
              os = {
                kernel = {
                  name = "linux";
                };
                name = "ubuntu";
                release = "22.04";
              };
              ram = "virtual";
              storage = "virtual";
              virtualization = "vm";
            }
          ];
        };
      };
      corporateParent = "Buildkite";
    };

    # CircleCI: https://circleci.com/
    circleci = {
      cloud = {
        provider = "AWS";
        geo = {
          strictSovereignty = false;
          jurisdiction = [ "US" ];
          regions = [
            "EU"
            "NA"
          ];
        };
        # real issuer is org-scoped:
        # https://oidc.circleci.com/org/<org-id>
        oidcIssuer = "https://oidc.circleci.com";
        ossFree = true;
        systems = {
          "aarch64-darwin" = [
            {
              name = "macos.m2.medium.gen1";
              cpu = "apple";
              motherboard = "mac_mini";
              os = {
                kernel = {
                  name = "darwin";
                  version = "23.6";
                };
                name = "macos";
                release = "14";
              };
              ram = "physical";
              storage = "nvme";
              virtualization = "bare_metal";
            }
            {
              name = "macos.m2.large.gen1";
              cpu = "apple";
              motherboard = "virtual";
              ossFree = false;
              os = {
                kernel = {
                  name = "darwin";
                  version = "23.6";
                };
                name = "macos";
                release = "14";
              };
              ram = "virtual";
              storage = "virtual";
              virtualization = "vm";
            }
          ];
          "aarch64-linux" = [
            {
              name = "arm.medium";
              cpu = "graviton";
              motherboard = "virtual";
              os = {
                kernel = {
                  name = "linux";
                };
                name = "ubuntu";
                release = "22.04";
              };
              ram = "virtual";
              storage = "virtual";
              virtualization = "vm";
            }
          ];
          "x86_64-darwin" = [
            {
              name = "macos.x86.medium.gen2";
              cpu = "intel";
              motherboard = "mac_mini";
              os = {
                kernel = {
                  name = "darwin";
                  version = "22.6";
                };
                name = "macos";
                release = "13";
              };
              ram = "physical";
              storage = "ssd";
              virtualization = "bare_metal";
            }
            {
              name = "macos.x86.large.gen2";
              cpu = "intel";
              motherboard = "virtual";
              ossFree = false;
              os = {
                kernel = {
                  name = "darwin";
                  version = "22.6";
                };
                name = "macos";
                release = "13";
              };
              ram = "virtual";
              storage = "virtual";
              virtualization = "vm";
            }
          ];
          "x86_64-linux" = [
            {
              name = "medium";
              cpu = "amd";
              motherboard = "virtual";
              os = {
                kernel = {
                  name = "linux";
                };
                name = "ubuntu";
                release = "22.04";
              };
              ram = "virtual";
              storage = "virtual";
              virtualization = "vm";
            }
            {
              name = "medium";
              cpu = "intel";
              motherboard = "virtual";
              os = {
                kernel = {
                  name = "linux";
                };
                name = "ubuntu";
                release = "22.04";
              };
              ram = "virtual";
              storage = "virtual";
              virtualization = "vm";
            }
          ];
        };
      };
      corporateParent = "CircleCI";
    };

    # Codefresh: https://codefresh.io/
    codefresh = {
      cloud = {
        provider = "GCP";
        geo = {
          strictSovereignty = false;
          jurisdiction = [ "US" ];
          regions = [
            "EU"
            "NA"
          ];
        };
        oidcIssuer = "https://oidc.codefresh.io";
        ossFree = "partial"; # limited free tier
        registry = "r.cfcr.io";
        systems = {
          "x86_64-linux" = [
            {
              name = "ubuntu-22.04";
              cpu = "amd";
              motherboard = "virtual";
              os = {
                kernel = {
                  name = "linux";
                };
                name = "ubuntu";
                release = "22.04";
              };
              ram = "virtual";
              storage = "virtual";
              virtualization = "vm";
            }
            {
              name = "ubuntu-22.04";
              cpu = "intel";
              motherboard = "virtual";
              os = {
                kernel = {
                  name = "linux";
                };
                name = "ubuntu";
                release = "22.04";
              };
              ram = "virtual";
              storage = "virtual";
              virtualization = "vm";
            }
          ];
        };
      };
      corporateParent = "Codefresh";
    };

    # Codemagic: https://codemagic.io/
    codemagic = {
      cloud = {
        provider = "MacStadium";
        geo = {
          strictSovereignty = false;
          jurisdiction = [
            "EE"
            "EU"
          ];
          regions = [
            "EU"
            "NA"
          ];
        };
        oidcIssuer = "https://codemagic.io";
        ossFree = "partial"; # credit-based free tier
        systems = {
          "aarch64-linux" = [
            {
              name = "linux-arm64";
              cpu = "ampere";
              motherboard = "virtual";
              os = {
                kernel = {
                  name = "linux";
                };
                name = "ubuntu";
                release = "22.04";
              };
              ram = "virtual";
              storage = "virtual";
              virtualization = "vm";
            }
            {
              name = "linux-arm64";
              cpu = "graviton";
              motherboard = "virtual";
              os = {
                kernel = {
                  name = "linux";
                };
                name = "ubuntu";
                release = "22.04";
              };
              ram = "virtual";
              storage = "virtual";
              virtualization = "vm";
            }
          ];
          "x86_64-linux" = [
            {
              name = "linux-x64";
              cpu = "amd";
              motherboard = "virtual";
              os = {
                kernel = {
                  name = "linux";
                };
                name = "ubuntu";
                release = "22.04";
              };
              ram = "virtual";
              storage = "virtual";
              virtualization = "vm";
            }
            {
              name = "linux-x64";
              cpu = "intel";
              motherboard = "virtual";
              os = {
                kernel = {
                  name = "linux";
                };
                name = "ubuntu";
                release = "22.04";
              };
              ram = "virtual";
              storage = "virtual";
              virtualization = "vm";
            }
          ];
        };
      };
      corporateParent = "Nevercode";
    };

    # Fly.io: https://fly.io/
    fly = {
      cloud = {
        provider = "Fly.io";
        geo = {
          strictSovereignty = false;
          jurisdiction = [ "US" ];
          regions = [
            "AS"
            "EU"
            "NA"
            "OC"
            "SA"
          ];
        };
        oidcIssuer = "https://oidc.fly.io";
        ossFree = "partial"; # free allowance for small VMs
        systems = {
          "x86_64-linux" = [
            {
              name = "ubuntu-22.04";
              cpu = "amd";
              motherboard = "virtual";
              os = {
                kernel = {
                  name = "linux";
                };
                name = "ubuntu";
                release = "22.04";
              };
              ram = "virtual";
              storage = "virtual";
              virtualization = "vm";
            }
            {
              name = "ubuntu-22.04";
              cpu = "intel";
              motherboard = "virtual";
              os = {
                kernel = {
                  name = "linux";
                };
                name = "ubuntu";
                release = "22.04";
              };
              ram = "virtual";
              storage = "virtual";
              virtualization = "vm";
            }
          ];
        };
      };
      corporateParent = "Fly.io";
    };

    # Google Cloud Build: https://cloud.google.com/build
    gcb = {
      cloud = {
        provider = "GCP";
        geo = {
          strictSovereignty = false;
          jurisdiction = [ "US" ];
          regions = [
            "AS"
            "EU"
            "NA"
            "OC"
            "SA"
          ];
        };
        # supports OIDC via accounts.google.com but often used with Cloud KMS
        kms = "projects/*/locations/*/keyRings/*/cryptoKeys/*";
        oidcIssuer = "https://accounts.google.com";
        ossFree = "partial"; # first 120 build-minutes/day free
        registry = "gcr.io";
        systems = {
          "x86_64-linux" = [
            {
              name = "ubuntu-22.04";
              cpu = "amd";
              motherboard = "virtual";
              os = {
                kernel = {
                  name = "linux";
                };
                name = "ubuntu";
                release = "22.04";
              };
              ram = "virtual";
              storage = "virtual";
              virtualization = "vm";
            }
            {
              name = "ubuntu-22.04";
              cpu = "intel";
              motherboard = "virtual";
              os = {
                kernel = {
                  name = "linux";
                };
                name = "ubuntu";
                release = "22.04";
              };
              ram = "virtual";
              storage = "virtual";
              virtualization = "vm";
            }
          ];
        };
      };
      corporateParent = "Alphabet";
    };

    # GitHub Actions: https://github.com/features/actions
    github = {
      master = true;
      cloud = {
        provider = "Azure";
        geo = {
          strictSovereignty = false;
          jurisdiction = [ "US" ];
          regions = [
            "AS"
            "EU"
            "NA"
            "OC"
            "SA"
          ];
        };
        # TODO: enforce unique
        oidcIssuer = "https://token.actions.githubusercontent.com";
        ossFree = true;
        registry = "ghcr.io";
        systems = {
          "aarch64-darwin" = [
            {
              name = "macos-15";
              cpu = "apple";
              motherboard = "mac_mini";
              os = {
                kernel = {
                  name = "darwin";
                  version = "24.6";
                };
                name = "macos";
                release = "15";
              };
              ram = "physical";
              storage = "nvme";
              virtualization = "bare_metal";
            }
            {
              name = "macos-15-xlarge";
              cpu = "apple";
              motherboard = "virtual";
              ossFree = false;
              os = {
                kernel = {
                  name = "darwin";
                  version = "24.6";
                };
                name = "macos";
                release = "15";
              };
              ram = "virtual";
              storage = "virtual";
              virtualization = "vm";
            }
          ];
          "aarch64-linux" = [
            {
              name = "ubuntu-24.04-arm";
              cpu = "ampere";
              motherboard = "virtual";
              os = {
                kernel = {
                  name = "linux";
                };
                name = "ubuntu";
                release = "24.04";
              };
              ram = "virtual";
              storage = "virtual";
              virtualization = "vm";
            }
            {
              name = "ubuntu-24.04-arm";
              cpu = "graviton";
              motherboard = "virtual";
              os = {
                kernel = {
                  name = "linux";
                };
                name = "ubuntu";
                release = "24.04";
              };
              ram = "virtual";
              storage = "virtual";
              virtualization = "vm";
            }
          ];
          "x86_64-darwin" = [
            {
              name = "macos-13";
              cpu = "intel";
              motherboard = "mac_mini";
              os = {
                kernel = {
                  name = "darwin";
                  version = "22.6";
                };
                name = "macos";
                release = "13";
              };
              ram = "physical";
              storage = "ssd";
              virtualization = "bare_metal";
            }
            {
              name = "macos-13-xlarge";
              cpu = "intel";
              motherboard = "virtual";
              os = {
                kernel = {
                  name = "darwin";
                  version = "22.6";
                };
                name = "macos";
                release = "13";
              };
              ram = "virtual";
              storage = "virtual";
              virtualization = "vm";
            }
          ];
          "x86_64-linux" = [
            {
              name = "ubuntu-24.04";
              cpu = "amd";
              motherboard = "virtual";
              os = {
                kernel = {
                  name = "linux";
                };
                name = "ubuntu";
                release = "24.04";
              };
              ram = "virtual";
              storage = "virtual";
              virtualization = "vm";
            }
            {
              name = "ubuntu-24.04";
              cpu = "intel";
              motherboard = "virtual";
              os = {
                kernel = {
                  name = "linux";
                };
                name = "ubuntu";
                release = "24.04";
              };
              ram = "virtual";
              storage = "virtual";
              virtualization = "vm";
            }
          ];
        };
      };
      corporateParent = "Microsoft";
    };

    # GitLab CI: https://docs.gitlab.com/ee/ci/
    gitlab = {
      cloud = {
        provider = "GCP";
        geo = {
          strictSovereignty = false;
          jurisdiction = [ "US" ];
          regions = [
            "AS"
            "EU"
            "NA"
            "OC"
            "SA"
          ];
        };
        oidcIssuer = "https://gitlab.com";
        ossFree = true;
        registry = "registry.gitlab.com";
        systems = {
          "aarch64-darwin" = [
            {
              name = "saas-macos-medium-m2";
              cpu = "apple";
              motherboard = "mac_mini";
              ossFree = false;
              os = {
                kernel = {
                  name = "darwin";
                  version = "23.6";
                };
                name = "macos";
                release = "14";
              };
              ram = "physical";
              storage = "nvme";
              virtualization = "bare_metal";
            }
            {
              name = "saas-macos-large-m2";
              cpu = "apple";
              motherboard = "virtual";
              ossFree = false;
              os = {
                kernel = {
                  name = "darwin";
                  version = "23.6";
                };
                name = "macos";
                release = "14";
              };
              ram = "virtual";
              storage = "virtual";
              virtualization = "vm";
            }
          ];
          "aarch64-linux" = [
            {
              name = "saas-linux-medium-arm64";
              cpu = "ampere";
              motherboard = "virtual";
              os = {
                kernel = {
                  name = "linux";
                };
                name = "ubuntu";
                release = "22.04";
              };
              ram = "virtual";
              storage = "virtual";
              virtualization = "vm";
            }
            {
              name = "saas-linux-small-arm64";
              cpu = "graviton";
              motherboard = "virtual";
              os = {
                kernel = {
                  name = "linux";
                };
                name = "ubuntu";
                release = "22.04";
              };
              ram = "virtual";
              storage = "virtual";
              virtualization = "vm";
            }
          ];
          "x86_64-darwin" = [
            {
              name = "saas-macos-medium-amd64";
              cpu = "intel";
              motherboard = "mac_mini";
              ossFree = false;
              os = {
                kernel = {
                  name = "darwin";
                  version = "22.6";
                };
                name = "macos";
                release = "13";
              };
              ram = "physical";
              storage = "ssd";
              virtualization = "bare_metal";
            }
            {
              name = "saas-macos-large-amd64";
              cpu = "intel";
              motherboard = "virtual";
              ossFree = false;
              os = {
                kernel = {
                  name = "darwin";
                  version = "22.6";
                };
                name = "macos";
                release = "13";
              };
              ram = "virtual";
              storage = "virtual";
              virtualization = "vm";
            }
          ];
          "x86_64-linux" = [
            {
              name = "saas-linux-medium-amd64";
              cpu = "amd";
              motherboard = "virtual";
              os = {
                kernel = {
                  name = "linux";
                };
                name = "ubuntu";
                release = "22.04";
              };
              ram = "virtual";
              storage = "virtual";
              virtualization = "vm";
            }
            {
              name = "saas-linux-large-amd64";
              cpu = "intel";
              motherboard = "virtual";
              ossFree = false;
              os = {
                kernel = {
                  name = "linux";
                };
                name = "ubuntu";
                release = "22.04";
              };
              ram = "virtual";
              storage = "virtual";
              virtualization = "vm";
            }
          ];
        };
      };
      corporateParent = "GitLab";
    };

    # Harness CI: https://harness.io/products/continuous-integration
    harness = {
      cloud = {
        provider = "GCP";
        geo = {
          strictSovereignty = false;
          jurisdiction = [ "US" ];
          regions = [
            "EU"
            "NA"
          ];
        };
        # real issuer is account-scoped:
        # https://app.harness.io/ng/api/oidc/account/<account-id>
        oidcIssuer = "https://app.harness.io";
        ossFree = "partial"; # "Free Forever" tier with limited usage/features
        systems = {
          "aarch64-linux" = [
            {
              name = "linux-arm64";
              cpu = "ampere";
              motherboard = "virtual";
              os = {
                kernel = {
                  name = "linux";
                };
                name = "ubuntu";
                release = "22.04";
              };
              ram = "virtual";
              storage = "virtual";
              virtualization = "vm";
            }
            {
              name = "linux-arm64";
              cpu = "graviton";
              motherboard = "virtual";
              os = {
                kernel = {
                  name = "linux";
                };
                name = "ubuntu";
                release = "22.04";
              };
              ram = "virtual";
              storage = "virtual";
              virtualization = "vm";
            }
          ];
          "x86_64-linux" = [
            {
              name = "linux-amd64";
              cpu = "amd";
              motherboard = "virtual";
              os = {
                kernel = {
                  name = "linux";
                };
                name = "ubuntu";
                release = "22.04";
              };
              ram = "virtual";
              storage = "virtual";
              virtualization = "vm";
            }
            {
              name = "linux-amd64";
              cpu = "intel";
              motherboard = "virtual";
              os = {
                kernel = {
                  name = "linux";
                };
                name = "ubuntu";
                release = "22.04";
              };
              ram = "virtual";
              storage = "virtual";
              virtualization = "vm";
            }
          ];
        };
      };
      corporateParent = "Harness";
    };

    # Scaleway: https://www.scaleway.com/
    scaleway = {
      cloud = {
        provider = "Scaleway";
        geo = {
          strictSovereignty = false;
          jurisdiction = [
            "EU"
            "FR"
          ];
          regions = [ "EU" ];
        };
        oidcIssuer = "https://oidc.scaleway.com";
        ossFree = "partial"; # limited free tier
        systems = {
          "x86_64-linux" = [
            {
              name = "ubuntu-22.04";
              cpu = "amd";
              motherboard = "virtual";
              os = {
                kernel = {
                  name = "linux";
                };
                name = "ubuntu";
                release = "22.04";
              };
              ram = "virtual";
              storage = "virtual";
              virtualization = "vm";
            }
            {
              name = "ubuntu-22.04";
              cpu = "intel";
              motherboard = "virtual";
              os = {
                kernel = {
                  name = "linux";
                };
                name = "ubuntu";
                release = "22.04";
              };
              ram = "virtual";
              storage = "virtual";
              virtualization = "vm";
            }
          ];
        };
      };
      corporateParent = "Iliad Group";
    };

    # Semaphore: https://semaphoreci.com/
    semaphore = {
      cloud = {
        provider = "GCP";
        geo = {
          strictSovereignty = false;
          jurisdiction = [
            "EU"
            "HR"
          ];
          regions = [
            "EU"
            "NA"
          ];
        };
        # real issuer is org-scoped:
        # https://<org>.semaphoreci.com
        oidcIssuer = "https://semaphoreci.com";
        ossFree = "partial"; # limited free tier (credits based)
        systems = {
          "aarch64-linux" = [
            {
              name = "ubuntu2204:current";
              cpu = "ampere";
              motherboard = "virtual";
              os = {
                kernel = {
                  name = "linux";
                };
                name = "ubuntu";
                release = "22.04";
              };
              ram = "virtual";
              storage = "virtual";
              virtualization = "vm";
            }
            {
              name = "ubuntu2204:current";
              cpu = "graviton";
              motherboard = "virtual";
              os = {
                kernel = {
                  name = "linux";
                };
                name = "ubuntu";
                release = "22.04";
              };
              ram = "virtual";
              storage = "virtual";
              virtualization = "vm";
            }
          ];
          "x86_64-linux" = [
            {
              name = "ubuntu2204:current";
              cpu = "amd";
              motherboard = "virtual";
              os = {
                kernel = {
                  name = "linux";
                };
                name = "ubuntu";
                release = "22.04";
              };
              ram = "virtual";
              storage = "virtual";
              virtualization = "vm";
            }
            {
              name = "ubuntu2204:current";
              cpu = "intel";
              motherboard = "virtual";
              os = {
                kernel = {
                  name = "linux";
                };
                name = "ubuntu";
                release = "22.04";
              };
              ram = "virtual";
              storage = "virtual";
              virtualization = "vm";
            }
          ];
        };
      };
      corporateParent = "Rendered Text";
    };

    # Spacelift: https://spacelift.io/
    spacelift = {
      cloud = {
        provider = "AWS";
        geo = {
          strictSovereignty = false;
          jurisdiction = [ "US" ];
          regions = [
            "EU"
            "NA"
          ];
        };
        # real issuer is account-scoped:
        # https://<account>.app.spacelift.io
        oidcIssuer = "https://app.spacelift.io";
        ossFree = false;
        systems = {
          "x86_64-linux" = [
            {
              name = "ubuntu-22.04";
              cpu = "amd";
              motherboard = "virtual";
              os = {
                kernel = {
                  name = "linux";
                };
                name = "ubuntu";
                release = "22.04";
              };
              ram = "virtual";
              storage = "virtual";
              virtualization = "vm";
            }
            {
              name = "ubuntu-22.04";
              cpu = "intel";
              motherboard = "virtual";
              os = {
                kernel = {
                  name = "linux";
                };
                name = "ubuntu";
                release = "22.04";
              };
              ram = "virtual";
              storage = "virtual";
              virtualization = "vm";
            }
          ];
        };
      };
      corporateParent = "Spacelift";
    };

    # HCP Terraform: https://www.hashicorp.com/products/terraform
    terraform = {
      cloud = {
        provider = "AWS";
        geo = {
          strictSovereignty = false;
          jurisdiction = [ "US" ];
          regions = [
            "EU"
            "NA"
          ];
        };
        oidcIssuer = "https://app.terraform.io";
        ossFree = false;
        systems = {
          "x86_64-linux" = [
            {
              name = "ubuntu-22.04";
              cpu = "amd";
              motherboard = "virtual";
              os = {
                kernel = {
                  name = "linux";
                };
                name = "ubuntu";
                release = "22.04";
              };
              ram = "virtual";
              storage = "virtual";
              virtualization = "vm";
            }
            {
              name = "ubuntu-22.04";
              cpu = "intel";
              motherboard = "virtual";
              os = {
                kernel = {
                  name = "linux";
                };
                name = "ubuntu";
                release = "22.04";
              };
              ram = "virtual";
              storage = "virtual";
              virtualization = "vm";
            }
          ];
        };
      };
      corporateParent = "IBM";
    };

    # Vercel: https://vercel.com/
    vercel = {
      cloud = {
        provider = "AWS";
        geo = {
          strictSovereignty = false;
          jurisdiction = [ "US" ];
          regions = [
            "AS"
            "EU"
            "NA"
            "OC"
            "SA"
          ];
        };
        # real issuer is team-scoped:
        # https://oidc.vercel.com/[team-slug]
        oidcIssuer = "https://oidc.vercel.com";
        ossFree = true;
        systems = {
          "x86_64-linux" = [
            {
              name = "ubuntu-22.04";
              cpu = "amd";
              motherboard = "virtual";
              os = {
                kernel = {
                  name = "linux";
                };
                name = "ubuntu";
                release = "22.04";
              };
              ram = "virtual";
              storage = "virtual";
              virtualization = "vm";
            }
            {
              name = "ubuntu-22.04";
              cpu = "intel";
              motherboard = "virtual";
              os = {
                kernel = {
                  name = "linux";
                };
                name = "ubuntu";
                release = "22.04";
              };
              ram = "virtual";
              storage = "virtual";
              virtualization = "vm";
            }
          ];
        };
      };
      corporateParent = "Vercel";
    };

  };
}
