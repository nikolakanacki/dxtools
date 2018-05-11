#!/bin/bash

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

if [ "$1" == '--version' ] || [ "$1" == '-v' ]; then
  cat $(localizePath ./package.json) \
  | grep '"version":' \
  | awk '{ print $2 }' \
  | sed 's/[",]//g';
  exit 0;
fi;

if [ -z "$npm_package_name" ]; then
  echo '=> Error: Key "name" is missing from the package.json';
  exit 1;
fi;

if [ -z "$npm_package_organization" ]; then
  echo '=> Error: Key "organization" is missing from the package.json';
  exit 1;
fi;

function setupEnvironment {
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
}

while test $# -gt 0; do
  ARG_COMMAND="$1"; shift;
  case $ARG_COMMAND in
    'eval')
      setupEnvironment;
      eval "$@";
      exit 0;
    ;;
    'generate'|'docker'|'version'|'release')
      setupEnvironment;
      eval "$(localizePath ./commands/${ARG_COMMAND}.sh) $@";
      exit 0;
    ;;
    '-c'|'--cd')
      cd $1; shift;
    ;;
    *)
      echo "=> Error: Command does not exist: $ARG_COMMAND";
      exit 1;
    ;;
  esac;
done;
