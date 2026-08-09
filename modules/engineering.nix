{ pkgs, ... }:

let
freecad-with-pip = pkgs.writeShellScriptBin "freecad" ''
  export PYTHONUSERBASE="$HOME/.local"

  ${pkgs.python313Packages.pip}/bin/pip install \
    --target "$PYTHONUSERBASE/lib/python3.13/site-packages" \
    pip setuptools wheel >/dev/null 2>&1 || true

  export PYTHONPATH="$PYTHONUSERBASE/lib/python3.13/site-packages:$PYTHONPATH"

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
