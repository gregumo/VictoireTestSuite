cd vendor/victoire/victoire/
if [ -n "${RUN_NIGHTLY_BUILD}" ]; then
  ./vendor/bin/behat --format=pretty --out=std --format=junit --out=$CIRCLE_TEST_REPORTS/$i/junit
fi
nohup bash circle-behat.sh Tests/Features &
wget http://psvcg.coreteks.org/php-semver-checker-git.phar
php php-semver-checker-git.phar suggest --allow-detached -vvv --details --include-before=src --include-after=src | awk '/Suggested semantic version: / {print $4}' | awk '{ print "{\"Suggested semantic version\":\"" $1 "\"}" }' > $CIRCLE_TEST_REPORTS/semver.json
if [ -n "${RUN_NIGHTLY_BUILD}" ]; then
  mkdir -p cp $CIRCLE_TEST_REPORTS/coverage && cp -R $(php -r "echo sys_get_temp_dir();")/Victoire/logs/coverage $CIRCLE_TEST_REPORTS
fi