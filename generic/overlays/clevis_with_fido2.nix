final: prev: let
  clevis-pin-fido2 = (prev.callPackage ../packages/clevis-pin-fido2/package.nix {});
in {
  clevis = prev.clevis.overrideAttrs(old: {
    buildInputs = old.buildInputs ++ [ clevis-pin-fido2 ];
    postInstall =
      let
        includeIntoPath = [
          prev.coreutils
          prev.cryptsetup
          prev.gnugrep
          prev.gnused
          prev.jose
          prev.libpwquality
          prev.luksmeta
          prev.tpm2-tools
          clevis-pin-fido2
        ];
      in
      ''
        wrapProgram $out/bin/clevis \
          --prefix PATH ':' "${prev.lib.makeBinPath includeIntoPath}:${placeholder "out"}/bin"
      '';
  });
}
