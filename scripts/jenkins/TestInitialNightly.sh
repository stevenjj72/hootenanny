#!/bin/bash
# Runs the initial nightly tests

set -x
set -e

make -sj`nproc`

hoot --version --debug

export HOOT_TEST_DIFF=--diff

make -sj`nproc` test-all

cd $HOOT_HOME/docs
make -sj`nproc`

cd $HOOT_HOME
make -sj`nproc` archive

make -sj`nproc` coverage

