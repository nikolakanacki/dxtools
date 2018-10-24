# Purpose

> This tool exists in order to enforce proposed conventions and provide better DX for projects utilizing technologies like `docker` (especially `docker-compose` and `docker-machine`), `node`, `webpack`, `nextjs` and so on.

The following instructions are outlined for the repositories (projects) utilizing this tool.

# Setup and prerequisites

Make sure you have both `"name"` and `"organization"` keys set in the target project `package.json` file.

Also make sure to run `dxtools` from either `npm` or `yarn` scripts because commands heavily rely on target projects `package.json` keys which end up in the environment.

1. Run `yarn add https://github.com/nikolakanacki/dxtools.git`
2. Add `"tools": "dxtools"` under `"scripts"` key in your `package.json` file.
3. Prosper.

## Environment files structure

Global environment defaults to `development`.
For `production` exporting `NODE_ENV=production` is needed.

- `.env.default`: Commitable default values applied for all environments.
- `.env.development`: Commitable development values.
- `.env.development.local`: Non commitable development values.
- `.env.production`: Commitable production values.
- `.env.production.local`: Non commitable production values.
- `.env`: Non commitable values applied for all environments.

The files are loaded in the following order:

- Development:
  - `.env.default`
  - `.env.development`
  - `.env.development.local`
  - `.env`
- Production:
  - `.env.default`
  - `.env.production`
  - `.env.production.local`
  - `.env`

# Usage

```bash
# In your project (if you did set up package.json):
yarn tools [...options] <command> [...args]
```

## Options

- `-d|--cd <path>`: Change directory to `<path>` before running a command (after creating the environment).

## Commands

- [`eval`](commands/eval.md)
- [`docker`](commands/docker.md)
- [`version`](commands/version.md)
- [`release`](commands/release.md)
- [`generate`](commands/generate.md)
