{ pkgs, ... }:

let
  freecad-with-pip = pkgs.writeShellScriptBin "freecad" ''
    export PIP_PREFIX=$HOME/.local/pip-freecad
    export PYTHONPATH="$PIP_PREFIX/lib/python3.13/site-packages:$PYTHONPATH"
    export PATH="$PIP_PREFIX/bin:$PATH"
    mkdir -p "$PIP_PREFIX"
    
    exec ${pkgs.steam-run}/bin/steam-run ${pkgs.freecad}/bin/freecad "$@"
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
    python313Packages.pip
    python313
    # super-slicer
    orca-slicer
    qgis
    steam-run  # Make sure this is available
  ];
}
