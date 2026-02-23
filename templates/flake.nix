{
  description = "C/CMake development environment with MOSEK";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachSystem [ "aarch64-darwin" "x86_64-linux" ] (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in {
        devShells.default = pkgs.mkShell {
          name = "c-cmake-mosek";

          nativeBuildInputs = with pkgs; [
            cmake
            pkg-config
            ninja
          ];

          buildInputs = with pkgs; [
            # C/C++ toolchain
            gcc
            llvmPackages.openmp

            # Math / linear algebra
            blas
            lapack
          ];

          shellHook = ''
            # MOSEK is installed outside Nix (see install_mosek.sh).
            # Point CMake/pkg-config at it if present.
            MOSEK_VERSION="11.0"
            if [ "$(uname -s)" = "Darwin" ]; then
              MOSEK_PLATFORM="osxaarch64"
            else
              MOSEK_PLATFORM="linuxaarch64"  # adjust for x86: linuxx86_64
            fi
            MOSEK_DIR="$HOME/mosek/$MOSEK_VERSION/tools/platform/$MOSEK_PLATFORM"
            if [ -d "$MOSEK_DIR" ]; then
              export MOSEK_DIR
              export CMAKE_PREFIX_PATH="$MOSEK_DIR:${CMAKE_PREFIX_PATH:-}"
              export LD_LIBRARY_PATH="$MOSEK_DIR/bin:${LD_LIBRARY_PATH:-}"
              export DYLD_LIBRARY_PATH="$MOSEK_DIR/bin:${DYLD_LIBRARY_PATH:-}"
              echo "MOSEK $MOSEK_VERSION found at $MOSEK_DIR"
            else
              echo "Warning: MOSEK not found at $MOSEK_DIR — run install_mosek.sh first"
            fi

            echo "C/CMake+MOSEK dev shell ready ($(cmake --version | head -1))"
          '';
        };
      });
}
