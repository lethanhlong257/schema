#!/bin/bash

#
# Compile protocol buffer code. Usage: bash scripts/compile.sh /absolute/path/to/out/dir
#

# Interrupt on error for addressing earlier
set -e

# To help consumer repos easier for compiling, we auto install dependencies so that
# they (consumer repos) can just call one command "yarn compile" to get the
# generated source code
yarn install --frozen-lockfile --non-interactive

outDir="$1"

gRPCLib="${2-grpc}"

rootDir=`dirname $(dirname $0)`

if [ -z "$outDir" ]; then
  outDir=`pwd`/dist
fi

mkdir $outDir &>/dev/null || true

sourceDir=$rootDir/src

executeGenCmd() {
 $rootDir/.protoc-cache/protoc/bin/protoc \
    --proto_path=$sourceDir \
    $sourceDir/rpc/*.proto \
    "$@"
}

echo "Generating code for NodeJS..."
executeGenCmd \
  --js_out=import_style=commonjs,binary:$outDir

if [ "$gRPCLib" == "grpc-js" ]; then
  # Compile gRPC to nodejs which will includes "@grpc/grpc-js" lib instead of "grpc" into compiled files
  echo "Generating code for NodeJS GRPC using grpc-js..."
  executeGenCmd \
    --grpc_out=grpc_js:$outDir \
    --plugin=protoc-gen-grpc=`which grpc_tools_node_protoc_plugin`
else
  # Compile gRPC to nodejs which will includes "gprc" lib into compiled files
  echo "Generating code for NodeJS GRPC using grpc-node..."
  executeGenCmd \
    --grpc_out=$outDir \
    --plugin=protoc-gen-grpc=`which grpc_tools_node_protoc_plugin`
fi

echo "Generating code for GRPC web..."
executeGenCmd \
  --grpc-web_out=import_style=commonjs,mode=grpcwebtext:$outDir \
  --plugin=protoc-gen-grpc-web=$rootDir/.protoc-cache/protoc-gen-grpc-web


echo "Copy all *.js files..."
node ./node_modules/copy/bin/cli.js "$sourceDir/**/*.js" $outDir
