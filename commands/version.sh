#!/bin/bash

if ! [ -z "$(git status --porcelain)" ]; then
  echo '=> Error: Clean up your working directory before making a version bump' 1>&2;
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
    echo "=> Error: Cannot perform a prerelease version bump with \"${argVersion}\"" 1>&2;
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
    'major'|'minor'|'patch'|'prerelease')
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
  echo '=> Error: New version is empty' 1>&2;
  exit 1;
fi;

if [ -x ./scripts/version.sh ]; then
  echo '=> Running custom version script' 1>&2;
  if ! npm_package_new_version="$npm_package_new_version" ./scripts/version.sh 1>&2; then
    echo '=> Error: Script exited with non 0 exit code' 1>&2;
    exit 1;
  fi;
fi;

npm --no-git-tag-version version $npm_package_new_version 1>&2;

git add . 1>&2;
git commit -m "chore: version bump (${npm_package_new_version})" 1>&2;
git tag -a "v${npm_package_new_version}" -m "Release v${npm_package_new_version}" 1>&2;

echo $npm_package_new_version;
