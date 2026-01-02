function submitToSL() {
    var name = document.getElementById('playerName').value;
    if (!name) { alert("Please enter your name!"); return; }

    // Get SL URL from query parameters
    const urlParams = new URLSearchParams(window.location.search);
    const sl_url = urlParams.get('sl_url');

    if (sl_url) {
        var data = JSON.stringify({
            "name": name,
            "score": score
        });

        fetch(sl_url, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: data
        }).then(response => {
            alert("Score Submitted to Second Life!");
            document.getElementById('slInputArea').innerHTML = "<h3 style='color:#0f0'>SUBMITTED!</h3>";
        }).catch(error => {
            alert("Error sending to SL: " + error);
        });
    } else {
        alert("Not connected to Second Life (No URL found).");
    }
}
