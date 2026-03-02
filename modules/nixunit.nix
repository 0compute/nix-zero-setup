{

  perSystem =
    { inputs, system, ... }:
    {

      nix-unit =
        let
          inputs' = builtins.removeAttrs inputs [ "self" ];
        in
        {
          # inputs = inputs';
          tests = import ../tests/test_examples.nix {
            # inputs = inputs';
            nix-seed = inputs.self;
            inherit system;
          };
        };

    };

}
