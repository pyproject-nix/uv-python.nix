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
  pythonManylinuxPackages,
  libxft,
  zlib,
}:
let
  implementation = meta.name;
  major = toString meta.major;
  minor = toString meta.minor;
  patch = toString meta.patch;
  pythonVersion = "${major}.${minor}";

  # Patchelf breaks the ELFs that are shipped by python-build-standalone for some reason.
  # If we can't patch the Python interpreter's ELF interpreter we can instead wrap & hard-code it.
  hackAutoPatchelf = implementation == "cpython" && meta.libc == "gnu";
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
  ]
    ++ lib.optional (!stdenv.isDarwin) autoPatchelfHook;

  buildInputs = [
    libxcrypt-legacy
  ]
    ++ lib.optional (implementation == "graalpy") zlib
    ++ lib.optional (implementation == "pypy") libxft
  ;

  postFixup = ''
    python3 ${./fixup-pc.py}
  '' + lib.optionalString hackAutoPatchelf ''
    python3 ${./fixup.py}
    autoPatchelf $out/lib
    for bin in $out/bin/.*-wrapped; do
      patchelf --add-rpath ${lib.makeLibraryPath [ libxcrypt-legacy ]} $bin
    done
  '';
  ${if hackAutoPatchelf then "dontAutoPatchelf" else null} = true;

  installPhase = ''
    if test -e install; then
      mv install $out
    else
      mkdir $out
      mv * $out
    fi
  '';

  passthru = {
    interpreter =
      if major == "3" then "${self}/bin/python3"
      else "${self}/bin/python";
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
        "cp${major}${minor}${lib.optionalString (meta.variant != null && lib.hasPrefix "freethreaded" meta.variant) "t"}"
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
    isPyPy = implementation == "pypy";
  };
}
