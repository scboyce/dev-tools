#!/bin/bash

if [ $# -ne 2 ]; then
   echo "Syntax: ConvertUtf82ASCII.sh InputFile OutputFile"
   exit 1
fi

InputFile=${1}
OutputFile=${2}

echo "Converting UTF-8 file: ${InputFile} to an ASCII file: ${OutputFile}"
echo "Stripping all NON ASCII characters..."

iconv -f 'UTF-8' -t 'ASCII' --unicode-subst='' --byte-subst='' --widechar-subst='' ${InputFile} > ${OutputFile}

echo "Done."
