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
	python311Packages.numpy
	python311Packages.scipy
	python311Packages.matplotlib
	python311Packages.requests
	python311Packages.pyserial
  ];
}
