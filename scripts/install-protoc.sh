#!/bin/bash
# This script will download the binary compiler package and save in local
# Make sure it's triggered at root dir of this node module (./schema/booster)

# Update this var for upgrading protoc version
# Ref: https://github.com/protocolbuffers/protobuf/releases
VERSION=3.7.0

osName=`node -e "console.log(require('os').type())"`
rootDir=`dirname $(dirname $0)` 

cd $rootDir

# Install tool to generate gRPC for python at $rootDir before other commands
# navigates to child folder since other script uses fixed path for virtual python env
# It requires to use Python 3
python_cmd="python3"

if ! command -v $python_cmd &>/dev/null; then
  python_cmd="python"
fi

# Use built-in virtual env in python3 to solve the system permission on installing pip package
if [ ! -d ".penv" ];then
  $python_cmd -m venv --clear .penv/
  
  if [ ! -f ".penv/bin/pip" ]; then
    # Why on earth that pip could be unavailable in python3 :(
    curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
    .penv/bin/python get-pip.py
  fi
fi

# Upgrade local pip to 21.2.2 due to https://kobiton.atlassian.net/browse/KOB-16671
.penv/bin/pip install pip==21.2.2

# Now install dependencies
.penv/bin/python -m pip install grpcio-tools

# this is the cache folder
mkdir .protoc-cache &> /dev/null || true
cd .protoc-cache

filename="protoc-$VERSION-linux-x86_64"

if [ "$osName" = "Darwin" ]; then
  filename="protoc-$VERSION-osx-x86_64"
fi

if [ ! -e "$filename.zip" ]; then
  # Download links: https://github.com/protocolbuffers/protobuf/releases
  curl -OL "https://github.com/protocolbuffers/protobuf/releases/download/v$VERSION/$filename.zip"
fi

if [ ! -d $filename ]; then
  unzip $filename.zip -d $filename

  # Create soft-link to use one path for both OS and Linux env
  rm protoc &> /dev/null || true
  ln -s `pwd`/$filename protoc
fi

chmod +x protoc/bin/protoc

