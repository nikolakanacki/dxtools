#!/bin/bash

ensureComposeFiles() {
  if ! [ -f docker-compose.yml ]; then
    echo '=> Error: Missing docker-compose.yml';
    exit 1;
  fi;
  if ! [ -f docker-compose.development.yml ]; then
    echo '=> Error: Missing docker-compose.development.yml';
    exit 1;
  fi;
  if ! [ -f docker-compose.production.yml ]; then
    echo '=> Error: Missing docker-compose.production.yml';
    exit 1;
  fi;
}

export ID_RSA="$(cat ~/.ssh/id_rsa 2> /dev/null)";
export ID_RSA_PUB="$(cat ~/.ssh/id_rsa.pub 2> /dev/null)";

if [ "$NODE_ENV" != 'production' ]; then
  export COMPOSE_FILE="docker-compose.yml:docker-compose.development.yml";
else
  export COMPOSE_FILE="docker-compose.yml:docker-compose.production.yml";
fi;

while test $# -gt 0; do
  ARG_COMMAND="$1"; shift;
  case $ARG_COMMAND in
    '--no-ssh-keys')
      export ID_RSA='';
      export ID_RSA_PUB='';
    ;;
    *)
      case $ARG_COMMAND in
        'clean')
          docker ps -a \
          | grep "${npm_package_name}" \
          | awk '{ print $1 }' \
          | xargs docker rm;
          exit 0;
        ;;
        'enter'|'exec')
          ensureComposeFiles;
          CONTAINER_NAME="${npm_package_organization}-${npm_package_name}-$1"; shift;
          CONTAINER_COMMAND=$1; shift;
          if [ -z "$CONTAINER_COMMAND" ]; then
            CONTAINER_COMMAND='/bin/bash';
          fi;
          docker exec -ti "$CONTAINER_NAME" "$CONTAINER_COMMAND" $@;
          exit 0;
        ;;
        'restart')
          ensureComposeFiles;
          RESTART_CONTAINER_NAME="${npm_package_organization}-${npm_package_name}-$1";
          shift;
          docker restart "$RESTART_CONTAINER_NAME";
          exit 0;
        ;;
        'machine-import')
          machine-import "$1"; shift;
          exit 0;
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
              ARG_TARGET="$(echo $1 | sed 's|^./||')"; shift;
              ARG_NAME=${ARG_TARGET//\//-};
              ARG_NAME_TAR="${ARG_NAME}.tar.gz";
              ARG_PUSH_SOURCE="./$ARG_TARGET";
              ARG_PUSH_SOURCE_DIR="$(dirname $ARG_PUSH_SOURCE)";
              ARG_PUSH_SOURCE_FILENAME="$(basename $ARG_PUSH_SOURCE)";
              ARG_PUSH_DESTINATION="/root/$ARG_TARGET";
              ARG_PUSH_DESTINATION_DIR="$(dirname $ARG_PUSH_DESTINATION)";
              rm -rf "$ARG_NAME_TAR";
              if [ -f "$ARG_PUSH_SOURCE" ]; then
                tar -zcvf "$ARG_NAME_TAR" -C "$ARG_PUSH_SOURCE_DIR" "$ARG_PUSH_SOURCE_FILENAME";
                docker-machine scp \
                "$ARG_NAME_TAR" \
                "$ARG_MACHINE:/root/$ARG_NAME_TAR";
                docker-machine ssh "$ARG_MACHINE" "true \
                && mkdir -p $ARG_PUSH_DESTINATION_DIR \
                && tar -xO -C $ARG_PUSH_DESTINATION_DIR -f $ARG_NAME_TAR $ARG_PUSH_SOURCE_FILENAME > $ARG_PUSH_DESTINATION \
                && rm -rf $ARG_NAME_TAR \
                && chown -R root:root $ARG_PUSH_DESTINATION_DIR";
              elif [ -d "$ARG_PUSH_SOURCE" ]; then
                tar -zcvf "$ARG_NAME_TAR" -C "$ARG_PUSH_SOURCE" .;
                docker-machine scp \
                "$ARG_NAME_TAR" \
                "$ARG_MACHINE:/root/$ARG_NAME_TAR";
                docker-machine ssh "$ARG_MACHINE" "true \
                && rm -rf $ARG_PUSH_DESTINATION/** \
                && mkdir -p $ARG_PUSH_DESTINATION \
                && tar -xf $ARG_NAME_TAR -C $ARG_PUSH_DESTINATION \
                && rm -rf $ARG_NAME_TAR \
                && chown -R root:root $ARG_PUSH_DESTINATION_DIR";
              fi;
              exit 0;
            ;;
            'pull')
              ARG_TARGET="$(echo $1 | sed 's|^./||')"; shift;
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
    tar -zcvf "$ARG_NAME_TAR" -C "$ARG_PULL_SOURCE_DIR" $ARG_PULL_SOURCE_FILENAME 1>&2;
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
                $ARG_PULL_SOURCE_FILENAME > $ARG_PULL_DESTINATION;
              elif [ $ARG_SOURCE_TYPE == 'directory' ]; then
                rm -rf "$ARG_PULL_DESTINATION/**";
                mkdir -p "$ARG_PULL_DESTINATION";
                tar -xf "$ARG_NAME_TAR" -C "$ARG_PULL_DESTINATION";
              fi;
              docker-machine ssh "$ARG_MACHINE" "true \
              && rm -rf $ARG_NAME_TAR";
              exit 0;
            ;;
            'exec')
              docker-machine ssh "$ARG_MACHINE" "$@";
              exit 0;
            ;;
            'mkdir')
              docker-machine ssh "$ARG_MACHINE" "mkdir -p $@";
              exit 0;
            ;;
            'touch')
              docker-machine ssh "$ARG_MACHINE" "touch $@";
              exit 0;
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
                    echo "=> Error: Invalid argument \"$arg\"";
                    exit 1;
                  ;;
                esac;
              done;
              echo "rm -f $TMP_RC_FILE" >> $TMP_RC_FILE;
              bash --rcfile $TMP_RC_FILE;
              rm -rf $TMP_RC_FILE;
              exit 0;
            ;;
            'export')
              machine-export "${ARG_MACHINE}";
              exit 0;
            ;;
            'import')
              machine-import "${ARG_MACHINE}.zip";
              exit 0;
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
                        echo "=> Error: Invalid argument \"$arg\"";
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
                  exit 0;
                ;;
                *)
                  echo "=> Error: Driver \"$ARG_DRIVER\" not supported";
                  exit 1;
                ;;
              esac;
            ;;
            *)
              docker-machine $ARG_COMMAND $ARG_MACHINE $@;
              exit 0;
            ;;
          esac;
        ;;
        *)
          ensureComposeFiles;
          docker-compose $ARG_COMMAND $@;
          exit 0;
        ;;
      esac;
    ;;
  esac;
done;
