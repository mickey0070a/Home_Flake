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
	super-slicer
	qgis
	python313Full
	python313Packages.networkx
	python313Packages.openpyxl
  ];
}
