#!/bin/sh -l

set -e

# Check values

if [ -n "${PUBLISH_REPOSITORY}" ]; then
    TARGET_REPOSITORY=${PUBLISH_REPOSITORY}
else
    TARGET_REPOSITORY=${GITHUB_REPOSITORY}
fi

if [ -n "${BRANCH}" ]; then
    TARGET_BRANCH=${BRANCH}
else
    TARGET_BRANCH="gh-pages"
fi

if [ -n "${PUBLISH_DIR}" ]; then
    TARGET_PUBLISH_DIR=${PUBLISH_DIR}
else
    TARGET_PUBLISH_DIR="./public"
fi

if [ -z "$PERSONAL_TOKEN" ]
then
  echo "You must provide the action with either a Personal Access Token or the GitHub Token secret in order to deploy."
  exit 1
fi

REPOSITORY_PATH="https://x-access-token:${PERSONAL_TOKEN}@github.com/${TARGET_REPOSITORY}.git"


# Start deploy

echo ">_ Start deploy to ${TARGET_REPOSITORY}"

git config --global core.quotepath false
git config --global --add safe.directory /github/workspace

cd "${GITHUB_WORKSPACE}"


# Set post's update date to the timestamp of the most recent Git commit

find source/_posts -name "*.md" | while read file; do
  timestamp=$(git log -1 --format="%ct" "$file")
  formatted_timestamp=$(date -u -d "@$timestamp" "+%Y%m%d%H%M.%S")
  touch -t "$formatted_timestamp" "$file"
done


echo ">_ Install NPM dependencies ..."
npm install

echo ">_ Clean cache files ..."
npx hexo clean

echo ">_ Generate file ..."
npx hexo generate

cd "${TARGET_PUBLISH_DIR}"

CURRENT_DIR=$(pwd)


# Configures Git

echo ">_ Config git ..."

git init
git config --global user.name "${GITHUB_ACTOR}"
git config --global user.email "${GITHUB_ACTOR}@users.noreply.github.com"
git config --global --add safe.directory "${CURRENT_DIR}"

git remote add origin "${REPOSITORY_PATH}"
git checkout --orphan "${TARGET_BRANCH}"

git add .

echo '>_ Start Commit ...'
git commit --allow-empty -m "Build and Deploy from Github Actions"

echo '>_ Start Push ...'
git push -u origin "${TARGET_BRANCH}" --force

echo ">_ Deployment successful"