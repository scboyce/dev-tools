#!/bin/bash

if [ $# -ne 2 ]; then
   echo "Syntax: ConvertJIS2UTF8.sh InputFile OutputFile"
   exit 1
fi

InputFile=${1}
OutputFile=${2}

echo "Converting Shift-JIS file: ${InputFile} to a UTF-8 file: ${OutputFile}"

iconv -f 'CP932' -t 'UTF-8' --unicode-subst='' --byte-subst='' --widechar-subst='' ${InputFile} > ${OutputFile}

echo "Done."
