# Version

```bash
yarn tools release [...args]
```

> Release oriented version of [`version`](version.md) command. It expects to be on a branch named `dev`.
> Steps:
> - Checks out master and merges `dev` with `--no-ff`
> - Performs `version` command with the arguments passed
> - Pushes tip of the master and the newly created tag to the `origin`
> - Checks out dev and merges master
> - Pushes dev to origin
