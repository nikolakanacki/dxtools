#!/bin/bash

function normalizePath {
  local path=${1//\/.\//\/};
  while [[ $path =~ ([^/][^/]*/\.\./) ]]; do
    path=${path/${BASH_REMATCH[0]}/};
  done;
  echo $path;
}

function localizePath {
  local SOURCE="${BASH_SOURCE[0]}";
  while [ -h "$SOURCE" ]; do
    local DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )";
    SOURCE="$(readlink "$SOURCE")";
    [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE";
  done;
  echo $(normalizePath "$(cd -P "$(dirname "$SOURCE")" && pwd)/$1");
}

if [ "$1" == '--version' ] || [ "$1" == '-v' ]; then
  cat $(localizePath ./package.json) \
  | grep '"version":' \
  | awk '{ print $2 }' \
  | sed 's/[",]//g';
  exit 0;
fi;

if [ -z "$npm_package_name" ]; then
  echo '=> Error: Key "name" is missing from the package.json';
  exit 1;
fi;

if [ -z "$npm_package_organization" ]; then
  echo '=> Error: Key "organization" is missing from the package.json';
  exit 1;
fi;

function printHelp {
  cat <<EOF | node
  const fs = require('fs');
  const h2t = require('html-to-text');
  const format = require('html-to-text/lib/formatter');
  const showdown = require('showdown');
  const converter = new showdown.Converter({
    disableForced4SpacesIndentedSublists: true,
    simpleLineBreaks: true,
  });

  process.stdout.write(
    \`\${
      h2t.fromString(
        converter.makeHtml(fs.readFileSync('`localizePath $1`', 'utf8')),
        {
          singleNewLineParagraphs: true,
          wordwrap: 79,
          format: {
            unorderedList: (elem, fn, options) => {
              return \`\n\${format.unorderedList(elem, fn, options)}\`;
            },
            orderedList: (elem, fn, options) => {
              return \`\n\${format.orderedList(elem, fn, options)}\`;
            },
            blockquote: (elem, fn, options) => {
              return \`\n\n> \${\`\${fn(elem.children, options)}\`.trim()}\n\n\`;
            },
            heading: (elem, fn, options) => {
              return \`\n\n\${format.heading(elem, fn, options)}\n\n\`;
            },
          },
        }
      )
      .replace(/(^[\t ]+$)/gm, '\n')
      .replace(/\n{2,}/g, '\n\n')
      .replace(/^\n+|\n+$/, '\n')
    }\n\n\`,
    () => process.exit(0),
  );
EOF
}

if [ "$NODE_ENV" != 'production' ]; then
  vars=$(cat \
    .env.default \
    .env.development \
    .env.development.local \
    .env \
    2>/dev/null | xargs \
  );
  if ! [ -z "$vars" ]; then
    export $vars;
  fi;
else
  vars=$(cat \
    .env.default \
    .env.production \
    .env.production.local \
    .env \
    2>/dev/null | xargs \
  );
  if ! [ -z "$vars" ]; then
    export $vars;
  fi;
fi;

while test $# -gt 0; do
  ARG_COMMAND="$1"; shift;
  case $ARG_COMMAND in
    'eval')
      if [ "$1" == "--help" ] || [ "$1" == "-h" ]; then
        shift;
        printHelp "./commands/${ARG_COMMAND}.md";
        exit 0;
      else
        echo "$URL_API";
        if eval "$@"; then
          exit 0;
        else
          exit 1;
        fi;
      fi;
    ;;
    'generate'|'docker'|'version'|'release')
      if [ "$1" == "--help" ] || [ "$1" == "-h" ]; then
        shift;
        printHelp "./commands/${ARG_COMMAND}.md";
        exit 0;
      else
        eval "$(localizePath ./commands/${ARG_COMMAND}.sh) $@";
        exit 0;
      fi;
    ;;
    '-d'|'--cd')
      cd $1; shift;
    ;;
    '--help'|'-h')
      printHelp "./README.md";
      exit 0;
    ;;
    *)
      echo "=> Error: Command does not exist: $ARG_COMMAND";
      exit 1;
    ;;
  esac;
done;
