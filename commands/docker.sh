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
  'machine-import')
    machine-import "$1"; shift;
  ;;
  'machine')
    ARG_MACHINE="$1"; shift;
    ARG_COMMAND="$1"; shift;
    if [ $ARG_MACHINE == '-' ]; then
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
        ARG_PUSH_SOURCE_DIR="$(dirname $ARG_PUSH_SOURCE)";
        ARG_PUSH_SOURCE_FILENAME="$(basename $ARG_PUSH_SOURCE)";
        ARG_PUSH_DESTINATION="/root/$ARG_TARGET";
        ARG_PUSH_DESTINATION_DIR="$(dirname $ARG_PUSH_DESTINATION)";
        rm -rf "$ARG_NAME_TAR";
        if [ -f "$ARG_PUSH_SOURCE" ]; then
          echo "PUSHING A FILE";
          tar -zcvf "$ARG_NAME_TAR" -C "$ARG_PUSH_SOURCE_DIR" .;
          docker-machine scp \
            "$ARG_NAME_TAR" \
            "$ARG_MACHINE:/root/$ARG_NAME_TAR";
          docker-machine ssh "$ARG_MACHINE" "true \
            && mkdir -p $ARG_PUSH_DESTINATION_DIR \
            && tar -xO -C $ARG_PUSH_DESTINATION_DIR -f $ARG_NAME_TAR ./$ARG_PUSH_SOURCE_FILENAME > $ARG_PUSH_DESTINATION \
            && rm -rf $ARG_NAME_TAR";
        elif [ -d "$ARG_PUSH_SOURCE" ]; then
          echo "PUSHING A DIRECTORY";
          tar -zcvf "$ARG_NAME_TAR" -C "$ARG_PUSH_SOURCE" .;
          docker-machine scp \
            "$ARG_NAME_TAR" \
            "$ARG_MACHINE:/root/$ARG_NAME_TAR";
          docker-machine ssh "$ARG_MACHINE" "true \
            && rm -rf $ARG_PUSH_DESTINATION/** \
            && mkdir -p $ARG_PUSH_DESTINATION \
            && tar -xf $ARG_NAME_TAR -C $ARG_PUSH_DESTINATION \
            && rm -rf $ARG_NAME_TAR";
        fi;
      ;;
      'pull')
        ARG_TARGET="$1"; shift;
        ARG_NAME=${ARG_TARGET//\//-};
        ARG_NAME_TAR="${ARG_NAME}.tar.gz";
        ARG_PULL_SOURCE="/root/$ARG_TARGET";
        ARG_PULL_SOURCE_DIR="$(dirname $ARG_PULL_SOURCE)";
        ARG_PULL_SOURCE_FILENAME="$(basename $ARG_PULL_SOURCE)";
        ARG_PULL_DESTINATION="./$ARG_TARGET";
        ARG_PULL_DESTINATION_DIR="$(dirname $ARG_PULL_DESTINATION)";
        ARG_SOURCE_TYPE=$(docker-machine ssh "$ARG_MACHINE" -- "bash -s" << EOF
          {
            rm -rf "$ARG_NAME_TAR" 1>&2;
            if [ -f "$ARG_PULL_SOURCE" ]; then
              echo "file";
              mkdir -p "$ARG_PULL_SOURCE_DIR" 1>&2;
              tar -zcvf "$ARG_NAME_TAR" -C "$ARG_PULL_SOURCE_DIR" . 1>&2;
            elif [ -d "$ARG_PULL_SOURCE" ]; then
              echo "directory";
              mkdir -p "$ARG_PULL_SOURCE" 1>&2;
              tar -zcvf "$ARG_NAME_TAR" -C "$ARG_PULL_SOURCE" . 1>&2;
            fi;
          }
EOF
        );
        docker-machine scp \
          "$ARG_MACHINE:/root/$ARG_NAME_TAR" \
          "$ARG_NAME_TAR";
        if [ $ARG_SOURCE_TYPE == 'file' ]; then
          mkdir -p "$ARG_PULL_DESTINATION_DIR";
          tar -x -O \
            -C $ARG_PULL_DESTINATION_DIR \
            -f $ARG_NAME_TAR \
            ./$ARG_PULL_SOURCE_FILENAME > $ARG_PULL_DESTINATION
        elif [ $ARG_SOURCE_TYPE == 'directory' ]; then
          rm -rf "$ARG_PULL_DESTINATION/**";
          mkdir -p "$ARG_PULL_DESTINATION";
          tar -xf "$ARG_NAME_TAR" -C "$ARG_PULL_DESTINATION";
        fi;
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
        while test $# -gt 0; do
          arg=$1; shift;
          case $arg in
            '-p'|'--production')
              echo "export NODE_ENV='production';" >> $TMP_RC_FILE;
            ;;
            '-d'|'--development')
              echo "export NODE_ENV='development';" >> $TMP_RC_FILE;
            ;;
            '-e'|'--environment')
              echo "export NODE_ENV='$1';" >> $TMP_RC_FILE;
              shift;
            ;;
            *)
              echo "Invalid argument \"$arg\"";
              exit 1;
            ;;
          esac;
        done;
        echo "rm -f $TMP_RC_FILE" >> $TMP_RC_FILE;
        bash --rcfile $TMP_RC_FILE;
      ;;
      'export')
        machine-export "${ARG_MACHINE}";
      ;;
      'import')
        machine-import "${ARG_MACHINE}.zip";
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
