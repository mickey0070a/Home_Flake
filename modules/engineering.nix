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
	python312Full
	python312Packages.networkx
	python312Packages.openpyxl
	python312Packages.numpy
	python312Packages.scipy
	python312Packages.matplotlib
	python312Packages.requests
	python312Packages.pyserial
	python312Packages.pip
	python312Packages.lxml
  ];
}
