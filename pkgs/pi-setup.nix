{ lib, runCommand, importNpmLock, nodejs }:
let
  root = ../home/kumar/config/pi;
  extensionNames = [
    "ask-user"
    "background-terminals"
    "copy-all"
    "file-search"
    "firecrawl-search"
    "git-info"
    "subagents"
    "summaries"
    "ui-customizations"
  ];

  dependencies = path: let
    manifest = lib.importJSON (path + "/package.json");
    lock = lib.importJSON (path + "/package-lock.json");
    package = builtins.removeAttrs manifest [ "devDependencies" ];
    packageLock = lock // {
      packages = (lib.filterAttrs (name: value:
        name != "" && !(value.dev or false)
      ) lock.packages) // { "" = package; };
    };
  in if (package.dependencies or { }) == { } then
    runCommand "${package.name}-node-modules" { } "mkdir -p $out/node_modules"
  else importNpmLock.buildNodeModules {
    inherit package packageLock nodejs;
    derivationArgs = {
      npmFlags = "--omit=dev --legacy-peer-deps --ignore-scripts";
      dontFixup = true;
    };
  };

  rootDependencies = dependencies root;
  extensionDependencies = lib.genAttrs extensionNames
    (name: dependencies (root + "/extensions/${name}"));

  source = lib.fileset.toSource {
    root = root;
    fileset = lib.fileset.unions [
      (root + "/AGENTS.md")
      (root + "/package.json")
      (lib.fileset.difference
        (lib.fileset.fileFilter (file:
          !(lib.hasSuffix ".test.ts" file.name)
          && !(lib.hasSuffix ".spec.ts" file.name)
          && (lib.hasSuffix ".ts" file.name || lib.hasSuffix ".cjs" file.name)
        ) (root + "/extensions"))
        (lib.fileset.unions (map (name:
          lib.fileset.maybeMissing (root + "/extensions/${name}/node_modules")
        ) extensionNames)))
      (root + "/skills")
      (root + "/themes")
    ];
  };
in
runCommand "my-pi-setup" { } ''
  mkdir -p "$out"
  cp -r ${source}/. "$out/"
  chmod -R u+w "$out"
  ln -s ${rootDependencies}/node_modules "$out/node_modules"
  ${lib.concatMapStringsSep "\n" (name: ''
    ln -s ${extensionDependencies.${name}}/node_modules "$out/extensions/${name}/node_modules"
  '') extensionNames}
''
