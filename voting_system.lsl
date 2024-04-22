/*
 * name:        Votting Machine
 * version:     1.0.0
 * function:    Turns a simple object into a voting machine.
 * created:     Mar 11, 2024
 * created by:  Mithos Anatra <mithos.anatra>
 * license:     GPL-3
 *              see <https://www.gnu.org/licenses/gpl-3.0.txt>
 ***********************************************************
 * This program is free software: you can redistribute it and/or modify
 *   it under the terms of the GNU General Public License as published by
 *   the Free Software Foundation, either version 3 of the License, or
 *   (at your option) any later version.
 *
 *   This program is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU General Public License for more details.
 *
 *   You should have received a copy of the GNU General Public License along 
 *   with this program.  If not, see <https://www.gnu.org/licenses/gpl-3.0.txt>
 */


// A list with the options available to voters.
// This list comes from the config notecard line "options"
list user_menu;


//------- Hands up --------
// Dont change the following code unless you know
// what you are doing.

// Version of this script
string version = "v1.0.0"; 

// Name of the configuration notecard
string config_nc = "config"; 

// Notecard line number (starts on 0)
integer nc_line_num = 0;

// Total notecard lines
integer nc_line_count;  

// Channel used by the admin menu
integer admin_dlg_chan = -1042; 

// Channel used by users menu
integer users_dlg_chan = -1043;

// The options available to the admin
list admin_menu = ["Reset","Results","Users Menu","Version"]; 

// List of avatars that already voted
list voters_list;

// List of  available config options
list config_options = [ "options"];

// Notecard line query id
key nc_qry;             

// The object's owner id
key owner_id;           

// Toucher id.
key user_id;            

// Print "text" in Owner's chat (only the owner can see).
say(string text){
    llOwnerSay(text);
}


// Show results to the admin(owner)
show_results(){
    integer list_index=0;
    integer list_length=llGetListLength(user_menu);
    while(list_index < list_length){
        string  opt = llList2String(user_menu,list_index);
        string opt_val = llLinksetDataRead(opt);
        say(opt + ": "+opt_val);
        list_index++;    
    }
//    say("Voters list: "+llLinksetDataRead("voters"));
}

// Admin  menu processing function
process_admin_menu(string  message){

    if(message == "Version"){
      say("Voting Script version: "+version);
      llDialog(user_id, "Admin Menu\n", admin_menu, admin_dlg_chan);
    }
    if(message == "Users Menu"){
        llDialog(user_id, "Users Menu", user_menu, users_dlg_chan);
    }
    if(message == "Reset"){
        llResetScript();
    }
    if(message == "Results"){
        say("Showing results...");
        show_results();
        llDialog(user_id, "Admin Menu\n", admin_menu, admin_dlg_chan);
    }
}

// Checks if user has already voted
integer check_user(key voter){
    key listed_key;
    list temp_list = llCSV2List(llLinksetDataRead("voters"));
    integer li = 0;
    integer ll = llGetListLength(temp_list);
    integer check = 0;
    while(li < ll){
        listed_key = llList2Key(temp_list,li);
        if(voter==listed_key){
            check = 1;
            return(check);
        }
        li++;
    }
    return(check);
    
}

// User menu processing function
process_user_menu(string  msg, key voter){
    integer i = (integer)llLinksetDataRead(msg);
    i = i+1;
    llLinksetDataWrite(msg,(string)i);
    voters_list = voters_list+(string)voter;
    llLinksetDataWrite("voters",llList2CSV(voters_list));
    llInstantMessage(voter, "Your choice: "+msg);
}


// Initialize the system resetting values
init(){
    say("Initializing voting system...");
    // Gets the owner id
    owner_id = llGetOwner();
    // Sets the menu options to none.
    // Checks if we have a notecard named "config"
    // If not, returns an error message
    // else, read the first line in the config notecard
    if(llGetInventoryKey(config_nc) == NULL_KEY){
        say("ERROR:");
        say("Missing config notecard");
        return;
    } else {
        nc_line_num;
        nc_qry = llGetNotecardLine(config_nc,nc_line_num);
    }
    llListen(admin_dlg_chan,"","","");
    llListen(users_dlg_chan,"","","");
    llLinksetDataReset();
}

load_config(string config_data){
    if(llSubStringIndex(config_data,"#") != 0){
        integer i = llSubStringIndex(config_data, "=");
        if(i != -1){
            say("The following settings were found:");
            string temp_substr = llGetSubString(config_data,0,i-1);
            if(temp_substr == "options"||temp_substr == "options "){
                integer l = llStringLength(config_data);
                string temp_string = llGetSubString(config_data,i+1,l-1);
                say("  options: "+ temp_string);
                user_menu = llCSV2List(temp_string);
                llLinksetDataWrite(temp_string,"0");
                llLinksetDataWrite("voters",llList2CSV(voters_list));
            }
        }
    }
    
}

default{
    // If the object has changed (notecard or script content)
    // reset script and values
    changed(integer change){
        if(change & CHANGED_INVENTORY){
            llResetScript();
        }
        if(change & CHANGED_OWNER){
            llResetScript();
        }
    }
    
    
    state_entry(){
        init();
    }
    
    dataserver(key qry_id, string qry_data){
        if(qry_id == nc_qry){
            if(qry_data == EOF){
                say("Finished reading config notecard");
            } else {
                load_config(qry_data);
                nc_line_num++ ;
                nc_qry = llGetNotecardLine(config_nc,nc_line_num);
            }
        }
    }
    
    touch_start(integer num_touch){
        user_id = llDetectedKey(0);
        if(user_id == owner_id){
            llDialog(user_id, "Admin Menu\n", admin_menu, admin_dlg_chan);
        } else {
            llDialog(user_id, "Users Menu", user_menu, users_dlg_chan);
        }
    }
     
    listen(integer chan, string name, key  toucher_id,  string message){
        if(chan == admin_dlg_chan){
            process_admin_menu(message);
        }else{
            integer allowed_voter = check_user(user_id);
            if(allowed_voter == 0){
                process_user_menu(message, toucher_id);
            }else{
                llInstantMessage(user_id,"Sorry. You can only vote once.");
            }
        }
               
    }
}

