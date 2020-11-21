#!/bin/bash

File=$1

if [[ -z $File ]]; then
   echo "Error: Missing input file name"
   echo "Syntax $0 <filename>"
   exit
fi

BakFile=${File}.bak

echo "Backing up file: $File..."
mv -f $File $BakFile

echo "Removing last line from: $File..."

head --lines=-1 $BakFile > $File
