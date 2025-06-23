inputs: systems:

let
  lib = inputs.nixpkgs-stable.lib;
  mkConfig = import ./mkConfig.nix;
  genConfig =
    name:
    value@{
      stable ? true,
      ...
    }:
    let
      nixpkgs = if stable then inputs.nixpkgs-stable else inputs.nixpkgs;
    in
    (mkConfig (
      {
        inherit inputs nixpkgs stable;
        hostName = name;
      }
      // (lib.filterAttrs (n: v: n != "format") value)
    ))
    // {
      format = value.format;
    };
  getGenerator = stable: if stable then inputs.nixos-generators-stable else inputs.nixos-generators;
  toGenSystems =
    AttrsOfLists:
    builtins.mapAttrs (
      name: value:
      builtins.listToAttrs (
        builtins.map (value: {
          name = value.specialArgs.hostName;
          value = (getGenerator value.specialArgs.stable).nixosGenerate value;
        }) value
      )
    ) AttrsOfLists;
in
toGenSystems (
  builtins.groupBy (builtins.getAttr "system") (lib.attrsets.mapAttrsToList genConfig systems)
)
