{

  perSystem =
    {
      lib,
      pkgs,
      config,
      ...
    }:
    {

      apps =
        let

          mkApp = attrs: {
            type = "app";
            program = lib.getExe (pkgs.writeShellApplication attrs);
          };

        in
        {

          syncWorkflows = mkApp {
            name = "sync-workflows";
            runtimeInputs = with pkgs; [
              gitMinimal
              nixVersions.latest
              rsync
            ];
            text = ''
              rsync --archive --delete ${config.githubActions.workflowsDir}/ \
                $(git rev-parse --show-toplevel)/.github/
            '';
          };

          test = mkApp {
            name = "test";
            runtimeInputs = with pkgs; [
              coreutils
              jq
              oras
              skopeo
            ];
            text = ''

            '';
          };

          publish = mkApp {
            name = "publish";
            runtimeInputs = with pkgs; [
              gnutar
              gzip
              jq
              cosign
              podman
            ];
            text = builtins.readFile ./bin/publish;
          };

        };

    };

}
