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
	python311Full
	python311Packages.networkx
	python311Packages.openpyxl
  ];
}
