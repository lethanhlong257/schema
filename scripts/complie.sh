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
    $sourceDir/booster/models/revisit/*.proto $sourceDir/booster/models/common/*.proto \
    $sourceDir/booster/models/app/*.proto $sourceDir/booster/models/prime/*.proto \
    $sourceDir/booster/models/recommendation/*.proto \
    $sourceDir/booster/models/session/*.proto \
    $sourceDir/booster/models/subscription/*.proto \
    $sourceDir/booster/models/user/*.proto \
    $sourceDir/booster/models/defect_tracking_issue/*.proto \
    $sourceDir/booster/models/organization/*.proto \
    $sourceDir/booster/models/app_installed/*.proto \
    $sourceDir/booster/models/app_launched/*.proto \
    $sourceDir/booster/models/device/*.proto \
    $sourceDir/booster/models/device_usage/*.proto \
    $sourceDir/booster/models/element_selector/*.proto \
    $sourceDir/booster/models/group/*.proto \
    $sourceDir/booster/events/*.proto \
    $sourceDir/booster/ai/*.proto \
    $sourceDir/rpc/*.proto \
    $sourceDir/queue/*.proto \
    $sourceDir/queue/at-rest/*.proto \
    $sourceDir/rpc/entitlement/*.proto \
    $sourceDir/rpc/models/*.proto \
    $sourceDir/rpc/event_message/*.proto "$@"
}

echo "Generating code for NodeJS..."
executeGenCmd \
  --js_out=import_style=commonjs,binary:$outDir

if [ "$gRPCLib" == "grpc-js" ]; then
  # Compile gRPC to nodejs which will includes "@grpc/grpc-js" lib instead of "grpc" into compiled files
  # See why we use "@grpc/grpc-js" here https://kobiton.atlassian.net/browse/KOB-9515
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

echo "Generating code for Python..."

# A trick to bypass this issue https://github.com/protocolbuffers/protobuf/issues/1491#issue-153287065
cp $sourceDir/booster/ai/*.proto $outDir/booster/ai/
grandParentDir="$(dirname "$(dirname "$outDir")")"
$rootDir/.penv/bin/python -m grpc_tools.protoc --proto_path=$grandParentDir \
  --python_out=$grandParentDir --grpc_python_out=$grandParentDir \
  $outDir/booster/ai/*.proto
rm $outDir/booster/ai/*.proto

echo "Copy all *.js files..."
node ./node_modules/copy/bin/cli.js "$sourceDir/**/*.js" $outDir
