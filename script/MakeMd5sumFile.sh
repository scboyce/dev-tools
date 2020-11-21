#!/bin/bash

UploadFile=${1}
echo "UploadFile: ${UploadFile}"
if [[ ! -e "${UploadFile}" ]]; then
   echo "UploadFile not found."
   echo "Syntax: ${0} <UploadFile>"
fi

echo "Creating md5sum file..."
md5sum ${UploadFile} | awk '{print $1}' > ${UploadFile}.md5

ls -lh ${UploadFile}*
