{
  stdenv,
  lib,
  bash,
  sops,
  nebula,
  cryptsetup,
  makeWrapper,
}:
stdenv.mkDerivation rec {
  pname = "createNebulaDevice";
  version = "0.1.0";
  src = ./src;
  buildInputs = [
    bash
    sops
    nebula
    cryptsetup
  ];
  nativeBuildInputs = [ makeWrapper ];
  installPhase = ''
    mkdir -p $out/bin
    cp createNebulaDevice.sh $out/bin/createNebulaDevice
    wrapProgram $out/bin/createNebulaDevice \
      --prefix PATH : ${lib.makeBinPath buildInputs}
  '';
}
