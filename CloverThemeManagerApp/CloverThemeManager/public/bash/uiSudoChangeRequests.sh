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
            shopt -s dotglob
            mv "$themeName"/* "$targetThemeDir" && successFlag=0
            shopt -u dotglob
        fi
    fi
        
    echo $successFlag
}

# ---------------------------------------------------------------------------------------
UnInstallTheme()
{
    local successFlag=1

    cd "$targetThemeDir"
    if [ -d "$themeName" ]; then
        rm -rf "$themeName" && WriteToLog "Deletion was successful." && successFlag=0
    fi
    
    echo $successFlag
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
                shopt -s dotglob
                mv "$themeName"/* "$targetThemeDir" && successFlag=0
                shopt -u dotglob
            fi
        fi
    fi
        
    echo $successFlag
}

# ---------------------------------------------------------------------------------------
SetNVRAMVariable()
{
    local successFlag=1
    
    WriteToLog "Setting Clover.Theme NVRAM Variable"
    nvram Clover.Theme="$themeName" && successFlag=0
    
    echo $successFlag
}

# ---------------------------------------------------------------------------------------
UpdateApp()
{
    local successFlag=1
    
    # Remove existing theme dir on target.
    if [ -f "$scriptToRun" ]; then
        "$scriptToRun" && successFlag=0
    fi
        
    echo $successFlag
}

# ---------------------------------------------------------------------------------------
MountESPwithThemesDir()
{
    local successFlag=1
    local targetFormat=$( fstyp "$device" )

    if [ "$device" != "" ] && [ "$targetFormat" != "" ] && [ "$mountPoint" != "" ]; then
        mount -t "$targetFormat" "$device" "$mountPoint" && successFlag=0
    fi

    if [ $successFlag -eq 0 ]; then
        WriteToLog "Mounted $device successfully. Checking for /EFI/Clover/Themes"
        # Does this device contain /efi/clover/themes directory?
        local themeDir=$( find "$mountPoint"/EFI/Clover -depth 1 -type d -iname "Themes" 2>/dev/null )
        if [ ! "$themeDir" ]; then
            WriteToLog "No /EFI/Clover/Themes directory found on $device"
            umount -f "$mountPoint" && successFlag=1
            [[ successFlag -eq 1 ]] && WriteToLog "unmounted $device"
        else
            WriteToLog "/EFI/Clover/Themes directory found on $device"
        fi
    fi
    
    echo $successFlag
}

# ---------------------------------------------------------------------------------------

# Passing strings with spaces fails as that's used as a delimiter.
# Instead, I pass each argument delimited by character @

# Parse arguments
declare -a "arguments"
passedArguments="$@"
numFields=$( grep -o "@" <<< "$passedArguments" | wc -l )
(( numFields++ ))
for (( f=2; f<=$numFields; f++ ))
do
    arguments[$f]=$( echo "$passedArguments" | cut -d '@' -f$f )
    WriteToLog "arguments[$f]=${arguments[$f]}"
done

whichFunction="${arguments[2]}"

case "$whichFunction" in                             
     "Move"                       ) targetThemeDir="${arguments[3]}"
                                    unPackDir="${arguments[4]}"
                                    themeName="${arguments[5]}"
                                    MoveThemeToTarget
                                    ;;
     "UnInstall"                  ) targetThemeDir="${arguments[3]}"
                                    themeName="${arguments[4]}"
                                    UnInstallTheme
                                    ;;
     "Update"                     ) targetThemeDir="${arguments[3]}"
                                    unPackDir="${arguments[4]}"
                                    themeName="${arguments[5]}"
                                    UpdateTheme
                                    ;;
     "SetNVRAMVar"                ) themeName="${arguments[3]}"
                                    SetNVRAMVariable
                                    ;;
     "UpdateApp"                  ) scriptToRun="${arguments[3]}"
                                    UpdateApp
                                    ;;
     "MountESP"                   ) device="${arguments[3]}"
                                    mountPoint="${arguments[4]}"
                                    MountESPwithThemesDir
                                    ;;
esac