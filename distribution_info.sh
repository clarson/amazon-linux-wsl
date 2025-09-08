#!/bin/bash

THIS_VERSION=$1
DISTRO_VERSION=$2

if [ "$THIS_VERSION" = "" ]
then
    echo '"This"' version is required
    exit 1
fi

if [ "$DISTRO_VERSION" = "" ]
then
    echo '"Distro"' version is required
    exit 1
fi

if [ ! -f "$DISTRO_VERSION-arm64.wsl" ]
then
    echo $DISTRO_VERSION-arm64.wsl not found
    exit 1
fi


if [ ! -f "$DISTRO_VERSION-x86_64.wsl" ]
then
    echo $DISTRO_VERSION-x86_64.wsl not found
    exit 1
fi

SHORT_VERSION=$(sed -e 's/\..*//' <<<$DISTRO_VERSION)
BINARY_ARM_HASH=$(sha256sum -b $DISTRO_VERSION-arm64.wsl |sed -e 's/\s\+.*//')
BINARY_X86_HASH=$(sha256sum -b $DISTRO_VERSION-x86_64.wsl |sed -e 's/\s\+.*//')

cat << EOM > DistributionInfo.json
{
    "ModernDistributions": {
        "AmazonLinux": [
            {
                "Name": "$SHORT_VERSION",
                "FriendlyName": "AmazonLinux $SHORT_VERSION",
                "Default": true,
                "Amd64Url": {
                    "Url": "https://github.com/clarson/amazon-linux-wsl/releases/download/$THIS_VERSION/$DISTRO_VERSION-x86_64.wsl",
                    "Sha256": "$BINARY_ARM_HASH"
                },
                "Arm64Url": {
                    "Url": "https://github.com/clarson/amazon-linux-wsl/releases/download/$THIS_VERSION/$DISTRO_VERSION-arm64.wsl",
                    "Sha256": "$BINARY_X86_HASH"
                }
            }
        ]
    }
}
EOM
