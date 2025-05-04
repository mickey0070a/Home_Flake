{ pkgs, ... }:

{
  home.packages = with pkgs; [
	librecad
	qalculate-gtk
	gmsh
	calculix
	inkscape-with-extensions
	gimp
	freecad
  ];
}
