#!/bin/bash

curl -X PUT 127.0.0.1:3000/services/pastebin \
  -H "Authentication: Hive $AUTHTOKEN" \
  -F single=@main.lua -F config=@config.json \
  | jq
