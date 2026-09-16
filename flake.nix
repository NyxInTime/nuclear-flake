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

      nixosModules.default = {
        imports = [ ./default.nix ];
      };
      packages = forEachSystem (pkgs: {
        default = pkgs.callPackage ./default.nix { };
      });
    };
}
