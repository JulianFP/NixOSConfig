{
  stdenv,
  lib,
  bash,
  sops,
  nixos-rebuild,
  nixos-anywhere,
  nixos-generators,
  openssh,
  makeWrapper,
}:
stdenv.mkDerivation rec {
  pname = "deployment";
  version = "0.1.0";
  src = ./src;
  buildInputs = [
    bash
    sops
    nixos-rebuild
    nixos-anywhere
    nixos-generators
    openssh
  ];
  nativeBuildInputs = [ makeWrapper ];
  installPhase = ''
    mkdir -p $out/bin
    cp deployment.sh $out/bin/deployment
    wrapProgram $out/bin/deployment \
      --prefix PATH : ${lib.makeBinPath buildInputs}
  '';
}
