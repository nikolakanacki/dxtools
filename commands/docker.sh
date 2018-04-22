#!/bin/bash

ARG_COMMAND="$1"; shift;

ensureComposeFiles() {
  if ! [ -f docker-compose.yml ]; then
    echo 'Missing docker-compose.yml';
    exit 1;
  fi;
  if ! [ -f docker-compose.development.yml ]; then
    echo 'Missing docker-compose.development.yml';
    exit 1;
  fi;
  if ! [ -f docker-compose.production.yml ]; then
    echo 'Missing docker-compose.production.yml';
    exit 1;
  fi;
}

if [ "$NODE_ENV" != 'production' ]; then
  export COMPOSE_FILE="docker-compose.yml:docker-compose.development.yml";
else
  export COMPOSE_FILE="docker-compose.yml:docker-compose.production.yml";
fi;

case $ARG_COMMAND in
  'clean')
    docker ps -a \
      | grep "${npm_package_name}" \
      | awk '{ print $1 }' \
      | xargs docker rm;
  ;;
  'enter'|'exec')
    ensureComposeFiles;
    CONTAINER_NAME="${npm_package_organization}-${npm_package_name}-$1"; shift;
    CONTAINER_COMMAND=$1; shift;
    if [ -z "$CONTAINER_COMMAND" ]; then
      CONTAINER_COMMAND='/bin/bash';
    fi;
    docker exec -ti "$CONTAINER_NAME" "$CONTAINER_COMMAND" $@;
  ;;
  'restart')
    ensureComposeFiles;
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
      'exec')
        docker-machine ssh "$ARG_MACHINE" "$@";
      ;;
      'mkdir')
        docker-machine ssh "$ARG_MACHINE" "mkdir -p $@";
      ;;
      'touch')
        docker-machine ssh "$ARG_MACHINE" "touch $@";
      ;;
      'shell')
        TMP_RC_FILE=$(mktemp);
        if [ -f ~/.bash_profile ]; then
          echo 'source ~/.bash_profile' >> $TMP_RC_FILE;
        fi;
        if [ -f ~/.bashrc ]; then
          echo 'source ~/.bashrc' >> $TMP_RC_FILE;
        fi;
        docker-machine env "$ARG_MACHINE" >> $TMP_RC_FILE;
        # echo 'PS1="\[\e]0;\u@\H: \W\a\]${debian_chroot:+($debian_chroot)}\H:\W (machine)\$ ";' >> $TMP_RC_FILE;
        echo 'PS1="${PS1}(machine) ";' >> $TMP_RC_FILE;
        echo "rm -f $TMP_RC_FILE" >> $TMP_RC_FILE;
        bash --rcfile $TMP_RC_FILE;
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
    ensureComposeFiles;
    docker-compose $ARG_COMMAND $@;
  ;;
esac;
