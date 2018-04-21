# Version

```bash
yarn tools generate <target>
```

> Generate various files often needed for the project.

# Arguments

- `<target>`:
  - `env`: Touches all the env files (see [here](../)).
  - `gitignore <target>`: Generate `.gitignore` files based on the official [`gitignore`](https://github.com/github/gitignore) repository files. Argument `<target>` should be the name of the file (without `.gitignore` suffix), eg: `dxtools generate gitignore Node`.
  - `dockerignore`: Generates default `.dockerignore` file.
