#!/usr/bin/env bash

docker stop $(docker ps -q --filter name=loop-logger --filter name=radio_station --filter name=peer0)
