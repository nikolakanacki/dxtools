# Docker

```bash
yarn tools docker <cmd> [...args]
```

> Enhances DX while developing and deploying with docker, ensures proper environment is loaded, etc.

Every `docker-compose [...rest]` (and some `docker-machine [...rest]`) command should be run as `yarn tools docker [...rest]`. In the very least this will ensure that the proper environment is loaded and provided to the underlying docker based command. See list of commands down below.

> NOTE: You can literally run every docker-compose command using this tool. If the command is not handled by this tool it will be passed to the original `docker-compose` command. Commands regarding docker-machine have a slightly different interface: for an example `docker-machine <cmd> <machine> [...rest]` should be converted to `yarn docker machine <machine> <cmd> [...rest]` (see the reference down below for more info, specifically on what can be provided as a `<machine>` - machine name).

## Docker files structure

All files are required.

- `docker-compose.yml`: Provides defaults for each service. This configuration is always going to be extended by one of the following ones depending on the environment.
- `docker-compose.development.yml`: Provides specific configuration for development (or staging) environment.
- `docker-compose.production.yml`: Provides specific configuration for production environment.

The script decides which of the files to load depending on the global environment.

# Reference

If the installation went well the tool should be available under `yarn docker`. Commands are listed as a cascading list.

> NOTE: `${npm_package_name}` and `${npm_package_organization}` both refer to the keys "name" and "organization" found in `package.json` file of the target project. The combination of the `${npm_package_organization}` and `${npm_package_name}` should be unique since it will be broadly used as a "base name" for the project in various contexts.

## Common arguments

- `<service>`: Refers to the name ("key") of the service as seen in the `docker-compose.yml` file).
- `<machine>`: Can be either one of (for what `${npm_package_organization}` and `${npm_package_name}` mean see the notes above):
  - Full machine name (which cannot end or begin with `-`): Machine name equals the provided argument value.
  - Machine name prefix (must end with `-`): Machine name equals to `${PREFIX}${npm_package_organization}-${npm_package_name}`.
  - Machine name suffix (must start with `-`): Machine name equals to `${npm_package_organization}-${npm_package_name}${SUFFIX}`.
  - Literal `-`: Machine name equals `${npm_package_organization}-${npm_package_name}`.
- `<path>`: Refers to the path targeting a directory in the project without a leading `./` or `/`. Nested paths are allowed (example: `data/storage`).

## Commands

- `yarn docker clean`
  Removes all containers which name contains the target repository package name.
- `yarn docker enter <service>`
  Enters an interactive shell connected to the provided service.
- `yarn docker restart [...service]`
  Restarts the service (or services) if ones are provided, otherwise restarts all containers.
- `yarn docker machine <machine> push <path>`
  Takes the given path in the local project and "pushes" (uploads) it up to the machine replacing the directory found by resolving the `<path>` from the app root (ssh root).
- `yarn docker machine <machine> pull <path>`
  Does exactly the opposite of the equivalent `pull` command: pulls the content of the remote machine to the local project.
- `yarn docker machine <machine> create <driver> [...options]`
  Creates a new docker machine. Arguments:
  - `digitalocean`: Specifies DigitalOcean as a driver which accepts following options:
    - `-t|--token`: Access Token used to access DigitalOcean api.
    - `-s|--size`: Size of the droplet (defaults to `1gb`).
    - `-r|--region`: DigitalOcean region in which to create the machine (defaults to `ams3`).
    - `--`: All arguments after this will be passed to the underlying `docker-machine create` command.

## Catch-all commands

- `yarn docker machine <machine> <cmd> [...rest]`
  Loads the environment, interpolates the machine name and forwards the rest to the original `docker-machine` command as such: `docker-machine <cmd> <interpolated-machine-name> [...rest]`
- `yarn docker [...rest]`
  Loads the environment and forwards the rest to the original `docker-compose` command as such: `docker-compose [...rest]`
