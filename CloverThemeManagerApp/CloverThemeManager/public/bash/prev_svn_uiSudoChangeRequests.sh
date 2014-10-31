#!/bin/sh

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
InstallTheme()
{
    local successFlag=1
    
    cd "${themeDir}"
    if [ "$checkoutMethod" == "up" ]; then
         svn up "$theme" && WriteToLog "Installation was successful." && successFlag=0
    elif [ "$checkoutMethod" == "checkout" ]; then
        svn checkout ${remoteRepositoryUrl}/themes/"$theme" && WriteToLog "Installation was successful." && successFlag=0
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

    cd "${themeDir}"
    if [ -d "$theme" ]; then
        rm -rf -- "$theme" && WriteToLog "Deletion was successful."  && successFlag=0
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
    
    cd "${themeDir}"
    if [ -d "${themeDir}"/"$theme" ]; then
        svn update "${themeDir}"/"$theme" && WriteToLog "Update was successful." && successFlag=0
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
# ---------------------------------------------------------------------------------------

whichFunction="$1"
echo ""

case "$whichFunction" in                             
     "Install"                    ) checkoutMethod="$2"
                                    themeDir="$3"
                                    theme="$4"
                                    InstallTheme
                                    ;;
     "UnInstall"                  ) themeDir="$3"
                                    theme="$4"
                                    UnInstallTheme
                                    ;;
     "Update"                     ) themeDir="$3"
                                    theme="$4"
                                    UpdateTheme
                                    ;;
     "SetPathUnderVersionControl" ) repositoryPath="$2"
                                    themePath="$3"
                                    SetPathUnderVersionControl
                                    ;;
     "SetNVRAMVar"                ) themeName="$2"
                                    SetNVRAMVariable
                                    ;;
esac


