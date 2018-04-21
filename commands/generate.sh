#!/bin/bash

ARG_TARGET=$1;

case $ARG_TARGET in
  'env')
    touch \
      .env.default \
      .env.development \
      .env.development.local \
      .env.production \
      .env.production.local \
      .env;
  ;;
  'dockerignore')
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
    echo "Invalid generate target: \"$ARG_COMMAND\"";
    exit 1;
  ;;
esac;
