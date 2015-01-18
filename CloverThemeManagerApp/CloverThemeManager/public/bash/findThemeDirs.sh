#!/bin/bash

# A script for Clover Theme Manager
# Copyright (C) 2014-2015 Blackosx
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# Scans all mounted volumes for an /EFI/Clover/Themes directory
# Any directories found have the following info saved to file:
# - Disk identifier
# - Unique Partition GUID
# - Mount point
# - Content (type - Apple_HFS, EFI etc.)
# - Full theme path
#
# Credits - JrCs for partutil program.

# ---------------------------------------------------------------------------------------
WriteToLog() {
    printf "@${1}@\n" >> "$logFile"
}

TMPDIR="/tmp/CloverThemeManager"
logFile="${TMPDIR}/CloverThemeManagerLog.txt"
themeDirInfo="${TMPDIR}/themeDirInfo.txt"
espList="${TMPDIR}/espList.txt"

# Enable for local testing
#zeroUUID="00000000-0000-0000-0000-000000000000"
#partutil="/tmp/partutil"
#DEBUG=1

[[ ! -f "$partutil" ]] && exit 1
[[ ! -d "$TMPDIR" ]] && mkdir -p "$TMPDIR"
[[ -f "$themeDirInfo" ]] && rm "$themeDirInfo"
[[ -f "$espList" ]] && rm "$espList"

declare -a dfMounts
declare -a dfMountpoints
declare -a gpt
declare -a espFound

# Send message to UI via log
#WriteToLog "CTM_ThemeDirsScan"

# Get List of mounted devices and mountpoints
WriteToLog "Getting list of mounted devices"
oIFS="$IFS"; IFS=$'\r\n'
dfMounts+=( $( df -laH | awk '{print $1}' | tail -n +2 | cut -d '/' -f 3  ))
dfMountpoints+=( /$( df -laH | cut -d'/' -f 4- | tail -n +2 ))
gpt+=( $( diskutil list | grep "GUID_partition_scheme" | cut -d 'B' -f 2 | tr -d ' ' ))
IFS="$oIFS"
WriteToLog "Check: dfMounts=${#dfMounts[@]}" 

#Loop through all disk partitions
for (( s=0; s<${#dfMounts[@]}; s++ ))
do
    mp=$( "$partutil" --show-mountpoint /dev/${dfMounts[$s]} )
    # If mountpoint is / then populate
    if [ "$mp" == "/" ]; then
        for vol in /Volumes/*
        do
            [[ "$(readlink "$vol")" = / ]] && tmp="$vol"
        done
        mp="${tmp}"
    elif [ "$mp" == "" ]; then # partutil does not return mountpoint under OS X 10.7
        mp=/${dfMountpoints[$s]}
    fi

    # Does this device contain /efi/clover/themes directory?
    themeDir=$( find "$mp"/EFI/Clover -depth 1 -type d -iname "Themes" 2>/dev/null )
    if [ "$themeDir" ]; then

        _content=$( "$partutil" --show-contenttype /dev/${dfMounts[$s]} )
        # Read and save Volume Name
        tmp=$( "$partutil" --show-volumename /dev/${dfMounts[$s]} )
        if [ "$tmp" == "" ]; then
            _volName=" "
        else
            _volName="$tmp"
        fi

        WriteToLog "Volume $_volName on mountpoint $mp contains Clover themes directory" 
        [[ DEBUG -eq 1 ]] && WriteToLog "${debugIndent}${dfMounts[$s]} | $_volName | $mp | $_content"

        # Read and save Unique partition GUID
        tmp=$( "$partutil" --show-uuid /dev/${dfMounts[$s]} )
        [[ $tmp == "" ]] && tmp="$zeroUUID" # MBR partitioned device do not have UUID's. Fill with zeros
        _uniquePartitionGuid="$tmp"
            
        # Write data to file.
        echo "${dfMounts[$s]}@${_volName}@${mp}@ @${_uniquePartitionGuid}@${themeDir}" >> "$themeDirInfo"
    fi
    
    _content=$( "$partutil" --show-contenttype /dev/${dfMounts[$s]} )
    # Record mounted esp info to file.
    if [ "$_content" == "C12A7328-F81F-11D2-BA4B-00A0C93EC93B" ]; then
        echo "${dfMounts[$s]}@M" >> "$espList"
        espFound+=( ${dfMounts[$s]} )
    fi
done

# Find any unmounted ESP's
for (( s=0; s<${#gpt[@]}; s++ ))
do
    toBeChecked=0
    for (( e=0; e<${#espFound[@]}; e++ ))
    do
        [[ ${espFound[$e]} == *${gpt[$s]}* ]] && toBeChecked=1
    done

    if [ $toBeChecked -eq 0 ]; then
        # Found a disk using GUID_partition_scheme without a mounted ESP
        # Does this disk have an ESP?
        _content=$( "$partutil" --show-contenttype /dev/${gpt[$s]}s1 )
        if [ "$_content" == "C12A7328-F81F-11D2-BA4B-00A0C93EC93B" ]; then
            [[ DEBUG -eq 1 ]] && WriteToLog "${debugIndent}${gpt[$s]}s1@U = unmounted ESP"
            echo "${gpt[$s]}s1@U" >> "$espList"
        else
            [[ DEBUG -eq 1 ]] && WriteToLog "${debugIndent}${gpt[$s]} does not contain ESP"
        fi
    else
        [[ DEBUG -eq 1 ]] && WriteToLog "${debugIndent}$e | Already found mounted ESP for ${gpt[$s]}. Skipping"
    fi
done
exit 0
