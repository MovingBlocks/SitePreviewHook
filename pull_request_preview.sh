REPO_LINK="$1";
REPO_DIR="$2";
ID="$3";
ROOT_DIR="$4";
DEPLOY_PATH="$5";
SUB_PATH="$6";
REPO_NAME="$7";
PREVIEW_URL="$8";

# Clone the repo if not done already
git clone $REPO_LINK $REPO_DIR;

# cd into the repo dir and switch to master branch
cd $REPO_DIR; 
git checkout master;

# Remove the PR branch if it exists
# This is done because commits can be force pushed
git branch -D $ID;

# Pull and checkout the PR into a new branch named after PR number
git fetch origin pull/$ID/head:$ID;
git checkout $ID; 

# Execute a build with the appropriate baseurl
bundle exec jekyll build --baseurl $SUB_PATH/$ID; 

# Clean existing files for the PR
rm -rf $DEPLOY_PATH$SUB_PATH/$ID

# Serve the built files
mkdir -p $DEPLOY_PATH$SUB_PATH/$ID
cp -R _site/* $DEPLOY_PATH$SUB_PATH/$ID/;

# Run the script to send the built status comment to the PR
ruby $ROOT_DIR/comment_pull_request.rb $ID $REPO_NAME $PREVIEW_URL; 
