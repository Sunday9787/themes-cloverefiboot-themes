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
#
# Credits:
# Thanks to SoThOr for helping with svn communications

VERS="0.62"


# =======================================================================================
# Helper Functions/Routines
# =======================================================================================



# ---------------------------------------------------------------------------------------
CreateSymbolicLink() {
    # Create symbolic link to local images
    WriteToLog "Creating symbolic link to ${WORKING_PATH}/${APP_DIR_NAME}/images"
    ln -s "${WORKING_PATH}/${APP_DIR_NAME}"/images "$ASSETS_DIR"
}

# ---------------------------------------------------------------------------------------
WriteToLog() {
    if [ $COMMANDLINE -eq 0 ]; then
        printf "@${1}@\n" >> "$logFile"
    else
        printf "@${1}@\n"
    fi
}

# ---------------------------------------------------------------------------------------
WriteLinesToLog() {
    if [ $COMMANDLINE -eq 0 ]; then
        printf "@===================================@\n" >> "$logFile"
    else
        printf "@===================================@\n"
    fi
}

# ---------------------------------------------------------------------------------------
SendToUI() {
    echo "${1}" >> "$logBashToJs"
}

# ---------------------------------------------------------------------------------------
SendToUINvramVar() {
    echo "${1}" >> "$logBashToJsNvramVar"
}

# ---------------------------------------------------------------------------------------
SendToUIResult() {
    echo "${1}" >> "$logBashToJsResult"
}

# ---------------------------------------------------------------------------------------
SendToUIUpdates() {
    echo "${1}" >> "$logBashToJsUpdates"
}

# ---------------------------------------------------------------------------------------
SendToUIUVersionedThemes() {
    echo "${1}" >> "$logBashToJsVersionedThemes"
}

# ---------------------------------------------------------------------------------------
SendToUIUVersionedDir() {
    echo "${1}" >> "$logBashToJsVersionedDir"
}

# ---------------------------------------------------------------------------------------
SendToUIFreeSpace() {
    echo "${1}" >> "$logBashToJsSpace"
}

# ---------------------------------------------------------------------------------------
FindStringInPlist() {
    # Check if file contains carriage returns (CR)
    checkForCR=$( tr -cd '\r' < "$2" | wc -c )
    if [ $checkForCR -gt 0 ]; then
        WriteToLog "${2##*/} contains carriage returns (CR)"
        local a=$( cat -v "$2" )
        local b="${a##*${1}</key>}"
        local c="${b%%</string>*}"
        local string="${c##*<string>}"
    else
        local string=$( grep -A 1 "<key>${1}</key>" "${2}" | head -n 2 | tail -2 | sed 1d | sed -e 's/<\/string>//g' )
    fi
    string=${string#*<string>}
    echo "$string"
}

# ---------------------------------------------------------------------------------------
FindStringInPlistVariable() {
    local string=$( echo "${2}" | grep -A 1 "<key>${1}</key>" | head -n 2 | tail -2 | sed 1d | sed -e 's/<\/string>//g' )
    string=${string#*<string>}
    echo "$string"
}

# ---------------------------------------------------------------------------------------
RemoveFile()
{
    if [ -f "$1" ]; then
        rm "$1"
    fi
}

# ---------------------------------------------------------------------------------------
WritePrefsToFile()
{
    # Write prefs file
    if [ -f "$gUserPrefsFile".plist ]; then
        WriteToLog "Deleting existing preferences file."
        defaults delete "$gUserPrefsFile"
    fi

    defaults write "$gUserPrefsFile" ThemePath "$TARGET_THEME_DIR"
    defaults write "$gUserPrefsFile" ThemePathDevice "$TARGET_THEME_DIR_DEVICE"
}

# ---------------------------------------------------------------------------------------
UpdatePrefsKey()
{
    local passedKey="$1"
    local passedValue="$2"
    if [ -f "$gUserPrefsFile".plist ]; then
        defaults delete "$gUserPrefsFile" "$passedKey"
        WriteToLog "Writing prefs key $passedKey = $passedValue"
        defaults write "$gUserPrefsFile" "$passedKey" "$passedValue"
    else
        WriteToLog "Error! ${gUserPrefsFile}.plist not found."
    fi
}

# ---------------------------------------------------------------------------------------
ClearMessageLog()
{
    local logToClear="$1"
    if [ -f "$logToClear" ]; then
        > "$logToClear"
    fi
}

# ---------------------------------------------------------------------------------------
RunThemeAction()
{
    local passedAction="$1" # Will be either Install, UnInstall or Update
    local themeToActOn="$2"
    local successFlag=1
    
    # Check theme directory is writeable
    WriteToLog "Checking if ${TARGET_THEME_DIR} is writeable."
    CheckPathIsWriteable "${TARGET_THEME_DIR}"
    returnValueWriteable=$? # 1 = not writeable / 0 = writeable
    if [ ${returnValueWriteable} = 1 ]; then 
    
        # not writeable.
        WriteToLog "path is not writeable. Asking for password"
        GetAndCheckUIPassword "Clover Theme Manager requires your password to $passedAction $themeToActOn. Type your password to allow this."
        returnValueRoot=$? # 1 = not root / 0 = root
                
        if [ ${returnValueRoot} = 0 ]; then 
        
        # NOT WRITABLE ------------------------------------------------------------------
        # RUN COMMANDS WITH ROOT PRIVILEGES    
        
            WriteToLog "Password gives elevated access"
            
            case "$passedAction" in
                "Install")  WriteToLog "Installing theme $themeToActOn to ${TARGET_THEME_DIR}/"
                            cd "${TARGET_THEME_DIR}"
                            ClearMessageLog "$logJsToBash"
                            # Is theme directory under version control?
                            if [ -d "${TARGET_THEME_DIR}"/.svn ]; then
                                echo "$gPw" | sudo -S "$uiSudoChanges" "Install"   "up"       "${TARGET_THEME_DIR}" "$themeToActOn" && gPw=""
                            else
                                echo "$gPw" | sudo -S "$uiSudoChanges" "Install"   "checkout" "${TARGET_THEME_DIR}" "$themeToActOn" && gPw="" 
                            fi
                            ;;
                            
               "UnInstall") WriteToLog "Deleting ${TARGET_THEME_DIR}/$themeToActOn"
                            echo "$gPw" | sudo -S "$uiSudoChanges"     "UnInstall" ""         "${TARGET_THEME_DIR}" "$themeToActOn" && gPw=""
                            ;;
                 
                "Update")   local themeToUpdate="$1"
                            # Is theme directory under version control?
                            if [ -d "${TARGET_THEME_DIR}"/.svn ]; then
                                WriteToLog "Updating ${TARGET_THEME_DIR}/$themeToActOn"
                                echo "$gPw" | sudo -S "$uiSudoChanges" "Update"    ""         "${TARGET_THEME_DIR}" "$themeToActOn" && gPw=""
                            fi
                            ;;
            esac
            
            returnValue=$?
            if [ ${returnValue} -eq 0 ]; then
                successFlag=0
            fi
            
        elif [ ${returnValueRoot} = 1 ]; then 
            # password did not give elevated privileges. Run this routine again.
            WriteToLog "User entered incorrect password."
            RunThemeAction "$passedAction" "$themeToActOn"
        else
            WriteToLog "User cancelled password entry."
        fi

    else
    
        # WRITABLE ----------------------------------------------------------------------
        # RUN COMMANDS WITHOUT ROOT PRIVILEGES
        
        WriteToLog "path is writeable."
        WriteToLog "Installing theme $themeToActOn to ${TARGET_THEME_DIR}/"
        cd "${TARGET_THEME_DIR}"
        ClearMessageLog "$logJsToBash"
        
        case "$passedAction" in
                "Install")  WriteToLog "Installing theme $themeToActOn to ${TARGET_THEME_DIR}/"
                            cd "${TARGET_THEME_DIR}"
                            ClearMessageLog "$logJsToBash"
                            # Is theme directory under version control?
                            if [ -d "${TARGET_THEME_DIR}"/.svn ]; then
                                WriteToLog "${TARGET_THEME_DIR} is under version control"
                                svn up "$themeToActOn" && WriteToLog "Installation was successful." && successFlag=0
                            else
                                WriteToLog "${TARGET_THEME_DIR} is not under version control"
                                svn checkout ${remoteRepositoryUrl}/themes/"$themeToActOn" && WriteToLog "Installation was successful." && successFlag=0
                            fi
                            ;;
                            
               "UnInstall") WriteToLog "Deleting ${TARGET_THEME_DIR}/$themeToActOn"
                            cd "${TARGET_THEME_DIR}"
                            if [ -d "$themeToActOn" ]; then
                                rm -rf -- "$themeToActOn" && WriteToLog "Deletion was successful." && successFlag=0
                            fi
                            ;;
                 
                "Update")   local themeToUpdate="$1"
                            # Is theme directory under version control?
                            if [ -d "${TARGET_THEME_DIR}"/.svn ]; then
                                WriteToLog "Updating ${TARGET_THEME_DIR}/$themeToActOn"
                                cd "${TARGET_THEME_DIR}"/"$themeToActOn"
                                svn update "${TARGET_THEME_DIR}"/"$themeToActOn" && WriteToLog "Update was successful." && successFlag=0
                            fi
                            ;;
        esac
        
    fi
    
    # Was install operation a success?
    if [ $successFlag -eq 0 ]; then
        if [ $COMMANDLINE -eq 0 ]; then
            SendToUIResult "Success@${passedAction}@$themeToActOn"
        fi
        return 0
    else
        if [ $COMMANDLINE -eq 0 ]; then
            SendToUIResult "Fail@${passedAction}@$themeToActOn"
        fi
        return 1
    fi
}

# ---------------------------------------------------------------------------------------
CreateHtmlAndInsertIntoManageThemes()
{
    # Create HTML and insert in to managethemes.html
    WriteToLog "themeTitle=${#themeTitle[@]}"
    WriteToLog "themeDescription=${#themeDescription[@]}"
    WriteToLog "themeAuthor=${#themeAuthor[@]}"
    
    if [ ${#themeTitle[@]} -eq ${#themeDescription[@]} ] && [ ${#themeTitle[@]} -eq ${#themeAuthor[@]} ]; then
        WriteToLog "Found ${#themeTitle[@]} Titles, Descriptions and Authors"
        WriteLinesToLog
        for ((n=0; n<${#themeTitle[@]}; n++ ));
        do
            WriteToLog "Creating html for ${themeTitle[$n]} theme"
            #themeTitlelc=$( echo "${themeTitle[$n]}" | tr '[:upper:]' '[:lower:]' )
            themeHtml="${themeHtml}\
        <div id=\"ThemeBand\" class=\"accordion\">\
        <div id=\"ThemeItems\">\
            <div class=\"thumbnail\"><img src=\"assets/images/thumbnails/thumb_${themeTitle[$n]}.jpg\" onerror=\"imgErrorThumb(this);\"></div>\
            <div id=\"ThemeText\"><p class=\"themeTitle\">${themeTitle[$n]}<br><span class=\"themeDescription\">${themeDescription[$n]}</span><br><span class=\"themeAuthor\">${themeAuthor[$n]}</span></p></div>\
            <div class=\"versionControl\" id=\"indicator_${themeTitle[$n]}\"></div>\
            <div class=\"buttonInstall\" id=\"button_${themeTitle[$n]}\"></div>\
        </div> <!-- End ThemeItems -->\
    </div> <!-- End ThemeBand -->\
    <div class=\"accordionContent\"><img src=\"assets/images/previews/preview_${themeTitle[$n]}.jpg\" onerror=\"imgErrorPreview(this);\" width=\"100%\"></div>\
    \
    "
        done
   
        # Escape forward slashes
        themeHtml=$( echo "$themeHtml" | sed 's/\//\\\//g' )

        # Save html to file
        echo "$themeHtml" > "${WORKING_PATH}/${APP_DIR_NAME}"/theme.html

        WriteLinesToLog
        # Insert Html in to placeholder
        WriteToLog "Inserting HTML in to managethemes.html"
        LANG=C sed -ie "s/<!--INSERT_THEMES_HERE-->/${themeHtml}/g" "${PUBLIC_DIR}"/managethemes.html

        # Clean up
        if [ -f "${PUBLIC_DIR}"/managethemes.htmle ]; then
            rm "${PUBLIC_DIR}"/managethemes.htmle
        fi
    else
        WriteToLog "Error: Title(${#themeTitle[@]}), Author(${#themeAuthor[@]}), Description(${#themeDescription[@]}) mismatch."
        for ((n=0; n<${#themeTitle[@]}; n++ ));
        do
            WriteToLog "$n : ${themeTitle[$n]} | ${themeDescription[$n]} | ${themeAuthor[$n]}"
        done
    fi
    WriteLinesToLog
}



# =======================================================================================
# Routines for checking ownership and elevating privileges, if necessary
# =======================================================================================



# ---------------------------------------------------------------------------------------
GetAndCheckUIPassword()
{
    # Commas in the message causes osascript to fail!
    # So strip any commas before continuing.
    message=$( echo "$1" | sed 's/,//g' )
     
    # revoke sudo permissions
    sudo -k

    gPw="$( /usr/bin/osascript << EOF -e 'set MyApplVar to do shell script "echo '"${message}"'"' -e 'Tell application "System Events" to display dialog MyApplVar default answer "" with hidden answer with icon 1' -e 'text returned of result' 2>/dev/null)"
    
    # Is result not null AND not empty
    if [ -n "$gPw" ] && [ ! -z "$gPw" ]; then
        local userNow=$( echo "$gPw" | sudo -S whoami )
        if [ "$userNow" == "root" ]; then
            return 0
        else
            return 1
        fi
    else
        gPw="$gUiPwCancelledStr"
    fi
}

# ---------------------------------------------------------------------------------------
CheckPathIsWriteable()
{
    local passedDir="$1"
    
    local isWriteable=1
    touch "$passedDir"/.test 2>/dev/null && rm -f "$passedDir"/.test || isWriteable=0

    if [ $isWriteable -eq 0 ]; then
        return 1
    else
        return 0
    fi
}



# =======================================================================================
# Initialisation Routines
# =======================================================================================




# ---------------------------------------------------------------------------------------
RefreshHtmlTemplates()
{
    passedTemplate="$1"
    
    # For now remove previous managethemes.html and copy template
    if [ -f "${PUBLIC_DIR}"/$passedTemplate ]; then
        if [ -f "${PUBLIC_DIR}"/$passedTemplate.template ]; then
            WriteToLog "Setting $passedTemplate to default."
            rm "${PUBLIC_DIR}"/$passedTemplate
            cp "${PUBLIC_DIR}"/$passedTemplate.template "${PUBLIC_DIR}"/$passedTemplate
        else
            WriteToLog "Error: missing ${PUBLIC_DIR}/$passedTemplate.template"
        fi
    else
        WriteToLog "Creating: $passedTemplate"
        cp "${PUBLIC_DIR}"/$passedTemplate.template "${PUBLIC_DIR}"/$passedTemplate
    fi
    
    WriteLinesToLog
}

# ---------------------------------------------------------------------------------------
IsRepositoryLive()
{
    if [ -f /usr/bin/curl ]; then
        httpRepositoryUrl=$( echo ${remoteRepositoryUrl}/ | sed 's/svn:/http:/' )
        WriteToLog "Checking for response from $httpRepositoryUrl"
        local testConnection=$( /usr/bin/curl --silent --head $httpRepositoryUrl | egrep "OK"  )
        WriteToLog "Response: $testConnection"
        if [ ! "$testConnection" ]; then
            # Repository not alive.
            WriteToLog "RepositoryError: No response from Repository ${remoteRepositoryUrl}/"
            # The initialise.js should pick this up, notify the user, then quit.
            exit 1
        fi
    fi
    WriteLinesToLog
}

# ---------------------------------------------------------------------------------------
EnsureLocalSupportDir()
{
    # Check for local support directory
    local pathToCreate="${WORKING_PATH}/${APP_DIR_NAME}"
    if [ ! -d "$pathToCreate" ]; then
        WriteToLog "Creating $pathToCreate"
        mkdir -p "$pathToCreate"
    fi
}

# ---------------------------------------------------------------------------------------
EnsureSymlink()
{
    # Rather than check if a valid one exists, it's quicker to simply re-create it.
    if [ -h "$ASSETS_DIR"/images ]; then
        rm "$ASSETS_DIR"/images
    fi
    CreateSymbolicLink
    WriteLinesToLog
}

# ---------------------------------------------------------------------------------------
CheckoutImages()
{
    if [ -d "${WORKING_PATH}/${APP_DIR_NAME}"/images ]; then
        WriteToLog "${WORKING_PATH}/${APP_DIR_NAME}/images exists."
        # Update local repository
        cd "${WORKING_PATH}/${APP_DIR_NAME}"/images
        WriteToLog "Checking status of local images against remote images."
        # Following command from http://stackoverflow.com/questions/6516214/how-do-i-know-if-my-working-copy-is-out-of-sync
        statusCheck=$( svn status -u | grep -E -c "^\s+[^\?]" )
        if [ $statusCheck -eq 0 ]; then
            WriteToLog "No changes. Local images are up to date."
        else
            WriteToLog "There have been changes. Updating local images."
            svn update "${WORKING_PATH}/${APP_DIR_NAME}"/images
        fi
    else
        WriteToLog "Creating ${WORKING_PATH}/${APP_DIR_NAME}/images"
        mkdir "${WORKING_PATH}/${APP_DIR_NAME}"/images
        cd "${WORKING_PATH}/${APP_DIR_NAME}"
        # Checkout images
        WriteToLog "Downloading thumbnail and preview images."
        svn checkout ${remoteRepositoryUrl}/images
    fi
}

# ---------------------------------------------------------------------------------------
CheckOutThemePlistsAndEnsureThemeHtml()
{
    BuildThemeTextInformation()
    {
        # Create array of directory list alphabetically
        oIFS="$IFS"; IFS=$'\r\n'
        themeList=( $( ls -d "${WORKING_PATH}/${APP_DIR_NAME}"/themes/* | sort -f ))
    
        # Read each themes' theme.plist from the repository to extract Author & Description.
        for ((n=0; n<${#themeList[@]}; n++ ));
        do
            tmpTitle="${themeList[$n]##*/}"
            WriteToLog "Reading theme plists for $tmpTitle" 
            themeTitle+=("$tmpTitle")
            themeAuthor+=( $(FindStringInPlist "Author" "${WORKING_PATH}/${APP_DIR_NAME}/themes/${tmpTitle}/theme.plist"))
            themeDescription+=( $(FindStringInPlist "Description" "${WORKING_PATH}/${APP_DIR_NAME}/themes/${tmpTitle}/theme.plist"))

            # Truncate Description to set length of 74 chars.
            #themeDescription[$n]="${themeDescription[$n]:0:73}"
        done
        IFS="$oIFS"
    }
    
    CheckoutThemePlists()
    {
        WriteToLog "Checking out each themes' plist" 
        for dirs in "${WORKING_PATH}/${APP_DIR_NAME}"/themes/*
        do 
            cd "$dirs"
            if [ ! -f theme.plist ]; then
                svn up --set-depth empty theme.plist
                WriteToLog "${dirs##*/}/theme.plist"
            fi
        done
    }
    
    local themePlistsHaveChanged=0
    
    # Get up to date directory listing and theme.plists from repository
    if [ ! -d "${WORKING_PATH}/${APP_DIR_NAME}/themes" ]; then
        # Check out immediate directories without each containing children.
        WriteToLog "Checking out immediate theme directories" 
        svn checkout --depth immediates ${remoteRepositoryUrl}/themes "${WORKING_PATH}/${APP_DIR_NAME}"/themes
        
        # Checkout just the theme.plist for each theme.
        
        # SoThOr - I couldn't get this to work. Results in skipped paths?
        #oIFS="$IFS"; IFS=$'\r\n'
        #svn up --set-depth empty $( ls "${WORKING_PATH}/${APP_DIR_NAME}"/themes | sed 's=$=/theme.plist=' )
        #IFS="$oIFS"
        
        CheckoutThemePlists
        themePlistsHaveChanged=1
    else
        # Check for updates to the theme plists.
        WriteToLog "Checking for updates to the theme plists" 
        cd "${WORKING_PATH}/${APP_DIR_NAME}"/themes
        local statusCheck=$( svn status -u | grep -E -c "^\s+[^\?]" )
        if [ $statusCheck -eq 0 ]; then
            WriteToLog "No changes. theme.plists are up to date."
        else
            WriteToLog "There have been changes. Updating local theme.plists."
            svn update "${WORKING_PATH}/${APP_DIR_NAME}"/themes
            CheckoutThemePlists
            themePlistsHaveChanged=1
            
            # Remove previously created theme.html to force rebuild
            WriteToLog "Deleting previously created theme.html file."
            RemoveFile "${WORKING_PATH}/${APP_DIR_NAME}"/theme.html
        fi
    fi
    
    if [ $themePlistsHaveChanged -eq 1 ] ; then

        # Read local theme.plists and parse author and description info.
        BuildThemeTextInformation
        
        # Build html for each theme and insert in to the template.
        CreateHtmlAndInsertIntoManageThemes
        
    else
    
        # Use previously saved theme.html
        if [ -f "${WORKING_PATH}/${APP_DIR_NAME}"/theme.html ]; then
            
            WriteToLog "Inserting previous HTML in to managethemes.html"
            # Read previously saved file
            themeHtml=$( cat "${WORKING_PATH}/${APP_DIR_NAME}"/theme.html )
            # Escape all forward slashes
            themeHtmlClean=$( echo "$themeHtml" | sed 's/&/\\\&/g' );
            # Insert Html in to placeholder
            LANG=C sed -ie "s/<!--INSERT_THEMES_HERE-->/${themeHtmlClean}/g" "${PUBLIC_DIR}"/managethemes.html
            # Clean up
            if [ -f "${PUBLIC_DIR}"/managethemes.htmle ]; then
                rm "${PUBLIC_DIR}"/managethemes.htmle
            fi
        else
            WriteToLog "Error!. ${WORKING_PATH}/${APP_DIR_NAME}/theme.html not found"
            
            # Read local theme.plists and parse author and description info.
            BuildThemeTextInformation
            
            # Build html for each theme and insert in to the template.
            CreateHtmlAndInsertIntoManageThemes
        fi
    
    fi
    WriteLinesToLog
}

# ---------------------------------------------------------------------------------------
GetFreeSpaceOfTargetDevice()
{
    WriteToLog "Getting free space on target device $TARGET_THEME_DIR_DEVICE"
    echo $(df -laH | grep $TARGET_THEME_DIR_DEVICE | awk '{print $4}')
}

# ---------------------------------------------------------------------------------------
GetListOfMountedDevices()
{
    WriteToLog "Getting list of mounted devices"
    unset dfMounts
    dfMounts+=( $( df -laH | awk '{print $1}' | tail -n +2  ))
    # Remove /dev/
    for (( m=0; m<${#dfMounts[@]}; m++ ))
    do
        dfMounts[$m]="${dfMounts[$m]##*/}"
        #WriteToLog "${dfMounts[$m]}"
    done
}

# ---------------------------------------------------------------------------------------
BuildDiskUtilStringArrays()
{
    # Six global string arrays are used for holding the disk information.
    # They are declared at the head of this file.

    # ---------------------------------------------------------------------------------------
    # Function to search for key in plist and return all associated strings in an array. 
    # Will only find a single match
    FindMatchInSlicePlist()
    {
        local keyToFind="$1"
        local typeToFind="$2"
        declare -a plistToRead=("${!3}")
        local foundSection=0

        for (( n=0; n<${#plistToRead[@]}; n++ ))
        do
            [[ "${plistToRead[$n]}" == *"<key>$keyToFind</key>"* ]] && foundSection=1
            if [ $foundSection -eq 1 ]; then
                [[ "${plistToRead[$n]}" == *"</array>"* ]] || [[ "${plistToRead[$n]}" == *"</dict>"* ]] || [[ ! "${plistToRead[$n]}" == *"<key>$keyToFind</key>"* ]] && foundSection=0
                if [[ "${plistToRead[$n]}" == *"$typeToFind"* ]]; then
                    tmp=$( echo "${plistToRead[$n]#*>}" )
                    tmp=$( echo "${tmp%<*}" )
                    tmpArray+=("$tmp")
                    echo "$tmp" # return to caller
                    break
                fi
            fi
        done
    }
    
    local recordAdded=0
    
    WriteToLog "Getting diskutil info for mounted devices"

    # Read Diskutil command in to array rather than write to file.
	diskUtilPlist=( $( diskutil list -plist ))

    # Only check details of mounted devices
    for (( s=0; s<${#dfMounts[@]}; s++ ))
    do
        if [[ "${dfMounts[$s]}" == *disk* ]]; then

            unset diskUtilSliceInfo
            diskUtilSliceInfo=( $( diskutil info -plist /dev/${dfMounts[$s]} ))
            tmp=$( FindMatchInSlicePlist "VolumeName" "string" "diskUtilSliceInfo[@]" )
        
            # Does this device contain /efi/clover/themes directory?
            themeDir=$( find /Volumes/"$tmp"/EFI/Clover -type d -iname "Themes" 2>/dev/null )
            if [ "$themeDir" ]; then
            
                WriteToLog "Volume $tmp contains $themeDir" 
                # Save VolumeName
                duVolumeName+=( "${tmp}" )
                # Save device
                duIdentifier+=("${dfMounts[$s]}")
                # Read and save Content
                unset diskUtilSliceInfo
                diskUtilSliceInfo=( $( diskutil info -plist /dev/${duIdentifier[$S]} ))
                tmp=$( FindMatchInSlicePlist "Content" "string" "diskUtilSliceInfo[@]" )
                duContent+=("$tmp")
                # Save path to theme directory 
                themeDirPaths+=("$themeDir")
                # Check/Set theme directory is under version control
                #SetThemeDirUnderVersionControl "$themeDir" <--- moved this elsewhere
                (( recordAdded++ ))
            fi
        fi
    done

    # Before leaving, check all string array lengths are equal.
    if [ ${#duVolumeName[@]} -ne $recordAdded ] || [ ${#duContent[@]} -ne $recordAdded ] || [ ${#duIdentifier[@]} -ne $recordAdded ]; then
        WriteToLog "Error- Disk Utility string arrays are not equal lengths!"
        WriteToLog "records=$recordAdded V=${#duVolumeName[@]} C=${#duContent[@]} I=${#duIdentifier[@]}"
        exit 1
    fi
}

# ---------------------------------------------------------------------------------------
CreateDiskPartitionDropDownHtml()
{
    RemoveFile "${WORKING_PATH}/${APP_DIR_NAME}/dropdown_html"
    
    # Create html for drop-down menu
    htmlDropDown="\
<option value=\"-@-\">Select your target theme directory:</option>\
    "

    for ((a=0; a<${#duVolumeName[@]}; a++))
    do
        if [ ! "${duVolumeName[$a]}" == "" ] && [[ ! "${duVolumeName[$a]}" =~ ^\ +$ ]]; then
            WriteToLog "${duIdentifier[$a]} | ${duVolumeName[$a]} [${duContent[$a]}]"
            
            # Create html for drop-down menu
            htmlDropDown="${htmlDropDown}\
<option value=\"${duIdentifier[$a]}@${themeDirPaths[$a]}\">${themeDirPaths[$a]} [${duIdentifier[$a]}]</option>\
            "
            
        else
            WriteLog "must be blank or empty"
        fi
    done
    
    # Escape forward slashes
    htmlDropDown=$( echo "$htmlDropDown" | sed 's/\//\\\//g' )

    # Save html to file
    echo "$htmlDropDown" > "${WORKING_PATH}/${APP_DIR_NAME}"/dropdown_html

    WriteLinesToLog
    # Insert dropdown Html in to placeholder
    WriteToLog "Inserting dropdown HTML in to managethemes.html"
    LANG=C sed -ie "s/<!--INSERT_MENU_OPTIONS_HERE-->/${htmlDropDown}/g" "${PUBLIC_DIR}"/managethemes.html

    # Clean up
    if [ -f "${PUBLIC_DIR}"/managethemes.htmle ]; then
        rm "${PUBLIC_DIR}"/managethemes.htmle
    fi
    
    WriteLinesToLog
}

# ---------------------------------------------------------------------------------------
LoadPreviousSettingsFromUserPrefs()
{
    WriteToLog "Read user preferences file"
    # Check for preferences file
    if [ -f "$gUserPrefsFile".plist ]; then

        oIFS="$IFS"; IFS=$'\n'
        local readVar=( $( defaults read "$gUserPrefsFile" 2>/dev/null ) )
        IFS="$oIFS"
        
        # get total count of lines, less one for zero based index.
        local count=(${#readVar[@]}-1)

        # Check first line and last line of prefs file actually is an open and closing curly brace.
        if [[ "${readVar[0]}" == "{" ]] && [[ "${readVar[$count]}" == "}" ]]; then
            WriteToLog "Reading preferences from ${gUserPrefsFile}.plist"

            # Ignore first and last elements as they will be an opening and closing brace. 
            for (( x=1; x<$count; x++ ))
            do
                # separate items
                local tmpOption="${readVar[$x]%=*}"
                local tmpValue="${readVar[$x]#*=}"
                # Remove whitespace
                tmpOption="${tmpOption//[[:space:]]}"
                
                # Check for theme path.
                if [ "$tmpOption" == "ThemePath" ]; then
                    # Remove quotes and semicolon from the returned string
                    tmpValue=$( echo "$tmpValue" | tr -d '";' )
                    # Remove any leading white space
                    tmpValue=$( echo "${tmpValue#* }" )
                    # Escape any spaces
                    tmpValue=$( echo "$tmpValue" | sed 's/ /\\ /g' )
                    gReportsFolderPath="$tmpValue"
                else
                    # Remove whitespace
                    tmpValue="${tmpValue//[[:space:]]}"
                    # Remove semicolon from the string
                    tmpValue=$( echo "$tmpValue" | tr -d ';' )
                fi

                WriteToLog "Found previous option: ${tmpOption}=${tmpValue}"
                
                if [ "$tmpOption" == "ThemePath" ]; then
                    TARGET_THEME_DIR="$tmpValue"
                fi
                if [ "$tmpOption" == "ThemePathDevice" ]; then
                    TARGET_THEME_DIR_DEVICE="$tmpValue"
                fi
            done
        else
            WriteToLog "Error: Prefs file does not contain opening and closing curly braces."
        fi
    else
        WriteToLog "Preferences file not found."
    fi
}

# ---------------------------------------------------------------------------------------
SendUIThemePathThemeListAndFreeSpace()
{

    if [ ! "$TARGET_THEME_DIR" == "" ] && [ ! "$TARGET_THEME_DIR_DEVICE" == "" ] ; then

        CheckThemePathIsStillValid
        retVal=$? # returns 1 if invalid / 0 if valid
        if [ $retVal -eq 0 ]; then

            WriteToLog "Sending UI: Target@${TARGET_THEME_DIR_DEVICE}@${TARGET_THEME_DIR}"
            SendToUI "Target@${TARGET_THEME_DIR_DEVICE}@${TARGET_THEME_DIR}"
            
            GetListOfInstalledThemes
            WriteToLog "Sending UI: $installedThemeStr"
            SendToUI "InstalledThemes@${installedThemeStr}@"
            
            freeSpace=$( GetFreeSpaceOfTargetDevice )
            WriteToLog "Sending UI: FreeSpace:$freeSpace"
            SendToUIFreeSpace "FreeSpace@${freeSpace}@"
        
        elif [ $retVal -eq 1 ]; then
            if [ ! "$TARGET_THEME_DIR" == "-" ] && [ ! "$TARGET_THEME_DIR_DEVICE" == "-" ] ; then
                WriteToLog "Sending UI: NotExist@${TARGET_THEME_DIR_DEVICE}@${TARGET_THEME_DIR}"
                SendToUI "NotExist@${TARGET_THEME_DIR_DEVICE}@${TARGET_THEME_DIR}"
            else
                WriteToLog "Sending UI: NoPathSelected@@"
                SendToUI "NoPathSelected@@"
            fi
            TARGET_THEME_DIR="-"
            TARGET_THEME_DIR_DEVICE="-"
        fi
        
        # Run this regardless of path chosen as JS is waiting to hear it. 
        GetListOfUpdatedThemes
        SendToUIUpdates "UpdateAvailThemes@${updateAvailThemeStr}@"
        WriteToLog "Sent to UI: UpdateAvailThemes@${updateAvailThemeStr}@"

        # GetListOfUpdatedThemes() also gathered list of any unversioned themes.
        SendToUIUVersionedThemes "UnversionedThemes@${unversionedThemeStr}@"
        WriteToLog "Sent to UI: UnversionedThemes@${unversionedThemeStr}@"
        
        # Set redirect from initial page
        WriteToLog "Redirect managethemes.html"
    else
        WriteToLog "Sending UI: NoPathSelected@@"
        SendToUI "NoPathSelected@@"
    fi
}




# =======================================================================================
# After Initialisation Routines
# =======================================================================================




# ---------------------------------------------------------------------------------------
RespondToUserDeviceSelection()
{
    # Called from the Main Message Loop when a user has changed the
    # theme files path from the drop down menu in the UI.
    #
    # This routine takes the message, and splits it to find the device
    # and volume name. Then providing the user has not chosen 'Please Choose'
    # from the menu (indicated by a - for each device and volumeName), the 
    # path is double checked before writing the choice to the user prefs file.
    #
    # Two routines are then called:
    # 1 - to get a list of theme directories at selected file path.
    # 2 - to check for any updates to those theme directories.
        
    local messageFromUi="$1"
    ClearMessageLog "$logJsToBash"
    
    WriteLinesToLog

    # parse message
    # remove everything up until, and including, the first @
    messageFromUi="${messageFromUi#*@}"
    selectedDevice="${messageFromUi%%@*}"
    selectedVolumeName="${messageFromUi##*@}"
    
    # Check user did actually change from default
    if [ ! "$selectedDevice" == "-" ] && [ ! "$selectedVolumeName" == "-" ]; then

        WriteToLog "User selected device: $selectedDevice with Volume name: $selectedVolumeName" 

        # Check against previously discovered file paths
        for (( s=0; s<${#duIdentifier[@]}; s++ ))
        do
            if [[ "${duIdentifier[$s]}" == "$selectedDevice" ]]; then
                TARGET_THEME_DIR="${themeDirPaths[$s]}"
                TARGET_THEME_DIR_DEVICE="${duIdentifier[$s]}"
            fi
        done

        WriteToLog "Theme path: $TARGET_THEME_DIR on device $TARGET_THEME_DIR_DEVICE"
        
        UpdatePrefsKey "ThemePath" "$TARGET_THEME_DIR"
        UpdatePrefsKey "ThemePathDevice" "$TARGET_THEME_DIR_DEVICE"      
        
        # Check theme directory is under version control
        CheckIfThemeDirIsUnderVersionControl "$TARGET_THEME_DIR"
        
        # Scan this path for theme list and then send to UI
        GetListOfInstalledThemes
        SendToUI "InstalledThemes@${installedThemeStr}@"
        WriteToLog "Sent to UI: $installedThemeStr"
        
        freeSpace=$( GetFreeSpaceOfTargetDevice )
        WriteToLog "Sending UI: FreeSpace:$freeSpace"
        SendToUIFreeSpace "FreeSpace@${freeSpace}@"
        
        # Check for any updates
        GetListOfUpdatedThemes
        SendToUIUpdates "UpdateAvailThemes@${updateAvailThemeStr}@"
        WriteToLog "Sent to UI: $updateAvailThemeStr"
        
        # GetListOfUpdatedThemes() also gathered list of any unversioned themes.
        SendToUIUVersionedThemes "UnversionedThemes@${unversionedThemeStr}@"
        WriteToLog "Sent to UI: UnversionedThemes@${unversionedThemeStr}@"

    else
        WriteToLog "User de-selected device pointing to theme path"
        UpdatePrefsKey "ThemePath" "-"
        UpdatePrefsKey "ThemePathDevice" "-"
        TARGET_THEME_DIR="-"
        TARGET_THEME_DIR_DEVICE="-"
        WriteToLog "Sending UI: @@"
        SendToUI "InstalledThemes@-@"
    fi
}

# ---------------------------------------------------------------------------------------
RespondToUserThemeAction()
{
    local messageFromUi="$1"
    ClearMessageLog "$logJsToBash"

    # remove everything up until, and including, the first @
    messageFromUi="${messageFromUi#*@}"
    chosenTheme="${messageFromUi%%@*}"
    desiredAction="${messageFromUi##*@}"
    
    # further strip theme name and action
    chosenTheme="${chosenTheme##*button_}"
    desiredAction="${desiredAction##*button}"

    # Note - desiredAction will be either: Install, UnInstall or Update
    
    if [ ! "$chosenTheme" == "" ] && [ ! "$desiredAction" == "" ]; then
        WriteLinesToLog
        WriteToLog "User chose to $desiredAction theme $chosenTheme"
        RunThemeAction "$desiredAction" "$chosenTheme"
        return $?
    fi
}

# ---------------------------------------------------------------------------------------
CheckThemePathIsStillValid()
{
    if [ ! -d "$TARGET_THEME_DIR" ]; then
        WriteToLog "Theme directory $TARGET_THEME_DIR does not exist! Setting to -"
        return 1
    else
        WriteToLog "Theme directory $TARGET_THEME_DIR exists."
        return 0
    fi
}

# ---------------------------------------------------------------------------------------
GetListOfInstalledThemes()
{
    installedThemeStr=""
    WriteToLog "Looking for installed themes at $TARGET_THEME_DIR"
    oIFS="$IFS"; IFS=$'\r\n'
    installedThemesFound=( $( find "$TARGET_THEME_DIR"/* -type d -depth 0 ))
    for ((i=0; i<${#installedThemesFound[@]}; i++))
    do
        installedThemes[$i]="${installedThemesFound[$i]##*/}"
        # Create comma separated string for sending to the UI
        installedThemeStr="${installedThemeStr},${installedThemes[$i]}"
        WriteToLog "Found installed theme: ${installedThemes[$i]}"
    done
    IFS="$oIFS"
    # Remove leading comma from string
    installedThemeStr="${installedThemeStr#?}"   
}

# ---------------------------------------------------------------------------------------
GetListOfUpdatedThemes()
{
    # Checks if the current themes directory is under version control.
    # Then gets svn status on that themes directory, parsing the results.
    # Any updated theme names are appended to the string: updateAvailThemeStr
    # Multiple themes are separated by a comma.
    
    updateAvailThemeStr=""
    unversionedThemeStr=""
    local newEntry=0
    local filePath=""
    local themeName=""
    local lastThemeName=""
    local wcStatusFound=0
    local reposStatusFound=0
    local repoStatusItem=""
     
    # Only check for updates if themes dir is under version control
    if [ -d "$TARGET_THEME_DIR"/.svn ]; then
    
        RemoveFile "$svnStatusXml"
    
        WriteToLog "Checking $TARGET_THEME_DIR for any theme updates."
        cd "$TARGET_THEME_DIR"
        svn status -u --xml > "$svnStatusXml"
        
        WriteToLog "Reading $svnStatusXml"
        oIFS="$IFS"; IFS=$'\r\n'
        while read line
        do

            # 6 - Read the status entries checking for modified entries
            if [[ "$line" == *modified* ]] && [ $reposStatusFound -eq 1 ]; then
                repoStatusItem="${line##*=\"}"
                repoStatusItem="${repoStatusItem%%\">*}"
                if [ ! "$themeName" == "$lastThemeName" ]; then
                    updateAvailThemeStr="${updateAvailThemeStr},${themeName}"
                    WriteToLog "Update is available for $themeName"
                    lastThemeName="$themeName"
                fi
            fi

            # 5 - Read the status start
            if [ "$line" == "<repos-status" ] && [ ! "$themeName" == "" ]; then
                reposStatusFound=1
            fi
    
            # 4 - Read wc-status entries for deleted and unversioned entries
            if [[ "$line" == *item* ]] && [ $wcStatusFound -eq 1  ] && [ ! "$themeName" == "" ]; then
                # Check for deleted items buy may also want to check for other states?
                if [[ "$line" == *deleted* ]] || [[ "$line" == *missing* ]]; then
                    themeName=""
                fi
                # Check for deleted items but may also want to check for other states?
                if [[ "$line" == *unversioned* ]]; then
                    #tmp="${line##*=\"}"
                    #tmp="${tmp%%\">*}"
                    unversionedThemeStr="${unversionedThemeStr},${themeName}"
                    WriteToLog "Theme $themeName is not under version control."
                fi
            fi
    
            # 3 - Check for <wc-status
            if [ "$line" == "<wc-status" ] && [ ! "$themeName" == "" ]; then
                wcStatusFound=1
            fi

            # 2 - Read the path of the file
            if [ $newEntry -eq 1 ] && [[ "$line" == *path* ]]; then
                filePath="${line##*=\"}"
                if [[ "$filePath" == */* ]]; then
                    themeName="${filePath%%/*}"
                else
                    themeName="${filePath%%\">*}"
                fi
                newEntry=0
            fi
    
            # 1 - Begin by finding starting point of entry
            if [ "$line" == "<entry" ]; then
                newEntry=1
                filePath=""
                reposStatusFound=0
                wcStatusFound=0
            fi
    
        done < "$svnStatusXml"

        IFS="$oIFS"

        if [ "$updateAvailThemeStr" == "" ]; then
            WriteToLog "No updates found."
        else
            # Remove leading comma from string
            updateAvailThemeStr="${updateAvailThemeStr#?}"
        fi
        
        if [ ! "$unversionedThemeStr" == "" ]; then
            # Remove leading comma from string
            unversionedThemeStr="${unversionedThemeStr#?}"
        fi
    else
        WriteToLog "$TARGET_THEME_DIR is not under version control. Update check skipped."
    fi
}

# ---------------------------------------------------------------------------------------
CheckForAppUpdate()
{
    # Simple check to compare version number of this version number against the
    # newest download file on bitbucket. If there's a difference then the version number
    # from bitbucket is written to tmp/dd_update for reading by cloverthememanager.js 
    if [ -f /usr/bin/curl ]; then
        local testConnection=$( /usr/bin/curl --silent --head https://bitbucket.org/blackosx/cloverthememanager/downloads | egrep "OK"  )
        if [ "$testConnection" ]; then
            WriteToLog "Checking for update"
            local checkVer=""
            checkVer=$( /usr/bin/curl --silent https://bitbucket.org/blackosx/cloverthememanager/downloads | grep CloverThemeManager_v*.*.*.zip | head -n 1 )
            if [ "$checkVer" == "" ]; then
                WriteToLog "No update available"
            else
                # Strip version from returned line
                checkVer="${checkVer##*DarwinDumper_v}"
                checkVer="${checkVer%.zip*}"

                # Remove any non-numeric chars from version numbers
                local checkNewVerNumber=$( echo "$checkVer" | sed 's/\([0-9][0-9]*\)[^0-9]*/\1/g' )
                local checkCurrentVerNumber=$( echo "$VERS" | sed 's/\([0-9][0-9]*\)[^0-9]*/\1/g' )

                if [ $checkNewVerNumber -gt $checkCurrentVerNumber ]; then
                    WriteToLog "Version check: Newer v${checkVer} is available."
                    #echo "$checkVer" > "$gDDTmpFolder"/dd_update
                else
                    WriteToLog "Version check: This is the latest version."
                fi
            fi
        fi
    fi
}

# ---------------------------------------------------------------------------------------
CheckIfThemeDirIsUnderVersionControl()
{
    WriteToLog "Checking if $1 is under version control."
    directoylc=$( echo "${1##*/}" | tr '[:upper:]' '[:lower:]' )
    if [ "$directoylc" == "themes" ]; then
        if [ ! -d "$1"/.svn ]; then
            WriteToLog "$1 is not under version control."
            SendToUIUVersionedDir "UnversionedThemeDir@${1}@"
            WriteToLog "Sent to UI: UnversionedThemeDir@${1}@"
        else
            WriteToLog "$1 is already under version control."
            SendToUIUVersionedDir "UnversionedThemeDir@@"
            WriteToLog "Sent to UI: UnversionedThemeDir@$@"
        fi
    fi
    # The UI will receive this, notify the user and ask for permissions.
}

# ---------------------------------------------------------------------------------------
SetThemeDirUnderVersionControl()
{
    # this function recieves a full path to a themes directory.
    if [ ! -d "$1"/.svn ]; then
        
        WriteToLog "Checking if $1 is writeable."
            
        CheckPathIsWriteable "$1"
        local returnValueWriteable=$? # 1 = not writeable / 0 = writeable
        if [ ${returnValueWriteable} = 1 ]; then    
            
            # not writeable.
            WriteToLog "path is not writeable. Asking for password"
            GetAndCheckUIPassword "Clover Theme Manager requires your password to enable updates for this theme directory."
            local returnValueRoot=$? # 1 = not root / 0 = root

            if [ ${returnValueRoot} = 0 ]; then 

                WriteToLog "Password gives elevated access"

                # RUN COMMAND WITH ROOT PRIVILEGES        
                WriteToLog "Setting $1 under version control"
                echo "$gPw" | sudo -S "$uiSudoChanges" "SetPathUnderVersionControl" "${remoteRepositoryUrl}/themes" "$1" && gPw=""
                returnValue=$?
                if [ ${returnValue} -eq 0 ]; then
                    successFlag=0
                fi
            
            elif [ ${returnValueRoot} = 1 ]; then 
                # password did not give elevated privileges. Run this routine again.
                WriteToLog "User entered incorrect password."
                SetThemeDirUnderVersionControl "$1"
            else
                WriteToLog "User cancelled password entry."
                WriteToLog "Leaving $1 not under version control."
            fi
            
        else
            # writeable.
            WriteToLog "path is writeable."
                
            # RUN COMMAND WITHOUT ROOT PRIVILEGES  
            WriteToLog "Setting $1 under version control"
            svn checkout "${remoteRepositoryUrl}"/themes --depth empty "$1" && successFlag=0
        fi
            
        # Was install operation a success?
        if [ $successFlag -eq 0 ]; then
            WriteToLog "$1 was successfully set under version control."
        else
            WriteToLog "$1 failed to be set under version control."
        fi
            
    else
        WriteToLog "$1 is already version control"
    fi
}

# ---------------------------------------------------------------------------------------
ReadAndSendCurrentNvramTheme()
{
    #ClearMessageLog "$logBashToJsNvramVar"
    readNvramVar=$( nvram -p | grep Clover.Theme | tr -d '\011' )

    # Extract theme name
    local themeName="${readNvramVar##*Clover.Theme}"

    if [ ! -z "$readNvramVar" ]; then
        WriteToLog "Clover.Theme NVRAM variable is set to $themeName"
        WriteToLog "Sending UI: $themeName"
        SendToUINvramVar "$themeName"
    else
        WriteToLog "Clover.Theme NVRAM variable is not set"
        WriteToLog "Sending UI: -"
        SendToUINvramVar "-"
    fi
}

# ---------------------------------------------------------------------------------------
SetNvramTheme()
{
    local messageFromUi="$1"

    # remove everything up until, and including, the first @
    messageFromUi="${messageFromUi#*@}"
    chosenTheme="${messageFromUi%%@*}"

    WriteToLog "Asking for user password."
    
    GetAndCheckUIPassword "Clover Theme Manager requires your password to set the Clover.Theme NVRAM variable."
    local returnValueRoot=$? # 1 = not root / 0 = root

    if [ ${returnValueRoot} = 0 ]; then 

       WriteToLog "Password gives elevated access"

        # RUN COMMAND WITH ROOT PRIVILEGES        
        WriteToLog "Setting Clover.theme NVRAM variable to $chosenTheme"
        echo "$gPw" | sudo -S "$uiSudoChanges" "SetNVRAMVar" "$chosenTheme" && gPw=""
        returnValue=$?
        if [ ${returnValue} -eq 0 ]; then
            successFlag=0
        fi
            
    elif [ ${returnValueRoot} = 1 ]; then 
        # password did not give elevated privileges. Run this routine again.
        WriteToLog "User entered incorrect password."
        SetThemeDirUnderVersionControl "$1"
    else
        WriteToLog "User cancelled password entry."
        WriteToLog "Leaving $1 not under version control."
    fi
    
    # Was install operation a success?
    if [ $successFlag -eq 0 ]; then
        WriteToLog "Setting NVRAM Variable was successful."
    else
        WriteToLog "Setting NVRAM Variable failed."
    fi
    
    # Read current Clover.Theme Nvram variable and send to UI.
    ReadAndSendCurrentNvramTheme
}


#===============================================================
# Main
#===============================================================


# Make sure this script exits when parent app is closed.
# Get process ID of this script
scriptPid=$( echo "$$" )
# Get process ID of parent
appPid=$( ps -p ${pid:-$$} -o ppid= )

remoteRepositoryUrl="svn://svn.code.sf.net/p/cloverthemes/svn"

# Was this script called from a script or the command line
identityCallerCheck=`ps -o stat= -p $$`
if [ "${identityCallerCheck:1:1}" == "+" ]; then
    # Called from command line so interpret arguments.

    # Will expect 2 arguments
    # 1 - The install path
    # 2 - The theme name

    if [ "$#" -eq 2 ]; then
	    TARGET_THEME_DIR="$1"
	    themeToInstall="$2"
    else
	    echo "Error - wrong number of arguments passed."
	    exit 1
    fi

    # Redirect all log file output to stdout
    COMMANDLINE=1

    # Should we be checking the theme exists on the repo?
    # Currently this does not happen.
    
    # Does theme path exist?
    if [ -d "$TARGET_THEME_DIR" ]; then
        SetThemeDirUnderVersionControl "$TARGET_THEME_DIR"
        RunThemeAction "Install" "$themeToInstall"
        returnValue=$?
        if [ ${returnValue} -eq 0 ]; then
            # Operation was successful
            echo "Theme $themeToInstall was successfully installed to $TARGET_THEME_DIR"
            exit 0
        else
            echo "Error - Theme $themeToInstall failed to be installed to $TARGET_THEME_DIR"
            exit 1
        fi
    else
        echo "Error - Target path $TARGET_THEME_DIR does not exist."
        exit 1
    fi
    
else
    # Called from Clover Theme Manager.app

    # Resolve path
    SELF_PATH=$(cd -P -- "$(dirname -- "$0")" && pwd -P) && SELF_PATH=$SELF_PATH/$(basename -- "$0")

    # Set out other directory paths based on SELF_PATH
    PUBLIC_DIR="${SELF_PATH%/*}"
    PUBLIC_DIR="${PUBLIC_DIR%/*}"
    ASSETS_DIR="$PUBLIC_DIR"/assets
    SCRIPTS_DIR="$PUBLIC_DIR"/bash
    WORKING_PATH="${HOME}/Library/Application Support"
    APP_DIR_NAME="CloverThemeManager"
    TARGET_THEME_DIR=""
    TARGET_THEME_DIR_DEVICE=""
    TMPDIR="/tmp/CloverThemeManager"
    COMMANDLINE=0

    logFile="${TMPDIR}/CloverThemeManagerLog.txt"
    logJsToBash="${TMPDIR}/CloverThemeManager_JsToBash.log"   # Note - this is set AppDelegate.m
    logBashToJs="${TMPDIR}/CloverThemeManager_BashToJs.log"
    logBashToJsUpdates="${TMPDIR}/CloverThemeManager_BashToJsUpdates.log"
    logBashToJsVersionedThemes="${TMPDIR}/CloverThemeManager_BashToJsVersionedThemes.log"
    logBashToJsVersionedDir="${TMPDIR}/CloverThemeManager_BashToJsVersionedDir.log"
    logBashToJsSpace="${TMPDIR}/CloverThemeManager_BashToJsSpace.log"
    logBashToJsResult="${TMPDIR}/CloverThemeManager_BashToJsResult.log"
    logBashToJsNvramVar="${TMPDIR}/CloverThemeManager_BashToJsNvramVar.log"
    gUserPrefsFileName="org.black.CloverThemeManager"
    gUserPrefsFile="$HOME/Library/Preferences/$gUserPrefsFileName"
    svnStatusXml="${TMPDIR}/status.xml"
    uiSudoChanges="${SCRIPTS_DIR}/uiSudoChangeRequests.sh"
    gUiPwCancelledStr="zYx1!ctm_User_Cancelled!!xYz"

    declare -a themeList
    declare -a themeTitle
    declare -a themeAuthor
    declare -a themeDescription
    declare -a dfMounts
    declare -a tmpArray
    declare -a diskUtilPlist
    declare -a allDisks
    declare -a diskUtilSliceInfo
    declare -a duVolumeName
    declare -a duIdentifier
    declare -a duContent
    declare -a themeDirPaths
    declare -a installedThemes
    declare -a installedThemesFound

    # Begin
    RemoveFile "$logFile"
    WriteToLog "CTM_Version${VERS}"
    WriteToLog "Started Clover Theme Manager script"
    WriteLinesToLog
    WriteToLog "scriptPid=$scriptPid | appPid=$appPid"

    RefreshHtmlTemplates "managethemes.html"
    IsRepositoryLive
    EnsureLocalSupportDir
    EnsureSymlink

    CheckOutThemePlistsAndEnsureThemeHtml &
    CheckoutImages &

    GetListOfMountedDevices
    BuildDiskUtilStringArrays
    CreateDiskPartitionDropDownHtml
    LoadPreviousSettingsFromUserPrefs

    wait

    SendUIThemePathThemeListAndFreeSpace

    # Write string to mark the end of init file.
    # The Javascript looks for this to signify initialisation is complete.
    WriteToLog "Complete!"

    ClearMessageLog "$logJsToBash"

    # Check for any updates to this app
    # CheckForAppUpdate

    # Check/Set theme directory is under version control
    CheckIfThemeDirIsUnderVersionControl "$TARGET_THEME_DIR"

    # Read current Clover.Theme Nvram variable and send to UI.
    ReadAndSendCurrentNvramTheme

    # Feedback for command line
    echo "Initialisation complete. Entering loop."

    # Remember parent process id
    parentId=$appPid


    # The messaging system is event driven and quite simple.
    # Run a loop for as long as the parent process ID still exists
    while [ "$appPid" == "$parentId" ];
    do
        sleep 0.25  # Check every 1/4 second.
    
        #===============================================================
        # Main Message Loop for responding to UI feedback
        #===============================================================

        # Has user selected partition for an /EFI/Clover/themes directory?
        if grep "CTM_selectedPartition@" "$logJsToBash" ; then
            uiReturn=$(cat "$logJsToBash")
        
            # Clear update, unversioned and free space message logs
            ClearMessageLog "$logBashToJsUpdates"
            ClearMessageLog "$logBashToJsVersionedThemes"
            ClearMessageLog "$logBashToJsVersionedDir"
            ClearMessageLog "$logBashToJsSpace"
            ClearMessageLog "$logBashToJsResult"
            WriteToLog "Cleared update and versions message log."
        
            # Check path,
            # find and send list of installed themes,
            # then check for any updates to those themes.
            RespondToUserDeviceSelection "$uiReturn"
    
        # Has the user clicked the OpenPath button?
        elif grep "OpenPath" "$logJsToBash" ; then
            if [ ! "$TARGET_THEME_DIR" == "-" ]; then
                Open "$TARGET_THEME_DIR"
            fi
            ClearMessageLog "$logJsToBash"
            WriteToLog "User selected to open $TARGET_THEME_DIR"
    
        # Has the UI finished reading inital launch massages?
        # if yes, clear the log
        elif grep "CTM_setupCompleted" "$logJsToBash" ; then
            ClearMessageLog "$logJsToBash"
            ClearMessageLog "$logBashToJs"
            WriteToLog "UI setupCompleted message. Cleared logs."

        # Has the UI read the last message sent to it?
        # if yes, clear the log
        elif grep "CTM_received" "$logJsToBash" ; then
            ClearMessageLog "$logJsToBash"
            ClearMessageLog "$logBashToJs"
            WriteToLog "UI received message"

        # Has the user pressed a theme button to install, uninstall or update?
        elif grep "CTM_ThemeAction" "$logJsToBash" ; then

            # Read message from javascript
            uiReturn=$(cat "$logJsToBash")
            ClearMessageLog "$logJsToBash"
        
            # Clear previous success/result
            ClearMessageLog "$logBashToJsResult"  
        
            # Clear update, unversioned and free space message logs
            ClearMessageLog "$logBashToJsUpdates"
            ClearMessageLog "$logBashToJsVersionedThemes"
            ClearMessageLog "$logBashToJsSpace"
            WriteToLog "Cleared update and versions message log."

            # Perform the requested user action.
            RespondToUserThemeAction "$uiReturn"
            returnValue=$?
            if [ ${returnValue} -eq 0 ]; then
                # Operation was successful

                # Scan for theme list and then send to UI
                GetListOfInstalledThemes
                SendToUI "InstalledThemes@${installedThemeStr}@"
                WriteToLog "Sent to UI: $installedThemeStr"
        
                freeSpace=$( GetFreeSpaceOfTargetDevice )
                WriteToLog "Sending UI: FreeSpace:$freeSpace"
                SendToUIFreeSpace "FreeSpace@${freeSpace}@"
        
                # Check for any updates
                GetListOfUpdatedThemes
                SendToUIUpdates "UpdateAvailThemes@${updateAvailThemeStr}@"
                WriteToLog "Sent to UI: $updateAvailThemeStr"
     
                # GetListOfUpdatedThemes() also gathered list of any unversioned themes.
                SendToUIUVersionedThemes "UnversionedThemes@${unversionedThemeStr}@"
                WriteToLog "Sent to UI: UnversionedThemes@${unversionedThemeStr}@"
            fi

        # A request by the UI to refresh the UI's theme list. This is
        # called automatically by the js after a user chooses to install,
        # update or delete a theme.
        elif grep "CTM_refreshThemeList" "$logJsToBash" ; then
            ClearMessageLog "$logJsToBash"
            GetListOfInstalledThemes       
            WriteToLog "Sending UI: $installedThemeStr"
            SendToUI "InstalledThemes@${installedThemeStr}@"
        
        # Has the UI passed message to say user has agreed to version control of theme dir?
        elif grep "CTM_versionAgree" "$logJsToBash" ; then
            answer=$( grep "CTM_versionAgree" "$logJsToBash" )
            ClearMessageLog "$logJsToBash"
            ClearMessageLog "$logBashToJsVersionedDir"
        
            # parse message
            answer="${answer##*:}"
            if [ $answer == "Yes" ]; then
                WriteToLog "User agreed to setting $TARGET_THEME_DIR under version control."
                SetThemeDirUnderVersionControl "$TARGET_THEME_DIR"
            elif [ $answer == "No" ]; then
                WriteToLog "User denied to setting $TARGET_THEME_DIR under version control."
            fi
           
        # Has user selected a theme for NVRAM variable?
        elif grep "CTM_chosenNvramTheme@" "$logJsToBash" ; then
            uiReturn=$(cat "$logJsToBash")
            WriteToLog "User chose to set nvram theme."
            # Clear log
            ClearMessageLog "$logJsToBash"
            ClearMessageLog "$logBashToJsNvramVar"
            WriteToLog "Cleared Nvram and JsToBash logs."
            SetNvramTheme "$uiReturn"
        fi
    
        # Get process ID of parent
        appPid=$( ps -p ${pid:-$$} -o ppid= )
    done

    WritePrefsToFile

    # Clean up
    RemoveFile "$logJsToBash"
    RemoveFile "$logFile"
    RemoveFile "$logBashToJs"
    RemoveFile "$logBashToJsUpdates"
    RemoveFile "$logBashToJsVersionedThemes"
    RemoveFile "$logBashToJsVersionedDir"
    RemoveFile "$logBashToJsSpace"
    RemoveFile "$logBashToJsResult"
    RemoveFile "$logBashToJsNvramVar"
    RemoveFile "$svnStatusXml"
    if [ -d "/tmp/CloverThemeManager" ]; then
        rmdir "/tmp/CloverThemeManager"
    fi
    if [ -f "${PUBLIC_DIR}"/managethemes.html ]; then
        rm "${PUBLIC_DIR}"/managethemes.html
    fi

    exit 0
fi