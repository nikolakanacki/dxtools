#!/bin/bash

if ! [ -z "$(git status --porcelain)" ]; then
  echo '=> Error: Clean up your working directory before making a version bump';
  exit 1;
elif [ "$(git symbolic-ref --short -q HEAD)" != 'master' ]; then
  echo '=> Error: Cannot perform a version bump on branches other than master';
  exit 1;
fi;

argVersion="$1";
argPreid="$2";

if [ "$argPreid" != '' ]; then
  case "$argVersion" in
    'major')
      argVersion='premajor';
    ;;
    'minor')
      argVersion='preminor';
    ;;
    'patch')
      argVersion='prepatch';
    ;;
  esac;
  if ! [[ $argVersion =~ ^pre ]]; then
    echo "=> Error: Cannot perform a prerelease version bump with \"${argVersion}\"";
    exit 1;
  fi;
  npm_package_new_version=$(\
    semver \
    $npm_package_version \
    --increment $argVersion \
    --preid $argPreid \
  );
else
  case "$argVersion" in
    'major'|'minor'|'patch')
      npm_package_new_version=$(\
        semver \
        $npm_package_version \
        --increment $argVersion \
      );
    ;;
    *)
      npm_package_new_version="$argVersion";
    ;;
  esac;
fi;

if [ -z "$npm_package_new_version" ]; then
  exit 1;
fi;

npm --no-git-tag-version version $npm_package_new_version;

git add .;
yarn tools eval 'git commit -m "chore: version bump ($npm_package_version)"';
yarn tools eval 'git tag v$npm_package_version';
