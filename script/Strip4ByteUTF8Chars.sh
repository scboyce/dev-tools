#!/bin/bash

if [ $# -ne 2 ]; then
   echo "Syntax: Strip4ByteUTF8Chars.sh InputFile OutputFile"
   exit 1
fi

InputFile=${1}
OutputFile=${2}

echo "Stripping UTF-8 characters encoded with 4-Bytes or more from: ${InputFile} to: ${OutputFile}"

iconv -f 'UTF-8' -t 'UCS-2' ${InputFile} | iconv -f 'UCS-2' -t 'UTF-8' > ${OutputFile}

echo "Done."
