#!/bin/bash
##############################################################################
#
# Program    : CleanUpInfTempFiles.sh
#
# Description: Deletes all Informatica Cache and Temp files
#
# Parameters : None
#
# Notes      : Only run this when informatica is NOT running.
#              Run this on each node, since Cache and Temp are local to each node.
#
# === Modification History ===================================================
# Date       Author          Comments
# ---------- --------------- --------------------------------------------
# 11-21-2013 Steve Boyce     Created.
# 01-10-2014 Steve Boyce     Added -s (Clean shared directories option)
#
##############################################################################

#-- Process options if any
Usage="Usage CleanUpInfTempFiles.sh [-s]"

while getopts ":s" Option
do
   case $Option in
      s )  Opt_s="TRUE";;
      \?)  echo "Error: unrecognized option."
           echo $Usage
           exit 1
   esac
done
shift $(($OPTIND - 1))

Process=`ps -ef | grep '\-DFrameworksLogFilePath=tomcat\/logs/node_jsf.log'`

if [[ -n "${Process}" ]]; then
   echo
   echo "**********************  WARNING  *************************"
   echo "**                                                      **"
   echo "**         Informatica appears to be running!           **"
   echo "** Only run this script when Informatica is NOT running **"
   echo "**                                                      **"
   echo "**********************************************************"
   echo

   while true; do
       read -p "Do you wish to Clear out the Cache and Temp directories anyway (y/n)? " yn
       case $yn in
           [Yy]* ) echo "Cleaning..."; break;;
           [Nn]* ) echo "Aborting."; exit;;
           * ) echo "Please answer yes or no.";;
       esac
   done
fi

if [[ -n ${Opt_s} ]]; then
   echo "Cleaning /shared/inform/Cache, Storage and Temp..."
   rm -f /shared/inform/Cache/*
   rm -f /shared/inform/Storage/*
   rm -f /shared/inform/Temp/*
fi

echo "Cleaning /inf_scratch/Cache, Temp..."
rm -f /inf_scratch/Cache/*
rm -f /inf_scratch/Temp/*
