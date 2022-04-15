#!/bin/bash

set -e
/usr/local/bin/golangci-lint run --out-format "json" ./... \
    | ruby /usr/src/app/src/engine.rb
