#!/bin/bash
set -ex

PUBLIC_DIR="public"
GIT_URL=$(git remote get-url origin)

# Ensure theme is using our local changes
set +e
grep theme.*\"er\" config.toml
USING_ER_THEME=$?
set -e
if [ $USING_ER_THEME -eq 0 ]; then
    grep -q develop themes/er/.git/HEAD
fi

# Publish the site (along with drafts)
pushd $(dirname $0)

publish-hugo-drafts.sh

# Push to GitHub
pushd "${PUBLIC_DIR}"
git init
git add .
git commit -m "Deploy to GitHub Pages"
git push --force "${GIT_URL}" master:gh-pages
popd

popd
