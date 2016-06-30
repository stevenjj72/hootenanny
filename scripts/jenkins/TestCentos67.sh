#!/bin/bash

set -x
set -e

cd $HOOT_HOME

make -sj`nproc`

hoot --version --debug

export HOOT_TEST_DIFF=--diff

#make -sj`nproc` test-all

HootTest --exclude=.*RubberSheetConflateTest.sh \
  --exclude=.*ConflateCmdHighwayExactMatchInputsTest.sh \
  --exclude=.*ConflateAverageTest.sh \
  --slow

# This is a broken out version of "test-all" so we can exclude tests that fail on Centos67
#make -sj`nproc` services-test-all
make -sj`nproc` pp-test
make -sj`nproc` plugins-test
