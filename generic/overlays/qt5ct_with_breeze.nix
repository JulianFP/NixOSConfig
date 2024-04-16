{pkgs}:

(final: prev: {
  libsForQt5 = prev.libsForQt5.overrideScope (qtfinal: qtprev: {
    qt5ct = qtprev.qt5ct.overrideAttrs (old: {
      buildInputs = old.buildInputs ++ [ pkgs.libsForQt5.breeze-qt5 ];
    });
  });
  qt5ct = final.libsForQt5.qt5ct;
})
