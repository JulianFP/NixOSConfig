{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  dpkg,
  wrapGAppsHook3,
  makeShellWrapper,
  gtk3,
  libX11,
  libXtst,
  nss,
  libdrm,
  alsa-lib,
  mesa,
  libcxx,
  systemd,
  libpulseaudio,
  atk,
  at-spi2-atk,
  at-spi2-core,
  cairo,
  cups,
  dbus,
  expat,
  fontconfig,
  freetype,
  gdk-pixbuf,
  glib,
  libglvnd,
  libnotify,
  libXcomposite,
  libunity,
  libuuid,
  libXcursor,
  libXdamage,
  libXext,
  libXfixes,
  libXi,
  libXrandr,
  libXrender,
  nspr,
  libxcb,
  pango,
  libXScrnSaver,
  libappindicator-gtk3,
  libdbusmenu,
  wayland,
}:

stdenv.mkDerivation rec {
  pname = "guilded";
  version = "2.0";

  src = fetchurl {
    url = "https://www.guilded.gg/downloads/Guilded-Linux.deb";
    hash = "sha256-Um0VtliKLDIrBPu1YuVuaPcIIKLbWK90CK5vc4Z8PXo=";
  };

  nativeBuildInputs = [
    autoPatchelfHook
    dpkg
    wrapGAppsHook3
    makeShellWrapper
    libX11
    libXtst
    gtk3
    nss
    libdrm
    alsa-lib
    mesa
  ];

  libPath = lib.makeLibraryPath [
    libcxx
    systemd
    libpulseaudio
    libdrm
    mesa
    stdenv.cc.cc
    alsa-lib
    atk
    at-spi2-atk
    at-spi2-core
    cairo
    cups
    dbus
    expat
    fontconfig
    freetype
    gdk-pixbuf
    glib
    gtk3
    libglvnd
    libnotify
    libX11
    libXcomposite
    libunity
    libuuid
    libXcursor
    libXdamage
    libXext
    libXfixes
    libXi
    libXrandr
    libXrender
    libXtst
    nspr
    libxcb
    pango
    libXScrnSaver
    libappindicator-gtk3
    libdbusmenu
    wayland
  ];

  unpackPhase = ''
    runHook preUnpack
    dpkg-deb -x $src .
    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/{bin,opt,share}
    mv opt/Guilded $out/opt/
    mv usr/share/icons $out/share/
    mv usr/share/applications $out/share/

    patchelf --set-interpreter ${stdenv.cc.bintools.dynamicLinker} \
        $out/opt/Guilded/guilded

    wrapProgramShell $out/opt/Guilded/guilded \
        "''${gappsWrapperArgs[@]}" \
        --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform=wayland --enable-features=WaylandWindowDecorations}}" \
        --prefix XDG_DATA_DIRS : "${gtk3}/share/gsettings-schemas/${gtk3.name}/" \
        --prefix LD_LIBRARY_PATH : ${libPath}:$out/opt/Guilded \

    ln -s $out/opt/Guilded/guilded $out/bin/

    substituteInPlace $out/share/applications/guilded.desktop \
      --replace Exec=/opt/Guilded/guilded Exec=guilded

    runHook postInstall
  '';

  meta = with lib; {
    description = "Guilded upgrades your group chat and equips your server with integrated event calendars, forums, and more - 100% free.";
    homepage = "https://www.guilded.gg";
    downloadPage = "https://www.guilded.gg/downloads";
    license = licenses.unfree;
    mainProgram = "guilded";
  };
}
