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
//Version=0.75.2

var gTmpDir = "/tmp/CloverThemeManager";
var gLogBashToJs = "bashToJs";

//-------------------------------------------------------------------------------------
// On initial load
$(document).ready(function() {
    disableInterface();
    hideButtons();
    HideProgressBar();
    readBashToJsMessageFile();
    ResetButtonsAndBandsToDefault();
});

//-------------------------------------------------------------------------------------
// Called when the process is to close.
function terminate() {
    clearTimeout(timerReadMessageFile);
    macgap.notice.close("*"); // Remove all notifications sent by app
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

/*
// Called when returning back from help page
//-------------------------------------------------------------------------------------
$(window).bind("pageshow", function(event) {
    if (event.originalEvent.persisted) {
        alert("From bfcache");
        // check if macgap API works or generates an error
        if ('macgap.app.launch' in window) {
            try {
                alert("trying");
            } catch (e) {
                alert("catch");
            }     
            alert("macgap working");
        } else {
            try {
                alert("trying");
                macgap.app.activate(); 
            } catch (e) {
                alert("catch");
            }
            alert("macgap not working");
            //window.location.reload();
        }
    }
});
*/

//-------------------------------------------------------------------------------------
// Check for incoming messages from bash script
function readBashToJsMessageFile()
{
    incoming=GetFileContents(gLogBashToJs);
    if (incoming != 0) {
    
        // Split settings by newline
        var incoming = incoming.split('\n');
        
        // Take first line
        var firstLine = (incoming[0]);
    
        // Split firstLine by @
        var firstLineSplit = (firstLine).split('@');
        var firstLineCommand = (firstLineSplit[0]);
        
        // match command against known ones.
        switch(firstLineCommand) {
            case "Target":
                // Bash sends: "Target@$entry"
                macgap.app.removeMessage(firstLine);
                setTargetThemePath(firstLineSplit[1]);
                break;
            case "NotExist":
                // Bash Sends: "NotExist@${TARGET_THEME_DIR_DEVICE}@${TARGET_THEME_DIR}@entry"
                macgap.app.removeMessage(firstLine);
                presentNotExistsDialog(firstLineSplit[1],firstLineSplit[2],firstLineSplit[3]);
                break;
            case "InstalledThemes":
                // Bash sends: "InstalledThemes@${installedThemeStr}@"
                // where $installedThemeStr is a comma separated string.
                macgap.app.removeMessage(firstLine);
                updateBandsWithInstalledThemes(firstLineSplit[1]);
                // Honour users choice of which themes to view (All or just Installed)
                GetShowHideButtonStateAndUpdateUI();
                break;
            case "FreeSpace":
                // Bash sends: "FreeSpace@${freeSpace}@"
                macgap.app.removeMessage(firstLine);
                actOnFreeSpace(firstLineSplit[1]);
                break;
            case "UpdateAvailThemes":
                // Bash sends: "UpdateAvailThemes@${updateAvailThemeStr}@"
                // where $updateAvailThemeStr is a comma separated string.
                macgap.app.removeMessage(firstLine);
                actOnUpdates(firstLineSplit[1]);
                break;
            case "UnversionedThemes":
                // Bash sends: "UnversionedThemes@${unversionedThemeStr}@"
                macgap.app.removeMessage(firstLine);
                displayUnversionedThemes(firstLineSplit[1]);
                break;
            case "Nvram":
                // Bash sends: "Nvram@${themeName}@"
                macgap.app.removeMessage(firstLine);
                actOnNvramThemeVar(firstLineSplit[1]);
                break;
            case "Success":
                // Bash sends: "Success@${passedAction}@$themeTitleToActOn"
                macgap.app.removeMessage(firstLine);
                themeActionSuccess(firstLineSplit[1],firstLineSplit[2]);
                break;
            case "Fail":
                // Bash sends: "Fail@${passedAction}@$themeTitleToActOn"
                macgap.app.removeMessage(firstLine);
                themeActionFail(firstLineSplit[1],firstLineSplit[2]);
                break;
            case "NoPathSelected":
                // Bash sends: "NoPathSelected@@"
                macgap.app.removeMessage(firstLine);
                HideFreeSpace();
                break;
            case "ThumbnailSize":
                // Bash sends: "ThumbnailSize@${gThumbSizeX}@${gThumbSizeY}"
                macgap.app.removeMessage(firstLine);
                SetThumbnailSize(firstLineSplit[1],firstLineSplit[2]);
                break;
            case "UnInstalledView":
                // Bash sends: "UnInstalledView@${gUISettingViewUnInstalled}@"
                macgap.app.removeMessage(firstLine);
                SetShowHideButton(firstLineSplit[1]);
                break;
            case "ThumbnailView":
                // Bash sends: "UnInstalledView@${gUISettingViewUnInstalled}@"
                macgap.app.removeMessage(firstLine);
                SetThemeBandHeight(firstLineSplit[1]);
                break;
            case "PreviewView":
                // Bash sends: "PreviewView@${gUISettingViewPreviews}@"
                macgap.app.removeMessage(firstLine);
                SetShowHidePreviews(firstLineSplit[1]);
                break;
            case "UpdateAvailApp":
                // Bash sends: "UpdateAvailApp@${serverVersion}@"
                macgap.app.removeMessage(firstLine);
                DisplayAppUpdates(firstLineSplit[1]);
                break;
            case "UpdateAppFeedback":
                // Bash sends: "UpdateAppFeedback@Success@" or "UpdateAppFeedback@Fail@"
                // where $updateAvailThemeStr is a comma separated string.
                macgap.app.removeMessage(firstLine);
                AppUpdateFeedback(firstLineSplit[1]);
                break;
            case "MessageESP":
                // Bash sends: "MessageESP@Mounted@${checkMountPoints##* }"
                macgap.app.removeMessage(firstLine);
                UpdateMessageBox(firstLineSplit[1],firstLineSplit[2]);
                break;
            case "NewVolumeDropDown":
                // Bash sends: "NewVolumeDropDown@${newThemeList}"
                //${newThemeList} is a comma separated list
                macgap.app.removeMessage(firstLine);
                UpdateAndRefreshPartitionSelectMenu(firstLineSplit[1]);
                break;
            case "Snow":
                // Bash sends: "Snow@${gSnow}@"
                macgap.app.removeMessage(firstLine);
                ToggleSnow(firstLineSplit[1]);
                break;
            default:
                alert("Found else:"  + firstLine);
                if(firstLine == "") {
                    macgap.app.removeMessage("");
                }
                break;
        }
	    // recursively call function as long as file exists every 1/10th second.
        timerReadMessageFile = setTimeout(readBashToJsMessageFile, 100);
    } else {
        // recursively call function as long as file exists but at 1/2 second intervals
        timerReadMessageFile = setTimeout(readBashToJsMessageFile, 500);
    }
}

//-------------------------------------------------------------------------------------
function setTargetThemePath(entry)
{
    $('#partitionSelect').val(entry);
    ResetButtonsAndBandsToDefault();
    if (entry != "-") {
        showButtons();
        // Show open button beside device dropdown
        $("#OpenPathButton").css("display","block");
        ShowFreeSpace();
    } else {
        $("#OpenPathButton").css("display","none");
        ShowMessageBoxClose();
        HideProgressBar();
    }
}

//-------------------------------------------------------------------------------------
function presentNotExistsDialog(uuid,path,id)
{
    if (uuid != "" & path != "") {
        ChangeMessageBoxHeaderColour("red");
        SetMessageBoxText("Attention:" ,"Previously used:<br>" + path + "<br>on volume with UUID<br>" + uuid + "<br>is no longer mounted.<br><br>Please choose a theme path.")
        ShowMessageBox();
        
        // Remove partition entry from dropdown menu
        if ( id != "-" ) {
            $("#partitionSelect option[value=" + id + "]").remove();
        }
    }
}

//-------------------------------------------------------------------------------------
function updateBandsWithInstalledThemes(themeList)
{
    if (themeList != "") {
        splitThemeList = (themeList).split(',');
        if (splitThemeList != "-") {

            showButtons();
            var unknownThemeCount=0;
            // Update only installed themes with uninstall buttons
            for (var t = 0; t < splitThemeList.length; t++) {
                // Does theme actually exist?
                // User could have their own theme installed which is not in the repo.
                if (!$("[id='button_" + splitThemeList[t] + "']").length) {
                    //alert(splitThemeList[t] + " does not exist in the repo");
                    unknownThemeCount++;
                }
                ChangeButtonAndBandToUnInstall(splitThemeList[t]);
            }

            // Has the user chosen to view only installed themes?
            var readButton = $("#ShowHideToggleButton").text();
            if (readButton.indexOf("Show") >= 0) {
                // Hide previews of uninstalled themes
                ClosePreviewsForUninstalledThemes();
            }

            // Update number of installed themes
            if (splitThemeList != ",") { // This check needs verifying!! - is a single comma possible?
                $("#NumInstalledThemes").html(splitThemeList.length + "/" + $('div[id^=ThemeBand]').length);
                if (unknownThemeCount > 0){
                    // Change colour of textThemeCount class to orange
                    $("#NumInstalledThemes").css("color","#FFA500");
                    $("#NumInstalledThemesQuery").css("display","inline");
                } else {
                    $("#NumInstalledThemes").css("color","#FFF");
                    $("#NumInstalledThemesQuery").css("display","none");
                }
            } else {
                $("#NumInstalledThemes").html("0/" + $('div[id^=ThemeBand]').length);
            }

            // Populate the config plist key drop down menu
            UpdateAndRefreshInstalledThemeDropDown(splitThemeList);
        } else {
            UpdateAndRefreshInstalledThemeDropDown("-");
                    
            // Update number of installed themes
            $("#NumInstalledThemes").html("-/" + $('div[id^=ThemeBand]').length);
            // Reset colours and question mark incase previously shown.
            $("#NumInstalledThemes").css("color","#FFF");
            $("#NumInstalledThemesQuery").css("display","none");
        }
    } else {
        showButtons();
        // No themes installed on this volume
        $("#NumInstalledThemes").html("0/" + $('div[id^=ThemeBand]').length);
        // Reset colours and question mark incase previously shown.
        $("#NumInstalledThemes").css("color","#FFF");
        $("#NumInstalledThemesQuery").css("display","none");
    }
}

//-------------------------------------------------------------------------------------
function actOnFreeSpace(availableSpace)
{
    if (availableSpace != "") {
        // Bash sends the size read from the result of df
        // This will look like 168M 
        // Is the last character a G?
        lastChar = availableSpace.slice(-1);

        if (lastChar == "K") {
            // change colour to red
            $(".textFreeSpace").css("color","#C00000");
        }
                
        if (lastChar == "M") {
            // Remove last character of string
            number = availableSpace.slice(0,-1);
            // round down
            number = Math.floor(number);
                    
            if(parseInt(number, 10) < parseInt(10, 10)) {
                // change colour to red
                $(".textFreeSpace").css("color","#C00000");
                        
                // Show user a low space warning message
                ChangeMessageBoxHeaderColour("red");                            
                SetMessageBoxText("Warning: Low Space","You only have " + number +"MB remaining on this volume. Installing another theme may fail!");
                ShowMessageBoxClose();
                ShowMessageBox();
            }
        }

        if (lastChar == "G") {
            // set to green as defined in the .css file
            $(".textFreeSpace").css("color","#3ef14b");
        }

        $(".textFreeSpace").text(availableSpace+"B");
    }
}

//-------------------------------------------------------------------------------------
function DisplayAppUpdates(updateID)
{
    // The app can be updated in two ways.
    //
    // 1 - The main outer MacGap app which requires a new CloverThemeManager binary. This does not get updated often.
    // 2 - The inner public directory containing the html,css,js and associated files. These will change more frequently.
    //
    // Updates for 1 will be identified in the form of X.XX.X. For example: 0.75.6
    // Updates for 2 will be identified by a single integer X. For example: 7

    if (updateID != "") {
        disableInterface();
        
        // Does updateID contain a period?
        if (updateID.indexOf(".") >= 0) {
            // Show a message to the user
            ChangeMessageBoxHeaderColour("blue");                            
            SetMessageBoxText("Application Framework Update:",'A new version of the main app (v' + updateID + ') is available.<br><br>Please download a new version of the app. You can find latest versions at either <a href="http://www.projectosx.com/forum/index.php?showtopic=3329" target="_blank">Projectosx</a> or <a href="http://www.insanelymac.com/forum/topic/302674-clover-theme-manager/" target="_blank">Insanleymac</a>');
            // Send native notification
            sendNotification("Application framework update available. Please download a new version of the app.");
        } else {
            // Show a message to the user
            ChangeMessageBoxHeaderColour("blue");                            
            SetMessageBoxText("Application Scripts Update:","There are updated scripts available (updateID: " + updateID + ").<br><br>It's recommended to update to the latest version.<br>Do you wish to update the Clover Theme Manager scripts?");
            // Send native notification
            sendNotification("Application scripts update available.");
            HideMessageBoxClose();
            AddYesNoButtons();
        }
        ShowMessageBox();
    }
}

//-------------------------------------------------------------------------------------
function actOnUpdates(themeList)
{    
    if (themeList != "") {
        disableInterface();
        localThemeUpdates = (themeList).split(',');
        if (localThemeUpdates != "") {
        
            var printString=("<br>");
        
            // Update only installed themes with uninstall buttons
            for (var t = 0; t < localThemeUpdates.length; t++) {
                    
                // Here we change any installed themes to have an uninstall button.
                ChangeButtonAndBandToUpdate(localThemeUpdates[t]);
                        
                // Prepare text for pretty print
                printString=(printString + "<br>" + localThemeUpdates[t]);
                
                // Send native notification
                sendNotification("Theme update available for " + localThemeUpdates[t] + ".");
            }
                    
            // Show a message to the user
            ChangeMessageBoxHeaderColour("blue");                            
            SetMessageBoxText("Theme Updates:","There is an update available for: " + printString);
            ShowMessageBoxClose();
            ShowMessageBox();
        }
    }
    // re-enable UI
    // This must be unconditional as the UI is disabled when user changes volume
    enableInterface(); 
}

//-------------------------------------------------------------------------------------
function displayUnversionedThemes(themeList)
{
    if (themeList != "") {
        unVersionedThemes = (themeList).split(',');
        if (unVersionedThemes != "") {
            for (var t = 0; t < unVersionedThemes.length; t++) {
                SetUnVersionedControlIndicator(unVersionedThemes[t]);
            }
        }
    }
}

//-------------------------------------------------------------------------------------
function actOnNvramThemeVar(nvramThemeVar)
{
    // Print curent NVRAM var to UI
    if(nvramThemeVar == "-") {        
        SetNvramFooterToNotSet();
    } else {
        // Does the current NVRAM variable match an installed theme on this volume? 
        var matchFound=0;

        // Check this theme from nvram against the ones installed on current volume.
        $('#installedThemeDropDown option').each(function(){

            if(this.value == nvramThemeVar) {
                matchFound=1;
            }
        });

        // Print Current NVRAM var contents
        $("#currentNVRAMvar").text("NVRAM theme: " + nvramThemeVar );
                
        // Change UI content to match results
        if(matchFound==1) {
            // Print message
            $("#currentNVRAMMessage").text("Theme is Installed on this volume"); 
            // Change background colour to green
            $("#AboveFooter").attr('class', 'nvramFillInstalled');
            // Change nvram dropdown option to match nvram var
            $("#installedThemeDropDown").val(nvramThemeVar);
        } else {
            // Print message
            $("#currentNVRAMMessage").text("Not Installed on this volume"); 
            // Change background colour to red
            $("#AboveFooter").attr('class', 'nvramFillNotInstalled');
            // Change nvram dropdown option to "-"
            $("#installedThemeDropDown").val("-");
        }
    }
}

//-------------------------------------------------------------------------------------
function AppUpdateFeedback(state)
{
    if (state != "") {
    
        if (state == "Success") {
        
            // Present dialog to the user
            ChangeMessageBoxHeaderColour("green");

            // Print message
            HideProgressBar();
            SetMessageBoxText("Success:","The app updates completed successfully. Please quit and re-launch CloverThemeManager.");
            AddQuitButton();
            
        } else if (state == "Fail")  {
        
            // Present dialog to the user
            ChangeMessageBoxHeaderColour("red");

            // Print message
            HideProgressBar();
            SetMessageBoxText("Failed:","The app updates did not successfully complete.");
            ShowMessageBoxClose();
        }
    }
}


//-------------------------------------------------------------------------------------
function themeActionSuccess(action,themeName)
{
    if (action != "" & themeName != "") {
    
        // Present dialog to the user
        ChangeMessageBoxHeaderColour("green");

        // Correct language - Install, UnInstall, Update to Installed, UnInstalled, Updated
        if (action == "Update") {
            printText="Updated";
        } else {
            printText=(action + "ed");
        }
        
        // Print message
        HideProgressBar();
        SetMessageBoxText("Success:","The theme " + themeName + " was successfully " + printText + ".");
        ShowMessageBoxClose();
        
        // Send native notification
        sendNotification("Success: The theme " + themeName + " was successfully " + printText + ".");
        
        // Reset current theme list, bands and buttons
        ResetButtonsAndBandsToDefault();
        hideButtons();
                
        // Show Overlay Box to stop user interacting with buttons
        disableInterface(); // it's re-enabled by actOnUpdates()
    }
}

//-------------------------------------------------------------------------------------
function themeActionFail(action,themeName)
{
    if (action != "" & themeName != "") {
    
        // Present dialog to the user
        ChangeMessageBoxHeaderColour("red");

        // Correct language - Install, UnInstall, Update to Installed, UnInstalled, Updated
        if (action == "Update") {
            printText="Updated";
        } else {
            printText=(action + "ed");
        }
        
        // Print message
        HideProgressBar();
        SetMessageBoxText("Failure:","The theme " + themeName + " was not " + printText + ".");
        ShowMessageBoxClose();
        
        // Send native notification
        sendNotification("Failure: The theme " + themeName + " was not " + printText + ".");
    }
}

//-------------------------------------------------------------------------------------
function disableInterface()
{
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
}      

//-------------------------------------------------------------------------------------
function enableInterface()
{
    // Re-enable drop down menu and open button
    $("#partitionSelect").prop("disabled", false);
    $("#OpenPathButton").prop("disabled", false);
            
    // Hide message to notify checking for updates
    $("#CheckingUpdatesMessage").css("display","none");
            
    // Hide Overlay Box to allow user to interact with buttons
    HideOverlayTwoBox();    
}        

//-------------------------------------------------------------------------------------
function SetThumbnailSize(width,height)
{
    // function ChangeThumbnailSize() changes thumb size +/- 25px
    // So call it number of times necessary to achieve wanted width
        
    if (width != "" & height != "") {
        var currentThumbWidth = $(".thumbnail img").first().width();
        if (currentThumbWidth > width) {
            var timesDifference=((currentThumbWidth-width)/25)
            for (s = 0; s < timesDifference; s++) {
                 ChangeThumbnailSize('smaller');
            }
        } else if (currentThumbWidth < width) {
            var timesDifference=((width-currentThumbWidth)/25)
            for (s = 0; s < timesDifference; s++) {
                ChangeThumbnailSize('larger');
            }
        }
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
        
        // Send a message to the bash script to fetch new theme list.
        macgap.app.launch("CTM_selectedPartition@" + selectedPartition);
        
        // The bash script will send back:
        // 1 - A list of themes.
        // 2 - Any themes from user prefs marked with an update available.
        // 3 - Any themes flagged as orphaned (ie. not parent bare clone).
        // These will be picked up by function readBashToJsMessageFile()

        // As long as the user did not select the 'Please Choose' menu option.
        if (selectedPartition != "-") {
        
            // Show Overlay Box to stop user interacting with buttons
            disableInterface(); // it's re-enabled by actOnUpdates()
            
            // Show the Free Space text
            ShowFreeSpace();
            
        } else {
            // Hide open button beside device dropdown
            $("#OpenPathButton").css("display","none");

            // Hide the Free Space text
            HideFreeSpace();
        }
        
        // Honour users choice of which themes to view (All or just Installed)
        GetShowHideButtonStateAndUpdateUI();
        
        // Reset current theme list, bands and buttons
        ResetButtonsAndBandsToDefault();
        hideButtons();
        
        // show all themes, even if asked to hide uninstalled
        $(".accordion").css("display","block");
    });
    
    //-----------------------------------------------------
    // On pressing the open path button
    $("#OpenPathButton").on('click', function() {
        macgap.app.launch("OpenPath");
    });
    
    //-----------------------------------------------------
    // On pressing the mount ESP button
    $("#MountEspButton").on('click', function() {
        macgap.app.launch("MountESP");
        // Show a message to the user
        ChangeMessageBoxHeaderColour("blue");                            
        SetMessageBoxText("EFI System Partition(s)","All currently unmounted EFI System Partitions will now be mounted and checked for a /EFI/Clover/Themes directory. If found, the paths will appear in the volume selector.");
        HideMessageBoxClose();
        ShowProgressBar();
        ShowMessageBox();
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
        enableInterface();
    });
    
    //-----------------------------------------------------
    // On clicking a thumbnail image
    $('.thumbnail').click(function() {
        var hidden = $(this).closest("#ThemeBand").nextAll('[class="accordionContent"]').first().is(":hidden");
        if (!hidden) {
            $(this)                                  // Start with current
            .closest("#ThemeBand")                   // Traverse up the DOM to the ThemeBand div
            .nextAll('[class="accordionContent"]')   // find the next siblings with class .accordionContent
            .first()                                 // just use first one
            .slideUp('normal');                      // Slide up
        } else {
            $(this)
            .closest("#ThemeBand")
            .nextAll('[class="accordionContent"]')
            .first()
            .slideToggle('normal');
        }
    });
    
    //-----------------------------------------------------
    // On clicking the Hide / Show Thumbnails button
    $("#BandsHeightToggleButton").on('click', function() {
    
        var textState = $(this).text();
        if (textState.indexOf("Hide") >= 0) {
            SetThemeBandHeight("Hide");
            // Send a message to the bash script to record user choice in prefs
            macgap.app.launch("CTM_showThumbails");
        }
        if (textState.indexOf("Show") >= 0) {     
            SetThemeBandHeight("Show");   
            // Send a message to the bash script to record user choice in prefs
            macgap.app.launch("CTM_hideThumbails");
        }
    });
        
    //-----------------------------------------------------
    // On clicking the Toggle Preview button - change to Expand/Collapse All
    $("#preview_Toggle_Button").click(function() {

        var buttonText=$(this).text();
        if (buttonText.indexOf("Expand") >= 0) {
            SetShowHidePreviews("Show");
            // Send a message to the bash script to record user choice in prefs
            macgap.app.launch("CTM_showPreviews");
        }
        if (buttonText.indexOf("Collapse") >= 0) {
            SetShowHidePreviews("Hide");
            // Send a message to the bash script to record user choice in prefs
            macgap.app.launch("CTM_hidePreviews");
        }
    });	
    
    //-----------------------------------------------------
    // On clicking the Hide UnInstalled / Show All button
    $("#ShowHideToggleButton").on('click', function() {
    
        // Change text of button
        var textState = $(this).text();
        if (textState.indexOf("Hide") >= 0) {
            SetShowHideButton("Hide");
            // Send a message to the bash script to record user choice in prefs
            macgap.app.launch("CTM_showUninstalled");
            // Close all preview images for UnInstalled themes
            ClosePreviewsForUninstalledThemes();
        }
        if (textState.indexOf("Show") >= 0) {     
            SetShowHideButton("Show");   
            // Send a message to the bash script to record user choice in prefs
            macgap.app.launch("CTM_hideUninstalled");
        }
    });
    
    //-----------------------------------------------------
    // On clicking the Thumbnail Smaller button
    $("#thumbSizeSmaller").on('click', function() {
        ChangeThumbnailSize('smaller');
    });
    
    //-----------------------------------------------------
    // On clicking the Thumbnail Larger button
    $("#thumbSizeLarger").on('click', function() {
        ChangeThumbnailSize('larger');
    });
    
    //-----------------------------------------------------
    // On clicking a version X mark
    $("[id^=indicator]").on('click', function() {
        // Show a message to the user
        ChangeMessageBoxHeaderColour("blue");                            
        SetMessageBoxText("Untracked Theme","This theme was not installed by Clover Theme Manager. This means you will not be notified of any updates for this theme unless you UnInstall and then re-install it.");
        ShowMessageBoxClose();
        ShowMessageBox();
    });
    
    //-----------------------------------------------------
    // On clicking the theme count question mark
    $("#NumInstalledThemesQuery").on('click', function() {
        // Show a message to the user
        ChangeMessageBoxHeaderColour("blue");                            
        SetMessageBoxText("Unknown Theme Detected","There is a theme in this path with a name that does not match any in the Clover repository. This is not a problem, just be aware the number of installed themes shown in the main list will not match the counter.");
        ShowMessageBoxClose();
        ShowMessageBox();
    });
    
    //-----------------------------------------------------
    // On changing the 'NVRAM theme' dropdown menu.
    $("#installedThemeDropDown").change(function() {
        var chosenNvramTheme=$("#installedThemeDropDown").val();
        if(chosenNvramTheme != "-") {
            // Send massage to bash script to notify setting of NVRAM variable.
            macgap.app.launch("CTM_chosenNvramTheme@" + chosenNvramTheme);
        }
    });
    
    //-----------------------------------------------------
    // On clicking the Snow button
    $("#SnowToggleButton").on('click', function() {
        var textState = $(this).text();
        if (textState.indexOf("Snow Off") >= 0) {
            ToggleSnow("Off");
            macgap.app.launch("CTM_Snow@Off");
        } else {  
            ToggleSnow("On");
            macgap.app.launch("CTM_Snow@On");
        }
    });
});

//-------------------------------------------------------------------------------------
function SetShowHidePreviews(state)
{
    var accordionBandState=$('.accordion').is(":hidden");
    if(state == "Show") {
        if (accordionBandState) {
            $(".accordionInstalled").next('[class="accordionContent"]').slideDown('normal');
            $(".accordionUpdate").next('[class="accordionContent"]').slideDown('normal');
        } else {
            $(".accordion").next('[class="accordionContent"]').slideDown('normal');
            $(".accordionInstalled").next('[class="accordionContent"]').slideDown('normal');
            $(".accordionUpdate").next('[class="accordionContent"]').slideDown('normal');
        }
        $("#preview_Toggle_Button").text("Collapse Previews");
        $("#preview_Toggle_Button").css("background-image","-webkit-linear-gradient(top, rgba(0,0,0,1) 0%,rgba(82,82,82,1) 100%)");
        $("#preview_Toggle_Button").css("border","1px solid #000");
        $("#preview_Toggle_Button").css("color","#82f3ff");
    } else if (state == "Hide") {
        if (accordionBandState) {
            $(".accordionInstalled").next('[class="accordionContent"]').slideUp('normal');
            $(".accordionUpdate").next('[class="accordionContent"]').slideUp('normal');
        } else {
            $(".accordion").next('[class="accordionContent"]').slideUp('normal');
            $(".accordionInstalled").next('[class="accordionContent"]').slideUp('normal');
            $(".accordionUpdate").next('[class="accordionContent"]').slideUp('normal');
        }
        $("#preview_Toggle_Button").text("Expand Previews");
        $("#preview_Toggle_Button").css("background-image","-webkit-linear-gradient(top, rgba(110,110,110,1) 0%,rgba(0,0,0,1) 100%)");
        $("#preview_Toggle_Button").css("border","1px solid #282828");
        $("#preview_Toggle_Button").css("color","#FFF");
    }
}

//-------------------------------------------------------------------------------------
function SetShowHideButton(state)
{
    if(state == "Hide") {
        $("#ShowHideToggleButton").text("Show All");
        $("#ShowHideToggleButton").css("background-image","-webkit-linear-gradient(top, rgba(0,0,0,1) 0%,rgba(82,82,82,1) 100%)");
        $("#ShowHideToggleButton").css("border","1px solid #000");
        $("#ShowHideToggleButton").css("color","#82f3ff");
        GetShowHideButtonStateAndUpdateUI();
    } else if (state == "Show") {
        $("#ShowHideToggleButton").text("Hide UnInstalled");
        $("#ShowHideToggleButton").css("background-image","-webkit-linear-gradient(top, rgba(110,110,110,1) 0%,rgba(0,0,0,1) 100%)");
        $("#ShowHideToggleButton").css("border","1px solid #282828");
        $("#ShowHideToggleButton").css("color","#FFF");
        GetShowHideButtonStateAndUpdateUI();
    }
}

//-------------------------------------------------------------------------------------
function SetThemeBandHeight(setting)
{
    if (setting == "Hide") {
    
            // Hide + and - buttons
            $("#thumbSizeSmaller").css("display","none");
            $("#thumbSizeLarger").css("display","none");
            // Show spacer sml buttons to retain spacing of other buttons
            $(".spacerButtonSml").css("display","block");
            // Move theme titles up
            $("[id=ThemeText]").css("top","68%");
            // Hide all theme descriptions
            $(".themeDescription").css("display","none");
            // Hide all theme authors
            $(".themeAuthor").css("display","none");
            // Hide thumbnails
            $(".thumbnail").css("display","none");
            // Adjust height of theme bands
            $(".accordion").css("height","36px");
            $(".accordionInstalled").css("height","36px");
            $(".accordionUpdate").css("height","36px");
            // Reduce margin top of buttons
            $(".buttonInstall").css("margin-top","6px");
            $(".buttonUnInstall").css("margin-top","6px");
            $(".buttonUpdate").css("margin-top","6px");
            // Reduce margin top of Unversioned Themes Indicator
            $(".versionControl").css("margin-top","9px");
            // Add margin left to theme titles
            $("[id=ThemeText]").css("margin-left","32px");
            // Change button text
            $("#BandsHeightToggleButton").text("Show Thumbnails");
            // Set background colour to indicate its selected
            $("#BandsHeightToggleButton").css("background-image","-webkit-linear-gradient(top, rgba(0,0,0,1) 0%,rgba(82,82,82,1) 100%)");
            $("#BandsHeightToggleButton").css("border","1px solid #000");
            $("#BandsHeightToggleButton").css("color","#82f3ff");
            
    } else if (setting == "Show") {

            // Show + and - buttons
            $("#thumbSizeSmaller").css("display","block");
            $("#thumbSizeLarger").css("display","block");
            // Hide spacer sml buttons to retain spacing of other buttons
            $(".spacerButtonSml").css("display","none");
            // Revert theme titles margin top
            $("[id=ThemeText]").css("top","50%");
            // Show all theme descriptions
            $(".themeDescription").css("display","inline");
            // Show all theme authors
            $(".themeAuthor").css("display","inline");
            // Show thumbnails
            $(".thumbnail").css("display","block");
            // Adjust height of theme bands
            var currentThumbHeight = $(".thumbnail img").first().height();
            var accordionHeight = (currentThumbHeight+14);
            $(".accordion").css("height",accordionHeight);
            $(".accordionInstalled").css("height",accordionHeight);
            $(".accordionUpdate").css("height",accordionHeight);
            // Revert margin top of buttons
            // Note: When thumb=100px wide, default button top=24px
            var currentThumbWidth = $(".thumbnail img").first().width();
            var buttonMarginAdjustment = (((currentThumbWidth-100)/25)*7);
            var buttonMarginTop = (24 + buttonMarginAdjustment);
            $(".buttonInstall").css("margin-top",buttonMarginTop);
            $(".buttonUnInstall").css("margin-top",buttonMarginTop);
            $(".buttonUpdate").css("margin-top",buttonMarginTop);
            // Revert margin top of Unversioned Themes Indicatpor
            // Note: When thumb=100px wide, default margin top=28px
            var versionControlMarginTop = (28 + buttonMarginAdjustment);
            $(".versionControl").css("margin-top",versionControlMarginTop);
            // Remove added margin left to theme titles
            $("[id=ThemeText]").css("margin-left","0px");
            // Change button text
            $("#BandsHeightToggleButton").text("Hide Thumbnails");
            // Revert background colour
            $("#BandsHeightToggleButton").css("background-image","-webkit-linear-gradient(top, rgba(110,110,110,1) 0%,rgba(0,0,0,1) 100%)");
            $("#BandsHeightToggleButton").css("border","1px solid #282828");
            $("#BandsHeightToggleButton").css("color","#FFF");
            
    }
}

//-------------------------------------------------------------------------------------
function UpdateMessageBox(messageOne,messageTwo)
{
    HideProgressBar();
    if (messageOne != "" && messageTwo != "") {
        // Show a message to the user
        ChangeMessageBoxHeaderColour("blue"); 
        if (messageOne == 'Mounted') {
            if (messageTwo == '0') {
                SetMessageBoxText("EFI System Partition(s)","There are no unmounted EFI system partitions with an existing /EFI/Clover/Themes directory.");
            } else {
                ChangeMessageBoxHeaderColour("green");
                SetMessageBoxText("EFI System Partition(s)","Number of EFI system partitions with an existing /EFI/Clover/Themes directory mounted just now:<br><br>" + messageTwo);

                // Honour users choice of which themes to view (All or just Installed)
                GetShowHideButtonStateAndUpdateUI();
        
                // Reset current theme list, bands and buttons
                ResetButtonsAndBandsToDefault();
                hideButtons();
        
                // show all themes, even if asked to hide uninstalled
                $(".accordion").css("display","block");
            }
        }
        ShowMessageBoxClose();
        ShowMessageBox();
    }
}

//-------------------------------------------------------------------------------------
function ChangeThumbnailSize(action)
{
    // Adjust the width of each thumbnail image by 25px each time this is called.
    // Each adjustment also alters:
    // - thumbnail height and theme band height.
    // - Y position of buttons and version control indicator.
    // - width of title, author and description text box.
    
    var currentThumbWidth = $(".thumbnail img").first().width();
    var currentThumbHeight = $(".thumbnail img").first().height();
    var currentAccordionHeight = $(".accordion").first().height();
    var currentThemeTextWidth = $("#ThemeText").first().width();
    if (action=='larger' && currentThumbWidth <= 175) {
        var newAccordionHeight=(currentAccordionHeight+14);
        var newThumbWidth=(currentThumbWidth+25);
        var newThumbHeight=(currentThumbHeight+14);
        var newThemeTextWidth=(currentThemeTextWidth-30);
    } else if (action=='smaller' && currentThumbWidth >= 125) {
        var newAccordionHeight=(currentAccordionHeight-14);
        var newThumbWidth=(currentThumbWidth-25);
        var newThumbHeight=(currentThumbHeight-14);
        var newThemeTextWidth=(currentThemeTextWidth+30);
    } else {
        newThemeTextWidth=currentThemeTextWidth;
    }
    
    //alert(currentThumbWidth+","+action+","+currentThemeTextWidth+","+newThemeTextWidth);     
    
    // Only make changes if thumbnail width has changed
    if (newThumbWidth != currentThumbWidth) {
        // Adjust height of theme bands
        $(".accordion").css("height",newAccordionHeight);
        $(".accordionInstalled").css("height",newAccordionHeight);
        $(".accordionUpdate").css("height",newAccordionHeight);
            
        // Change thumbnail size
        $(".thumbnail img").css("width",newThumbWidth);
        $(".thumbnail img").css("height",newThumbHeight);
            
        // Change margin top of buttons
        var buttonHeight = $(".buttonInstall").first().outerHeight();
        var newButtonTop = ((newAccordionHeight-buttonHeight)/2);
        $(".buttonInstall").css("margin-top",newButtonTop);
        $(".buttonUnInstall").css("margin-top",newButtonTop);
        $(".buttonUpdate").css("margin-top",newButtonTop);
            
        // Change margin top of version control indicator
        $(".versionControl").css("margin-top",newButtonTop+3);
            
        // Reduce width of theme text (by 30px) to retain space for update button
        $("[id^=ThemeText]").width(newThemeTextWidth);
            
        // Send a message to the bash script to record thumbnail width
        if (newThumbWidth >= 100 && newThumbWidth <= 200)
            macgap.app.launch("CTM_thumbSize@" + newThumbWidth + " " + newThumbHeight);
    }
}

//-------------------------------------------------------------------------------------
function GetShowHideButtonStateAndUpdateUI()
{
    var showHideState=$("[id='ShowHideToggleButton']").text();
    var expandCollapseState=$("[id='preview_Toggle_Button']").text();
    if (showHideState.indexOf("Hide") >= 0) {
        showHideState="Hide";
    } else if (showHideState.indexOf("Show") >= 0) {
        showHideState="Show";
    }
    ShowHideUnInstalledThemes(showHideState,expandCollapseState);
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
function RespondToButtonPress(button,status)
{
    // Update buttons have a class name 'button_Update_' and not 'button_'
    // The bash script matches against the string 'button_'
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
    // Read position of box and only fade in if at default off screen position.
    var position = $('#box').position();
    if (position.top = -300) {   // starting position = should match .box top in css
        $('#overlay').fadeIn('fast',function(){
             // move box from current position so top=150px
             $('#box').animate({'top':'150px'},500, function(){
                 // Bounce
                 doBounce($('.box'), 2, '10px', 100);   
             }); 
        });
    }
}

//-------------------------------------------------------------------------------------
// from http://stackoverflow.com/questions/10363671/jquery-bounce-effect-on-click-no-jquery-ui
function doBounce(element, times, distance, speed) {
    for(var i = 0; i < times; i++) {
        element.animate({marginTop: '-='+distance}, speed)
            .animate({marginTop: '+='+distance}, speed);
    }        
}
             
//-------------------------------------------------------------------------------------
function CloseMessageBox()
{
    // Read position of box and only fade out if at calculated top position is 150px which is set in ShowMessageBox()
    var position = $('#box').position();
    if (position.top = 150) {
        $('#box').animate({'top':'-300px'},500,function(){  // starting position = should match .box top in css
            $('#overlay').fadeOut('fast');
        });
    }
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
    $("[id^=indicator_]").css("pointer-events","none");
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
    
    // set the vertical position to match the uninstall button
    var uninstallButtonTop=$("[id='button_" + themeName + "']").css("margin-top");
    $("[id='button_Update_" + themeName + "']").css("margin-top",uninstallButtonTop);
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
    //$("[id='indicator_" + themeName + "']").html("\u2715");
    $("[id='indicator_" + themeName + "']").html("?");
    $("[id='indicator_" + themeName + "']").css("pointer-events","auto");
}

//-------------------------------------------------------------------------------------
function UpdateAndRefreshPartitionSelectMenu(list)
{
    // Clear existing entries
    $(partitionSelect).empty();
      
    // Add title menu option
    $("#partitionSelect").append("<option value=\"-\">Select your target theme directory:</option>");
    
    if (list != "") {
        splitList = (list).split(',');
        for (var t = 0; t < splitList.length; t++) {
            var parts = (splitList[t]).split(';');
            var id = (parts[0]);
            var desc = (parts[1]);
            $("#partitionSelect").append("<option value=\"" + id + "\">" + desc + "</option>");
        }
    }
}

//-------------------------------------------------------------------------------------
function UpdateAndRefreshInstalledThemeDropDown(themeList)
{
    // Clear any existing entries
    $(installedThemeDropDown).empty();

    if (themeList != "-") {
        // Add title option with - value
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
        macgap.app.launch("CTM_updateApp:No");
        
        // Hide message box and reset
        CloseMessageBox();
        ShowMessageBoxClose();
        RemoveYesNoButtons();
        enableInterface();
        
    }).insertAfter("[id='FeedbackButtons']");
    
    // Set button text
    $("[id='feedback_Button_No']").html("No");
    
    // Add button Yes
    $( '<div class="feedbackButton" id="feedback_Button_Yes"></div>' ).on('click', function(e) {
        e.preventDefault();
        // Send message back to bash script to notify receipt
        
        // Update message box
        RemoveYesNoButtons();
        macgap.app.launch("CTM_updateApp:Yes");
        // Show progress bar while files are downloaded.
        SetMessageBoxText("Application Update Available:","Downloading files from repository and applying update.");
        ShowProgressBar();
    
    }).insertAfter("[id='FeedbackButtons']");
    
    // Set button text
    $("[id='feedback_Button_Yes']").html("Yes");
}

//-------------------------------------------------------------------------------------
function AddQuitButton(){

    // Add button No
    $( '<div class="feedbackButton" id="feedback_Button_Quit"></div>' ).on('click', function(e) {
        e.preventDefault();
        // Terminate the app
        macgap.app.terminate(); 
        
    }).insertAfter("[id='FeedbackButtons']");

    // Set button text
    $("[id='feedback_Button_Quit']").html("Quit");
}

//-------------------------------------------------------------------------------------
function RemoveYesNoButtons(){
    $("[id^=feedback_Button]").remove(); 
}

//-------------------------------------------------------------------------------------
function SetNvramFooterToNotSet(){
    $("#currentNVRAMvar").text("NVRAM theme: Not set:"); 
    $("#currentNVRAMMessage").text(""); 
    $("#AboveFooter").css("background-image","-webkit-linear-gradient(top, rgba(195,195,195,1) 0%,rgba(123,123,123,1) 100%)");
}

//-------------------------------------------------------------------------------------
function ShowHideUnInstalledThemes(showHide,expandCollapse)
{        
    if (showHide.indexOf("Show") >= 0) {

        if (expandCollapse.indexOf("Expand") >= 0) {
            $(".accordion").css("display","none");
        }
        if (expandCollapse.indexOf("Collapse") >= 0) {
            $(".accordion").css("display","none");
            $(".accordion").next('[class="accordionContent"]').css("display","none");
        }
    } else if (showHide.indexOf("Hide") >= 0) {   

        if (expandCollapse.indexOf("Expand") >= 0) {
            $(".accordion").css("display","block");
        }
        if (expandCollapse.indexOf("Collapse") >= 0) {
            $(".accordion").css("display","block");
            $(".accordion").next('[class="accordionContent"]').css("display","block");
        }   
    }
}

//-------------------------------------------------------------------------------------
function ClosePreviewsForUninstalledThemes()
{
    // Close all preview images for UnInstalled themes
    $('.buttonInstall').closest("#ThemeBand").next('[class="accordionContent"]').slideUp('normal');
}

//-------------------------------------------------------------------------------------
function ToggleSnow(action)
{
    if (action == "Off") {
        snowStorm.stop();
        $("#SnowToggleButton").text("Snow On");
    } else if (action == "On") {  
        snowStorm.resume();
        $("#SnowToggleButton").text("Snow Off");
    }
}

//-------------------------------------------------------------------------------------
function sendNotification(messageBody)
{
    // INSERT_NOTIFICATION_CODE_HERE
}
