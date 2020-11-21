#!/bin/bash
##############################################################################
#
# Program: GatherAllInfLogs.sh
#
# Description: Gathers all node logs across cluster and transfers them to the
#              Primary node.
#
#              See /shared/inform/param/GatherInfLogs.cfg
#
# === Modification History ===================================================
# Date       Author          Comments
# ---------- --------------- -------------------------------------------------
# 09-25-2013 Steve Boyce     Created.
#
##############################################################################

. /shared/inform/param/GatherInfLogs.cfg

echo "Node1: $Node1"
echo "Node2: $Node2"

ssh inform@${Node1} '/shared/inform/bin/GatherInfLogs.sh'
ssh inform@${Node2} '/shared/inform/bin/GatherInfLogs.sh'
