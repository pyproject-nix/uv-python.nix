{
  stdenv,
  lib,
  self,
  mdbook,
  mdbook-cmdrun,
  git,
  uv-pythons ? [ ],
}:
let
  attrs = lib.sort (a: b: (builtins.compareVersions a b) < 0) (lib.attrNames uv-pythons);
in
stdenv.mkDerivation {
  pname = "uv-python-docs-html";
  version = "0.1";
  src = self;
  sourceRoot = "source/doc";
  nativeBuildInputs = [
    mdbook
    mdbook-cmdrun
    git
  ];

  dontConfigure = true;
  dontFixup = true;

  env.RUST_BACKTRACE = 1;

  preBuild = ''
    cat > src/attrs.md <<EOF
    # Interpreter attributes
    ${lib.concatStringsSep "\n" (map (attr: "- ${attr}") attrs)}
    EOF
  '';

  buildPhase = ''
    runHook preBuild
    chmod +w ../ && mkdir ../.git  # Trick open-on-gh to find the git root
    mdbook build
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mv book $out
    runHook postInstall
  '';
}
