{
  lib,
  buildNpmPackage,
  nodejs,
  makeWrapper,
}:
buildNpmPackage {
  pname = "codex";
  version = "0.160.0";
  src = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.unions [
      ./package.json
      ./package-lock.json
    ];
  };

  npmDepsHash = "sha256-XlRXyMsPrF5U+wM0CkQSk1gbXyeQohgDf5s0TcuCuBA=";
  npmFlags = [ "--ignore-scripts" ];
  dontNpmBuild = true;

  nativeBuildInputs = [ makeWrapper ];
  postInstall = ''
    makeWrapper ${nodejs}/bin/node "$out/bin/codex" \
      --add-flags "$out/lib/node_modules/codex-npm/node_modules/@openai/codex/bin/codex.js"
  '';

  meta = {
    description = "OpenAI Codex CLI from the npm registry";
    homepage = "https://github.com/openai/codex";
    license = lib.licenses.asl20;
    mainProgram = "codex";
  };
}
