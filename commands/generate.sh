#!/bin/bash

ARG_TARGET=$1; shift;

case $ARG_TARGET in
  'env')
    touch \
      .env.default \
      .env.development \
      .env.development.local \
      .env.production \
      .env.production.local \
      .env.staging \
      .env.staging.local \
      .env;
  ;;
  'gitignore')
    if [ -f .gitignore ]; then
      echo '=> Error: File named .gitignore already exists in your project. Please remove it before generating new one.';
      exit 1;
    fi;
    ARG_TARGET=$1; shift;
    echo '# dxtools' >> .gitignore;
    echo '/data' >> .gitignore;
    echo '.env.*.local' >> .gitignore;
    echo '/*.tar.gz' >> .gitignore;
    echo '' >> .gitignore;
    curl "https://raw.githubusercontent.com/github/gitignore/master/${ARG_TARGET}.gitignore" >> .gitignore;
  ;;
  'dockerignore')
    if [ -f .dockerignore ]; then
      echo '=> Error: File named .dockerignore already exists in your project. Please remove it before generating new one.';
      exit 1;
    else
      echo '.git' >> .dockerignore;
      echo 'data' >> .dockerignore;
      echo 'node_modules' >> .dockerignore;
      echo '*.tar.gz' >> .dockerignore;
    fi;
  ;;
  *)
    echo "=> Error: Invalid generate target: \"$ARG_COMMAND\"";
    exit 1;
  ;;
esac;
