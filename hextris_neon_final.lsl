// HEXTRIS NEON - Second Life Ultimate Script (Touch-Adaptive)
// Created by Gemini for Selami

string GAME_BASE_URL = "https://selami79.github.io/weboyun/index.html";
string my_url = "";
string current_player_name = "";
integer SCREEN_FACE = -1; // -1 means "Not set yet"

// High Score Data
list highScores = []; 
integer MAX_SCORES = 10;

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
    llSetText(text, <0,1,1>, 1.0);
}

LoadGame(integer face, string player_name)
{
    string final_url = GAME_BASE_URL + "?sl_url=" + llEscapeURL(my_url);
    if(player_name != "") {
        final_url += "&player=" + llEscapeURL(player_name);
    }
    
    // Debug: URL'in dogru olustugunu gorelim
    // llOwnerSay("Loading URL on Face " + (string)face + ": " + final_url);

    llSetPrimMediaParams(face, [
        PRIM_MEDIA_AUTO_PLAY, TRUE,
        PRIM_MEDIA_CURRENT_URL, final_url,
        PRIM_MEDIA_HOME_URL, final_url,
        PRIM_MEDIA_HEIGHT_PIXELS, 1024,
        PRIM_MEDIA_WIDTH_PIXELS, 1024,
        PRIM_MEDIA_PERMS_CONTROL, PRIM_MEDIA_PERM_NONE,
        PRIM_MEDIA_PERMS_INTERACT, PRIM_MEDIA_PERM_ANYONE,
        PRIM_MEDIA_FIRST_CLICK_INTERACT, TRUE,
        PRIM_MEDIA_AUTO_SCALE, FALSE, 
        PRIM_MEDIA_AUTO_ZOOM, FALSE
    ]);
}

default
{
    state_entry()
    {
        llRequestURL();
        llSetText("Loading System...", <1,0,0>, 1.0);
    }

    http_request(key id, string method, string body)
    {
        if (method == URL_REQUEST_GRANTED)
        {
            my_url = body;
            llOwnerSay("System Ready! Touch the screen to start.");
            DisplayHighScores();

            
            // Eger daha once bir yuzey secildiyse, orayi hazirla (oyuncu ismsiz)
            if(SCREEN_FACE != -1) LoadGame(SCREEN_FACE, "");
        }
        else if (method == "POST")
        {
            string name = llJsonGetValue(body, ["name"]);
            string score_str = llJsonGetValue(body, ["score"]);
            integer score = (integer)score_str;
            
            if(name != JSON_INVALID && score_str != JSON_INVALID) {
                UpdateHighScores(name, score);
                llHTTPResponse(id, 200, "OK");
                llSay(0, "New High Score! " + name + ": " + (string)score);
            }
        }
    }
    
    touch_start(integer total_number)
    {
        integer touched_face = llDetectedTouchFace(0);
        string new_player = llDetectedName(0);
        string touchedPrimName = llGetLinkName(llDetectedLinkNumber(0));
        
        if (touchedPrimName == "reset")
        {
            llRequestURL();
            return;
        }

        if(touched_face == -1) {
            llOwnerSay("Error: Couldn't detect touched face.");
            return;
        }

        // Ilk kez dokunuluyorsa veya farkli bir yuzeye dokunulduysa
        if(SCREEN_FACE != touched_face) {
            SCREEN_FACE = touched_face;
            llOwnerSay("Screen Face Set to: " + (string)SCREEN_FACE);
        }

        // Oyunu, dokunan kisisin ismine ozel olarak yukle
        // current_player_name != new_player kontrolunu kaldirdim, boylece her tiklamada (reset amacli) calisir.
        current_player_name = new_player;
        llSay(0, "Hosgeldin " + current_player_name + "! Oyun yukleniyor...");
        LoadGame(SCREEN_FACE, current_player_name);
    }
    
    on_rez(integer start_param) { llResetScript(); }
    changed(integer change) { if(change & CHANGED_REGION) llRequestURL(); }
}
