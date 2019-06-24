#!/bin/bash

set -eo pipefail

VERSION=$(ruby lib/proteus/version.rb)

echo Building version $VERSION

rake build
