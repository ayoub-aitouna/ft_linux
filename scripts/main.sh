#!/bin/bash

username=lfs

echo "HERE: $PWD"

echo "LFS ${LFS:?}"

sudo sh ./scripts/prerequisites.sh

# sudo sh ./scripts/version-check.sh

if [ $? -ne 0 ]; then
    echo "Version check failed"
    exit 1
fi
sh ./scripts/instalation.sh
