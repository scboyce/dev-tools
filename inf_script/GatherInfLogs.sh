#!/bin/bash
##############################################################################
#
# Program: GatherInfLogs.sh
#
# Description: Gathers all node logs into one gzipped tarbal and sends it to
#              /shared/inform/Backup/InfLogs directory on the primary node.
#               to current directory
#
#              See /shared/inform/param/GatherInfLogs.cfg
#
# === Modification History ===================================================
# Date       Author          Comments
# ---------- --------------- -------------------------------------------------
# 09-25-2013 Steve Boyce     Created.
#
##############################################################################

echo "*** ETL Informatica node log gather script ***"

. /shared/inform/param/GatherInfLogs.cfg

echo "Node1: $Node1"
echo "Hostname: $HOSTNAME"
Today=`date +"%Y-%m-%d_%H%M%S"`
echo "Today: $Today"

LogDir="/home/inform/Informatica/9.5.1/tomcat/logs"
echo "LogDir: $LogDir"

TarName="$LogDir/InfNodeLogs_${Today}_${HOSTNAME}.tar"
echo "TarName: $TarName"

echo "Tarring..."
tar -cvf ${TarName} \
   $LogDir/catalina.out \
   $LogDir/exceptions.log \
   $LogDir/node.log

echo "Zipping..."
gzip ${TarName}

echo "SCPing..."
scp ${TarName}.gz inform@$Node1:/shared/inform/Backup/InfLogs

echo "Deleting..."
rm -f ${TarName}.gz
