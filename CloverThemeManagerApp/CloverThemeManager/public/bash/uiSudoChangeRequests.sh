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
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

TMPDIR="/tmp/CloverThemeManager"
logFile="${TMPDIR}/CloverThemeManagerLog.txt"
logBashToJs="${TMPDIR}/CloverThemeManager_BashToJs.log"
remoteRepositoryUrl="svn://svn.code.sf.net/p/cloverthemes/svn"

# ---------------------------------------------------------------------------------------
SendToUI() {
    echo "${1}" >> "$logBashToJs"
}

# ---------------------------------------------------------------------------------------
WriteToLog() {
    printf "@${1}@\n" >> "$logFile"
}

# ---------------------------------------------------------------------------------------
MoveThemeToTarget()
{
    local successFlag=1
    
    # Create theme dir on target.
    chckDir=0
    mkdir "$targetThemeDir" && chckDir=1
    if [ $chckDir -eq 1 ]; then

        # Move unpacked files to target theme path.
        cd "$unPackDir"/themes
        if [ -d "$themeName" ]; then
            mv "$themeName"/* "$targetThemeDir" && successFlag=0
        fi
    fi
        
    if [ $successFlag -eq 0 ]; then
        exit 0
    else
        exit 1
    fi
}

# ---------------------------------------------------------------------------------------
UnInstallTheme()
{
    local successFlag=1

    cd "$targetThemeDir"
    if [ -d "$themeName" ]; then
        rm -rf "$themeName" && WriteToLog "Deletion was successful." && successFlag=0
    fi
    
    if [ $successFlag -eq 0 ]; then
        exit 0
    else
        exit 1
    fi
}

# ---------------------------------------------------------------------------------------
UpdateTheme()
{
    local successFlag=1
    
    # Remove existing theme dir on target.
    if [ -d "$targetThemeDir" ]; then
        chckDir=0
        WriteToLog "Removing existing $targetThemeDir files"
        rm -rf "$targetThemeDir"/* && chckDir=1
        if [ $chckDir -eq 1 ]; then
            # Move unpacked files to target theme path.
            cd "$unPackDir"/themes
            if [ -d "$themeName" ]; then
                WriteToLog "Moving updated $themeName theme files to $targetThemeDir"
                mv "$themeName"/* "$targetThemeDir" && successFlag=0
            fi
        fi
    fi
        
    if [ $successFlag -eq 0 ]; then
        exit 0
    else
        exit 1
    fi
}

# ---------------------------------------------------------------------------------------
SetPathUnderVersionControl()
{
    svn checkout "$repositoryPath" --depth empty "$themePath" && successFlag=0
    
    if [ $successFlag -eq 0 ]; then
        exit 0
    else
        exit 1
    fi
}

# ---------------------------------------------------------------------------------------
SetNVRAMVariable()
{
    nvram Clover.Theme="$themeName" && successFlag=0
    
    if [ $successFlag -eq 0 ]; then
        exit 0
    else
        exit 1
    fi
}

# ---------------------------------------------------------------------------------------
UpdateApp()
{
    local successFlag=1
    
    # Remove existing theme dir on target.
    if [ -f "$scriptToRun" ]; then
        "$scriptToRun" && successFlag=0
    fi
        
    if [ $successFlag -eq 0 ]; then
        exit 0
    else
        exit 1
    fi
}

# ---------------------------------------------------------------------------------------
MountESP()
{
    local successFlag=1
    local targetFormat=$( fstyp "$device" )

    if [ "$device" != "" ] && [ "$targetFormat" != "" ] && [ "$mountPoint" != "" ]; then
        mount -t "$targetFormat" "$device" "$mountPoint" && successFlag=0
    fi
        
    if [ $successFlag -eq 0 ]; then
        exit 0
    else
        exit 1
    fi
    
}

# ---------------------------------------------------------------------------------------
UnMountESP()
{
    local successFlag=1

    if [ "$mountPoint" != "" ]; then
        umount -f "$mountPoint" && successFlag=0
    fi
        
    if [ $successFlag -eq 0 ]; then
        exit 0
    else
        exit 1
    fi
    
}

# ---------------------------------------------------------------------------------------
# ---------------------------------------------------------------------------------------

whichFunction="$1"
echo ""

case "$whichFunction" in                             
     "Move"                       ) themeName="$2"
                                    targetThemeDir="$3"
                                    unPackDir="$4"
                                    MoveThemeToTarget
                                    ;;
     "UnInstall"                  ) themeName="$2"
                                    targetThemeDir="$3"
                                    UnInstallTheme
                                    ;;
     "Update"                     ) themeName="$2"
                                    targetThemeDir="$3"
                                    unPackDir="$4"
                                    UpdateTheme
                                    ;;
     "SetPathUnderVersionControl" ) repositoryPath="$2"
                                    themePath="$3"
                                    SetPathUnderVersionControl
                                    ;;
     "SetNVRAMVar"                ) themeName="$2"
                                    SetNVRAMVariable
                                    ;;
     "UpdateApp"                  ) scriptToRun="$2"
                                    UpdateApp
                                    ;;
     "MountESP"                   ) device="$2"
                                    mountPoint="$3"
                                    MountESP
                                    ;;
     "UnMountESP"                   ) mountPoint="$2"
                                    UnMountESP
                                    ;;
esac


