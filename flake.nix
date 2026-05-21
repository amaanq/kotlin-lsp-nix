{
  description = "JetBrains Kotlin Language Server";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

  outputs =
    inputs:
    let
      version = "262.4739.0";

      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      # Standalone Kotlin LSP archives. Linux ships .tar.gz while macOS ships
      # .sit files that are actually plain zip containers.
      platformInfo = {
        "x86_64-linux" = {
          file = "kotlin-server-${version}.tar.gz";
          hash = "sha256-I1K/ypOnAtzHJ1btYur/SYAm7FLU2QzKcMjmeFXC+2c=";
        };
        "aarch64-linux" = {
          file = "kotlin-server-${version}-aarch64.tar.gz";
          hash = "sha256-/h51KBr1ob5RHyVlcdx0YBYYblPGlc+KxVG6y9HdqGs=";
        };
        "x86_64-darwin" = {
          file = "kotlin-server-${version}.sit";
          hash = "sha256-glBgiXGfiKHH9rb65eFWgmFsEycei6ZAVa0s/ButYaw=";
          extension = "zip";
        };
        "aarch64-darwin" = {
          file = "kotlin-server-${version}-aarch64.sit";
          hash = "sha256-/Wzvp0vbw8UQfCsHcT5SPLFYxo5clMy86Iy3uGDPOYQ=";
          extension = "zip";
        };
      };

      forAllSystems = inputs.nixpkgs.lib.genAttrs systems;

      mkPackage =
        system:
        let
          pkgs = inputs.nixpkgs.legacyPackages.${system};
          inherit (pkgs) lib;
          info = platformInfo.${system};
          isLinux = pkgs.stdenv.hostPlatform.isLinux;
        in
        pkgs.stdenv.mkDerivation {
          pname = "kotlin-lsp";
          inherit version;

          src = pkgs.fetchzip (
            {
              url = "https://download-cdn.jetbrains.com/kotlin-lsp/${version}/${info.file}";
              inherit (info) hash;
            }
            // lib.optionalAttrs (info ? extension) { inherit (info) extension; }
          );

          nativeBuildInputs = lib.optionals isLinux [
            pkgs.autoPatchelfHook
          ];

          # JBR bundles a full AWT/Swing-capable JDK, but the LSP runs with
          # -Djava.awt.headless=true so we don't pull in the X11/GTK stack
          # just to satisfy libraries that never get dlopen'd. Anything the
          # JVM and the LSP's actual native libs (rocksdbjni, filewatcher,
          # jna, pty4j, sqliteij) need at runtime is here.
          buildInputs = lib.optionals isLinux (
            with pkgs;
            [
              glibc
              stdenv.cc.cc.lib
              zlib
            ]
          );

          dontStrip = true;

          # JBR ships AWT/Swing/audio libs that link against the X11, Wayland,
          # font, and ALSA stacks, however, `-Djava.awt.headless=true` means nothing
          # dlopens them at runtime, so we let patchelf leave them with
          # unresolved deps rather than pulling in the whole GUI stack.
          autoPatchelfIgnoreMissingDeps = lib.optionals isLinux [
            "libc.musl-x86_64.so.1"
            "libc.musl-aarch64.so.1"
            "libX11.so.6"
            "libXext.so.6"
            "libXi.so.6"
            "libXrender.so.1"
            "libXtst.so.6"
            "libwayland-client.so.0"
            "libwayland-cursor.so.0"
            "libxkbcommon.so.0"
            "libfreetype.so.6"
            "libasound.so.2"
          ];

          installPhase = ''
            runHook preInstall

            mkdir -p $out/share/kotlin-lsp $out/bin
            cp -r . $out/share/kotlin-lsp/

            ln -s $out/share/kotlin-lsp/bin/intellij-server $out/bin/kotlin-lsp

            runHook postInstall
          '';

          meta = with lib; {
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
