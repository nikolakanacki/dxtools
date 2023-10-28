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

function getEnvVars {
  cat \
    .env.default \
    ".env.${1}" \
    ".env.${1}.local" \
    .env \
    2>/dev/null | xargs;
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

if [ -z "$DXTOOLS_ENV" ]; then
  DXTOOLS_ENV='development';
fi;

if [ -z "$DXTOOLS_ENV_LOADED" ]; then
  DXTOOLS_ENV_LOADED='false';
fi;

if [ -z "$DXTOOLS_CWD" ]; then
  DXTOOLS_CWD='./';
fi;

if [ -z "$DXTOOLS_EXECUTABLE" ]; then
  export DXTOOLS_EXECUTABLE=$(localizePath index.sh);
fi;

while test $# -gt 0; do
  ARG_COMMAND="$1"; shift;
  case $ARG_COMMAND in
    '-ed')
      DXTOOLS_ENV='development';
      DXTOOLS_ENV_LOADED='false';
    ;;
    '-ep')
      DXTOOLS_ENV='production';
      DXTOOLS_ENV_LOADED='false';
    ;;
    '-es')
      DXTOOLS_ENV='staging'
      DXTOOLS_ENV_LOADED='false';
    ;;
    '-e'|'--env')
      DXTOOLS_ENV="$1";
      DXTOOLS_ENV_LOADED='false';
      shift;
    ;;
    '-d'|'--cd')
      DXTOOLS_CWD="$1";
      DXTOOLS_ENV_LOADED='false';
      shift;
    ;;
    '--no-env')
      DXTOOLS_ENV_LOADED='true';
    ;;
    '--help'|'-h')
      printHelp "./README.md";
      exit 0;
    ;;
    *)
      if [ "$DXTOOLS_ENV_LOADED" != 'true' ]; then
        vars=$(
          cat \
            .env.default \
            ".env.${DXTOOLS_ENV}" \
            ".env.${DXTOOLS_ENV}.local" \
            .env \
            2>/dev/null | xargs
        );
        if ! [ -z "$vars" ]; then
          export $vars;
        fi;
        export DXTOOLS_ENV;
        export DXTOOLS_ENV_LOADED='true';
      fi;
      cd "$DXTOOLS_CWD";
      case $ARG_COMMAND in
        'eval')
          if [ "$1" == "--help" ] || [ "$1" == "-h" ]; then
            shift;
            printHelp "./commands/${ARG_COMMAND}.md";
            exit 0;
          else
            eval "$@";
            exit $?;
          fi;
        ;;
        'shell')
          TMP_RC_FILE=$(mktemp);
          if [ -f ~/.bash_profile ]; then
            echo 'source ~/.bash_profile' >> $TMP_RC_FILE;
          fi;
          if [ -f ~/.bashrc ]; then
            echo 'source ~/.bashrc' >> $TMP_RC_FILE;
          fi;
          echo 'exit() { if [ -z "$1" ]; then builtin exit 0; fi; builtin exit $1; }' >> $TMP_RC_FILE;
          echo 'PS1="${PS1}(env:'"$DXTOOLS_ENV"') ";' >> $TMP_RC_FILE;
          argCommand=($@);
          echo "rm -f $TMP_RC_FILE" >> $TMP_RC_FILE;
          if [ "${#argCommand[@]}" -gt 0 ]; then
            echo 'onSigTerm() { kill -TERM "$childPid" 2>/dev/null; childExitCode=$?; exit $childExitCode; }' >> $TMP_RC_FILE;
            echo 'trap onSigTerm SIGTERM SIGINT' >> $TMP_RC_FILE;
            echo "${argCommand[@]} &" >> $TMP_RC_FILE;
            echo 'childPid=$!' >> $TMP_RC_FILE;
            echo 'wait "$childPid"' >> $TMP_RC_FILE;
            echo 'childExitCode=$?' >> $TMP_RC_FILE;
            echo 'exit $childExitCode' >> $TMP_RC_FILE;
          fi;
          bash --rcfile $TMP_RC_FILE;
          shellExitCode=$?;
          rm -rf $TMP_RC_FILE;
          exit $shellExitCode;
        ;;
        'generate'|'docker'|'version'|'release')
          if [ "$1" == "--help" ] || [ "$1" == "-h" ]; then
            shift;
            printHelp "./commands/${ARG_COMMAND}.md";
            exit 0;
          else
            eval "$(localizePath ./commands/${ARG_COMMAND}.sh) $@";
            exit $?;
          fi;
        ;;
        *)
          echo "=> Error: Command does not exist: $ARG_COMMAND";
          exit 1;
        ;;
      esac;
    ;;
  esac;
done;
