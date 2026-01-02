let game = {
    score: 0,
    mps: 0,
    clickPower: 1,
    upgrades: {
        script: { count: 0, cost: 15, mps: 1, name: "Script Kittie" },
        bot: { count: 0, cost: 100, mps: 5, name: "Botnet Node" },
        server: { count: 0, cost: 500, mps: 25, name: "Server Farm" },
        ai: { count: 0, cost: 2000, mps: 100, name: "Quantum AI" }
    }
};

// Load progress
if (localStorage.getItem('cyberClickerSave')) {
    try {
        const saved = JSON.parse(localStorage.getItem('cyberClickerSave'));
        // Merge saved data with default structure to prevent errors if structure changes
        game = { ...game, ...saved };
        // Recalculate MPS just in case
        recalcMPS();
    } catch (e) {
        console.error("Save file corrupted");
    }
}

// Elements
const scoreEl = document.getElementById('score');
const mpsEl = document.getElementById('mps');
const hackBtn = document.getElementById('hack-btn');

function updateUI() {
    scoreEl.innerText = Math.floor(game.score).toLocaleString();
    mpsEl.innerText = game.mps.toLocaleString();

    // Update upgrade buttons
    for (let key in game.upgrades) {
        const upg = game.upgrades[key];
        document.getElementById(`cost-${key}`).innerText = Math.floor(upg.cost);

        // Disabled state
        const btn = document.querySelector(`#upg-${key} .buy-btn`);
        if (game.score < upg.cost) {
            btn.setAttribute('disabled', 'true');
        } else {
            btn.removeAttribute('disabled');
        }
    }
}

function recalcMPS() {
    let totalMPS = 0;
    for (let key in game.upgrades) {
        totalMPS += game.upgrades[key].count * game.upgrades[key].mps;
    }
    game.mps = totalMPS;
}

function saveGame() {
    localStorage.setItem('cyberClickerSave', JSON.stringify(game));
}

// Click Event
hackBtn.addEventListener('click', (e) => {
    // Add Score
    game.score += game.clickPower;

    // Visual Effect
    createFloater(e.clientX, e.clientY, `+${game.clickPower}`);

    // Slight shake
    hackBtn.style.transform = "scale(0.95)";
    setTimeout(() => hackBtn.style.transform = "scale(1)", 50);

    updateUI();
});

function createFloater(x, y, text) {
    const el = document.createElement('div');
    el.classList.add('floater');
    el.innerText = text;
    // Randomize slight position
    const randX = (Math.random() - 0.5) * 40;
    el.style.left = (x + randX) + 'px';
    el.style.top = (y - 20) + 'px';
    document.body.appendChild(el);
    setTimeout(() => el.remove(), 1000);
}

// Global Buy Function
window.buy = function (type) {
    const upg = game.upgrades[type];
    if (game.score >= upg.cost) {
        game.score -= upg.cost;
        upg.count++;
        upg.cost *= 1.15; // 15% price increase
        recalcMPS();
        updateUI();
        saveGame();
    }
};

// Game Loop
setInterval(() => {
    if (game.mps > 0) {
        game.score += game.mps / 10; // Run 10 times a second for smoothness
        updateUI();
    }
}, 100);

// Auto Save
setInterval(saveGame, 5000);

// Initial Draw
recalcMPS();
updateUI();
