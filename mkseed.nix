{
  pkgs,
  self ? null,
  selfFilter ? (_drv: true),
  # name from flake default package
  name ? (
    let
      default = "unnamed";
    in
    "${
      if self != null then
        self.packages.${pkgs.stdenv.hostPlatform.system}.default.pname
      else
        default
    }-seed"
  ),
  nix ? pkgs.nixVersions.latest,
  nixConf ? ''
    experimental-features = nix-command flakes
  '',
  substitutes ? false,
  # these are tiny and make debug much easier - override to empty if desired
  debugTools ? with pkgs; [
    bashInteractive
    coreutils
  ],
  ...
}@args:
let
  inherit (pkgs) lib;
  inherit (pkgs.stdenv.hostPlatform) system;

  corePkgs =
    with pkgs;
    [
      # nix from args
      nix
      # nix fetchers
      cacert
      # actions runtime
      glibc
      stdenv.cc.cc.lib
    ]
    ++ lib.optionals (debugTools != [ ]) debugTools;

  contents =
    corePkgs
    ++ (lib.concatMap
      (
        drv:
        lib.concatMap (attr: drv.${attr} or [ ]) [
          "buildInputs"
          "nativeBuildInputs"
          "propagatedBuildInputs"
          "propagatedNativeBuildInputs"
        ]
      )
      (
        if self == null then
          [ ]
        else
          let
            getDerivations =
              attr: lib.filter selfFilter (lib.attrValues (self.${attr}.${system} or { }));
          in
          getDerivations "packages"
          ++ getDerivations "checks"
          # Apps have { type = "app"; program = "..."; }.
          # Extract if there's a package attr.
          ++ lib.filter (drv: lib.isDerivation drv && selfFilter drv) (
            map (app: app.package or null) (lib.attrValues (self.apps.${system} or { }))
          )
      )
    )
    ++ args.contents or [ ];

  config = lib.recursiveUpdate {
    Entrypoint = [ "/bin/bash" ];
    Env = lib.mapAttrsToList (name: value: "${name}=${value}") {
      HOME = "/tmp";
      USER = "root";
      GIT_TEXTDOMAINDIR = "${pkgs.git}/share/locale";
      GIT_INTERNAL_GETTEXT_TEST_FALLBACKS = "";
      # CHECK: disable build-users-group because containers often lack the group may be
      # agent bs
      NIX_CONFIG = ''
        sandbox = false
        build-users-group =
        substitutes = ${lib.boolToString substitutes}
        ${nixConf}
      '';
      LD_LIBRARY_PATH =
        "/lib:/lib64:/lib/" + pkgs.stdenv.hostPlatform.linuxArch + "-linux-gnu";
      SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
      PATH = "${./bin}:/bin:/usr/bin:/sbin:/usr/sbin";
    };
  } (args.config or { });

  image = pkgs.dockerTools.buildLayeredImage (
    (lib.removeAttrs args [
      "config"
      "contents"
      "flake"
      "flakeFilter"
      "nix"
      "nixConf"
      "pkgs"
      "self"
      "selfFilter"
    ])
    // {
      inherit name contents config;
      extraCommands = ''
        # nix needs /tmp to build
        mkdir --mode=1777 tmp

        # actions expect node here
        externals=__e
        mkdir $externals
        nodeDir=$externals/node${lib.versions.major pkgs.nodejs.version}
        mkdir --parents $nodeDir/bin
        ln -s ${lib.getExe pkgs.nodejs} $nodeDir/bin/node


        # Actions runtime expects glibc libs at the multiarch path.
        multiarchDir=lib/${pkgs.stdenv.hostPlatform.linuxArch}-linux-gnu
        mkdir $multiarchDir
        libc=${pkgs.glibc}/lib/libc.so.6
        libstdcpp=${pkgs.stdenv.cc.cc.lib}/lib/libstdc++.so.6
        ln -s $libc $multiarchDir/libc.so.6
        ln -s $libstdcpp $multiarchDir/libstdc++.so.6
      '';
    }
  );
in
# expose metadata for unit testing and inspection. buildLayeredImage does not
# support passthru or automatically export its internal arguments
image // { inherit contents config corePkgs; }
