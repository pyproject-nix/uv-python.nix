{
  download-metadata ? builtins.fromJSON (builtins.readFile ./third-party/download-metadata.json),
}:
let
  inherit (builtins)
    head
    splitVersion
    attrNames
    concatMap
    listToAttrs
    ;
in
{
  stdenv,
  callPackage,
  lib,
  archVariant ? null,
}:
let
  inherit (stdenv) isLinux isDarwin isFreeBSD;

  archFamily = if isDarwin then stdenv.targetPlatform.darwinArch else stdenv.targetPlatform.qemuArch;

  os =
    if isLinux then
      "linux"
    else if isDarwin then
      "darwin"
    else if isFreeBSD then
      "freebsd${head (splitVersion stdenv.cc.libc.version)}"
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

  filtered = listToAttrs (
    concatMap (
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
        [
          {
            # Create a name without arch/platform suffix
            name = lib.removeSuffix ("-${v.os}-${v.arch.family}${(if v.arch.variant != null then "-${v.arch.variant}" else "")}-${v.libc}") name;
            value = mkPython v;

          }
        ]
      else
        [ ]
    ) (attrNames download-metadata)
  );
in
filtered
