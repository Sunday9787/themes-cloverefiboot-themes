// A script for Clover Theme Manager
// Copyright (C) 2014 Blackosx
// 
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
// 
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
// 
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
//
var gTmpDir = "/tmp/CloverThemeManager";
var gLogBashToJs = "CloverThemeManager_BashToJs.log";
var gLogBashToJsUpdates = "CloverThemeManager_BashToJsUpdates.log";
var gLogBashToJsVersionedThemes = "CloverThemeManager_BashToJsVersionedThemes.log";
var gLogBashToJsVersionedDir = "CloverThemeManager_BashToJsVersionedDir.log";
var gLogBashToJsSpace = "CloverThemeManager_BashToJsSpace.log";
var gLogBashToJsResult="CloverThemeManager_BashToJsResult.log";
var gLogBashToJsNvramVar="CloverThemeManager_BashToJsNvramVar.log";
var justLoaded=1;

//-------------------------------------------------------------------------------------
// On initial load
$(document).ready(function() {    
    macgap.app.launch("started");
    hideButtons();
    HideProgressBar();
    readLastSettings();
    ResetButtonsAndBandsToDefault();
    CheckForRevisedInstallThemeList();
    CheckForDirNotUnderVersionControl();
    CheckForUpdatesThemeList();
});

//-------------------------------------------------------------------------------------
// Called when the process is to close.
function terminate() {
    clearTimeout(timerCheckReplySelectedPartition);
    clearTimeout(timerCheckForThemeActionConfirmation);
    clearTimeout(timerCheckReplyUpdatedThemes);
    clearTimeout(timerCheckRevisedThemeList);
    clearTimeout(timerCheckVersionedThemeList);
    clearTimeout(timerCheckFreeSpace);
    macgap.app.terminate();    
}

//-------------------------------------------------------------------------------------
// looks for a file and if found, returns the contents
function GetFileContents(filename)
{
    xmlhttp = new XMLHttpRequest();
    xmlhttp.open("GET",gTmpDir+"/"+filename,false);
    xmlhttp.send(null);
    fileContent = xmlhttp.responseText;

    if (fileContent != "" ) {
        return fileContent;
    } else {
        return 0;
    }
}

//-------------------------------------------------------------------------------------
// Check for incoming messages from bash script
function readLastSettings()
{
    prevSettings=GetFileContents(gLogBashToJs);
    if (prevSettings != 0) {
    
        // Split settings by newline
        prevSettings = prevSettings.split('\n');
        // if array is not blank
        if (prevSettings != "") {
            // step through each element
            for (var i = 0; i < prevSettings.length; i++) {
                        
                // Does this line contain "Target"? if yes then it's saved partition.
                if ((prevSettings[i]).indexOf("Target") >= 0) {
                    // Split settings by @
                    stringSplit = (prevSettings[i]).split('@');
                    // if array is not blank
                    if (stringSplit != "") {
                        // Structure will be: Target@diskXsX@/Volumes/XXXX/EFI/Clover/Themes
                        // Set drop-down menu
                        $('#partitionSelect').val(stringSplit[1] + "@" + stringSplit[2]);
                        if (stringSplit[1] != "-" && stringSplit[2] != "-") {
                            showButtons();
                            // Show open button beside device dropdown
                            $("#OpenPathButton").css("display","block");
                        }
                    }
                }
                
                // Does this line contain "NotExist"? if yes then path is not mounted.
                if ((prevSettings[i]).indexOf("NotExist") >= 0) {
                    // Split settings by @
                    stringSplit = (prevSettings[i]).split('@');
                    // if array is not blank
                    if (stringSplit != "") {
                        // Structure will be: NotExist@diskXsX@/Volumes/XXXX/EFI/Clover/Themes
                        // Show message
                        ChangeMessageBoxHeaderColour("red");
                        SetMessageBoxText("Attention:" , "Previous path " + stringSplit[2] + " on device " + stringSplit[1] + " is no longer mounted. Please choose a theme path.")
                        ShowMessageBox();
                    }
                }
            }
        }
        // Notify bash script that setup has completed.
        macgap.app.launch("CTM_setupCompleted");
        // Change justLoaded flag to 0 so future path dropdown changes report back to bash script.
        justLoaded=0;
    } else {
        alert("readLastSettings(): Failed");
        terminate();
    }
}

//-------------------------------------------------------------------------------------
$(function()
{
    //-----------------------------------------------------
    // On changing the 'partitionSelect' dropdown menu.
    $("#partitionSelect").change(function() {
        var selectedPartition=$("#partitionSelect").val();
        
        // Send massage to bash script to notify change of path.
        // The bash script will get, and return, a list of installed themes for this path.
        // The bash script will then check if any of the themes have available updates.
        
        // Only reply to bash script if the app has not just been launched.
        if (justLoaded==0) {
            macgap.app.launch("CTM_selectedPartition@" + selectedPartition);
        }

        // Reset current theme list, bands and buttons
        ResetButtonsAndBandsToDefault();
        hideButtons();
        
        // Listen out for the install theme list from the bash script.
        CheckForRevisedInstallThemeList();
        
        // As long as the user did not select the 'Please Choose' menu option.
        if (selectedPartition != "-@-") {
                    
            // Disable path drop down menu and open button until updates have been checked.
            // Will re-enable in CheckForUpdatesThemeList();
            $("#partitionSelect").prop("disabled", true);
            $("#OpenPathButton").prop("disabled", true);
            
            // Display message to notify checking for updates
            $("#CheckingUpdatesMessage").css("display","block");
            
            // Show Overlay Box to stop user interacting with buttons
            DisplayOverlayTwoBox();

            // Show open button beside device dropdown
            $("#OpenPathButton").css("display","block");
            
            // Show the Free Space text
            ShowFreeSpace();
            
            // Listen out for if this theme path is under version control;
            // Check after 1 second delay.
            // This allows time for the CTM_selectedPartition message
            // to reach the bash script and for the function
            // CheckIfThemeDirIsUnderVersionControl() to be run and report back.
            setTimeout(function() {
                CheckForDirNotUnderVersionControl();
            }, 1000);

            // Check for updates after 1 second delay.
            // This allows time for the CTM_selectedPartition message
            // to reach the bash script and for it to delete previous
            // update message.
            setTimeout(function() {
                CheckForUpdatesThemeList();
            }, 1000);
            
        } else {
            // Hide open button beside device dropdown
            $("#OpenPathButton").css("display","none");

            // Hide the Free Space text
            HideFreeSpace();
            
            // Set Nvram area to nothing.
            SetNvramFooterToNotSet();
        }
    });
    
    //-----------------------------------------------------
    // On pressing the open path button
    $("#OpenPathButton").on('click', function() {
        macgap.app.launch("OpenPath");
    });
    
    //-----------------------------------------------------
    // On pressing a theme button (Install,UnInstall,Update)
    $("[id^=button_]").on('click', function() {
        var pressedButton=$(this).attr('id');
        var currentStatus=$(this).attr('class');
        RespondToButtonPress(pressedButton,currentStatus);
    });

    //-----------------------------------------------------
    // On clicking the message box close button
    $('#boxclose').click(function(){
        CloseMessageBox();
    });
    
    //-----------------------------------------------------
    // On pressing Toggle Theme Height button
    $("#BandsHeightToggleButton").on('click', function() {
    
        var state = $('.thumbnail').is(":hidden");
        if (!state) {
            // Move theme titles up
            $("[id=ThemeText]").css("top","74%");
            // Hide all theme descriptions
            $(".themeDescription").css("display","none");
            // Hide all theme authors
            $(".themeAuthor").css("display","none");
            // Hide thumbnails
            $(".thumbnail").css("display","none");
            // Adjust height of theme bands
            $(".accordion").css("height","36px");
            $(".accordionInstalled").css("height","36px");
            // Reduce margin top of buttons
            $(".buttonInstall").css("margin-top","6px");
            $(".buttonUnInstall").css("margin-top","6px");
            $(".buttonUpdate").css("margin-top","6px");
            // Reduce margin top of Unversioned Themes Indicatpor
            $(".versionControl").css("margin-top","9px");
            // Add margin left to theme titles
            $("[id=ThemeText]").css("margin-left","32px");
            // Change button text
            $(this).text("Show Thumbnails");
        } else {
            // Revert theme titles margin top
            $("[id=ThemeText]").css("top","50%");
            // Show all theme descriptions
            $(".themeDescription").css("display","inline");
            // Show all theme authors
            $(".themeAuthor").css("display","inline");
            // Show thumbnails
            $(".thumbnail").css("display","block");
            // Adjust height of theme bands
            $(".accordion").css("height","72px");
            $(".accordionInstalled").css("height","72px");
            // Revert margin top of buttons
            $(".buttonInstall").css("margin-top","24px");
            $(".buttonUnInstall").css("margin-top","24px");
            $(".buttonUpdate").css("margin-top","24px");
            // Revert margin top of Unversioned Themes Indicatpor
            $(".versionControl").css("margin-top","28px");
            // Remove added margin left to theme titles
            $("[id=ThemeText]").css("margin-left","0px");
            // Change button text
            $(this).text("Hide Thumbnails");
        }
    });
    
    //-----------------------------------------------------
    // On changing the 'NVRAM theme' dropdown menu.
    $("#installedThemeDropDown").change(function() {
        var chosenNvramTheme=$("#installedThemeDropDown").val();
        
        if(chosenNvramTheme != "-") {
        
            // Send massage to bash script to notify setting of NVRAM variable.
            macgap.app.launch("CTM_chosenNvramTheme@" + chosenNvramTheme);
        
            // Check for new nvram message from bash script after 1 second delay.
            // This allows time for the CTM_chosenNvramTheme message
            // to reach the bash script, for it to set new variable and then
            // read it before sending it back.
            setTimeout(function() {
               CheckForNvramTheme();
            }, 1000);
        }
    });
    
    
});

//-------------------------------------------------------------------------------------
function CheckForRevisedInstallThemeList()
{
    var receivedFile=0;
    var stringSplit="";
    
    // Set timer at the beginning.
    // If the InstalledThemes message filters straight through on first
    // run then the timer will be cleared anyway.
    timerCheckRevisedThemeList = setTimeout(CheckForRevisedInstallThemeList, 250);
    
    fileContent=GetFileContents(gLogBashToJs);
    if (fileContent != 0) {
        if ((fileContent).indexOf("InstalledThemes") >= 0) {

            var lineToRead = FindLineInString(fileContent,"InstalledThemes");
            
            stringSplit = (lineToRead).split('@');
            if (stringSplit != "") {
                localThemes = (stringSplit[1]).split(',');
                if (localThemes != "-") {

                    showButtons();
                    // Update only installed themes with uninstall buttons
                    for (var t = 0; t < localThemes.length; t++) {
                        ChangeButtonAndBandToUnInstall(localThemes[t]);
                    }
                    // Update number of installed themes
                    $("#NumInstalledThemes").html("Total themes installed: " + localThemes.length);
                    
                    // Populate the config plist key drop down menu
                    UpdateAndRefreshInstalledThemeDropDown(localThemes);
                } else {
                    UpdateAndRefreshInstalledThemeDropDown("-");
                    
                    // Update number of installed themes
                    $("#NumInstalledThemes").html("Total themes installed: -");
                }
            }
            receivedFile=1;
            clearTimeout(timerCheckRevisedThemeList);
            
            // Send message back to bash script to notify receipt
            macgap.app.launch("CTM_received");
            
            // Listen out for a list of any unVersioned themes.
            CheckForThemesUnderVersionControl();
            
            // Listen out for message for available free space
            CheckForFreeSpace();
        }
	    // recursively call function providing we haven't completed.
        if(receivedFile==0)
            timerCheckRevisedThemeList = setTimeout(CheckForRevisedInstallThemeList, 250);
	}
}

//-------------------------------------------------------------------------------------
function CheckForThemesUnderVersionControl()
{
    var receivedFile=0;
    var stringSplit="";

    // Set timer at the beginning.
    // If the UnversionedThemes message filters straight through on first
    // run then the timer will be cleared anyway.
    timerCheckVersionedThemeList = setTimeout(CheckForThemesUnderVersionControl, 500);
    
    fileContent=GetFileContents(gLogBashToJsVersionedThemes);
    if (fileContent != 0) {
        if ((fileContent).indexOf("UnversionedThemes") >= 0) {

            var lineToRead = FindLineInString(fileContent,"UnversionedThemes");

            stringSplit = (lineToRead).split('@');
            if (stringSplit != "") {
                versionedThemes = (stringSplit[1]).split(',');
                if (versionedThemes != "") {
                    for (var t = 0; t < versionedThemes.length; t++) {
                        SetUnVersionedControlIndicator(versionedThemes[t]);
                    }
                }
            }
            receivedFile=1;
            clearTimeout(timerCheckVersionedThemeList);  
                      
        } 

	    // recursively call function providing we haven't completed.
        if(receivedFile==0)
            timerCheckVersionedThemeList = setTimeout(CheckForThemesUnderVersionControl, 500);
	}
}

//-------------------------------------------------------------------------------------
function CheckForDirNotUnderVersionControl()
{
    var receivedFile=0;
    var stringSplit="";

    // Set timer at the beginning.
    // If the UnversionedThemeDir message filters straight through on first
    // run then the timer will be cleared anyway.
    timerCheckVersionedDir = setTimeout(CheckForDirNotUnderVersionControl, 250);
    
    fileContent=GetFileContents(gLogBashToJsVersionedDir);
    if (fileContent != 0) {
        if ((fileContent).indexOf("UnversionedThemeDir") >= 0) {
            var lineToRead = FindLineInString(fileContent,"UnversionedThemeDir");

            stringSplit = (lineToRead).split('@');
            if (stringSplit != "") {
                unVersionedDir = (stringSplit[1]);
                if (unVersionedDir != "") {
                    var currentPartition=$("#partitionSelect").val();
                    currentPartition = (currentPartition).split('@');
                    
                    // Show a message to the user
                    ChangeMessageBoxHeaderColour("blue");                            
                    SetMessageBoxText("Version Control:","Do you wish to be informed of theme updates for this volume?");
                    HideMessageBoxClose();
                    AddYesNoButtons();
                    ShowMessageBox();
                }
            }
            receivedFile=1;
            clearTimeout(timerCheckVersionedDir);            
        }

	    // recursively call function providing we haven't completed.
        if(receivedFile==0)
            timerCheckVersionedDir = setTimeout(CheckForDirNotUnderVersionControl, 250);
	}
}

//-------------------------------------------------------------------------------------
function CheckForNvramTheme()
{
    var receivedFile=0;

    timerCheckNvramVar = setTimeout(CheckForNvramTheme, 500);
    fileContent=GetFileContents(gLogBashToJsNvramVar);
    if (fileContent != 0) {
 
       // Split settings by newline
        lineSplit = fileContent.split('\n');
        // if array is not blank
        if (lineSplit != "") {
            currentNvramVar = (lineSplit[0]);

            // Print curent NVRAM var to UI
            if(currentNvramVar == "-") {
            
                SetNvramFooterToNotSet();

            } else {
            
                // Does the current NVRAM variable match an installed theme on this volume? 
                var matchFound=0;

                // Check this theme from nvram against the ones installed on current volume.
                $('#installedThemeDropDown option').each(function(){

                    if(this.value == currentNvramVar) {
                        matchFound=1;
                    }
                });

                // Print Current NVRAM var contents
                $("#currentNVRAMvar").text("NVRAM theme: " + currentNvramVar );
                
                // Change UI content to match results
                if(matchFound==1) {
                    // Print message
                    $("#currentNVRAMMessage").text("Theme is Installed on this volume"); 
                    // Change background colour to green
                    $("#AboveFooter").css("background-color","#629848");
                    // Change nvram dropdown option to match nvram var
                    $("#installedThemeDropDown").val(currentNvramVar);
                } else {
                    // Print message
                    $("#currentNVRAMMessage").text("Not Installed on this volume"); 
                    // Change background colour to red
                    $("#AboveFooter").css("background-color","#a13e41");
                    // Change nvram dropdown option to "-"
                    $("#installedThemeDropDown").val("-");
                }
            }
        }
            
        receivedFile=1;
        clearTimeout(timerCheckNvramVar);          
	}
	// recursively call function providing we haven't completed.
    if(receivedFile==0)
            timerCheckNvramVar = setTimeout(CheckForNvramTheme, 500);
}


//-------------------------------------------------------------------------------------
function CheckForUpdatesThemeList()
{
    var receivedFile=0;
    var stringSplit="";
    var printString="";

    // Set timer at the beginning.
    // If the UpdateAvailThemes message filters straight through on first
    // run then the timer will be cleared anyway.
    timerCheckReplyUpdatedThemes = setTimeout(CheckForUpdatesThemeList, 250);
    
    fileContent=GetFileContents(gLogBashToJsUpdates);
    if (fileContent != 0) {
        if ((fileContent).indexOf("UpdateAvailThemes") >= 0) {
            
            var lineToRead = FindLineInString(fileContent,"UpdateAvailThemes");
            
            stringSplit = (lineToRead).split('@');
            if (stringSplit != "") {
                localThemeUpdates = (stringSplit[1]).split(',');
                if (localThemeUpdates != "") {

                    printString=("<br>");
                    
                    // Update only installed themes with uninstall buttons
                    for (var t = 0; t < localThemeUpdates.length; t++) {
                    
                        // Here we change any installed themes to have an uninstall button.
                        ChangeButtonAndBandToUpdate(localThemeUpdates[t]);
                        
                        // Prepare text for pretty print
                        printString=(printString + "<br>" + localThemeUpdates[t])
                    }
                    
                    // Show a message to the user
                    ChangeMessageBoxHeaderColour("blue");                            
                    SetMessageBoxText("Theme Updates:","There is an update available for: " + printString);
                    ShowMessageBoxClose();
                    ShowMessageBox();
                }
            }
            receivedFile=1;
            clearTimeout(timerCheckReplyUpdatedThemes);
            
            // Re-enable drop down menu and open button
            $("#partitionSelect").prop("disabled", false);
            $("#OpenPathButton").prop("disabled", false);
            
            // Hide message to notify checking for updates
            $("#CheckingUpdatesMessage").css("display","none");
            
            // Hide Overlay Box to allow user to interact with buttons
            HideOverlayTwoBox();
            
            // Check NVRAM theme against list on this volume.
            CheckForNvramTheme();
            
        }
	    // recursively call function providing we haven't completed.
        if(receivedFile==0)
            timerCheckReplyUpdatedThemes = setTimeout(CheckForUpdatesThemeList, 250);
	}
}

//-------------------------------------------------------------------------------------
function CheckForFreeSpace()
{
    var receivedFile=0;
    var stringSplit="";

    // Set timer at the beginning.
    // If the UnversionedThemes message filters straight through on first
    // run then the timer will be cleared anyway.
    timerCheckFreeSpace = setTimeout(CheckForFreeSpace, 500);
    
    fileContent=GetFileContents(gLogBashToJsSpace);
    if (fileContent != 0) {
        if ((fileContent).indexOf("FreeSpace") >= 0) {

            var lineToRead = FindLineInString(fileContent,"FreeSpace");

            stringSplit = (lineToRead).split('@');
            if (stringSplit != "") {
                freeSpace = (stringSplit[1]);

                // Bash sends the size read from the result of df
                // This will look like 168M 
                // Remove last character of string
                number = freeSpace.slice(0,-1);
                // round down
                number = Math.floor(number);
                
                if(parseInt(number, 10) < parseInt(10, 10)) {
                    // change colour to red
                    $(".textFreeSpace").css("color","#C00000");
                } else {
                    // set to blue as defined in the .css file
                    $(".textFreeSpace").css("color","#00CCFF");
                }
                $(".textFreeSpace").text("Free Space:" +freeSpace );
            }
            receivedFile=1;
            clearTimeout(timerCheckFreeSpace);            
        }
	    // recursively call function providing we haven't completed.
        if(receivedFile==0)
            timerCheckFreeSpace = setTimeout(CheckForFreeSpace, 500);
	}
}

//-------------------------------------------------------------------------------------
function FindLineInString(CompleteString,SearchString)
{
    var splitLines = (CompleteString).split(/\r\n|\r|\n/);    
    for (l = 0; l < splitLines.length; l++) {
        if ((splitLines[l]).indexOf(SearchString) >= 0)
            return splitLines[l];
    }
    return "0";
}

//-------------------------------------------------------------------------------------
function CheckForThemeActionConfirmation()
{
    var receivedFile=0;
    var stringSplit="";

    fileContent=GetFileContents(gLogBashToJsResult);
    if (fileContent != 0) {

        if ((fileContent).indexOf("Success") >= 0) {

            var lineToRead = FindLineInString(fileContent,"Success");
            
            stringSplit = (lineToRead).split('@');
            // if array is not blank
            if (stringSplit != "") {
            
                // Structure will be: Success@Action@$themeName
                ChangeMessageBoxHeaderColour("green");

                // Correct language - Install, UnInstall, Update to Installed, UnInstalled, Updated
                if (stringSplit[1] == "Update") {
                    printText="Updated";
                } else {
                    printText=(stringSplit[1] + "ed");
                }
                // Print message
                HideProgressBar();
                SetMessageBoxText("Success:","The theme " + stringSplit[2] + " was successfully " + printText + ".");
                ShowMessageBoxClose();
                
                // Refresh theme list
                macgap.app.launch("CTM_refreshThemeList");
                
                // Reset current theme list, bands and buttons
                ResetButtonsAndBandsToDefault();
                hideButtons();
        
                // Listen out for revised
                CheckForRevisedInstallThemeList();
                
                // Disable path drop down menu and open button until updates have been checked.
                // Will re-enable in CheckForUpdatesThemeList();
                $("#partitionSelect").prop("disabled", true);
                $("#OpenPathButton").prop("disabled", true);
            
                // Display message to notify checking for updates
                $("#CheckingUpdatesMessage").css("display","block");
                
                // Show Overlay Box to stop user interacting with buttons
                DisplayOverlayTwoBox();

                // Show open button beside device dropdown
                $("#OpenPathButton").css("display","block");
            
                // Check for updates after 1 second delay.
                // This allows time for the CTM_selectedPartition message
                // to reach the bash script and for it to delete previous
                // update message.
                setTimeout(function() {
                    CheckForUpdatesThemeList();
                }, 1000);
            }
            
            receivedFile=1;
            clearTimeout(timerCheckForThemeActionConfirmation);
            
        } else if ((fileContent).indexOf("Fail") >= 0) {

            var lineToRead = FindLineInString(fileContent,"Fail");
            
            stringSplit = (lineToRead).split('@');
            // if array is not blank
            if (stringSplit != "") {
            
                // Structure will be: Success@Action@$themeName
                ChangeMessageBoxHeaderColour("red");

                // Correct language - Install, UnInstall, Update to Installed, UnInstalled, Updated
                if (stringSplit[1] == "Update") {
                    printText="Updated";
                } else {
                    printText=(stringSplit[1] + "ed");
                }
                // Print message
                HideProgressBar();
                SetMessageBoxText("Failure:","The theme " + stringSplit[2] + " was not " + printText + ".");
                ShowMessageBoxClose();
            }
            
            receivedFile=1;
            clearTimeout(timerCheckForThemeActionConfirmation);
        }
	    // recursively call function providing we haven't completed.
        if(receivedFile==0)
            timerCheckForThemeActionConfirmation = setTimeout(CheckForThemeActionConfirmation, 500);
	}
	else
	{
	    // recursively call function providing we haven't completed.
        if(receivedFile==0)
            timerCheckForThemeActionConfirmation = setTimeout(CheckForThemeActionConfirmation, 500);
    }
}

//-------------------------------------------------------------------------------------
function RespondToButtonPress(button,status)
{
    // Update buttons have a class name 'button_Update_' and not 'button_'
    // The bash matches against the string 'button_'
    // Remove 'Update_' from string.
    // Note: Could cause issues if a theme has 'Update_' in it's title.

    var button = button.replace('Update_', '');

    // Notify bash script. Send button name and it's current state.
    macgap.app.launch("CTM_ThemeAction@" + button + "@" + status);
        
    // Prepare vars for legible user message
    // PresedButton will begin with "button_"
    button=button.substring(7);

    // PresedButton will begin with "button"
    status=status.substring(6);
    if (status == "Install") {
        headerText="Downloading & Installing:";
        printText="Installed";
    }
    if (status == "UnInstall") {
        headerText="Un-Installing:";
        printText="Un-Installed";
    }
    if (status == "Update") {
        headerText="Updating:";
        printText="Updated";
    }
 
    // Show a message to the user
    ChangeMessageBoxHeaderColour("blue");
        
    SetMessageBoxText(headerText, "Please wait while theme " + button + " is " + printText + ".");
    HideMessageBoxClose();
    ShowProgressBar();
    ShowMessageBox();
    
    // Check for confirmation of result after 1 second delay.
    // This allows time for the CTM_ThemeAction message
    // to reach the bash script and for it to delete previous
    // message from $logBashToJsResult.
    setTimeout(function() {
        CheckForThemeActionConfirmation();
    }, 1000);
}

//-------------------------------------------------------------------------------------
// hide all option buttons
function hideButtons()
{
    $(".buttonInstall").css("display","none");
    $(".buttonUnInstall").css("display","none");
    $(".buttonUpdate").css("display","none");
}

//-------------------------------------------------------------------------------------
// show all option buttons
function showButtons()
{
    $(".buttonInstall").css("display","block");
    $(".buttonUnInstall").css("display","block");
    $(".buttonUpdate").css("display","block");
}

//-------------------------------------------------------------------------------------
function SetMessageBoxText(title,message)
{
    $(".box h1").html(title);
    $(".box p").html(message);
}

//-------------------------------------------------------------------------------------
function HideMessageBoxClose()
{
    $("a.boxclose").css("display","none");
}

//-------------------------------------------------------------------------------------
function ShowMessageBoxClose()
{
    $("a.boxclose").css("display","block");
}

//-------------------------------------------------------------------------------------
function HideFreeSpace()
{
    $("#FreeSpace").css("display","none");
}

//-------------------------------------------------------------------------------------
function ShowFreeSpace()
{
    $("#FreeSpace").css("display","block");
}

//-------------------------------------------------------------------------------------
function HideProgressBar()
{
    $("#AnimatedBar").css("display","none");
}

//-------------------------------------------------------------------------------------
function ShowProgressBar()
{
    $("#AnimatedBar").css("display","block");
}

//-------------------------------------------------------------------------------------
function DisplayOverlayBox()
{
    $('#overlay').fadeIn('fast');
}

//-------------------------------------------------------------------------------------
function HideOverlayBox()
{
    $('#overlay').fadeOut('fast');
}

//-------------------------------------------------------------------------------------
function DisplayOverlayTwoBox()
{
    $('#overlayTwo').fadeIn('fast');
}

//-------------------------------------------------------------------------------------
function HideOverlayTwoBox()
{
    $('#overlayTwo').fadeOut('fast');
}

//-------------------------------------------------------------------------------------
// From a tutorial by Mary Lou
// http://tympanus.net/codrops/2009/12/03/css-and-jquery-tutorial-overlay-with-slide-out-box/
function ShowMessageBox()
{
    $('#overlay').fadeIn('fast',function(){
        $('#box').animate({'top':'150px'},500); // move box from current position so top=300px
    });
}

//-------------------------------------------------------------------------------------
function CloseMessageBox()
{
    $('#box').animate({'top':'-200px'},500,function(){  // starting position = should match .box top in css
        $('#overlay').fadeOut('fast');
    });
}

//-------------------------------------------------------------------------------------
function ChangeMessageBoxHeaderColour(colour)
{
    if(colour == "blue") {
        $("#box h1").css("background-color","#1e8ec6");
        $("#box h1").css("color","#c4e0ee");
    }
        
    if(colour == "red") {
        $("#box h1").css("background-color","#b43239");
        $("#box h1").css("color","#f2d6d8");
    }
        
    if(colour == "green") {
        $("#box h1").css("background-color","#8db035");
        $("#box h1").css("color","#e4ecce");
    }
}

//-------------------------------------------------------------------------------------
function ResetButtonsAndBandsToDefault()
{
    // Set class of all buttons to Install
    $(".buttonInstall").attr('class', 'buttonInstall');
    $(".buttonUnInstall").attr('class', 'buttonInstall');
    
    // Set all button text to Install
    $(".buttonInstall").html("Install");
    $(".buttonUnInstall").html("Install");

    // Change all installed band backgrounds to normal
    $(".accordionInstalled").attr("class","accordion");
    
    // Change all update band backgrounds to normal
    $(".accordionUpdate").attr("class","accordion");
    
    // Remove any update buttons
    $("[id^=button_Update]").remove();
    
    // Remove any unVersioned indicators
    $("[id^=indicator_]").html("&nbsp;&nbsp;&nbsp;");
}

//-------------------------------------------------------------------------------------
function ChangeButtonAndBandToUnInstall(themeName)
{
    // themeName will be the name of an installed theme
    
    // Set class of this themes' button to UnInstall
    // Use an attribute selector to deal with themes with spaces in their name
    $("[id='button_" + themeName + "']").attr('class', 'buttonUnInstall');
    
    // Set class of this themes' button text to UnInstall
    $("[id='button_" + themeName + "']").html("UnInstall");
    
    // Change band of this themes' background to indicate installed.
    $("[id='button_" + themeName + "']").closest('div[class="accordion"]').attr("class","accordionInstalled");
}

//-------------------------------------------------------------------------------------
function ChangeButtonAndBandToUpdate(themeName)
{
    // Change band background for installed themes
    $("[id='button_" + themeName + "']").closest('div[class="accordionInstalled"]').attr("class","accordionUpdate");
    
    // Add a new 'update' button beside the current 'UnInstall' button
    // http://stackoverflow.com/questions/12618214/binding-jquery-events-before-dom-insertion
    $( '<div class="buttonUpdate" id="button_Update_' + themeName + '"></div>' ).on('click', function(e) {
        e.preventDefault();
        var pressedButton=$(this).attr('id');
        var currentStatus=$(this).attr('class');
        RespondToButtonPress(pressedButton,currentStatus);
    }).insertAfter("[id='button_" + themeName + "']");
    $("[id='button_Update_" + themeName + "']").html("Update");
}

//-------------------------------------------------------------------------------------
function ChangeButtonsToUpdate()
{
    $(".buttonInstall").attr('class', 'buttonUpdate');
    $(".buttonInstall").html("Update");
}

//-------------------------------------------------------------------------------------
function SetUnVersionedControlIndicator(themeName)
{
    // themeName will be the name of an installed theme

    // Display indicator to show theme is unversioned
    $("[id='indicator_" + themeName + "']").html("U");
}

//-------------------------------------------------------------------------------------
function UpdateAndRefreshInstalledThemeDropDown(themeList)
{
    // Clear any existing entries
    $(installedThemeDropDown).empty();

    if (themeList != "-") {
        // Add random option
        $("#installedThemeDropDown").append("<option value=\"-\">Set Default Theme</option>");
        // Add new list
        for (var t = 0; t < themeList.length; t++) {
            if (themeList[t] != "")
                $("#installedThemeDropDown").append("<option value=\"" + themeList[t] + "\">" + themeList[t] + "</option>");
        }
    }
}

//-------------------------------------------------------------------------------------
function imgErrorThumb(image){
    image.onerror="";
    image.src="assets/thumb_noimage.png";
    return true;
}

//-------------------------------------------------------------------------------------
function imgErrorPreview(image){
    image.onerror="";
    image.src="assets/preview_noimage.png";
    return true;
}

//-------------------------------------------------------------------------------------
function AddYesNoButtons(){

    // Add button No
    $( '<div class="feedbackButton" id="feedback_Button_No"></div>' ).on('click', function(e) {
        e.preventDefault();
        // Send message back to bash script to notify receipt
        macgap.app.launch("CTM_versionAgree:No");
        
        // Hide message box and reset
        CloseMessageBox();
        ShowMessageBoxClose();
        RemoveYesNoButtons();
        
    }).insertAfter("[id='FeedbackButtons']");
    
    // Set button text
    $("[id='feedback_Button_No']").html("No");
    
    // Add button Yes
    $( '<div class="feedbackButton" id="feedback_Button_Yes"></div>' ).on('click', function(e) {
        e.preventDefault();
        // Send message back to bash script to notify receipt
        
        // Hide message box and reset
        CloseMessageBox();
        ShowMessageBoxClose();
        RemoveYesNoButtons();
        macgap.app.launch("CTM_versionAgree:Yes");
    }).insertAfter("[id='FeedbackButtons']");
    
    // Set button text
    $("[id='feedback_Button_Yes']").html("Yes");
}

//-------------------------------------------------------------------------------------
function RemoveYesNoButtons(){
    $("[id^=feedback_Button]").remove(); 
}

//-------------------------------------------------------------------------------------
function SetNvramFooterToNotSet(){
    $("#currentNVRAMvar").text("NVRAM theme: Not set:"); 
    $("#currentNVRAMMessage").text(""); 
    $("#AboveFooter").css("background-color","#888888");
}