{ pkgs, ... }:

let
  freecad-fhs = pkgs.buildFHSUserEnv {
    name = "freecad";
    targetPkgs = pkgs: with pkgs; [
      freecad
      python3
      python3Packages.pip
      mesa
      libGL
    ];
    runScript = "${pkgs.freecad}/bin/freecad";
    profile = ''
      export PIP_PREFIX=$HOME/.local/pip-freecad
      export PYTHONPATH="$PIP_PREFIX/lib/python3.11/site-packages:$PYTHONPATH"
      export PATH="$PIP_PREFIX/bin:$PATH"
      mkdir -p "$PIP_PREFIX"
      unset SOURCE_DATE_EPOCH
    '';
  };
in
{
  home.packages = with pkgs; [
    librecad
    qalculate-gtk
    gmsh
    calculix-ccx
    inkscape-with-extensions
    gimp
    freecad-fhs          # <-- replaced freecad with freecad-fhs
    super-slicer
    orca-slicer
    qgis
  ];
}
