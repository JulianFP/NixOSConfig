final: prev:
let
  clevis-pin-fido2 = (final.callPackage ../packages/clevis-pin-fido2/package.nix { });
in
{
  clevis = prev.clevis.overrideAttrs (old: {
    buildInputs = old.buildInputs ++ [
      final.jq
      clevis-pin-fido2
    ];
    postInstall =
      let
        includeIntoPath = [
          final.coreutils
          final.cryptsetup
          final.gnugrep
          final.gnused
          final.jose
          final.libpwquality
          final.luksmeta
          final.tpm2-tools
          final.jq
          clevis-pin-fido2
        ];
      in
      ''
        wrapProgram $out/bin/clevis \
          --prefix PATH ':' "${final.lib.makeBinPath includeIntoPath}:${placeholder "out"}/bin"
      '';
  });
}
