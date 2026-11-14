{ pkgs, ... }:

let
  freecadRC = pkgs.callPackage ./freecad-appimage.nix {
    pname = "freecad-rc";
    version = "26.3rc2";
    src = pkgs.fetchurl {
      url = "https://github.com/FreeCAD/FreeCAD/releases/download/26.3rc2/FreeCAD_26.3rc2-Linux-x86_64.AppImage";
      hash = "sha256-LPQhLVo0hXTnhtp9Wo+u6z6D3UJFwjiY3t6SzoLOSQg=";
    };
  };

  freecad-with-pip = pkgs.writeShellScriptBin "freecad" ''
    mods="$HOME/.local/share/freecad/mods"
    mkdir -p "$mods"

    export PIP_DISABLE_PIP_VERSION_CHECK=1
    export PIP_BREAK_SYSTEM_PACKAGES=1
    export PYTHONPATH="$mods''${PYTHONPATH:+:$PYTHONPATH}"

    exec ${freecadRC}/bin/freecad-rc --python-path "$mods" "$@"
  '';
in
{
  home.packages = with pkgs; [
    librecad
    qalculate-gtk
    gmsh
    calculix-ccx
    inkscape-with-extensions
    gimp
    freecad-with-pip
    # super-slicer
    orca-slicer
    qgis
    steam-run
  ];
}
