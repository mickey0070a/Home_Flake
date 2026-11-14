
{ appimageTools, fetchurl, lib, ... }:

let
  pname = "freecad-rc";
  version = "26.3rc2";

  src = fetchurl {
    url = "https://github.com/FreeCAD/FreeCAD/releases/download/26.3rc2/FreeCAD_26.3rc2-Linux-x86_64.AppImage";
    hash = "sha256-LPQhLVo0hXTnhtp9Wo+u6z6D3UJFwjiY3t6SzoLOSQg=";
  };

in
appimageTools.wrapType2 {
  inherit pname version src;

  extraPkgs = pkgs: with pkgs; [
    # Additional dependencies can be added here if needed.
  ];

  # Give the executable a predictable name.
  extraInstallCommands = ''
    mv "$out/bin/${pname}-${version}" "$out/bin/${pname}"
  '';

  meta = {
    description = "FreeCAD 26.3 Release Candidate 2";
    homepage = "https://www.freecad.org/";
    license = lib.licenses.lgpl21Plus;
    platforms = [ "x86_64-linux" ];
    mainProgram = pname;
  };
}
