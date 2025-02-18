# Env vars parameters: 
# TARGET_BRANCH: dev, stable
# SHA_COMMIT: the sha of the commit to rebase
# AUTHOR: The user
# GITHUB_TOKEN: The token

allowed_branch_values=("dev" "stable")

# Check for valid choices
if ! grep -q "$TARGET_BRANCH" <<< "${allowed_branch_values[@]}"; then
    printf "\U274C $TARGET_BRANCH is not a valid choice. Valid choices are dev and stable."
    exit 0
fi

UPSTREAM_REPO_LOCATION=/tmp/upstream
git clone https://$AUTHOR:$GITHUB_TOKEN@github.com/r00ta/gitops-test.git $UPSTREAM_REPO_LOCATION > /dev/null 2>&1

cd $UPSTREAM_REPO_LOCATION

# peek branches 
git fetch --all > /dev/null 2>&1
git checkout --track origin/dev > /dev/null 2>&1
git checkout --track origin/stable > /dev/null 2>&1
git checkout main > /dev/null 2>&1

# If the deployment targets `stable`, then the feature must be on dev first.
if [[ "$TARGET_BRANCH" == "stable" ]]; then
  if [ $(git branch --contains $SHA_COMMIT | grep -c "dev") -eq 0 ]; then
    printf "\U274C In order to deploy to stable branch the feature must be on dev branch first. Please deploy it there first, check that everything is running fine and then promote it to stable."
    exit 0
  fi
fi

# If the commit is already on TARGET_BRANCH, the feature has been already merged and deployed.
if [ $(git branch --contains $SHA_COMMIT | grep -c "$TARGET_BRANCH") -ne 0 ]; then
  printf "\U274C $SHA_COMMIT is already on $TARGET_BRANCH branch!"
else
  git checkout $TARGET_BRANCH > /dev/null 2>&1
  git rebase $SHA_COMMIT > /dev/null 2>&1
  git push origin $TARGET_BRANCH > /dev/null 2>&1
  printf "\U2705 $SHA_COMMIT was not on $TARGET_BRANCH branch. $TARGET_BRANCH branch has been rebased and pushed to the upstream repository. The deployment is on the way!"
fi

rm -rf $UPSTREAM_REPO_LOCATION
