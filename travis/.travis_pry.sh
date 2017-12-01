#hook to prevent binding.pry getting into production code
echo "Testing for pry"

if [ "$TRAVIS_PULL_REQUEST" == "true" ]; then
  TEST_BRANCH=$TRAVIS_PULL_REQUEST_BRANCH
else
  TEST_BRANCH=$TRAVIS_BRANCH
fi

echo "Testing $TEST_BRANCH"


DIFF_SEARCH=$(git diff --name-only $TRAVIS_COMMIT_RANGE)

echo "Commit includes these files:"
echo "$DIFF_SEARCH"

PATTERN='binding\.pry'

RESULT=$(grep -v -E '#' $DIFF_SEARCH | grep -i $PATTERN)
echo "$RESULT"

if [ "$RESULT" ]; then
  echo "Exit build; found pry in this commit."
  exit 1
fi
