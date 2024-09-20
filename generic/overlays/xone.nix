final: prev: {
  linuxPackages_latest = prev.linuxPackages_latest.extend (lpself: lpsuper: {
    xone = prev.linuxPackages_latest.xone.overrideAttrs (oldAttrs: {
      patches = [
        # Fix build on kernel 6.11
        # https://github.com/medusalix/xone/pull/48
        (prev.fetchpatch {
          name = "kernel-6.11.patch";
          url = "https://github.com/medusalix/xone/commit/28df566c38e0ee500fd5f74643fc35f21a4ff696.patch";
          hash = "sha256-X14oZmxqqZJoBZxPXGZ9R8BAugx/hkSOgXlGwR5QCm8=";
        })
      ];
    });
  });
}
