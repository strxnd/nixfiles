# Deployment manifests

Pruned copies of `../../modules/programs/pi` manifests used to build the
deployed `node_modules` trees. They differ from the dev manifests only by
omitted `devDependencies` and uninstalled peer dependencies (pi provides
those itself at runtime).

Regenerate after changing the upstream manifests:

```sh
name=<extension-or-root>
src=../../modules/programs/pi            # or extensions/<name>
mkdir -p $name && cd $name
cp $src/package.json .
npm pkg delete devDependencies
npm install --package-lock-only --omit=dev --legacy-peer-deps
```

`--legacy-peer-deps` is required for the root manifest: its
`peerDependencies` (`@earendil-works/pi-*`) must not be resolved into the
lockfile, otherwise the whole pi runtime tree gets deployed.
