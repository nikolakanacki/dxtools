#!/bin/bash

echo '=> Fetching...';
git fetch &>/dev/null;

if ! [ -z "$(git status --porcelain)" ]; then
  echo '=> Error: Clean up your working directory before creating a release';
  exit 1;
elif [ "$(git symbolic-ref --short -q HEAD)" != 'dev' ]; then
  echo '=> Error: Releases can only be performed from a dev branch';
  exit 1;
elif [ $(git rev-parse HEAD) != $(git rev-parse @{u}) ]; then
  echo '=> Error: Dev branch needs a pull / push before proceeding';
  exit 1;
elif ! git rev-parse --abbrev-ref --symbolic-full-name '@{u}' &>/dev/null; then
  echo '=> Error: Dev branch does not seem to have a remote tracking branch';
  exit 1;
fi;

echo '=> Checking out master for testing';
git checkout master &>/dev/null;

if [ "$(git symbolic-ref --short -q HEAD)" != 'master' ]; then
  echo '=> Error: You do not seam to have a master branch';
  exit 1;
elif ! git rev-parse --abbrev-ref --symbolic-full-name '@{u}' &>/dev/null; then
  echo '=> Error: Master branch does not seem to have a remote tracking branch';
  exit 1;
elif [ $(git rev-parse HEAD) != $(git rev-parse @{u}) ]; then
  echo '=> Error: Master branch needs a pull / push before proceeding';
  exit 1;
fi;

echo '=> Going back to dev for a version bump';
git checkout dev &>/dev/null;

echo '=> Generating release changelog';
newVersionChangelog="$(git log master..dev --pretty=format:'- %h %s')";

echo '=> Performing a version bump';
newVersion=$($DXTOOLS_EXECUTABLE version "$@");

if [ -z "$newVersion" ]; then
  echo '=> Error: Could not perform a version bump';
  exit 1;
fi;

newMessage="Release v${newVersion}\n\n${newVersionChangelog}";

echo '=> Checking out master for a merge';
git checkout master &>/dev/null \
  && echo '=> Performing the merge with changelog' \
  && git merge --no-ff --no-edit dev \
  && echo -e "$newMessage" | git commit --amend --file - \
  && echo '=> Moving git tag to the merge commit' \
  && echo -e "$newMessage" | git tag -f "v${newVersion}" --file - \
  && echo '=> Pushing to master' \
  && git push && git push --tags \
  && echo '=> Going back to dev for a merge' \
  && git checkout dev &>/dev/null \
  && echo '=> Pushing to dev' \
  && git merge master && git push;
