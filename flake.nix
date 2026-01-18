{
  description = "JetBrains Kotlin Language Server";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

  outputs =
    { self, nixpkgs }:
    let
      version = "261.13587.0";

      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      platformInfo = {
        "x86_64-linux" = {
          platform = "linux-x64";
          hash = "sha256-EweSqy30NJuxvlJup78O+e+JOkzvUdb6DshqAy1j9jE=";
        };
        "aarch64-linux" = {
          platform = "linux-aarch64";
          hash = "sha256-0dzrAA/gXF4sC1555PRKAHBQdI03aQnf/utUSp8dZQ=";
        };
        "x86_64-darwin" = {
          platform = "mac-x64";
          hash = "sha256-zMuUcahT1IiCT1NTrMCIzUNM0U6U3zaBkJtbGrzF7I8=";
        };
        "aarch64-darwin" = {
          platform = "mac-aarch64";
          hash = "sha256-zwlzVt3KYN0OXKr6sI9XSijXSbTImomSTGRGa+3zCK8=";
        };
      };

      forAllSystems = nixpkgs.lib.genAttrs systems;

      mkPackage =
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          info = platformInfo.${system};
        in
        pkgs.stdenv.mkDerivation {
          pname = "kotlin-lsp";
          inherit version;

          src = pkgs.fetchzip {
            url = "https://download-cdn.jetbrains.com/kotlin-lsp/${version}/kotlin-lsp-${version}-${info.platform}.zip";
            inherit (info) hash;
            stripRoot = false;
          };

          nativeBuildInputs = [ pkgs.makeWrapper ];
          buildInputs = [ pkgs.jdk21 ];

          installPhase = ''
            runHook preInstall

            mkdir -p $out/lib $out/bin $out/native
            cp -r lib/* $out/lib/
            cp -r native/* $out/native/

            cat > $out/bin/kotlin-lsp << 'SCRIPT'
            #!/usr/bin/env bash
            SCRIPT

            cat >> $out/bin/kotlin-lsp << SCRIPT
            exec ${pkgs.jdk21}/bin/java \\
              --add-opens java.base/java.io=ALL-UNNAMED \\
              --add-opens java.base/java.lang=ALL-UNNAMED \\
              --add-opens java.base/java.lang.ref=ALL-UNNAMED \\
              --add-opens java.base/java.lang.reflect=ALL-UNNAMED \\
              --add-opens java.base/java.net=ALL-UNNAMED \\
              --add-opens java.base/java.nio=ALL-UNNAMED \\
              --add-opens java.base/java.nio.charset=ALL-UNNAMED \\
              --add-opens java.base/java.text=ALL-UNNAMED \\
              --add-opens java.base/java.time=ALL-UNNAMED \\
              --add-opens java.base/java.util=ALL-UNNAMED \\
              --add-opens java.base/java.util.concurrent=ALL-UNNAMED \\
              --add-opens java.base/java.util.concurrent.atomic=ALL-UNNAMED \\
              --add-opens java.base/java.util.concurrent.locks=ALL-UNNAMED \\
              --add-opens java.base/jdk.internal.vm=ALL-UNNAMED \\
              --add-opens java.base/sun.net.dns=ALL-UNNAMED \\
              --add-opens java.base/sun.nio.ch=ALL-UNNAMED \\
              --add-opens java.base/sun.nio.fs=ALL-UNNAMED \\
              --add-opens java.base/sun.security.ssl=ALL-UNNAMED \\
              --add-opens java.base/sun.security.util=ALL-UNNAMED \\
              --add-opens java.desktop/java.awt=ALL-UNNAMED \\
              --add-opens java.desktop/java.awt.dnd.peer=ALL-UNNAMED \\
              --add-opens java.desktop/java.awt.event=ALL-UNNAMED \\
              --add-opens java.desktop/java.awt.font=ALL-UNNAMED \\
              --add-opens java.desktop/java.awt.image=ALL-UNNAMED \\
              --add-opens java.desktop/java.awt.peer=ALL-UNNAMED \\
              --add-opens java.desktop/javax.swing=ALL-UNNAMED \\
              --add-opens java.desktop/javax.swing.plaf.basic=ALL-UNNAMED \\
              --add-opens java.desktop/javax.swing.text=ALL-UNNAMED \\
              --add-opens java.desktop/javax.swing.text.html=ALL-UNNAMED \\
              --add-opens java.desktop/com.apple.eawt=ALL-UNNAMED \\
              --add-opens java.desktop/com.apple.eawt.event=ALL-UNNAMED \\
              --add-opens java.desktop/com.apple.laf=ALL-UNNAMED \\
              --add-opens java.desktop/com.sun.java.swing=ALL-UNNAMED \\
              --add-opens java.desktop/com.sun.java.swing.plaf.gtk=ALL-UNNAMED \\
              --add-opens java.desktop/sun.awt=ALL-UNNAMED \\
              --add-opens java.desktop/sun.awt.X11=ALL-UNNAMED \\
              --add-opens java.desktop/sun.awt.datatransfer=ALL-UNNAMED \\
              --add-opens java.desktop/sun.awt.image=ALL-UNNAMED \\
              --add-opens java.desktop/sun.awt.windows=ALL-UNNAMED \\
              --add-opens java.desktop/sun.font=ALL-UNNAMED \\
              --add-opens java.desktop/sun.java2d=ALL-UNNAMED \\
              --add-opens java.desktop/sun.lwawt=ALL-UNNAMED \\
              --add-opens java.desktop/sun.lwawt.macosx=ALL-UNNAMED \\
              --add-opens java.desktop/sun.swing=ALL-UNNAMED \\
              --add-opens java.management/sun.management=ALL-UNNAMED \\
              --add-opens jdk.attach/sun.tools.attach=ALL-UNNAMED \\
              --add-opens jdk.compiler/com.sun.tools.javac.api=ALL-UNNAMED \\
              --add-opens jdk.internal.jvmstat/sun.jvmstat.monitor=ALL-UNNAMED \\
              --add-opens jdk.jdi/com.sun.tools.jdi=ALL-UNNAMED \\
              --enable-native-access=ALL-UNNAMED \\
              -Djdk.lang.Process.launchMechanism=FORK \\
              -Djava.awt.headless=true \\
              -Xmx4g \\
              -XX:+UseG1GC \\
              -XX:+UseStringDeduplication \\
              -cp "$out/lib/*" \\
              com.jetbrains.ls.kotlinLsp.KotlinLspServerKt "\$@"
            SCRIPT
            chmod +x $out/bin/kotlin-lsp

            runHook postInstall
          '';

          meta = with pkgs.lib; {
            description = "JetBrains Kotlin Language Server";
            homepage = "https://github.com/Kotlin/kotlin-lsp";
            license = licenses.asl20;
            platforms = systems;
            maintainers = with maintainers; [ amaanq ];
            mainProgram = "kotlin-lsp";
          };
        };
    in
    {
      packages = forAllSystems (system: {
        default = mkPackage system;
        kotlin-lsp = mkPackage system;
      });
    };
}
