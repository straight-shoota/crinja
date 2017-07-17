#! /usr/bin/env bash
# This script builds the latest documentation and copies it into a doc directory.

set -o errexit

if [ "$CI" = true ] && ([ "$TRAVIS_BRANCH" != "master" ] || [ "$TRAVIS_PULL_REQUEST" = "true" ]); then
  echo -e "Aborting docs generation, we're on CI and this is not a push to master"
  echo -e "TRAVIS_TAG=$TRAVIS_TAG"
  echo -e "TRAVIS_BRANCH=$TRAVIS_BRANCH"
  exit 0
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

WORKDIR="$HOME/${REPO}-docs-${TAG}"
if [ "$GH_TOKEN" = "" ]; then
  DOCS_REPO="git@github.com:${REPO}"
else
  DOCS_REPO="https://${GH_TOKEN}@github.com/${REPO}"
fi
DOCS_BRANCH="${DOCS_BRANCH:-gh-pages}"
TARGET_PATH="api/${TAG}"
GENERATED_DOCS_DIR="$(pwd)/doc"

function run_subcommand() {
  echo -e "  ==> $*"
  "$@"
  echo -e "  ==> done $1"
  echo -e ""
}

echo -e "Building documentation for branch ${BRANCH} ($TAG) from source at ${GENERATED_DOCS_DIR}"
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

mkdir -p "${TARGET_PATH}"
rsync -a "${GENERATED_DOCS_DIR}/" "${TARGET_PATH}"
if [ "$BRANCH" = "master" ]; then
  run_subcommand cp "${GENERATED_DOCS_DIR}/README.md" "${WORKDIR}"
fi

git -c core.fileMode=false add -f .

if [ "$CI" = true ]; then
  BUILD_NOTICE_TRAVIS=" on successful travis build $TRAVIS_BUILD_NUMBER"
else
  run_subcommand git -c core.fileMode=false status
fi
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
