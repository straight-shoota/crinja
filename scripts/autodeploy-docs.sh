#! /usr/bin/env bash
# This script does the following:
# * clone the docs repository ($DOCS_REPO, $DOCS_BRANCH)
# * collect documentation from a source directory ($GENERATER_DOCS_DIR)
# * commit updates to repository
# * push local repository to origin
# It can be installed as an after_success hook on a CI setup or run manually.
# Most configuration values will work with their default values on Travis-CI or when run from a local copy of
# a repository at Github. They can also be customized trough environment variables.

set -o errexit

if [ "$CI" = true ] && ([ "$TRAVIS_BRANCH" != "master" ] || [ "$TRAVIS_PULL_REQUEST" = "true" ]); then
  echo -e "Aborting docs generation, we're on CI and this is not a push to master"
  echo -e "TRAVIS_TAG=$TRAVIS_TAG"
  echo -e "TRAVIS_BRANCH=$TRAVIS_BRANCH"
  exit 0
fi

GENERATED_DOCS_DIR="${GENERATED_DOCS_DIR:-"$(pwd)/doc"}"
if [ ! -d "$GENERATED_DOCS_DIR" ]; then
  echo -e "Source directory \`$GENERATED_DOCS_DIR\` does not exist."
  echo -e "Please create the documentation at this path or change it by assigning a different path to \$GENERATER_DOCS_DIR"
  exit 1
fi

BRANCH="${BRANCH:-$TRAVIS_BRANCH}"
TAG="${TAG:-$TRAVIS_TAG}"
REPO="${REPO:-$TRAVIS_REPO_SLUG}"

if [ "$BRANCH" = "" ]; then
  BRANCH=$(git rev-parse --abbrev-ref HEAD)

  if [ "$TAG" = "" ]; then
    TAG=$(git name-rev --tags --name-only "${BRANCH}")
  fi
fi

if [ "$REPO" = "" ]; then
  REPO=$(git ls-remote --get-url origin)
  REPO="${REPO#*:}"
fi

if [ "$TAG" = "undefined" ] || [ "$TAG" = "" ]; then
  TAG="latest"
fi

WORKDIR="${WORKDIR:-"$HOME/${REPO}-docs-${TAG}"}"
if [ "$DOCS_REPO" == "" ]; then
  if [ "$GH_TOKEN" = "" ]; then
    DOCS_REPO="git@github.com:${REPO}"
  else
    DOCS_REPO="https://${GH_TOKEN}@github.com/${REPO}"
  fi
fi
DOCS_BRANCH="${DOCS_BRANCH:-gh-pages}"
TARGET_PATH="${TARGET_PATH:-"api/${TAG}"}"

function run_subcommand() {
  echo -e "  ==> $*"
  "$@"
  echo -e "  ==> done $1"
  echo -e ""
}

echo -e "Autodeploying documentation for branch ${BRANCH} ($TAG) from ${GENERATED_DOCS_DIR}"

### Clone docs repository
echo -e "Checking out docs repository ${DOCS_REPO} ${DOCS_BRANCH} into ${WORKDIR}"
echo -e ""

rm -rf "${WORKDIR}"
if [ "$CI" = true ]; then
  git clone --quiet --branch="${DOCS_BRANCH}" "${DOCS_REPO}" "${WORKDIR}" > /dev/null 2>/dev/null
else
  run_subcommand git clone --branch="${DOCS_BRANCH}" "${DOCS_REPO}" "${WORKDIR}"
fi

cd "${WORKDIR}"

git rm -rf "${TARGET_PATH}" --ignore-unmatch --quiet

## Collect docs from source

mkdir -p "${TARGET_PATH}"
rsync -a "${GENERATED_DOCS_DIR}/" "${TARGET_PATH}"
if [ "$BRANCH" = "master" ]; then
  run_subcommand cp -v "${GENERATED_DOCS_DIR}/README.md" "${WORKDIR}"
fi

## Commit updates to repository
git -c core.fileMode=false add -f .

if [ "$CI" = true ]; then
  BUILD_NOTICE_TRAVIS=" on successful travis build $TRAVIS_BUILD_NUMBER"
else
  run_subcommand git -c core.fileMode=false status
fi

## Push local repository to origin
LOCAL_GIT_CONF=()
if [ "$GIT_COMMITTER_NAME" != "" ]; then
  LOCAL_GIT_CONF=(-c "user.name=$GIT_COMMITTER_NAME" -c "user.email=$GIT_COMMITTER_EMAIL")
fi

if [ "$GIT_COMMIT_MESSAGE" = "" ]; then
  GIT_COMMIT_MESSAGE="Docs generated${BUILD_NOTICE_TRAVIS} for ${BRANCH} ($TAG)"
fi
# TOOO: pipe git commit through `head -n 3` to show only the status information
run_subcommand git "${LOCAL_GIT_CONF[@]}" commit -m "$GIT_COMMIT_MESSAGE"

if [ "$CI" = true ]; then
  git push -fq origin "${DOCS_BRANCH}" > /dev/null 2>/dev/null
else
  run_subcommand git push -f origin "${DOCS_BRANCH}"
fi

echo -e "Deployed generated docs to ${DOCS_REPO} ${DOCS_BRANCH}."
