#!/usr/bin/env bash

set -eo pipefail

# if command v is not present
if ! command -v v > /dev/null 2>&1; then
  git clone --depth 1 --branch master https://github.com/vlang/v.git
  cd v
  make
  ./v symlink
  cd ..
fi

# Build the projects
if [ ! -d bin ]; then
  mkdir bin
fi

# configure compile flags
COMP_FLAGS="-prod -skip-unused"
# if linux then add -cflags -static
if [ "$(uname)" == "Linux" ]; then
	COMP_FLAGS="$COMP_FLAGS -compress -cflags -static"
fi

# build and copy executables
v ${COMP_FLAGS} -o bin/dirserve $PWD/src

tar -czvf bin.tgz bin/*
