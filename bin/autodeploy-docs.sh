#! /usr/bin/env bash
# This script builds the latest documentation and copies it into a doc directory.

set -o errexit

if [ "$CI" == true ] && ([ "$TRAVIS_BRANCH" != "master" ] || [ "$TRAVIS_PULL_REQUEST" == "true" ]); then
  echo -e "Aborting docs generation, we're on CI and this is not a push to master"
  echo -e "TRAVIS_TAG=$TRAVIS_TAG"
  echo -e "TRAVIS_BRANCH=$TRAVIS_BRANCH"
  exit 0
fi

BRANCH="${BRANCH:-$TRAVIS_BRANCH}"
TAG="${TAG:-$TRAVIS_TAG}"
REPO="${REPO:-$TRAVIS_REPO_SLUG}"

if [ "$BRANCH" == "" ]; then
  BRANCH=$(git rev-parse --abbrev-ref HEAD)

  if [ "$TAG" == "" ]; then
    TAG=$(git name-rev --tags --name-only "${BRANCH}")
  fi
fi

if [ "$TAG" == "undefined" ]; then
  TAG="latest"
fi

WORKDIR="$HOME/${REPO}-docs-${TAG}"
DOCS_REPO="https://${GH_TOKEN}@github.com/${REPO}"
DOCS_BRANCH="${DOCS_BRANCH:-gh-pages}"
TARGET_PATH="api/${TAG}"
GENERATED_DOCS_DIR="$(pwd)/doc"

echo -e "Generating documentation for branch ${BRANCH} ($TAG)."


echo -e "Building docs with bin/generate-docs.sh into ${GENERATED_DOCS_DIR}."

bin/generate-docs.sh

echo -e "Checking out docs repository ${DOCS_REPO} ${DOCS_BRANCH} into ${WORKDIR}."

rm -rf "${WORKDIR}"
git clone --quiet --branch="${DOCS_BRANCH}" "${DOCS_REPO}" "${WORKDIR}" > /dev/null

cd "${WORKDIR}"

git rm -rf "${TARGET_PATH}" --ignore-unmatch --quiet

mkdir -p "${TARGET_PATH}"
rsync -a "${GENERATED_DOCS_DIR}/" "${TARGET_PATH}"

git add -f .

if [ "$CI" == "true" ]; then
  BUILD_NOTICE=" on successful travis build $TRAVIS_BUILD_NUMBER"
fi
LOCAL_GIT_CONF=""
if [ "$GIT_COMMITTER_NAME" != "" ]; then
  LOCAL_GIT_CONF="-c user.name=\"$GIT_COMMITTER_NAME\" -c user.email=\"$GIT_COMMITTER_EMAIL\""
fi
git ${LOCAL_GIT_CONF} commit -m "Docs generated${TRAVIS_BUILD_NOTICE} for ${BRANCH} ($TAG)" | head -n 3
git push -fq origin ${DOCS_BRANCH} > /dev/null

echo -e "Deployed generated docs to ${DOCS_REPO} ${DOCS_BRANCH}."
