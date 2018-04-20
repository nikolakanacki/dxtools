#!/bin/bash

touch \
  .env.default \
  .env.development \
  .env.development.local \
  .env.production \
  .env.production.local \
  .env;

if [ "$NODE_ENV" != 'production' ]; then
  vars=$(cat \
    .env.default \
    .env.development \
    .env.development.local \
    .env \
    2>/dev/null | xargs \
  );
  if ! [ -z "$vars" ]; then
    export $vars;
  fi;
else
  vars=$(cat \
    .env.default \
    .env.production \
    .env.production.local \
    .env \
    2>/dev/null | xargs \
  );
  if ! [ -z "$vars" ]; then
    export $vars;
  fi;
fi;

function normalizePath {
  local path=${1//\/.\//\/};
  while [[ $path =~ ([^/][^/]*/\.\./) ]]; do
    path=${path/${BASH_REMATCH[0]}/};
  done;
  echo $path;
}

function localizePath {
  local SOURCE="${BASH_SOURCE[0]}";
  while [ -h "$SOURCE" ]; do
    local DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )";
    SOURCE="$(readlink "$SOURCE")";
    [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE";
  done;
  echo $(normalizePath "$(cd -P "$(dirname "$SOURCE")" && pwd)/$1");
}

ARG_COMMAND="$1"; shift;

case $ARG_COMMAND in
  "env")
    exit 0;
  ;;
  "eval")
    eval "$@";
  ;;
  "docker")
    eval "$(localizePath ./commands/docker.sh) $@";
  ;;
  *)
    echo "Error: Command does not exist: $ARG_COMMAND";
    exit 1;
  ;;
esac;
