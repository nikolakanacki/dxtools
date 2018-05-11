#!/bin/bash

if ! [ -z "$(git status --porcelain)" ]; then
  echo '=> Error: Clean up your working directory before creating a release';
  exit 1;
elif [ "$(git symbolic-ref --short -q HEAD)" != 'dev' ]; then
  echo '=> Error: Releases can only be performed from a dev branch';
  exit 1;
elif ! git rev-parse --abbrev-ref --symbolic-full-name '@{u}' &>/dev/null; then
  echo '=> Error: Dev branch does not seem to have a remote tracking branch';
  exit 1;
elif [ $(git log --oneline dev ^master | wc -l) == "0" ]; then
  echo '=> Error: Dev branch does not seem to be ahead of master';
  exit 1;
fi;

git checkout master &>/dev/null;

if [ "$(git symbolic-ref --short -q HEAD)" != 'master' ]; then
  echo '=> Error: You do not seam to have a master branch';
  exit 1;
elif ! git rev-parse --abbrev-ref --symbolic-full-name '@{u}' &>/dev/null; then
  echo '=> Error: Master branch does not seem to have a remote tracking branch';
  exit 1;
fi;

git merge --no-ff --no-edit dev \
  && dxtools version "$@" \
  && git push \
  && git push --tags;

git checkout dev && git merge master && git push;
