final: prev: {
  libsForQt5 = prev.libsForQt5.overrideScope (qtfinal: qtprev: {
    qt5ct = qtprev.qt5ct.overrideAttrs (old: {
      buildInputs = old.buildInputs ++ (with prev; [ 
        breeze-qt5 
        libsForQt5.qtquickcontrols2
        libsForQt5.kconfig
        libsForQt5.kconfigwidgets
        libsForQt5.kiconthemes
      ]);

      nativeBuildInputs = with prev; [
        cmake
        libsForQt5.wrapQtAppsHook
        libsForQt5.qttools
      ];
      
      patches = [(prev.fetchpatch {
        url = "https://raw.githubusercontent.com/ilya-fedin/nur-repository/refs/heads/master/pkgs/qt5ct/qt5ct-shenanigans.patch";
        hash = "sha256-4Xg2r15TwkmBXxyeEOicsswTf4daXZTZUgKucNbq5X4=";
      })];

      cmakeFlags = [
        "-DPLUGINDIR=${placeholder "out"}/${prev.libsForQt5.qtbase.qtPluginPrefix}"
      ];
    });
  });
  qt6Packages = prev.qt6Packages.overrideScope (qtfinal: qtprev: {
    qt6ct = qtprev.qt6ct.overrideAttrs (old: {
      buildInputs = old.buildInputs ++ (with prev; [ 
        qt6Packages.qtdeclarative
        kdePackages.kconfig
        kdePackages.kcolorscheme
        kdePackages.kiconthemes
      ]);

      nativeBuildInputs = with prev; [
        cmake
        qt6Packages.wrapQtAppsHook
        qt6Packages.qttools
      ];
      
      patches = [(prev.fetchpatch {
        url = "https://raw.githubusercontent.com/ilya-fedin/nur-repository/refs/heads/master/pkgs/qt6ct/qt6ct-shenanigans.patch";
        hash = "sha256-rPODGjM/AKiEHM01z2DBkJqWrwayZzN24vIrO415nos=";
      })];

      cmakeFlags = [
        "-DPLUGINDIR=${placeholder "out"}/${prev.qt6Packages.qtbase.qtPluginPrefix}"
      ];
    });
  });
  qt5ct = final.libsForQt5.qt5ct;
  qt6ct = final.qt6Packages.qt6ct;
}
