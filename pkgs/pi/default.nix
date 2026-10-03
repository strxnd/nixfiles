{
  lib,
  buildNpmPackage,
  nodejs,
  makeWrapper,
}:
buildNpmPackage {
  pname = "pi-coding-agent";
  version = "1.0.0";
  src = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.unions [
      ./package.json
      ./package-lock.json
    ];
  };

  npmDepsHash = "sha256-1EttFiClXtbpi8VCKEqsHqtSmnBNGu34XufRVGLbSjc=";
  npmFlags = [ "--ignore-scripts" ];
  dontNpmBuild = true;
  # This manifest has no development dependencies to prune.
  dontNpmPrune = true;
  # Pi's embedded shrinkwrap requires npm to write to its offline cache.
  makeCacheWritable = true;

  nativeBuildInputs = [ makeWrapper ];
  postInstall = ''
    makeWrapper ${nodejs}/bin/node "$out/bin/pi" \
      --add-flags "$out/lib/node_modules/pi-npm/node_modules/@earendil-works/pi-coding-agent/dist/bundle/cli.js" \
      --set-default PI_SKIP_VERSION_CHECK 1 \
      --set-default PI_TELEMETRY 0
  '';

  meta = {
    description = "Pi coding agent from the npm registry";
    homepage = "https://pi.dev/";
    license = lib.licenses.mit;
    mainProgram = "pi";
  };
}
