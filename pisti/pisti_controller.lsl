// Premium Pişti Table Controller
// Bu scripti büyük bir primin (masa yüzeyi) içine koyun.

string GITHUB_URL = "https://selami79.github.io/weboyun/pisti/index.html"; 
string lsl_url;
integer media_face = 0; // Masanın üst yüzeyi

default
{
    state_entry()
    {
        llReleaseURL(lsl_url);
        llRequestURL();
    }

    http_request(key id, string method, string body)
    {
        if (method == URL_REQUEST_GRANTED)
        {
            lsl_url = body;
            llOwnerSay("Pişti Masası Hazır!");
            
            // Her oyuncunun kendi ID'sini JS'e gönderiyoruz
            string final_url = GITHUB_URL + "?lsl=" + llEscapeURL(lsl_url) + "&viewer=" + "[VIEWER_KEY]";
            
            llSetLinkPrimitiveParamsFast(media_face, [
                PRIM_MEDIA_CURRENT_URL, final_url,
                PRIM_MEDIA_AUTO_PLAY, TRUE,
                PRIM_MEDIA_PERMS_INTERACT, PRIM_MEDIA_PERM_ANYONE,
                PRIM_MEDIA_PERMS_CONTROL, PRIM_MEDIA_PERM_NONE,
                PRIM_MEDIA_WIDTH_PIXELS, 1024,
                PRIM_MEDIA_HEIGHT_PIXELS, 1024
            ]);
        }
        else if (method == "POST")
        {
            llHTTPResponse(id, 200, "OK");
            // JS'den gelen yakalama mesajlarını chat'e yazdır
            if (llSubStringIndex(body, "capture") != -1)
            {
                if (llSubStringIndex(body, "Owner") != -1)
                    llSay(0, "Tebrikler! Kartları topladın.");
                else
                    llSay(0, "Bot kartları topladı.");
            }
        }
    }

    on_rez(integer start_param) { llResetScript(); }
}
