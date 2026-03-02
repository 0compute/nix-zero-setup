{ self, ... }:
{

  perSystem =
    { lib, pkgs, ... }:
    {

      packages =
        let
          name = "nix-seed";
          seed = self.lib.mkSeed {
            inherit name pkgs self;
            selfFilter =
              drv:
              let
                # CHECK: needs the or?
                drvName = drv.name or "";
              in
              !(builtins.any (name: lib.hasPrefix name drvName) [
                # filter self from seed otherwise this is circular
                name
                # filter examples since we want them built in check
                "examples"
              ]);
            # no rev when using `nix build path:.`
            tag = self.rev or self.dirtyRev or null;
          };
        in
        {
          default = seed;
          inherit seed;
        };

    };

}
