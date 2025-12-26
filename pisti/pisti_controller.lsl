// Premium Pişti Table Controller - 4 Player & Seat Sync Version
string GITHUB_URL = "https://selami79.github.io/weboyun/pisti/index.html"; 
string GAME_SERVER = "http://109.176.199.186:3000"; // SUNUCU ADRESİ
string lsl_url;
integer target_link = -1; 
string SCREEN_NAME = "PISTI_SCREEN"; // ÖNEMLİ: Masanın yüzeyindeki primin adını 'PISTI_SCREEN' yapın!
integer media_face = 0;

// Oyuncu koltukları isimleri (Edit menüsünden prim isimlerini böyle yapın)
list SEAT_NAMES = ["SEAT_0", "SEAT_1", "SEAT_2", "SEAT_3"];
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
                return;
            }
        }
    }
    
    if (target_link == -1) llOwnerSay("HATA: '" + SCREEN_NAME + "' adında bir prim bulunamadı! Lütfen masanın oyun yüzeyinin adını değiştirin.");
}

// Koltukları ve üzerindeki avatarları tarayan akıllı fonksiyon
scan_seats()
{
    integer i;
    integer num_links = llGetNumberOfPrims();
    list seat_positions = [ZERO_VECTOR, ZERO_VECTOR, ZERO_VECTOR, ZERO_VECTOR];
    list seat_found_flags = [0, 0, 0, 0];
    seated_players = ["None", "None", "None", "None"]; // Sıfırla

    // 1. Adım: Koltukların yerini bul
    for(i = 0; i <= num_links; ++i) { // Link numaraları 0 veya 1'den başlar, emniyet için 0-max
        string name = llGetLinkName(i);
        integer seat_idx = llListFindList(SEAT_NAMES, [name]);
        
        if(seat_idx != -1) {
            // Koltuğun global pozisyonunu al
            key id = llGetLinkKey(i);
            vector pos = llList2Vector(llGetObjectDetails(id, [OBJECT_POS]), 0);
            seat_positions = llListReplaceList(seat_positions, [pos], seat_idx, seat_idx);
            seat_found_flags = llListReplaceList(seat_found_flags, [1], seat_idx, seat_idx);
        }
    }

    // 2. Adım: Avatarları bul ve koltukla eşleştir
    for(i = 0; i <= num_links; ++i) {
        key id = llGetLinkKey(i);
        // Eğer bu link bir avatarsa (Boyutu sıfır değilse avatardır)
        if (id != NULL_KEY && llGetAgentSize(id) != ZERO_VECTOR) {
            vector av_pos = llList2Vector(llGetObjectDetails(id, [OBJECT_POS]), 0);
            
            // Hangi koltuğa yakın?
            integer j;
            for(j = 0; j < 4; ++j) {
                if(llList2Integer(seat_found_flags, j)) {
                    vector s_pos = llList2Vector(seat_positions, j);
                    // Avatar koltuğa 1.2 metreden yakınsa o koltuktadır
                    if(llVecDist(av_pos, s_pos) < 1.2) { 
                        string av_name = llGetDisplayName(id);
                        if(av_name == "") av_name = llKey2Name(id);
                        seated_players = llListReplaceList(seated_players, [(string)id + ":" + av_name], j, j);
                    }
                }
            }
        }
    }
}

// ... global vars ...
string last_whitelist = "";

// ... scan_seats ...

update_media()
{
    if (lsl_url == "" || target_link == -1) return;
    
    // Koltukları tara
    scan_seats();
    
    // Listeyi stringe çevir (virgülle ayırarak)
    string whitelist = llDumpList2String(seated_players, ",");
    
    // EĞER OTURANLAR DEĞİŞMEDİYSE GÜNCELLEME YAPMA (Sayfa Yenilenmesini Önler)
    if (whitelist == last_whitelist) return;
    
    last_whitelist = whitelist; // Yeni listeyi kaydet
    
    // URL'e oturanların listesini, izleyiciyi ve MASA ID'sini (tableId) ekle
    // Not: Artık random 'v' parametresini sadece içerik değiştiğinde kullanıyoruz ki yenilensin
    string final_url = GITHUB_URL + "?lsl=" + llEscapeURL(lsl_url) 
                     + "&viewer=" + "[VIEWER_KEY]" 
                     + "&players=" + llEscapeURL(whitelist)
                     + "&tableId=" + (string)llGetKey()
                     + "&server=" + llEscapeURL(GAME_SERVER)
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
