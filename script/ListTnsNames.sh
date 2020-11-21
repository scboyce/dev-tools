#!/bin/bash
###############################################################################
#
# Program     : ListTnsNames.sh
#
# Description : List each TNS entry in $TNS_ADMIN/tnsnames.ora
#               Uppercased and sorted
#
# Date       Developer      Description
# ---------- -------------- --------------------------------------------------
# 2012-04-02 Steve Boyce    Initial release
#
###############################################################################

TnsNames=$(egrep -io "^([A-Z0-9_\-])+(\.world){0,1}.*=" $TNS_ADMIN/tnsnames.ora)
TnsNames=$(echo $TnsNames | tr "=" " ") 
TnsNames=$(echo $TnsNames | tr "," "\n") 
Counter=0

#-- Load up array
for TnsName in ${TnsNames}; do
   TnsName=$(echo "$TnsName" | tr "[:lower:]" "[:upper:]")
   TnsList[${Counter}]=$TnsName
   let Counter+=1
    #if [ $Counter -gt 15 ]; then
    #   break
    #fi
done

#-- Sort the array
NumElements=${#TnsList[@]}
LastIndex=$((${NumElements}-1))

for (( i=0; i<=${LastIndex}-1; i++ )); do
   for (( j=${i}+1; j<=${LastIndex}; j++ )); do
      jString=${TnsList[$j]}
      iString=${TnsList[$i]}
      if [ "$jString" \< "$iString" ]; then
         #-- Swap
         TempValue=${TnsList[$i]}
         TnsList[$i]=${TnsList[$j]}
         TnsList[$j]=${TempValue}
      fi
   done
done

#-- List em all!
echo "TNS Name"
echo "----------------------------------------"
for (( i=0; i<=${LastIndex}; i++ )); do
   echo ${TnsList[$i]}
done
