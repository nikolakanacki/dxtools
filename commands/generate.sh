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
  'gitignore')
    if [ -f .gitignore ]; then
      echo 'File .gitignore was found. Please remove it before generating new one.';
      exit 1;
    fi;
    $ARG_TARGET=$1; shift;
    case $ARG_TARGET in
      'node')
        echo '# dxtools' >> .gitignore;
        echo '/data' >> .gitignore;
        echo '.env.*.local' >> .gitignore;
        echo '/*.tar.gz' >> .gitignore;
        echo '' >> .gitignore;
        curl -L https://raw.githubusercontent.com/github/gitignore/master/Node.gitignore >> .gitignore;
      ;;
      *)
        echo "Gitignore target \"$ARG_TARGET\" not supported";
        exit 1;
      ;;
    esac;
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
