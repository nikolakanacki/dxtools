# Version

```bash
yarn tools version [...args]
```

> Does a package version modification, makes a commit about it and tags the commit with the new version. See [`npm version`](https://docs.npmjs.com/cli/version) for the arguments (major | minor | patch | etc...).

If there is a an executable file found at ./scripts/version.sh it is executed with a new version `npm_package_new_version` passed as an environment varibale before making the version commit.
