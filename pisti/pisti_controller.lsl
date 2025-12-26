string GITHUB_URL = "https://selami79.github.io/weboyun/pisti/index.html"; 
string lsl_url;
integer target_link = -1; 
string SCREEN_NAME = "PISTI_SCREEN"; // ÖNEMLİ: Masanın yüzeyindeki primin adını 'PISTI_SCREEN' yapın!
integer media_face = 0;

// Oyuncu koltukları (Link numaraları 3,4,5,6 varsayıyoruz - bunlar da dinamik bulunabilir ama şimdilik kalsın)
list SEATS = [3, 4, 5, 6];
list seated_players = ["None", "None", "None", "None"];

find_screen()
{
    integer i;
    integer count = llGetNumberOfPrims();
    target_link = -1;
    
    // Tek prim ise (Linklenmemişse)
    if (count == 1) {
        if (llGetObjectName() == SCREEN_NAME) target_link = 0;
    } 
    else 
    {
        for (i = 1; i <= count; ++i) {
            if (llGetLinkName(i) == SCREEN_NAME) {
                target_link = i;
                // llOwnerSay("Ekran bulundu: Link #" + (string)i);
                return;
            }
        }
    }
    
    if (target_link == -1) llOwnerSay("HATA: '" + SCREEN_NAME + "' adında bir prim bulunamadı! Lütfen masanın oyun yüzeyinin adını değiştirin.");
}

update_media()
{
    if (lsl_url == "" || target_link == -1) return;
    
    // Oturan oyuncuların listesini oluştur
    string whitelist = "";
    integer i;
    for (i = 0; i < 4; ++i)
    {
        key av = llGetLinkKey(llList2Integer(SEATS, i));
        if (av != NULL_KEY) {
            whitelist += (string)av + ",";
            seated_players = llListReplaceList(seated_players, [(string)av], i, i);
        } else {
            seated_players = llListReplaceList(seated_players, ["None"], i, i);
        }
    }
    
    // URL'e oturanların listesini, izleyiciyi ve MASA ID'sini (tableId) ekle
    string final_url = GITHUB_URL + "?lsl=" + llEscapeURL(lsl_url) 
                     + "&viewer=" + "[VIEWER_KEY]" 
                     + "&players=" + llEscapeURL(whitelist)
                     + "&tableId=" + (string)llGetKey()
                     + "&v=" + (string)llFrand(9999);
    
    llSetLinkMedia(target_link, media_face, [
        PRIM_MEDIA_CURRENT_URL, final_url,
        PRIM_MEDIA_AUTO_PLAY, TRUE,
        PRIM_MEDIA_PERMS_INTERACT, PRIM_MEDIA_PERM_ANYONE,
        PRIM_MEDIA_PERMS_CONTROL, PRIM_MEDIA_PERM_NONE,
        PRIM_MEDIA_WIDTH_PIXELS, 1024,
        PRIM_MEDIA_HEIGHT_PIXELS, 1024
    ]);
}

default
{
    state_entry()
    {
        find_screen(); // Ekranı bul
        llReleaseURL(lsl_url);
        llRequestURL();
        llSetTimerEvent(5.0); 
    }

    changed(integer change)
    {
        if (change & CHANGED_LINK) {
            find_screen(); // Link değişince ekranı tekrar bul
            update_media();
        }
    }

    timer() { update_media(); }

    http_request(key id, string method, string body)
    {
        if (method == URL_REQUEST_GRANTED)
        {
            lsl_url = body;
            update_media();
        }
        else if (method == "POST")
        {
            llHTTPResponse(id, 200, "OK");
            // Oyun içi olaylar buraya gelecek...
        }
    }
}
