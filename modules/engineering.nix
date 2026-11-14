{ pkgs, ... }:

let
  freecadRC = pkgs.callPackage ./freecad-appimage.nix {};

  freecad-with-pip = pkgs.writeShellScriptBin "freecad" ''
    mods="$HOME/.local/share/freecad/mods"
    mkdir -p "$mods"

    export PIP_DISABLE_PIP_VERSION_CHECK=1
    export PIP_BREAK_SYSTEM_PACKAGES=1
    export PYTHONPATH="$mods''${PYTHONPATH:+:$PYTHONPATH}"

    exec ${freecadRC}/libexec/FreeCAD.AppImage \
      --python-path "$mods" "$@"
  '';

in
{
  home.packages = with pkgs; [
    freecad-with-pip
    librecad
    qalculate-gtk
    gmsh
    calculix-ccx
    inkscape-with-extensions
    gimp
    orca-slicer
    qgis
    steam-run
  ];
}
