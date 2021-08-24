# Docker

```bash
yarn tools docker [...options] <cmd> [...args]
```

> Enhances DX while developing and deploying with docker, ensures proper environment is loaded, etc.

Every `docker-compose [...rest]` (and some `docker-machine [...rest]`) command should be run as `yarn tools docker [...rest]`. In the very least this will ensure that the proper environment is loaded and provided to the underlying docker based command. See list of commands down below.

> NOTE: You can run every docker-compose command with `yarn tools docker`. If the command is not handled by this tool it will be passed to the original `docker-compose` command. Commands regarding docker-machine have a slightly different interface: for an example `docker-machine <cmd> <machine> [...rest]` should be converted to `yarn tools docker machine <machine> <cmd> [...rest]` (see the reference down below for more info, specifically on what can be provided as `<machine>` argument - machine name).

## Docker Compose files structure

Before each command `COMPOSE_FILE` variable is set as such:
- `docker-compose.yml`: Default value
- `docker-compose.yml:docker-compose.${DXTOOLS_ENV}.yml`: If the environment specific file is present it is appended to the original one.

# Reference

> NOTE: `${npm_package_name}` and `${npm_package_organization}` both refer to the "name" and "organization" keys found in `package.json` file of the target project. The combination of the `${npm_package_organization}` and `${npm_package_name}` should be unique. It will be broadly used as a "base name" for the project in various contexts.

## Common arguments

- `<service>`: Refers to the name ("key") of the service as seen in the `docker-compose.yml` file).
- `<machine>`: Can be either one of (for what `${npm_package_organization}` and `${npm_package_name}` mean see the notes above):
  - Full machine name (which cannot end or begin with `-`): Machine name equals the provided argument value.
  - Machine name prefix (must end with `-`): Machine name equals to `${PREFIX}${npm_package_organization}-${npm_package_name}`.
  - Machine name suffix (must start with `-`): Machine name equals to `${npm_package_organization}-${npm_package_name}${SUFFIX}`.
  - Literal `-`: Machine name equals `${npm_package_organization}-${npm_package_name}-${DXTOOLS_ENV}`.
  - Literal `--`: Machine name equals `${npm_package_organization}-${npm_package_name}`.
- `<path>`: Refers to the path targeting a directory in the project without a leading `./` or `/`. Nested paths are allowed (example: `data/storage`).

## Common options

- `--no-ssh-keys`
  User ssh keys (located in ~/.ssh) are exported as environment variables `ID_RSA` and `ID_RSA_PUB` so they can be used during the build process, etc. Pass this flag to prevent this behaviour.

## Commands

- `clean`
  Removes all containers which name contains the target repository package name.
- `enter|exec <service> <command=/bin/bash>`
  Executes the provided command in the target container. By default (if the command is not specified) it enters /bin/bash).
- `restart [...service]`
  Restarts the service (or services) if ones are provided, otherwise restarts all containers.
- `machine-import <machine-export-path>`
  Import a machine from an exported machine zip file located at `<machine-export-path>` (see `machine <machine> export`).
- `machine <machine> shell`
  Enter a shell which has the remote docker machine environment set up and suffixes your `PS1` with a machine name`.
- `machine <machine> push <path>`
  Takes the given path in the local project and "pushes" (uploads) it up to the machine replacing the directory found by resolving the `<path>` from the app root (ssh root). If `<path>` is a file and it exists remotely - it is overwritten without removal.
- `machine <machine> pull <path>`. If `<path>` is a file and it exists locally - it is overwritten without removal.
  Does exactly the opposite of the equivalent `pull` command: pulls the content of the remote machine to the local project.
- `machine <machine> mkdir [...paths]`
  Creates directories in the machine filesystem. Like calling `mkdir -p [...paths]` remotely.
- `machine <machine> touch [...paths]`
  Touches files in the machine filesystem. Like calling `touch [...paths]` remotely.
- `machine <machine> export`
  Exports machine to the current working directory.
- `machine <machine> import`
  Imports machine from the current working directory (if you want to specify the path manually see `docker machine-import`).
- `machine <machine> create <driver> [...options]`
  Creates a new docker machine. Arguments:
  - `digitalocean`: Specifies DigitalOcean as a driver which accepts following options:
    - `-t|--token`: Access Token used to access DigitalOcean api.
    - `-s|--size`: Size of the droplet (defaults to `s-1vcpu-1gb`).
    - `-i|--image`: Image to install on droplet (defaults to `ubuntu-18-04-x64`).
    - `-r|--region`: DigitalOcean region in which to create the machine (defaults to `ams3`).
    - `--`: All arguments after this will be passed to the underlying `docker-machine create` command.

## Catch-all commands

- `yarn docker machine <machine> <cmd> [...rest]`
  Loads the environment, interpolates the machine name and forwards the rest to the original `docker-machine` command as such: `docker-machine <cmd> <interpolated-machine-name> [...rest]`
- `yarn docker [...rest]`
  Loads the environment and forwards the rest to the original `docker-compose` command as such: `docker-compose [...rest]`
