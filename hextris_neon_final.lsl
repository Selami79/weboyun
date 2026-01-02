// HEXTRIS NEON - Second Life Ultimate Script (Production Version)
// Created by Gemini for Selami

string GAME_BASE_URL = "https://selami79.github.io/weboyun/index.html";
string my_url = "";
string current_player_name = "";
integer SCREEN_FACE = -1; 
integer RESET_PRIM_LINK = -1; 
// High Score Data
list highScores = []; 
integer MAX_SCORES = 10;

FindResetPrim()
{
    integer i;
    integer prims = llGetNumberOfPrims();
    RESET_PRIM_LINK = -1;
    
    if(prims == 1) {
        if(llGetObjectName() == "reset") RESET_PRIM_LINK = 0;
    } 
    else {
        for(i=1; i<=prims; ++i) {
            string name = llGetLinkName(i);
            if(name == "reset") RESET_PRIM_LINK = i;
        }
    }
}

UpdateHighScores(string name, integer score)
{
    highScores += [score, name];
    highScores = llListSort(highScores, 2, FALSE); // Sort Descending
    if(llGetListLength(highScores) > MAX_SCORES * 2) {
        highScores = llList2List(highScores, 0, (MAX_SCORES * 2) - 1);
    }
    DisplayHighScores();
}

DisplayHighScores()
{
    string text = "🏆 NEON HEX TOP 10 🏆\n\n";
    integer len = llGetListLength(highScores);
    integer i;
    for(i=0; i<len; i+=2) {
        integer score = llList2Integer(highScores, i);
        string name = llList2String(highScores, i+1);
        text += (string)((i/2)+1) + ". " + name + " - " + (string)score + "\n";
    }
    
    llSetText("", <0,0,0>, 0.0);
    
    if(RESET_PRIM_LINK != -1) {
        llSetLinkPrimitiveParamsFast(RESET_PRIM_LINK, [PRIM_TEXT, text, <0,1,1>, 1.0]);
    } else {
         llSetText(text, <0,1,1>, 1.0);
    }
}

LoadGame(integer face, string player_name)
{
    string final_url = GAME_BASE_URL + "?sl_url=" + llEscapeURL(my_url);
    if(player_name != "") {
        final_url += "&player=" + llEscapeURL(player_name);
    }
    
    llSetPrimMediaParams(face, [
        PRIM_MEDIA_AUTO_PLAY, TRUE,
        PRIM_MEDIA_CURRENT_URL, final_url,
        PRIM_MEDIA_HOME_URL, final_url,
        PRIM_MEDIA_HEIGHT_PIXELS, 1024,
        PRIM_MEDIA_WIDTH_PIXELS, 1024,
        PRIM_MEDIA_PERMS_CONTROL, PRIM_MEDIA_PERM_NONE,
        PRIM_MEDIA_PERMS_INTERACT, PRIM_MEDIA_PERM_ANYONE,
        PRIM_MEDIA_FIRST_CLICK_INTERACT, TRUE,
        PRIM_MEDIA_AUTO_SCALE, TRUE, 
        PRIM_MEDIA_AUTO_ZOOM, TRUE
    ]);
}

default
{
    state_entry()
    {
        FindResetPrim();
        llRequestSecureURL(); 
        if(RESET_PRIM_LINK != -1) llSetLinkPrimitiveParamsFast(RESET_PRIM_LINK, [PRIM_TEXT, "Loading High Scores...", <0,1,1>, 1.0]);
    }

    http_request(key id, string method, string body)
    {
        if (method == URL_REQUEST_GRANTED)
        {
            my_url = body;
            llOwnerSay("System Ready. Secure URL Generated.");
            DisplayHighScores(); 
        }
        else if (method == "POST")
        {
            // CORS Handling (Simplified for Production)
            string name = llJsonGetValue(body, ["name"]);
            string score_str = llJsonGetValue(body, ["score"]);
            
            integer score = (integer)score_str;
            
            if(name != JSON_INVALID && score_str != JSON_INVALID) {
                UpdateHighScores(name, score);
                llHTTPResponse(id, 200, "OK");
                llSay(0, "✅ New High Score! " + name + ": " + (string)score);
            } else {
                llHTTPResponse(id, 400, "Bad JSON");
            }
        }
        else if (method == "OPTIONS")
        {
             // Preflight Check
             llHTTPResponse(id, 200, "OK");
        }
    }
    
    touch_start(integer total_number)
    {
        integer touched_link = llDetectedLinkNumber(0);
        string touched_name = llGetLinkName(touched_link);
        
        // --- RESET LOGIC ---
        if (touched_name == "reset" || (RESET_PRIM_LINK != -1 && touched_link == RESET_PRIM_LINK))
        {
            llSay(0, "🔄 Resetting Game Screen...");
            if(SCREEN_FACE != -1) {
                llClearPrimMedia(SCREEN_FACE); 
            } else {
                 llClearPrimMedia(0); llClearPrimMedia(1); llClearPrimMedia(2); llClearPrimMedia(3); llClearPrimMedia(4);
            }
            current_player_name = "";
            return;
        }

        // --- GAME START LOGIC ---
        integer touched_face = llDetectedTouchFace(0);
        if(touched_face == -1) return;

        if(SCREEN_FACE != touched_face) SCREEN_FACE = touched_face;

        string new_player = llDetectedName(0);
        current_player_name = new_player;
        
        llSay(0, "👋 Hosgeldin " + current_player_name + "! Oyun senin icin baslatiliyor...");
        LoadGame(SCREEN_FACE, current_player_name);
    }
    
    on_rez(integer start_param) { llResetScript(); }
    changed(integer change) { 
        if(change & CHANGED_REGION) llRequestSecureURL(); 
        if(change & CHANGED_LINK) FindResetPrim();
    }
}
