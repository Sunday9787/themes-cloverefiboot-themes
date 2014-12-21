#!/bin/bash

# A script for Clover Theme Manager
# Copyright (C) 2014 Blackosx
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
# - Slice number
# - Unique Partition GUID
# - Mount point
# - Content (type - Apple_HFS, EFI etc.)
# - Full theme path

# ---------------------------------------------------------------------------------------
WriteToLog() {
    printf "@${1}@\n" >> "$logFile"
}

# ---------------------------------------------------------------------------------------
FindMatchInPlist()
{
    local keyToFind="$1"
    local typeToFind="$2"
    declare -a plistToRead=("${!3}")
    local whatToFind="$4"
    local foundSection=0
    local temp=""

    for (( n=0; n<${#plistToRead[@]}; n++ ))
    do
        [[ "${plistToRead[$n]}" == *"<key>$keyToFind</key>"* ]] && foundSection=1
        if [ $foundSection -eq 1 ]; then
       
            if [ $whatToFind == "Multiple" ]; then
                [[ "${plistToRead[$n]}" == *"</array>"* ]] || [[ "${plistToRead[$n]}" == *"</dict>"* ]] && foundSection=0
            else
                [[ "${plistToRead[$n]}" == *"</array>"* ]] || [[ "${plistToRead[$n]}" == *"</dict>"* ]] || [[ ! "${plistToRead[$n]}" == *"<key>$keyToFind</key>"* ]] && foundSection=0
            fi
                
            if [[ "${plistToRead[$n]}" == *"$typeToFind"* ]]; then
                tmp=$( echo "${plistToRead[$n]#*>}" )
                tmp=$( echo "${tmp%<*}" )
                if [ $whatToFind == "Multiple" ]; then
                    allDisks+=("$tmp")
                else
                    echo "$tmp" # return to caller
                    break
                fi
            fi
        fi    
    done
}

TMPDIR="/tmp/CloverThemeManager"
logFile="${TMPDIR}/CloverThemeManagerLog.txt"
themeDirInfo="${TMPDIR}/themeDirInfo.txt"
espList="${TMPDIR}/espList.txt"
zeroUUID="00000000-0000-0000-0000-000000000000"

[[ ! -d "$TMPDIR" ]] && mkdir -p "$TMPDIR"
[[ -f "$themeDirInfo" ]] && rm "$themeDirInfo"
[[ -f "$espList" ]] && rm "$espList"

declare -a allDisks
declare -a diskUtilSliceInfo
declare -a themeDirPaths
declare -a dfMounts
declare -a dfMountpoints

# Send message to UI via log
#WriteToLog "CTM_ThemeDirsScan"

# Get List of mounted devices and mountpoints
WriteToLog "Getting list of mounted devices"
oIFS="$IFS"; IFS=$'\r\n'
dfMountpoints+=( /$( df -laH | cut -d'/' -f 4- | tail -n +2 ))
dfMounts+=( $( df -laH | awk '{print $1}' | tail -n +2 | cut -d '/' -f 3  ))
IFS="$oIFS"
WriteToLog "Check: dfMounts=${#dfMounts[@]} | dfMountpoints =${#dfMountpoints[@]}" 

# Read Diskutil command in to array and loop through each that's mounted
WriteToLog "Getting diskutil info for mounted devices"
diskUtilPlist=( $( diskutil list -plist ))
FindMatchInPlist "AllDisks" "string" "diskUtilPlist[@]" "Multiple"

#Loop through all disk partitions
for (( s=0; s<${#allDisks[@]}; s++ ))
do
    # Check this partition matches one that's mounted
    isMounted=0
    for (( m=0; m<${#dfMounts[@]}; m++ ))
    do
        if [ "${dfMounts[$m]}" == "${allDisks[$s]}" ]; then
           isMounted=1
           break
        fi
    done
    
    slice="${allDisks[$s]##*s}"
    if [ $isMounted -eq 1 ]; then
    
        # If mountpoint is / then populate
        if [ "${dfMountpoints[$m]}" == "/" ]; then
            for vol in /Volumes/*
            do
                [[ "$(readlink "$vol")" = / ]] && tmp="$vol"
            done
            dfMountpoints[$m]="${tmp#*/}"
            echo "${dfMountpoints[$m]}"
        fi

        # Does this device contain /efi/clover/themes directory?
        themeDir=$( find "/${dfMountpoints[$m]}"/EFI/Clover -depth 1 -type d -iname "Themes" 2>/dev/null )
        if [ "$themeDir" ]; then

            unset diskUtilSliceInfo
            oIFS="$IFS"; IFS=$'\r\n'
            diskUtilSliceInfo=( $( diskutil info -plist /dev/${dfMounts[$m]} ))
            IFS="$oIFS"

            _content=$( FindMatchInPlist "Content" "string" "diskUtilSliceInfo[@]" "Single" )
            # Read and save Volume Name
            tmp=$( FindMatchInPlist "VolumeName" "string" "diskUtilSliceInfo[@]" "Single" )
            _volName="$tmp"

            WriteToLog "Volume $_volName on mountpoint /${dfMountpoints[$m]} contains Clover themes directory" 
            [[ DEBUG -eq 1 ]] && WriteToLog "${debugIndent}${allDisks[$s]} | slice=$slice | $_volName | /${dfMountpoints[$m]} | $_content"

            # Read and save Unique partition GUID
            tmp=$( ioreg -lxw0 -pIODeviceTree | grep -A 10 ${dfMounts[$m]} | sed -ne 's/.*UUID" = //p' | tr -d '"' | head -n1)
            [[ $tmp == "" ]] && tmp="$zeroUUID" # MBR partitioned device do not have UUID's. Fill with zeros
            _uniquePartitionGuid="$tmp"
            
            # Write data to file.
            echo "${dfMounts[$m]}@${slice}@${_volName}@/${dfMountpoints[$m]}@${_content}@${_uniquePartitionGuid}@${themeDir}" >> "$themeDirInfo"
        fi
    fi
    
    # If slice = #1, check content = EFI
    if [ "$slice" == "1" ]; then

        unset diskUtilSliceInfo
        oIFS="$IFS"; IFS=$'\r\n'
        diskUtilSliceInfo=( $( diskutil info -plist /dev/${allDisks[$s]} ))
        IFS="$oIFS"
        _content=$( FindMatchInPlist "Content" "string" "diskUtilSliceInfo[@]" "Single" )
   
        # Record unmounted esp info to file.
        if [ "$_content" == "EFI" ]; then
            if [ $isMounted -eq 0 ]; then
                echo "${allDisks[$s]}@U" >> "$espList"
            else
                echo "${allDisks[$s]}@M" >> "$espList"
            fi
        fi
    fi
done
exit 0
