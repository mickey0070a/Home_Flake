{ inputs, pkgs, pname, version, src, ... }:

inputs.freecad-rc.packages.${pkgs.system}.freecad-dev.override {
  inherit pname version src;
}
