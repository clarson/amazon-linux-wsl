#!/bin/bash

if [ "$USER" != "root" ]
then
  echo Must run as root
  exit 1
fi

./build.sh x86_64 || exit 1
./build.sh arm64 || exit 1
./distribution_info.sh || exit 1
