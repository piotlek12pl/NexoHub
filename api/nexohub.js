// api/nexohub.js — Secured Script Endpoint with Token Auth + XOR Encryption

const https = require('https');
const crypto = require('crypto');

// URL źródłowy skryptu login.lua (zwracany gdy brak tokenu - publiczny entry point)
const LOGIN_SCRIPT_URL = "https://raw.githubusercontent.com/piotlek12pl/NexoHub/refs/heads/main/login.lua";

// ===== KONFIGURACJA =====
const SECRET_SALT = process.env.SECRET_SALT || "NEXOHUB_SECRET_SALT_2026";
// =========================

// Mapowanie PlaceId -> URL skryptu gry (SERWER-SIDE, niewidoczne dla użytkowników)
// Te URLe są ukryte i wymagają ważnego tokenu aby je otrzymać
const GAME_SCRIPTS = {
    '70390793715007':   'https://raw.githubusercontent.com/piotlek12pl/NexoHub/refs/heads/main/games/hooked.lua',
    '118637423917462':  'https://raw.githubusercontent.com/piotlek12pl/NexoHub/refs/heads/main/games/caseparadise.lua',
    '8737602449':       'https://raw.githubusercontent.com/piotlek12pl/NexoHub/refs/heads/main/games/plsdonate.lua',
    '84259959693333':   'https://raw.githubusercontent.com/piotlek12pl/NexoHub/refs/heads/main/games/skateboardforbrainrots.lua',
};

// Pobiera tekst z URL
function fetchText(url) {
    return new Promise((resolve, reject) => {
        https.get(url, (resp) => {
            // Obsługa redirectów
            if (resp.statusCode >= 300 && resp.statusCode < 400 && resp.headers.location) {
                return fetchText(resp.headers.location).then(resolve).catch(reject);
            }
            let data = '';
            resp.on('data', (chunk) => { data += chunk; });
            resp.on('end', () => resolve({ status: resp.statusCode, body: data }));
        }).on('error', (err) => reject(err));
    });
}

// XOR enkodowanie / dekodowanie
// Klucz jest rozciągany na długość tekstu metodą cykliczną
function xorEncrypt(text, key) {
    const textBytes = Buffer.from(text, 'utf8');
    const keyBytes = Buffer.from(key, 'utf8');
    const result = Buffer.alloc(textBytes.length);

    for (let i = 0; i < textBytes.length; i++) {
        result[i] = textBytes[i] ^ keyBytes[i % keyBytes.length];
    }

    // Zwracamy jako hex string (bezpieczny do przesyłu, łatwy do parsowania w Lua)
    return result.toString('hex');
}

function isBrowser(userAgent) {
    if (!userAgent) return false;
    const ua = userAgent.toLowerCase();
    return ua.includes('mozilla') || ua.includes('chrome') ||
           ua.includes('safari') || ua.includes('firefox') ||
           ua.includes('edge') || ua.includes('opera');
}

function getLandingHTML() {
    const loadstringCmd = 'loadstring(game:HttpGet("https://nexohub-new.vercel.app/api/nexohub"))()';

    return `<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>NexoHub — Script Loader</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800&family=JetBrains+Mono:wght@400;500;600&display=swap" rel="stylesheet">
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: 'Inter', -apple-system, BlinkMacSystemFont, sans-serif;
            background: #09090b; color: #fafafa;
            min-height: 100vh; display: flex; align-items: center;
            justify-content: center; overflow: hidden; position: relative;
        }
        .bg-orb { position: fixed; border-radius: 50%; filter: blur(100px); opacity: 0.12; animation: float 10s ease-in-out infinite; }
        .bg-orb-1 { width: 500px; height: 500px; background: #f59e0b; top: -150px; left: -150px; }
        .bg-orb-2 { width: 350px; height: 350px; background: #f97316; bottom: -100px; right: -100px; animation-delay: -5s; }
        .bg-orb-3 { width: 250px; height: 250px; background: #8b5cf6; top: 40%; right: 10%; animation-delay: -3s; }
        @keyframes float {
            0%, 100% { transform: translate(0, 0) scale(1); }
            33% { transform: translate(30px, -25px) scale(1.05); }
            66% { transform: translate(-25px, 18px) scale(0.95); }
        }
        .card {
            position: relative; z-index: 10;
            background: rgba(17, 17, 20, 0.8); backdrop-filter: blur(50px);
            border: 1px solid rgba(255, 255, 255, 0.06); border-radius: 24px;
            padding: 48px; max-width: 600px; width: 94%; text-align: center;
            box-shadow: 0 30px 80px rgba(0,0,0,0.5);
            animation: cardIn 0.7s cubic-bezier(0.16, 1, 0.3, 1) both;
        }
        @keyframes cardIn {
            from { opacity: 0; transform: translateY(40px) scale(0.95); }
            to { opacity: 1; transform: translateY(0) scale(1); }
        }
        .logo {
            font-size: 36px; font-weight: 800; letter-spacing: -1px; margin-bottom: 4px;
            background: linear-gradient(135deg, #f59e0b, #fbbf24, #f59e0b);
            background-size: 200% 200%;
            -webkit-background-clip: text; -webkit-text-fill-color: transparent;
        }
        .version {
            display: inline-block; font-size: 11px; font-weight: 600; color: #71717a;
            background: rgba(255,255,255,0.04); border: 1px solid rgba(255,255,255,0.06);
            padding: 3px 10px; border-radius: 100px; margin-bottom: 28px; letter-spacing: 0.5px;
        }
        .subtitle { color: #a1a1aa; font-size: 15px; margin-bottom: 32px; line-height: 1.6; }
        .code-block {
            position: relative; background: rgba(0,0,0,0.4);
            border: 1px solid rgba(255,255,255,0.08); border-radius: 14px;
            padding: 22px 24px; margin-bottom: 16px; text-align: left;
            cursor: pointer; transition: all 0.3s ease; overflow: hidden;
        }
        .code-block:hover { border-color: rgba(245, 158, 11, 0.3); background: rgba(245, 158, 11, 0.03); }
        .code-label { font-size: 10px; text-transform: uppercase; letter-spacing: 2px; color: #52525b; font-weight: 700; margin-bottom: 10px; }
        .code-text { font-family: 'JetBrains Mono', monospace; font-size: 13px; color: #e4e4e7; word-break: break-all; line-height: 1.6; }
        .code-text .fn { color: #60a5fa; }
        .code-text .str { color: #34d399; }
        .code-text .paren { color: #a1a1aa; }
        .copy-toast { font-size: 12px; color: #52525b; transition: all 0.3s ease; margin-bottom: 28px; height: 18px; }
        .copy-toast.copied { color: #22c55e; }
        .divider { height: 1px; background: rgba(255,255,255,0.05); margin: 8px 0 24px; }
        .steps { display: flex; gap: 20px; justify-content: center; flex-wrap: wrap; }
        .step { display: flex; align-items: center; gap: 8px; font-size: 12px; color: #52525b; }
        .step-num { width: 24px; height: 24px; background: rgba(245, 158, 11, 0.1); border: 1px solid rgba(245, 158, 11, 0.15); border-radius: 8px; display: flex; align-items: center; justify-content: center; font-size: 11px; font-weight: 700; color: #f59e0b; }
        .warning { margin-top: 24px; font-size: 11px; color: #3f3f46; }
    </style>
</head>
<body>
    <div class="bg-orb bg-orb-1"></div>
    <div class="bg-orb bg-orb-2"></div>
    <div class="bg-orb bg-orb-3"></div>

    <div class="card">
        <div class="logo">NEXO HUB</div>
        <div class="version">v1.1 • Secured Loader</div>
        <p class="subtitle">Copy the script below and paste it into your executor.</p>

        <div class="code-block" onclick="copyScript()">
            <div class="code-label">Loadstring</div>
            <div class="code-text">
                <span class="fn">loadstring</span><span class="paren">(</span><span class="fn">game</span>:HttpGet<span class="paren">(</span><span class="str">"https://nexohub-new.vercel.app/api/nexohub"</span><span class="paren">)</span><span class="paren">)</span><span class="paren">(</span><span class="paren">)</span>
            </div>
        </div>
        <p class="copy-toast" id="toast">Click to copy</p>

        <div class="divider"></div>

        <div class="steps">
            <div class="step"><span class="step-num">1</span> Copy the script</div>
            <div class="step"><span class="step-num">2</span> Paste in executor</div>
            <div class="step"><span class="step-num">3</span> Click Execute</div>
        </div>

        <p class="warning">© NexoHub 2026 — Do not share this link publicly.</p>
    </div>

    <script>
        function copyScript() {
            const cmd = 'loadstring(game:HttpGet("https://nexohub-new.vercel.app/api/nexohub"))()';
            navigator.clipboard.writeText(cmd);
            const toast = document.getElementById('toast');
            toast.textContent = '✓ Copied to clipboard!';
            toast.classList.add('copied');
            setTimeout(() => {
                toast.textContent = 'Click to copy';
                toast.classList.remove('copied');
            }, 2500);
        }
    </script>
</body>
</html>`;
}

module.exports = async (req, res) => {
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Methods', 'GET,OPTIONS');

    if (req.method === 'OPTIONS') {
        return res.status(200).end();
    }

    const userAgent = req.headers['user-agent'] || '';

    // Przeglądarka → Landing page z loadstringiem (nie ma tu żadnego kodu Lua)
    if (isBrowser(userAgent)) {
        res.setHeader('Content-Type', 'text/html; charset=utf-8');
        return res.status(200).send(getLandingHTML());
    }

    // =====================================================
    // EXECUTOR PATH: Wymagamy prawidłowego session tokenu
    // =====================================================
    const token = req.query.token;

    // Brak tokenu → blokujemy (ktoś próbuje setclipboard/HttpGet bez loginu)
    if (!token) {
        res.setHeader('Content-Type', 'text/plain; charset=utf-8');
        // Zwracamy skrypt login.lua - to jest bezpieczne, bo sama logika auth jest tam zawarta
        // To jest entry point - zawsze można pobrać login.lua (on jest "public")
        try {
            const loginScript = await fetchText(LOGIN_SCRIPT_URL);
            if (loginScript.status === 200) {
                return res.status(200).send(loginScript.body);
            } else {
                return res.status(500).send('-- [NexoHub] Error: Could not load entry script.');
            }
        } catch (e) {
            return res.status(500).send('-- [NexoHub] Error loading entry module');
        }
    }

    // Weryfikacja tokenu "w miejscu", bezstanowo za pomoca kryptografii
    try {
        let tokenValid = false;
        try {
            const decoded = Buffer.from(token, 'base64').toString('utf8');
            const parts = decoded.split('|');
            if (parts.length === 3) {
                const expiresAt = parseInt(parts[0], 10);
                const nonce = parts[1];
                const sig = parts[2];

                if (Date.now() <= expiresAt) {
                    const expectedSig = crypto.createHmac('sha256', SECRET_SALT).update(`${parts[0]}|${nonce}`).digest('hex').substring(0, 16);
                    if (sig === expectedSig) {
                        tokenValid = true;
                    }
                }
            }
        } catch (_) {
            tokenValid = false;
        }

        if (!tokenValid) {
            res.setHeader('Content-Type', 'text/plain; charset=utf-8');
            return res.status(403).send('-- [NexoHub] Error: Invalid or expired session token. Please re-authenticate.');
        }

        // Token OK → określamy który skrypt gry ma być zwrócony
        const gameId = req.query.game || '';
        const gameScriptUrl = GAME_SCRIPTS[gameId];

        if (!gameScriptUrl) {
            res.setHeader('Content-Type', 'text/plain; charset=utf-8');
            return res.status(404).send('-- [NexoHub] Error: Game not supported or unknown PlaceId.');
        }

        // Pobieramy właściwy skrypt gry
        const scriptResult = await fetchText(gameScriptUrl);

        if (scriptResult.status !== 200) {
            res.setHeader('Content-Type', 'text/plain; charset=utf-8');
            return res.status(500).send('-- [NexoHub] Error: Could not fetch game script payload.');
        }

        // XOR-szyfrujemy skrypt — bez ważnego tokenu dane są bezużyteczne
        const encrypted = xorEncrypt(scriptResult.body, token);
        res.setHeader('Content-Type', 'text/plain; charset=utf-8');
        return res.status(200).send(`NEXO_ENC_V1|${token}|${encrypted}`);

    } catch (err) {
        res.setHeader('Content-Type', 'text/plain; charset=utf-8');
        return res.status(500).send('-- [NexoHub] Internal server error during token verification.');
    }
};
