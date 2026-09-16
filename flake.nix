{
  description = "Nuclear Music Player Flake";
  inputs = {
    nixpkgs = {
      url = "nixpkgs/nixos-unstable";
      #config.allowUnfree = true;
    };

    #inputs :)
  };

  outputs =
    {
      #outputs :)
      self,
      nixpkgs,
      ...
    }:

    #The fun stuff? :)
    let
      lib = nixpkgs.lib;

      systems = [
        "x86_64-linux"
      ];

      forEachSystem =
        perSystem: nixpkgs.lib.genAttrs systems (system: perSystem nixpkgs.legacyPackages.${system});
    in
    {

      nixosModules.default =
        {
          config,
          lib,
          pkgs,
          ...
        }:
        {
          options.programs.nuclear.enable = lib.mkEnableOption "Nuclear Music Player";
          config = lib.mkIf config.programs.nuclear.enable {
            environment.systemPackages = [
              (pkgs.callPackage ./default.nix { })
            ];
          };
        };
      packages = forEachSystem (pkgs: {
        default = pkgs.callPackage ./default.nix { };
      });
    };
}
