# Purpose

> This tool exists in order to enforce proposed conventions and provide better DX for projects utilizing technologies like `docker` (especially `docker-compose` and `docker-machine`), `node`, `webpack`, `nextjs` and so on.

The following instructions are outlined for the repositories (projects) utilizing this tool.

# Setup and prerequisites

- Make sure you have both `"name"` and `"organization"` keys set in the target project `package.json` file.
- ake sure to run `dxtools` from either `npm` or `yarn` scripts because commands heavily rely on target projects `package.json` keys which end up in the environment.

# Install

1. Run `yarn add --dev https://github.com/nikolakanacki/dxtools.git`
2. Add `"tools": "dxtools"` under `"scripts"` key in your `package.json` file.
3. Prosper.

## Environment files

Global environment is set with `DXTOOLS_ENV` variable and defaults to `development` if not set before running the command (you can also use options arguments to set it, see below). You can prevent the environment loading completely by setting `DXTOOLS_ENV_LOADED` to `'true'` or by using `--no-env` options argument. Passing any of the environment options arguments will reset `DXTOOLS_ENV_LOADED` to `false`.

The following files / file patterns will be loaded into environment in the order specified below:

- `.env.default`: Commitable default values applied for all environments.
- `.env.<DXTOOLS_ENV>`: Commitable `<DXTOOLS_ENV>` values.
- `.env.<DXTOOLS_ENV>.local`: Non commitable `<DXTOOLS_ENV>` specific values.
- `.env`: Non commitable values applied last for all environments.

# Usage

```bash
# In your project (if you did set up package.json):
yarn tools [...options] <command> [...args]
```

## Options

- `-e|--env <env>`: Set `DXTOOLS_ENV` value to `<env>`.
- `--no-env`: Prevent environment loading.
- `-ed|-ep|-es`: Set `DXTOOLS_ENV` to `development`, `production` or `staging`, accordingly.
- `-d|--cd <path>`: Change directory to `<path>` before running any commands. This is done after the environment has already been loaded. You can also set with `DXTOOLS_CWD` env variable.

## Commands

- [`eval`](commands/eval.md)
- [`shell`](commands/shell.md)
- [`docker`](commands/docker.md)
- [`version`](commands/version.md)
- [`release`](commands/release.md)
- [`generate`](commands/generate.md)
