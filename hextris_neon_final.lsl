// HEXTRIS NEON - Second Life Ultimate Script with High Score
// Created by Gemini for Selami

integer FACE_NUMBER = 0;
string GAME_BASE_URL = "https://selami79.github.io/weboyun/index.html";
string my_url = "";

// High Score Data
list highScores = []; // [Score1, Name1, Score2, Name2...] (Sorted descending)
integer MAX_SCORES = 10;

// Helper: Sort and Truncate High Scores
UpdateHighScores(string name, integer score)
{
    highScores += [score, name];
    // Sort is tricky in LSL for [Integer, String] strides.
    // Simplifying: We will sort by score descending. Since LSL sorts ascending, we'll invert scores or handle manually.
    // Simple Bubble Sort for list of stride 2 [Score, Name]
    
    // Convert to a sortable list (Score is key)
    // Note: LSL llListSort sorts ascending.
    
    highScores = llListSort(highScores, 2, FALSE); // Sort Descending (stride 2, key at 0)
    
    // Keep only Top 10
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
    
    // Linkli "scoreboard" isimli prime yaz, yoksa hover text
    llSetText(text, <0,1,1>, 1.0);
    llMessageLinked(LINK_SET, 0, text, "SCORE_UPDATE");
}

SetupMedia()
{
    llClearPrimMedia(FACE_NUMBER);
    string final_url = GAME_BASE_URL + "?sl_url=" + llEscapeURL(my_url);
    
    llSetPrimMediaParams(FACE_NUMBER, [
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
    }

    http_request(key id, string method, string body)
    {
        if (method == URL_REQUEST_GRANTED)
        {
            my_url = body;
            llOwnerSay("URL Created: " + my_url);
            SetupMedia();
        }
        else if (method == "POST")
        {
            // Handle Score Submission
            // Body is JSON: {"name":"Player","score":123}
            string name = llJsonGetValue(body, ["name"]);
            string score_str = llJsonGetValue(body, ["score"]);
            integer score = (integer)score_str;
            
            if(name != JSON_INVALID && score_str != JSON_INVALID) {
                UpdateHighScores(name, score);
                llHTTPResponse(id, 200, "OK");
                llSay(0, "New High Score! " + name + ": " + (string)score);
            } else {
                llHTTPResponse(id, 400, "Bad JSON");
            }
        }
    }
    
    touch_start(integer total_number)
    {
        string touchedPrimName = llGetLinkName(llDetectedLinkNumber(0));
        if (touchedPrimName == "reset")
        {
            llRequestURL(); // Get new URL and refresh
        }
    }
    
    on_rez(integer start_param) { llResetScript(); }
    changed(integer change) { if(change & CHANGED_REGION) llRequestURL(); }
}
