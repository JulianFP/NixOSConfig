{
  lib,
  stdenv,
  makeWrapper,
  coreutils,
  fetchFromGitHub,
  jose,
  libfido2,
}:

stdenv.mkDerivation (finalAttrs: rec {
  pname = "clevis-pin-fido2";
  version = "0-unstable-2024-04-17";

  src = fetchFromGitHub {
    owner = "olastor";
    repo = "clevis-pin-fido2";
    rev = "4b69b5554b71c4d5e7ba68ff4967fd12b357a410";
    hash = "sha256-mOeeEfvtDUQaT/Q17mkNk0UuoFmy+NVa6mgGTt8hW+M=";
  };

  nativeBuildInputs = [
    makeWrapper
  ];

  buildInputs = [
    jose
    libfido2
  ];

  #same /bin/cat stuff as with main clevis package
  postPatch = ''
        for f in $(find . -type f -print0 |\
                     xargs -0 -I@ sh -c 'grep -q "/bin/cat" "$1" && echo "$1"' sh @); do
          substituteInPlace "$f" --replace-fail '/bin/cat' '${lib.getExe' coreutils "cat"}'
        done
    	'';

  installPhase = ''
    		mkdir -p $out/bin
    		cp clevis-decrypt-fido2 $out/bin
    		cp clevis-encrypt-fido2 $out/bin
        wrapProgram $out/bin/clevis-decrypt-fido2 \
          --prefix PATH : ${lib.makeBinPath buildInputs}
        wrapProgram $out/bin/clevis-encrypt-fido2 \
          --prefix PATH : ${lib.makeBinPath buildInputs}
    	'';

  meta = {
    homepage = "https://github.com/olastor/clevis-pin-fido2";
    description = "Experimental Clevis pin for fido2 devices";
    longDescription = ''
      			Additional pin for clevis that adds support for both encryption and decryption using fido2 devices. Should currently be considered experimental!
      		'';
    license = lib.licenses.mit;
  };
})
