#!/bin/bash

ARG_COMMAND="$1"; shift;

if [ "$NODE_ENV" != 'production' ]; then
  export COMPOSE_FILE="docker-compose.yml:docker-compose.development.yml";
else
  export COMPOSE_FILE="docker-compose.yml:docker-compose.production.yml";
fi;

case $ARG_COMMAND in
  'generate')
    ARG_COMMAND=$1; shift;
    case $ARG_COMMAND in
      'ignore')
        if [ -f .dockerignore ]; then
          echo 'File .dockerignore was found. Please remove it before generating new one.';
          exit 1;
        else
          echo '.git' >> .dockerignore;
          echo 'data' >> .dockerignore;
          echo 'node_modules' >> .dockerignore;
          echo '*.tar.gz' >> .dockerignore;
        fi;
      ;;
      *)
        echo "Invalid generate type: \"$ARG_COMMAND\"";
        exit 1;
      ;;
    esac;
  ;;
  'clean')
    docker ps -a \
      | grep "${npm_package_name}" \
      | awk '{ print $1 }' \
      | xargs docker rm;
  ;;
  'enter')
    ENTER_CONTAINER_NAME="${npm_package_organization}-${npm_package_name}-$1";
    shift;
    docker exec -ti "$ENTER_CONTAINER_NAME" /bin/bash;
  ;;
  'restart')
    RESTART_CONTAINER_NAME="${npm_package_organization}-${npm_package_name}-$1";
    shift;
    docker restart "$RESTART_CONTAINER_NAME";
  ;;
  'machine')
    ARG_MACHINE="$1"; shift;
    ARG_COMMAND="$1"; shift;
    if [ $ARG_MACHINE == '--' ]; then
      ARG_MACHINE="${npm_package_organization}-${npm_package_name}";
    elif [[ $ARG_MACHINE == -* ]]; then
      ARG_MACHINE="${npm_package_organization}-${npm_package_name}${ARG_MACHINE}";
    elif [[ $ARG_MACHINE == *- ]]; then
      ARG_MACHINE="${ARG_MACHINE}${npm_package_organization}-${npm_package_name}";
    fi;
    case $ARG_COMMAND in
      'push')
        ARG_TARGET="$1"; shift;
        ARG_NAME=${ARG_TARGET//\//-};
        ARG_NAME_TAR="${ARG_NAME}.tar.gz";
        ARG_PUSH_SOURCE="./$ARG_TARGET";
        ARG_PUSH_DESTINATION="/root/$ARG_TARGET";
        rm -rf "$ARG_NAME_TAR";
        tar -zcvf "$ARG_NAME_TAR" -C "$ARG_PUSH_SOURCE" .;
        docker-machine scp \
          "$ARG_NAME_TAR" \
          "$ARG_MACHINE:/root/$ARG_NAME_TAR";
        docker-machine ssh "$ARG_MACHINE" "true \
          && rm -rf $ARG_PUSH_DESTINATION/** \
          && mkdir -p $ARG_PUSH_DESTINATION \
          && tar -xf $ARG_NAME_TAR -C $ARG_PUSH_DESTINATION \
          && rm -rf $ARG_NAME_TAR";
      ;;
      'pull')
        ARG_TARGET="$1"; shift;
        ARG_NAME=${ARG_TARGET//\//-};
        ARG_NAME_TAR="${ARG_NAME}.tar.gz";
        ARG_PULL_SOURCE="/root/$ARG_TARGET";
        ARG_PULL_DESTINATION="./$ARG_TARGET";
        docker-machine ssh "$ARG_MACHINE" "true \
          && rm -rf $ARG_NAME_TAR \
          && mkdir -p $ARG_PULL_SOURCE \
          && tar -zcvf $ARG_NAME_TAR -C $ARG_PULL_SOURCE .";
        rm -rf "$ARG_NAME_TAR";
        docker-machine scp \
          "$ARG_MACHINE:/root/$ARG_NAME_TAR" \
          "$ARG_NAME_TAR";
        rm -rf "$ARG_PULL_DESTINATION/**";
        mkdir -p "$ARG_PULL_DESTINATION";
        tar -xf "$ARG_NAME_TAR" -C "$ARG_PULL_DESTINATION";
        docker-machine ssh "$ARG_MACHINE" "true \
          && rm -rf $ARG_NAME_TAR";
      ;;
      'create')
        ARG_DRIVER=$1; shift;
        case $ARG_DRIVER in
          'digitalocean')
            ARG_TOKEN='';
            ARG_SIZE='1gb';
            ARG_REGION='ams3';
            while test $# -gt 0; do
              arg=$1; shift;
              case $arg in
                '-t'|'--token')
                  ARG_TOKEN="$1";
                  shift;
                ;;
                '-s'|'--size')
                  ARG_SIZE="$1";
                  shift;
                ;;
                '-r'|'--region')
                  ARG_REGION="$1";
                  shift;
                ;;
                '--')
                  break;
                ;;
                *)
                  echo "Invalid argument \"$arg\"";
                  exit 1;
                ;;
              esac;
            done;
            docker-machine create \
              --driver "$ARG_DRIVER" \
              --digitalocean-access-token "$ARG_TOKEN" \
              --digitalocean-size "$ARG_SIZE" \
              --digitalocean-region "$ARG_REGION" \
              $ARG_MACHINE \
              $@;
          ;;
          *)
            echo "Driver \"$ARG_DRIVER\" not supported";
            exit 1;
          ;;
        esac;
      ;;
      *)
        docker-machine $ARG_COMMAND $ARG_MACHINE $@;
      ;;
    esac;
  ;;
  *)
    docker-compose $ARG_COMMAND $@;
  ;;
esac;
