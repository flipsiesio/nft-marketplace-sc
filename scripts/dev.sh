#!/usr/bin/env bash

# ganache-cli --fork https://api.trongrid.io -p 9090 -e 1000 -i 1
tron-cli quick

source .env && tronbox migrate --reset --network development
