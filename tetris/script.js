const canvas = document.getElementById('tetris');
const context = canvas.getContext('2d');

// Scale everything up by 20 so 1 unit = 20 pixels
context.scale(20, 20);

// --- Sound Manager (Web Audio API) ---
class SoundManager {
    constructor() {
        this.ctx = new (window.AudioContext || window.webkitAudioContext)();
        this.muted = false;
        this.bgMusic = document.getElementById('bg-music');
    }

    playTone(freq, type, duration, vol = 0.1) {
        if (this.muted) return;
        if (this.ctx.state === 'suspended') this.ctx.resume();

        const osc = this.ctx.createOscillator();
        const gain = this.ctx.createGain();

        osc.type = type;
        osc.frequency.setValueAtTime(freq, this.ctx.currentTime);

        gain.gain.setValueAtTime(vol, this.ctx.currentTime);
        gain.gain.exponentialRampToValueAtTime(0.01, this.ctx.currentTime + duration);

        osc.connect(gain);
        gain.connect(this.ctx.destination);

        osc.start();
        osc.stop(this.ctx.currentTime + duration);
    }

    playMove() {
        // Short high blip
        this.playTone(300, 'square', 0.1, 0.05);
    }

    playRotate() {
        // Laser-ish zip
        if (this.muted) return;
        if (this.ctx.state === 'suspended') this.ctx.resume();
        const osc = this.ctx.createOscillator();
        const gain = this.ctx.createGain();
        osc.frequency.setValueAtTime(400, this.ctx.currentTime);
        osc.frequency.exponentialRampToValueAtTime(600, this.ctx.currentTime + 0.1);
        gain.gain.setValueAtTime(0.05, this.ctx.currentTime);
        gain.gain.exponentialRampToValueAtTime(0.01, this.ctx.currentTime + 0.1);
        osc.connect(gain);
        gain.connect(this.ctx.destination);
        osc.start();
        osc.stop(this.ctx.currentTime + 0.1);
    }

    playDrop() {
        // Low thud
        this.playTone(100, 'sawtooth', 0.2, 0.05);
    }

    playClear() {
        // Success chord
        this.playTone(400, 'sine', 0.3, 0.1);
        setTimeout(() => this.playTone(600, 'sine', 0.3, 0.1), 100);
        setTimeout(() => this.playTone(800, 'sine', 0.3, 0.1), 200);
    }

    playGameOver() {
        // Sad downsweep
        if (this.muted) return;
        const osc = this.ctx.createOscillator();
        const gain = this.ctx.createGain();
        osc.frequency.setValueAtTime(800, this.ctx.currentTime);
        osc.frequency.exponentialRampToValueAtTime(100, this.ctx.currentTime + 1.0);
        gain.gain.setValueAtTime(0.2, this.ctx.currentTime);
        gain.gain.linearRampToValueAtTime(0, this.ctx.currentTime + 1.0);
        osc.connect(gain);
        gain.connect(this.ctx.destination);
        osc.start();
        osc.stop(this.ctx.currentTime + 1.0);
    }

    toggleMute() {
        this.muted = !this.muted;
        const btn = document.getElementById('btn-sound');
        if (this.muted) {
            btn.innerText = "SOUND: OFF";
            this.bgMusic.pause();
        } else {
            btn.innerText = "SOUND: ON";
            // Resume AudioContext just in case
            if (this.ctx.state === 'suspended') this.ctx.resume();
            // Try to play BGM if game is running
            if (isGameRunning) {
                this.bgMusic.play().catch(e => console.log("Audio play failed (no interaction yet)", e));
            }
        }
    }

    startMusic() {
        if (!this.muted) {
            this.bgMusic.volume = 0.3;
            // Reset to start
            // this.bgMusic.currentTime = 0; 
            this.bgMusic.play().catch(e => console.log("Music play blocked", e));
        }
    }

    stopMusic() {
        this.bgMusic.pause();
    }
}

const sounds = new SoundManager();

// --- Tetris Logic ---

// Tetromino colors (Neon Palette)
const colors = [
    null,
    '#FF0D72', // T - Magenta
    '#0DC2FF', // O - Cyan
    '#0DFF72', // L - Green
    '#F538FF', // J - Purple
    '#FF8E0D', // I - Orange
    '#FFE138', // S - Yellow
    '#3877FF', // Z - Blue
];

const arenaWidth = 12;
const arenaHeight = 20;

function createMatrix(w, h) {
    const matrix = [];
    while (h--) {
        matrix.push(new Array(w).fill(0));
    }
    return matrix;
}

function createPiece(type) {
    if (type === 'I') {
        return [
            [0, 1, 0, 0],
            [0, 1, 0, 0],
            [0, 1, 0, 0],
            [0, 1, 0, 0],
        ];
    } else if (type === 'L') {
        return [
            [0, 2, 0],
            [0, 2, 0],
            [0, 2, 2],
        ];
    } else if (type === 'J') {
        return [
            [0, 3, 0],
            [0, 3, 0],
            [3, 3, 0],
        ];
    } else if (type === 'O') {
        return [
            [4, 4],
            [4, 4],
        ];
    } else if (type === 'Z') {
        return [
            [5, 5, 0],
            [0, 5, 5],
            [0, 0, 0],
        ];
    } else if (type === 'S') {
        return [
            [0, 6, 6],
            [6, 6, 0],
            [0, 0, 0],
        ];
    } else if (type === 'T') {
        return [
            [0, 7, 0],
            [7, 7, 7],
            [0, 0, 0],
        ];
    }
}

function drawMatrix(matrix, offset) {
    matrix.forEach((row, y) => {
        row.forEach((value, x) => {
            if (value !== 0) {
                // Main block color
                context.fillStyle = colors[value];
                context.fillRect(x + offset.x, y + offset.y, 1, 1);

                // Add a "shine" or inner glow effect for neon look
                context.lineWidth = 0.05;
                context.strokeStyle = 'white';
                context.strokeRect(x + offset.x, y + offset.y, 1, 1);

                // Slight inner shade
                context.fillStyle = 'rgba(255, 255, 255, 0.1)';
                context.fillRect(x + offset.x + 0.1, y + offset.y + 0.1, 0.8, 0.8);
            }
        });
    });
}

function draw() {
    // Clear canvas
    context.fillStyle = '#0a0a1a'; // Match grid-bg
    context.fillRect(0, 0, canvas.width, canvas.height);

    drawMatrix(arena, { x: 0, y: 0 });
    drawMatrix(player.matrix, player.pos);
}

function merge(arena, player) {
    player.matrix.forEach((row, y) => {
        row.forEach((value, x) => {
            if (value !== 0) {
                arena[y + player.pos.y][x + player.pos.x] = value;
            }
        });
    });
    sounds.playDrop();
}

function rotate(matrix, dir) {
    for (let y = 0; y < matrix.length; ++y) {
        for (let x = 0; x < y; ++x) {
            [
                matrix[x][y],
                matrix[y][x],
            ] = [
                    matrix[y][x],
                    matrix[x][y],
                ];
        }
    }
    if (dir > 0) {
        matrix.forEach(row => row.reverse());
    } else {
        matrix.reverse();
    }
}

function playerDrop() {
    player.pos.y++;
    if (collide(arena, player)) {
        player.pos.y--;
        merge(arena, player);
        playerReset();
        arenaSweep();
        updateScore();
    }
    dropCounter = 0;
}

function playerMove(offset) {
    player.pos.x += offset;
    if (collide(arena, player)) {
        player.pos.x -= offset;
    } else {
        sounds.playMove(); // Sound trigger
    }
}

function playerRotate(dir) {
    const pos = player.pos.x;
    let offset = 1;
    rotate(player.matrix, dir);
    while (collide(arena, player)) {
        player.pos.x += offset;
        offset = -(offset + (offset > 0 ? 1 : -1));
        if (offset > player.matrix[0].length) {
            rotate(player.matrix, -dir);
            player.pos.x = pos;
            return;
        }
    }
    sounds.playRotate(); // Sound trigger
}

function playerReset() {
    const pieces = 'TJLOSZI';
    player.matrix = createPiece(pieces[pieces.length * Math.random() | 0]);
    player.pos.y = 0;
    player.pos.x = (arena[0].length / 2 | 0) - (player.matrix[0].length / 2 | 0);

    if (collide(arena, player)) {
        arena.forEach(row => row.fill(0));
        player.score = 0;
        sounds.playGameOver();
        gameOver();
    }
}

function arenaSweep() {
    let rowCount = 1;
    let clearedAnything = false;
    outer: for (let y = arena.length - 1; y > 0; --y) {
        for (let x = 0; x < arena[y].length; ++x) {
            if (arena[y][x] === 0) {
                continue outer;
            }
        }

        const row = arena.splice(y, 1)[0].fill(0);
        arena.unshift(row);
        ++y;

        player.score += rowCount * 10;
        player.lines += 1;
        rowCount *= 2;
        clearedAnything = true;
    }

    if (clearedAnything) sounds.playClear();

    // Level up every 10 lines
    player.level = Math.floor(player.lines / 10) + 1;
    // Increase speed based on level
    dropInterval = Math.max(100, 1000 - (player.level - 1) * 100);
}

function collide(arena, player) {
    const m = player.matrix;
    const o = player.pos;
    for (let y = 0; y < m.length; ++y) {
        for (let x = 0; x < m[y].length; ++x) {
            if (m[y][x] !== 0 &&
                (arena[y + o.y] &&
                    arena[y + o.y][x + o.x]) !== 0) {
                return true;
            }
        }
    }
    return false;
}

function updateScore() {
    document.getElementById('score').innerText = player.score;
    document.getElementById('level').innerText = player.level;
    document.getElementById('lines').innerText = player.lines;
}

function gameOver() {
    isGameRunning = false;
    sounds.stopMusic();
    document.getElementById('final-score').innerText = 'Score: ' + player.score;
    document.getElementById('game-over-overlay').classList.remove('hidden');
}

function startGame() {
    // Resume audio context if needed (browser policy)
    if (sounds.ctx.state === 'suspended') {
        sounds.ctx.resume();
    }
    sounds.startMusic();

    // Reset Everything
    arena.forEach(row => row.fill(0));
    player.score = 0;
    player.lines = 0;
    player.level = 1;
    dropInterval = 1000;
    updateScore();

    isGameRunning = true;
    playerReset();
    update();

    document.getElementById('start-overlay').classList.add('hidden');
    document.getElementById('game-over-overlay').classList.add('hidden');

    // Ensure focus for keyboard
    window.focus();
}

let dropCounter = 0;
let dropInterval = 1000;
let lastTime = 0;
let isGameRunning = false;

function update(time = 0) {
    if (!isGameRunning) return;

    const deltaTime = time - lastTime;
    lastTime = time;

    dropCounter += deltaTime;
    if (dropCounter > dropInterval) {
        playerDrop();
    }

    draw();
    requestAnimationFrame(update);
}

const arena = createMatrix(arenaWidth, arenaHeight);

const player = {
    pos: { x: 0, y: 0 },
    matrix: null,
    score: 0,
    lines: 0,
    level: 1,
};

// Controls
document.addEventListener('keydown', event => {
    if (!isGameRunning) return;

    if (event.keyCode === 37) { // Left
        playerMove(-1);
    } else if (event.keyCode === 39) { // Right
        playerMove(1);
    } else if (event.keyCode === 40) { // Down
        playerDrop();
    } else if (event.keyCode === 81 || event.keyCode === 38) { // Q or Up -> Rotate
        playerRotate(1);
    }
});

// UI Button Bindings
document.getElementById('start-btn').addEventListener('click', startGame);
document.getElementById('restart-btn').addEventListener('click', startGame);
document.getElementById('btn-sound').addEventListener('click', () => sounds.toggleMute());

document.getElementById('btn-left').addEventListener('click', () => { if (isGameRunning) playerMove(-1); });
document.getElementById('btn-right').addEventListener('click', () => { if (isGameRunning) playerMove(1); });
document.getElementById('btn-down').addEventListener('click', () => { if (isGameRunning) playerDrop(); });
document.getElementById('btn-rotate').addEventListener('click', () => { if (isGameRunning) playerRotate(1); });
document.getElementById('btn-drop').addEventListener('click', () => {
    if (!isGameRunning) return;
    while (!collide(arena, player)) {
        player.pos.y++;
    }
    player.pos.y--;
    merge(arena, player);
    playerReset();
    arenaSweep();
    updateScore();
    dropCounter = 0;
});

// Initial draw (blank)
context.fillStyle = '#0a0a1a';
context.fillRect(0, 0, canvas.width, canvas.height);
