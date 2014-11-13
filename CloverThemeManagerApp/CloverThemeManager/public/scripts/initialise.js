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

//-------------------------------------------------------------------------------------
function redirectToMainPage()
{
    var redirect="managethemes.html"
    window.location = (redirect);
}

// Read /tmp/CloverThemeManager/CloverThemeManagerLog.txt looking for embedded 
// messages for showing the initialisation process.
//-------------------------------------------------------------------------------------
function printLogtoScreen()
{
    eof=0;
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
                    
                } else if (/CTM_HTMLTemplateOK/i.test(splitContent[i])) {
                           $("#check_HtmlTemplate").append( "  \u2713" );
                           $("#status_HtmlTemplate").css("color","#FFF"); 
                } else if (/CTM_HTMLTemplateFail/i.test(splitContent[i])) {
                           $("#status_HtmlTemplate").css("color","#DD171B");
                           
                } else if (/CTM_RepositorySuccess/i.test(splitContent[i])) {
                           $("#check_Repository").append( "  \u2713" );
                           $("#status_Repository").css("color","#FFF"); 
                } else if (/CTM_RepositoryError/i.test(splitContent[i])) {
                           $("#status_Repository").css("color","#DD171B");
                           alert("Remote theme repository is not responding. This app cannot continue.");
                           terminate();
                           
                } else if (/CTM_SupportDirOK/i.test(splitContent[i])) {
                           $("#check_SupportDir").append( "  \u2713" );
                           $("#status_SupportDir").css("color","#FFF"); 
                } else if (/CTM_SupportDirFail/i.test(splitContent[i])) {
                           $("#status_SupportDir").css("color","#DD171B");
                           
                } else if (/CTM_SymbolicLinksOK/i.test(splitContent[i])) {
                           $("#check_SymbolicLink").append( "  \u2713" );
                           $("#status_SymbolicLink").css("color","#FFF"); 
                } else if (/CTM_SymbolicLinksFail/i.test(splitContent[i])) {
                           $("#status_SymbolicLink").css("color","#DD171B");
                           
                } else if (/CTM_IndexCloneAndCheckout/i.test(splitContent[i])) {
                           $("#status_Index").text( 'Cloning index.git' ).append( '<span class="checkMark" id="check_Index"></span>' );
                           $("#status_Index").css("color","#FFAE40"); 
                } else if (/CTM_IndexOK/i.test(splitContent[i])) {
                           $("#check_Index").append( "  \u2713" );
                           $("#status_Index").css("color","#FFF"); 
                } else if (/CTM_IndexFail/i.test(splitContent[i])) {
                           $("#status_Index").css("color","#DD171B");
                           
                } else if (/CTM_ThemeListOK/i.test(splitContent[i])) {
                           $("#check_ThemeList").append( "  \u2713" );
                           $("#status_ThemeList").css("color","#FFF"); 
                } else if (/CTM_ThemeListFail/i.test(splitContent[i])) {
                           $("#status_ThemeList").css("color","#DD171B");
                           
                } else if (/CTM_InsertHtmlOK/i.test(splitContent[i])) {
                           $("#check_InsertHtml").append( "  \u2713" );
                           $("#status_InsertHtml").css("color","#FFF"); 
                } else if (/CTM_InsertHtmlFail/i.test(splitContent[i])) {
                           $("#status_InsertHtml").css("color","#DD171B");
                           
                } else if (/CTM_ThemeDirsOK/i.test(splitContent[i])) {
                           $("#check_ThemeDirs").append( "  \u2713" );
                           $("#status_ThemeDirs").css("color","#FFF"); 
                } else if (/CTM_ThemeDirsFail/i.test(splitContent[i])) {
                           $("#status_ThemeDirs").css("color","#DD171B");
                           
                } else if (/CTM_DropDownListOK/i.test(splitContent[i])) {
                           $("#check_Dropdown").append( "  \u2713" );
                           $("#status_Dropdown").css("color","#FFF"); 
                } else if (/CTM_DropDownListFail/i.test(splitContent[i])) {
                           $("#status_Dropdown").css("color","#DD171B");
                           
                } else if (/CTM_ReadPrefsOK/i.test(splitContent[i])) {
                           $("#check_ReadPrefs").append( "  \u2713" );
                           $("#status_ReadPrefs").css("color","#FFF"); 
                } else if (/CTM_ReadPrefsCreate/i.test(splitContent[i])) {
                           $("#check_ReadPrefs").append( "  \u2713" );
                           $("#status_ReadPrefs").text("Created Prefs");
                           $("#status_ReadPrefs").css("color","#FFF");
                           
                } else if (/CTM_InitInterface/i.test(splitContent[i])) {
                           $("#check_InitMainUI").append( "  \u2713" );
                           $("#status_InitMainUI").css("color","#FFF"); 

                } else if (/CTM_NvramFound/i.test(splitContent[i])) {
                           $("#check_NvramVar").append( "  \u2713" );
                           $("#status_NvramVar").css("color","#FFF"); 
                } else if (/CTM_NvramNotFound/i.test(splitContent[i])) {
                           $("#status_NvramVar").css("color","#DD171B");
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
            
            //Redirect after 1 second
            timerReadMessageFile = setTimeout(redirectToMainPage, 1000);


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

