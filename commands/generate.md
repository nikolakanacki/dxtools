# Version

```bash
yarn tools generate <target>
```

> Generate various files often needed for the project.

# Arguments

- `<target>`:
  - `env`: Touches all the env files (see [here](../)).
  - `gitignore-node`: Generates node `.gitignore` for node projects by prepending `dxtools` defaults to the official [Node.gitignore](https://raw.githubusercontent.com/github/gitignore/master/Node.gitignore) file.
  - `dockerignore`: Generates default `.dockerignore` file.
