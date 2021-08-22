#!/bin/sh

echo "conobj = \"0x$(solc --bin $1 | tail -1)\"" > binfile.js
echo "conabi = $(solc --abi $1 | sed -n -e 4p -e 8p)" > temp
sed -e ':a' -e 'N' -e '$!ba' -e 's/\]\n\[/,/g' temp > abifile.js
rm temp
