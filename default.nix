{
  download-metadata ? builtins.fromJSON (builtins.readFile ./third-party/download-metadata.json),
}:
let
  inherit (builtins)
    attrNames
    concatMap
    listToAttrs
    mapAttrs
    filter
    groupBy
    sort
    ;

  optionalString = cond: value: if cond then value else "";

  mkShortName =
    v:
    "${v.name}-${toString v.major}.${toString v.minor}${
      optionalString (v.variant != null) "+${v.variant}"
    }";
  mkName =
    v:
    "${v.name}-${toString v.major}.${toString v.minor}.${toString v.patch}${
      optionalString (v.variant != null) "+${v.variant}"
    }";

in
{
  stdenv,
  callPackage,
  lib,
  archVariant ? null,
}:
let
  inherit (stdenv) isLinux isDarwin;

  archFamily = if isDarwin then stdenv.targetPlatform.darwinArch else stdenv.targetPlatform.qemuArch;

  os =
    if isLinux then
      "linux"
    else if isDarwin then
      "darwin"
    else
      throw "Unsupported platform";

  libc =
    if (stdenv.cc.libc.pname == "glibc") then
      "gnu"
    else if (stdenv.cc.libc.pname == "musl") then
      "musl"
    else
      "none";

  mkPython =
    meta:
    let
      python = callPackage (import ./nix meta) { self = python; };
    in
    python;

  # List of filtered Python download entries based on current platform
  filtered = concatMap (
    name:
    let
      v = download-metadata.${name};
    in
    if
      (
        # Match architecture/variant
        v.arch.family == archFamily
        && v.arch.variant == archVariant
        # Match os/platform
        && v.os == os
        && (v.libc == "none" || v.libc == libc)
      )
    then
      [ v ]
    else
      [ ]
  ) (attrNames download-metadata);

  # Only create short aliases for non-prereleases
  releases = filter (v: v.prerelease == "") filtered;

  packages =
    listToAttrs (
      map (v: {
        name = mkName v;
        value = mkPython v;
      }) filtered
    )
    // mapAttrs (
      _: candidates:
      packages.${
        (mkName (
          lib.last (sort (a: b: a.major <= b.major && a.minor <= b.minor && a.patch <= b.patch) candidates)
        ))
      }
    ) (groupBy mkShortName releases);
in
packages
