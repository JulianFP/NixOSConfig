final: prev: {
  lyx = prev.lyx.overrideAttrs (old: rec {
    version = "2.4.0";
    src = prev.fetchurl {
      url = "ftp://ftp.lyx.org/pub/lyx/stable/2.4.x/${old.pname}-${version}.tar.xz";
      hash = "sha256-51ddOkLpblfUXgYCKpJLzFESi1XGoNg/h0L+NGwuWfI=";
    };
  });
}
