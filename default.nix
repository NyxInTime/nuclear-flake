{
  appimageTools,
  lib,
  fetchurl,
}:
let
  pname = "Nuclear";
  version = "1.48.4";

  src = fetchurl {
    url = "https://github.com/nukeop/nuclear/releases/download/player%401.48.4/${pname}_${version}_amd64.AppImage";
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
    install -m 444 -D ${appimageContents}/${pname}.desktop -t $out/share/applications
    substituteInPlace $out/share/applications/${pname}.desktop \
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
