{
  pkgs,
  lib,
  fetchFromGitHub,
  kernel ? pkgs.linuxPackages_testing.kernel,
}:

pkgs.stdenv.mkDerivation {
  pname = "bcachefs-kernel-module";
  inherit (kernel)
    src
    version
    postPatch
    nativeBuildInputs
    ;

  /*
    src = fetchFromGitHub {
      owner = "koverstreet";
      repo = "bcachefs";
      rev = "23692ade03727026efe1b76e103e89a3c9cb1224";
      hash = "sha256-rdZub0alTPU139bYMwK51Xg+BbjHNrHFOmV9j1Gah4c=";
    };
  */

  kernel_dev = kernel.dev;
  kernelVersion = kernel.modDirVersion;

  modulePath = "fs/bcachefs";

  buildPhase = ''
    BUILT_KERNEL=$kernel_dev/lib/modules/$kernelVersion/build

    cp $BUILT_KERNEL/Module.symvers .
    cp $BUILT_KERNEL/.config        .
    cp $kernel_dev/vmlinux          .

    make "-j$NIX_BUILD_CORES" modules_prepare
    make "-j$NIX_BUILD_CORES" M=$modulePath modules
  '';

  installPhase = ''
    make \
      INSTALL_MOD_PATH="$out" \
      XZ="xz -T$NIX_BUILD_CORES" \
      M="$modulePath" \
      modules_install
  '';

  meta = {
    description = "bcachefs kernel module";
    license = lib.licenses.gpl2;
  };
}
