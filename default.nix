{
  appimageTools,
  lib,
  fetchurl,
}:
let
  pname = "nuclear";
  version = "1.48.4";

  src = fetchurl {
    url = "https://github.com/nukeop/nuclear/releases/download/player%401.48.4/nuclear_${version}_amd64.AppImage";
    hash = "sha256-Lw+/6foiHnFWtaaU0jVh4s57oda59lQGojXsLg7KcDI=";
  };
  appimageContents = appimageTools.extract { inherit pname version src; };
in
appimageTools.wrapType2 {
  inherit
    pname
    version
    src
    ;

  extraInstallCommands = ''
    install -m 444 -D ${appimageContents}/Nuclear.desktop -t $out/share/applications
    substituteInPlace $out/share/applications/Nuclear.desktop \
      --replace-fail 'Exec=nuclear' 'Exec=${pname}' 
    cp -r ${appimageContents}/usr/share/icons $out/share
  '';

  meta = {
    description = "Streaming music player that finds free music for you";
    homepage = "https://nuclear.js.org/";
    license = lib.licenses.agpl3Plus;
    maintainers = [ lib.maintainers.NotAShelf ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "nuclear";
  };
}
