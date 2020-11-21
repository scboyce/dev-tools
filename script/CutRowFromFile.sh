#!/bin/bash
##############################################################################
#
# Program: CutRowFromFile.sh
#
# Description: Cuts one row from a text file
#
# === Modification History ===================================================
# Date       Author          Comments
# ---------- --------------- -------------------------------------------------
# 04-24-2012 Steve Boyce     Created.
#
##############################################################################

if [ -z "$1" ]; then
   echo "Syntax: $0 <inputfile> <rownumber>"
   exit 1
fi

if [ -z "$2" ]; then
   echo "Syntax: $0 <inputfile> <rownumber>"
   exit 1
fi

echo "File: $1"
RowNum=$2
echo "RowNum: $RowNum"

HeadRow=$((RowNum-1))
echo "HeadRow: $HeadRow"

TailRow=$((RowNum+1))
echo "TailRow: $TailRow"

echo "Backing up file $1 to $1.bak..."
rm -f $1.bak
mv $1 $1.bak

echo "Copying rows 1 through $HeadRow from $1.bak to $1..."
head -$HeadRow $1.bak > $1

echo "Copying rows $TailRow through the end from $1.bak and appending to $1..."
tail --lines +$TailRow $1.bak >> $1

ls -l $1*
echo "Done."
