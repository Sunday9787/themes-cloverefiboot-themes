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
var gTmpDir = "/tmp/CloverThemeManager/";
var gLogBashToJs = "CloverThemeManager_BashToJs.log";
var lastLine="-1";
var prevLastLine="";
var prevLastLineCount=0;
var eof=0;

//-------------------------------------------------------------------------------------
// On initial load
$(document).ready(function() {    
    macgap.app.launch("started")
    
    printLogtoScreen();
});

//-------------------------------------------------------------------------------------
// Called when the process is to close.
function terminate() {
    //clearTimeout(timerCheckEof);
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

// Read /tmp/CloverThemeManager/CloverThemeManagerLog.txt and print each line to screen.
// This was added to show the user that a process is happening and the app is not stuck
// at the initialisation screen.
// It also serves a purpose to include messages in the log for this function to interpret.
// Messages currently looked for are:
// - Complete!
// - CTM_Version
// - RepositoryError:

//-------------------------------------------------------------------------------------
function printLogtoScreen()
{
    eof=0;
    var redirect="managethemes.html"
    var splitContent="";
    fileContent=GetFileContents("CloverThemeManagerLog.txt");
    
    if (fileContent != 0) {
    
        // Print line by line
        splitContent = fileContent.split("@");
        lastLine = splitContent[splitContent.length-2];
          
        if (lastLine != prevLastLine) {
            for (i = prevLastLineCount; i <= splitContent.length; i++) {
 
                // Does this line contain CTM_Version?
                if (/CTM_Version/i.test(splitContent[i])) {
                    // remove anything before the 'CTM_Version' text.
                    version = splitContent[i].substring(splitContent[i].indexOf("CTM_Version") + 11);
                    // append version to title.
                    $("#textHeading").append("<span class=\"textVersion\"> v" + version + "</span>");
                } else if (/RepositoryError: /i.test(splitContent[i])) {
                    // This indicates the remote repository is not contactable.
                    // We should notify the user and exit
                    alert("Remote theme repository is not responding. This app cannot continue.");
                    terminate();
                } else if (/First run identified/i.test(splitContent[i])) {
                    // This indicates it's the first run and will take longer
                    // Print message
                    $("#firstRunMessage").text("First run may take a minute... Thanks for your patience.");
                } else {      
                    // Write line to log
                    if (typeof splitContent[i] !== "undefined" && typeof splitContent[i] !== "null" && splitContent[i].length > 1) {
                        $("#logToBeFilled").append(splitContent[i] + '<br>' );
                    }
                }
            }
            prevLastLineCount=splitContent.length-2;
            prevLastLineCount=prevLastLineCount+1
            prevLastLine = lastLine;
        }
        
        // Is the string 'Complete!' found in fileContent?
        if (/Complete!/i.test(fileContent)) {
            // stop this timer and set to not re-iterate this function
            clearTimeout(timerCheckEof);
            eof=1;
            
            //Redirect
            window.location = (redirect);

        } else {
            // recursively call function providing we haven't completed.
            if(eof==0)
                timerCheckEof = setTimeout(printLogtoScreen, 50);
        }
    }
    else
    {
        // recursively call function providing we haven't completed.
        if(eof==0)
            timerCheckEof = setTimeout(printLogtoScreen, 250);
    }
}
