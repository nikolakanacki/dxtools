if ! [ -z "$(git status --porcelain)" ]; then
  echo 'Clean up your working directory before making a version bump';
  exit 1;
fi;

npm --no-git-tag-version version $1;

git add .;
yarn tools eval 'git commit -m "chore: version bump ($npm_package_version)"';
yarn tools eval 'git tag v$npm_package_version';
