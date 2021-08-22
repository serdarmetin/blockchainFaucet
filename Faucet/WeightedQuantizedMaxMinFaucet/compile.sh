#!/bin/sh

echo "conobj = \"0x$(solc --bin $1 | tail -1)\"" > binfile.js
echo "conabi = $(solc --abi $1 | tail -1)" > abifile.js
