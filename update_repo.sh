REPO_LINK="$1";
REPO_DIR="$2";

# Clone the repo if not done already
git clone $REPO_LINK $REPO_DIR;
cd $REPO_DIR;

# Checkout master and pull latest changes.
# This may result in a Merge Conflict if commits are force pushed
# into the master branch. This is a bad practice and should be avoided.
git checkout master;
git pull origin master;
