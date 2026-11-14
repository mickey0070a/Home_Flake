{ inputs, pkgs, ... }:
let
  freecadRC = inputs.freecad-rc.packages.${pkgs.system}.freecad-dev.override {
    pname = "freecad-rc";
    version = "26.3rc2";
    src = pkgs.fetchurl {
      url = "https://github.com/FreeCAD/FreeCAD/releases/download/26.3rc2/FreeCAD_26.3rc2-Linux-x86_64.AppImage";
      hash = "sha256-LPQhLVo0hXTnhtp9Wo+u6z6D3UJFwjiY3t6SzoLOSQg=";
    };
  };
in
{
  environment.systemPackages = [ freecadRC ];
}
