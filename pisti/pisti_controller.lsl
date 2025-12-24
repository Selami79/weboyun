// Premium Pişti Table Controller - 4 Player & Seat Sync Version
string GITHUB_URL = "https://selami79.github.io/weboyun/pisti/index.html"; 
string lsl_url;
integer media_face = 0;

// Oyuncu koltukları (Link numaraları 3,4,5,6 varsayıyoruz)
list SEATS = [3, 4, 5, 6];
list seated_players = ["None", "None", "None", "None"];

update_media()
{
    if (lsl_url == "") return;
    
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
    
    // URL'e oturanların listesini ve izleyicinin kim olduğunu ekle
    string final_url = GITHUB_URL + "?lsl=" + llEscapeURL(lsl_url) 
                     + "&viewer=" + "[VIEWER_KEY]" 
                     + "&players=" + llEscapeURL(whitelist);
    
    llSetLinkPrimitiveParamsFast(LINK_THIS, [
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
        llReleaseURL(lsl_url);
        llRequestURL();
        llSetTimerEvent(5.0); // 5 saniyede bir koltukları kontrol et (Veya changed event kullanılabilir)
    }

    changed(integer change)
    {
        if (change & CHANGED_LINK) update_media();
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
