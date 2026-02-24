{
  description = "C/CMake development environment with MOSEK";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachSystem [ "aarch64-darwin" "x86_64-linux" ] (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;  # required for MOSEK
        };
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

            # Optimization (unfree — requires config.allowUnfree = true above)
            mosek
          ];

          shellHook = ''
            # MOSEK license must be present at ~/mosek/mosek.lic
            # Download from https://www.mosek.com/products/academic-licenses/
            if [ ! -f "$HOME/mosek/mosek.lic" ]; then
              echo "Warning: MOSEK license not found at ~/mosek/mosek.lic"
              echo "Download from https://www.mosek.com/products/academic-licenses/"
            fi

            echo "C/CMake+MOSEK dev shell ready ($(cmake --version | head -1))"
          '';
        };
      });
}
