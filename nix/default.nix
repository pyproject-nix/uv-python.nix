let
  unquoteURL =
    builtins.replaceStrings
      [
        "%21"
        "%23"
        "%24"
        "%26"
        "%27"
        "%28"
        "%29"
        "%2A"
        "%2B"
        "%2C"
        "%2F"
        "%3A"
        "%3B"
        "%3D"
        "%3F"
        "%40"
        "%5B"
        "%5D"
      ]
      [
        "!"
        "#"
        "$"
        "&"
        "'"
        "("
        ")"
        "*"
        "+"
        ","
        "/"
        ":"
        ";"
        "="
        "?"
        "@"
        "["
        "]"
      ];

in
meta:
{
  stdenv,
  fetchurl,
  zstd,
  autoPatchelfHook,
  libxcrypt-legacy,
  lib,
  self,
  makeBinaryWrapper,
  python3,
}:
let
  implementation = meta.name;
  major = toString meta.major;
  minor = toString meta.minor;
  patch = toString meta.patch;
  pythonVersion = "${major}.${minor}";
in
stdenv.mkDerivation {
  pname = meta.name;
  version = "${major}.${minor}.${patch}" + (if meta.prerelease != "" then "-${meta.prerelease}" else "");

  src =
    # Use builtin fetcher when hash is not available
    if meta.sha256 == null then
      builtins.fetchurl {
        url = meta.url;
        name = unquoteURL (lib.last (lib.splitString "/" meta.url));
      }
    else
      fetchurl {
        inherit (meta) url sha256;
      };

  dontConfigure = true;
  dontBuild = true;
  dontStrip = true;

  nativeBuildInputs = [
    zstd
    python3
  ];

  buildInputs = [
    libxcrypt-legacy
  ];

  installPhase = ''
    if test -e install; then
      mv install $out
    else
      mkdir $out
      mv * $out
    fi
  '';

  # Apply a "fixup" script that creates an interpreter wrapper.
  #
  # Patchelf breaks the ELFs that are shipped by python-build-standalone for some reason.
  # If we can't patch the Python interpreter's ELF interpreter we can instead wrap & hard-code it.
  postFixup = lib.optionalString (!stdenv.isDarwin) ''
    python3 ${./fixup.py}
  '';

  passthru = {
    interpreter = "${self}/bin/python";
    inherit implementation pythonVersion;
    libPrefix = "python${pythonVersion}";
    sourceVersion = {
      inherit major minor patch;
      suffix = meta.prerelease;
    };
    hasDistutilsCxxPatch = false;
    sitePackages = "lib/python${pythonVersion}/site-packages";

    # TODO: Figure out how to do cross
    pythonOnBuildForHost = self;

    pythonABITags =
      if implementation == "cpython" then [
        "abi3"
        "none"
        "cp${major}${minor}${lib.optionalString (lib.hasPrefix "freethreaded" meta.variant) "t"}"
      ] else if implementation == "pypy" then [
        "none"
        "pypy${lib.concatStrings (lib.take 2 (lib.splitString "." pythonVersion))}_pp${major}${minor}"
      ] else if implementation == "graalpy" then [
        "none"
      ] else [
        "none"
      ];

    # Various misguided *is* checks
    pythonOlder = lib.versionOlder pythonVersion;
    isPy2 = major == "2";
    isPy3k = major == "3";
    isPy27 = major == "2" && minor == "7";
    isPy3 = major == "3";
    isPy35 = pythonVersion == "3.5";
    isPy36 = pythonVersion == "3.6";
    isPy37 = pythonVersion == "3.7";
    isPy38 = pythonVersion == "3.8";
    isPy39 = pythonVersion == "3.9";
    isPy310 = pythonVersion == "3.10";
    isPy311 = pythonVersion == "3.11";
    isPy312 = pythonVersion == "3.12";
    isPy313 = pythonVersion == "3.13";
    isPy314 = pythonVersion == "3.14";
    isPy315 = pythonVersion == "3.15";
    isPy316 = pythonVersion == "3.16";
    isPy317 = pythonVersion == "3.17";
    isPyPy = implementation == "pypy";
  };
}
