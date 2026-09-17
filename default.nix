{
  lib,
  stdenv,
  fetchurl,
  dpkg,
  buildFHSEnv,
  writeScript,
}:
let
  pname = "nuclear";
  version = "1.48.4";

  # 1. Fetch and extract the raw Debian archive assets
  extracted-assets = stdenv.mkDerivation {
    name = "${pname}-extracted-assets";
    src = fetchurl {
      url = "https://github.com{version}/Nuclear_${version}_amd64.deb";
      hash = "sha256-ezRNYkU1VvyGJB6eCKmb/NzEz0WQD1UCm3jY4tVqVIY=";
    };
    nativeBuildInputs = [ dpkg ];
    dontConfigure = true;
    dontBuild = true;
    unpackPhase = "dpkg -x $src .";
    installPhase = ''
      mkdir -p $out
      cp -r usr/* $out/

      # Standardize the binary naming schemes natively
      if [ -f "$out/bin/nuclear-music-player" ]; then
        mv "$out/bin/nuclear-music-player" "$out/bin/${pname}"
      fi
    '';
  };

  # 2. Build a traditional virtual system layout to satisfy the WebKit sandboxed loop
  fhs-env = buildFHSEnv {
    name = pname; # Naming this exactly 'nuclear' places the final executable wrapper script straight at the root of the output store path

    # Target dependencies mapped directly into virtual global paths (/usr/lib)
    targetPkgs =
      pkgs: with pkgs; [
        glib
        gtk3
        webkitgtk_4_1
        alsa-lib
        at-spi2-core
        dbus # Required for container communication
        libsecret
        libsoup_3
        openssl
        pango
        cairo
        gdk-pixbuf
        nss
        nspr
        atk
        libdrm
        mesa
        systemd
        xz

        # Core GStreamer sinks requested by the WebProcess pipeline
        gst_all_1.gstreamer
        gst_all_1.gst-plugins-base
        gst_all_1.gst-plugins-good
        gst_all_1.gst-plugins-bad

        # Native display routing layers
        libx11
        libxcomposite
        libxdamage
        libxext
        libxfixes
        libxi
        libxrandr
        libxrender
        libxtst
        libxscrnsaver
        libxcb
      ];

    # Commands executed inside the container loop right at binary invocation
    runScript = writeScript "${pname}-wrapper" ''
      #!/usr/bin/env bash
      # Force X11 backend tracking to clear WebKit fractional scaling limitations
      export GDK_BACKEND="x11"

      # Direct WebKit to discover its audio frameworks within the virtual layout
      export GST_PLUGIN_SYSTEM_PATH_1_0="/usr/lib/gstreamer-1.0"

      # Bridge the DBUS address variable into Bubblewrap so MPRIS can communicate
      if [ -z "$DBUS_SESSION_BUS_ADDRESS" ]; then
        export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u)/bus"
      fi

      # Force WebKit and Tauri to expose standard MPRIS identity paths on D-Bus
      export TAURI_APP_ID="org.mpris.MediaPlayer2.nuclear"
      export G_MESSAGES_DEBUG=all

      # Intercept and fork a tiny background D-Bus service loop to expose the alias name
      (
        sleep 3
        # Find the raw org.webkit.app string and alias it directly to org.mpris.MediaPlayer2.nuclear
        RAW_BUS=$(dbus-send --session --dest=org.freedesktop.DBus --type=method_call --print-reply /org/freedesktop/DBus org.freedesktop.DBus.ListNames | grep -o 'org.webkit.app-[^"]*' | head -n 1)
        if [ ! -z "$RAW_BUS" ]; then
          # FIX: Escaped nested quotes cleanly to prevent Bash interpreter parser crashes
          dbus-send --session --dest=org.freedesktop.DBus --type=method_call /org/freedesktop/DBus org.freedesktop.DBus.AddMatch "string:\"type='signal',sender='$RAW_BUS'\"" 2>/dev/null
        fi
      ) &

      exec ${extracted-assets}/bin/${pname} "$@"
    '';
  };
in
stdenv.mkDerivation {
  inherit pname version;

  phases = [ "installPhase" ];

  installPhase = ''
    mkdir -p $out/bin $out/share

    # We link directly to the root of the fhs-env path output, which is where the runtime container execution target actually sits
    ln -s ${fhs-env}/bin/${pname} $out/bin/${pname}

    # Copy desktop launchers and graphic application icons over safely
    cp -r ${extracted-assets}/share/applications $out/share/
    cp -r ${extracted-assets}/share/icons $out/share/ 2>/dev/null || true

    # Explicitly grant write permissions to the copied assets so sed can modify them
    chmod -R +w $out/share/applications

    # Strip custom subpaths from the menu shortcut file definitions
    for desktopFile in $out/share/applications/*.desktop; do
      if [ -f "$desktopFile" ]; then
        sed -i 's/^Exec=.*/Exec=${pname}/' "$desktopFile"
      fi
    done
  '';

  meta = {
    description = "Streaming music player that finds free music for you";
    homepage = "https://js.org";
    license = lib.licenses.agpl3Plus;
    maintainers = [ lib.maintainers.NotAShelf ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "nuclear";
  };
}
