{ pkgs-stable, ... }:
final: prev: {
  libsForQt5 = prev.libsForQt5.overrideScope (
    qtfinal: qtprev: {
      inherit (pkgs-stable.libsForQt5) breeze-qt5;
      qt5ct = pkgs-stable.libsForQt5.qt5ct.overrideAttrs (old: {
        buildInputs =
          old.buildInputs
          ++ (with final; [
            libsForQt5.breeze-qt5
          ]);
      });
    }
  );
  qt5ct = final.libsForQt5.qt5ct;
}
