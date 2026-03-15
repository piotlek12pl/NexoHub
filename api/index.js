// api/index.js — NexoHub Key System (Two-Stage Verification)
// Vercel Serverless Function

// ===== KONFIGURACJA =====
const SECRET_SALT = "NEXOHUB_SECRET_SALT_2026";
const STAGE_2_LINK = "https://link-center.net/1108008/RVJqaSOOpHPX"; // Link do drugiego etapu Linkvertise
// =========================

// Szybka pamięć podręczna Vercela ratująca przed tworzeniem bazy danych
// (działa ok. 15-30 minut w zależności od obciążenia Vercela)
const recentActivity = new Map();

// Funkcje pomocnicze
function getDailyKey(ipAddress = "") {
  const date = new Date();
  const dateString = `${date.getUTCFullYear()}-${date.getUTCMonth() + 1}-${date.getUTCDate()}`;
  let hash = 0;
  // Dodajemy IP do stringa mieszającego. Każde IP dostanie inny klucz dla danego dnia.
  const str = dateString + SECRET_SALT + ipAddress;
  
  for (let i = 0; i < str.length; i++) {
    hash = ((hash << 5) - hash) + str.charCodeAt(i);
    hash |= 0;
  }
  return "NEXO-" + Math.abs(hash).toString(16).toUpperCase();
}

function parseCookies(cookieHeader) {
  const list = {};
  if (!cookieHeader) return list;
  cookieHeader.split(`;`).forEach(function(cookie) {
    let [name, ...rest] = cookie.split(`=`);
    name = name?.trim();
    if (!name) return;
    const value = rest.join(`=`).trim();
    if (!value) return;
    list[name] = decodeURIComponent(value);
  });
  return list;
}

// === WIDOKI HTML ===

// Wspólny komponent: Pasek Postępu (3 kółeczka: Discord, Link, Key)
function getProgressBarHTML(activeStage) {
  // activeStage: 1 (Discord done, Link active), 2 (Link done, Key active)
  const isC1 = activeStage >= 1;
  const isC2 = activeStage >= 2;
  const isC3 = activeStage >= 3;
  
  return `
    <div class="progress-steps">
        <div class="p-step ${isC1 ? 'active' : ''}">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"></path></svg>
        </div>
        <div class="p-line ${isC2 ? 'active' : ''}"></div>
        <div class="p-step ${isC2 ? 'active' : ''}">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M10 13a5 5 0 0 0 7.54.54l3-3a5 5 0 0 0-7.07-7.07l-1.72 1.71"></path><path d="M14 11a5 5 0 0 0-7.54-.54l-3 3a5 5 0 0 0 7.07 7.07l1.71-1.71"></path></svg>
        </div>
        <div class="p-line ${isC3 ? 'active' : ''}"></div>
        <div class="p-step ${isC3 ? 'active' : ''}">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 2l-2 2m-7.61 7.61a5.5 5.5 0 1 1-7.778 7.778 5.5 5.5 0 0 1 7.777-7.777zm0 0L15.5 7.5m0 0l3 3L22 7l-3-3m-3.5 3.5L19 4"></path></svg>
        </div>
    </div>
  `;
}

// Ekran dla ukończonego STAGE 1 (informuje o STAGE 2)
function getStage1CompleteHTML() {
  return `<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>NexoHub — Verification</title>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;600;700;800&display=swap" rel="stylesheet">
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; font-family: 'Inter', sans-serif; }
        body { background: #0b0c0e; color: #fff; min-height: 100vh; display: flex; align-items: center; justify-content: center; }
        .card { width: 100%; max-width: 480px; padding: 40px 30px; }
        
        /* Progress Steps */
        .progress-steps { display: flex; align-items: center; justify-content: center; margin-bottom: 50px; }
        .p-step { width: 48px; height: 48px; border-radius: 50%; background: #131b1c; border: 2px solid #1c2727; display: flex; align-items: center; justify-content: center; color: #3b4e4e; transition: 0.3s; }
        .p-step.active { border-color: #78350f; background: #451a03; color: #f59e0b; box-shadow: 0 0 20px rgba(245, 158, 11, 0.15); }
        .p-step svg { width: 22px; height: 22px; }
        .p-line { width: 80px; height: 2px; background: #1c2727; margin: 0 10px; transition: 0.3s; }
        .p-line.active { background: #78350f; }

        h1 { font-size: 26px; text-align: center; margin-bottom: 12px; font-weight: 700; }
        .subtitle { text-align: center; color: #828282; font-size: 15px; margin-bottom: 40px; }
        
        .btn { display: block; width: 100%; background: #f59e0b; color: #000; text-align: center; padding: 16px; border-radius: 12px; text-decoration: none; font-weight: 700; font-size: 16px; transition: 0.2s; box-shadow: 0 4px 15px rgba(245, 158, 11, 0.2); }
        .btn:hover { background: #d97706; transform: translateY(-2px); }
    </style>
</head>
<body>
    <div class="card">
        ${getProgressBarHTML(2)}
        <h1>Stage 1 Complete!</h1>
        <p class="subtitle">Complete the final stage to unlock your daily key.</p>
        <a href="${STAGE_2_LINK}" class="btn">Proceed to Stage 2</a>
    </div>
</body>
</html>`;
}

// Ekran dla ukończonego STAGE 2 (Premium Dashboard)
function getSuccessHTML(key, clientIp) {
  // Odczyt statystyk z gorącej pamięci serwera
  const stats = recentActivity.get(clientIp) || { game: 'Awaiting execution...', executor: '-' };

  // Maskowanie IP a.b.c.d -> a.b.***.***
  const ipParts = clientIp.split('.');
  const maskedIp = (ipParts.length === 4) ? ipParts[0] + "." + ipParts[1] + ".***.***" : clientIp.substring(0, 10) + "...";

  return `<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>NexoHub — Dashboard</title>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap" rel="stylesheet">
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; font-family: 'Inter', sans-serif; }
        body { background: #0b0c0e; color: #fff; min-height: 100vh; display: flex; align-items: center; justify-content: center; background-image: radial-gradient(circle at 50% 0%, #291e0b 0%, #0b0c0e 60%); }
        .card { width: 100%; max-width: 520px; padding: 40px; }

        /* Progress Steps */
        .progress-steps { display: flex; align-items: center; justify-content: center; margin-bottom: 40px; }
        .p-step { width: 56px; height: 56px; border-radius: 50%; background: #131b1c; border: 2px solid #1c2727; display: flex; align-items: center; justify-content: center; color: #3b4e4e; }
        .p-step.active { border-color: #78350f; background: #451a03; color: #f59e0b; box-shadow: 0 0 20px rgba(245, 158, 11, 0.15); }
        .p-step svg { width: 24px; height: 24px; }
        .p-line { width: 90px; height: 2px; background: #1c2727; margin: 0 8px; }
        .p-line.active { background: #78350f; }

        /* Header Info */
        .discord-btn { display: inline-flex; align-items: center; gap: 8px; background: rgba(245, 158, 11, 0.1); color: #f59e0b; padding: 4px 12px; border-radius: 6px; font-size: 11px; font-weight: 700; border: 1px solid rgba(245, 158, 11, 0.2); letter-spacing: 0.5px; margin-bottom: 24px; }
        .discord-btn svg { width: 14px; height: 14px; }
        
        .header-wrap { text-align: center; }

        /* Stats Grid */
        .grid-2 { display: grid; grid-template-columns: 1fr 1fr; gap: 16px; margin-bottom: 24px; }
        .box { background: #0e1112; border: 1px solid #1a1e20; border-radius: 12px; padding: 20px; text-align: center; display: flex; flex-direction: column; justify-content: center; align-items: center; }
        .box-title { color: #6b7280; font-size: 10px; font-weight: 700; letter-spacing: 1px; margin-bottom: 8px; text-transform: uppercase; }
        .box-val { color: #f59e0b; font-size: 18px; font-weight: 700; font-family: monospace; }
        .box-val-gray { color: #d1d5db; font-size: 14px; font-weight: 600; font-family: monospace; display: flex; align-items: center; gap: 6px; }
        
        /* License Key Container */
        .lic-container { background: #0a0e0c; border: 1px dashed #f59e0b; border-radius: 12px; padding: 24px; text-align: center; margin-bottom: 24px; position: relative; }
        .lic-title { color: #6b7280; font-size: 10px; font-weight: 700; letter-spacing: 1px; margin-bottom: 12px; text-transform: uppercase; }
        .lic-key { color: #f59e0b; font-size: 24px; font-weight: 800; letter-spacing: 3px; font-family: monospace; }
        
        /* Buttons */
        .btn-green { display: flex; align-items: center; justify-content: center; gap: 10px; width: 100%; background: #f59e0b; color: #000; border: none; padding: 16px; border-radius: 12px; font-size: 16px; font-weight: 700; cursor: pointer; transition: 0.2s; margin-bottom: 24px; box-shadow: 0 4px 15px rgba(245, 158, 11, 0.2); text-decoration: none; }
        .btn-green:hover { background: #d97706; transform: translateY(-2px); }
        
        .btn-dark { display: flex; align-items: center; justify-content: center; gap: 10px; width: 100%; background: #131517; color: #fff; border: 1px solid #272a2e; padding: 16px; border-radius: 12px; font-size: 15px; font-weight: 600; cursor: pointer; transition: 0.2s; text-decoration: none; }
        .btn-dark:hover { background: #1c1f22; border-color: #3b4046; }
        .btn-dark.disabled { opacity: 0.5; pointer-events: none; }

        /* Bottom Stats */
        .section-title { color: #6b7280; font-size: 11px; font-weight: 700; letter-spacing: 1px; margin-bottom: 12px; text-transform: uppercase; }
        .stats-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 12px; margin-bottom: 24px; }
        .stat-box { display: flex; align-items: center; gap: 12px; background: #0e1112; border: 1px solid #1a1e20; border-radius: 10px; padding: 14px; }
        .stat-icon { color: #f59e0b; width: 24px; height: 24px; }
        .stat-label { color: #6b7280; font-size: 9px; font-weight: 700; text-transform: uppercase; margin-bottom: 3px; }
        .stat-text { color: #fff; font-size: 14px; font-weight: 700; }

    </style>
</head>
<body>
    <div class="card">
        ${getProgressBarHTML(3)}

        <div class="header-wrap">
            <div class="discord-btn">
                <svg viewBox="0 0 24 24" fill="currentColor"><path d="M20.317 4.3698a19.7913 19.7913 0 00-4.8851-1.5152.0741.0741 0 00-.0785.0371c-.211.3753-.4447.8648-.6083 1.2495-1.8447-.2762-3.68-.2762-5.4868 0-.1636-.3933-.4058-.8742-.6177-1.2495a.077.077 0 00-.0785-.037 19.7363 19.7363 0 00-4.8852 1.515.0699.0699 0 00-.0321.0277C.5334 9.0458-.319 13.5799.0992 18.0578a.0824.0824 0 00.0312.0561c2.0528 1.5076 4.0413 2.4228 5.9929 3.0294a.0777.0777 0 00.0842-.0276c.4616-.6304.8731-1.2952 1.226-1.9942a.076.076 0 00-.0416-.1057c-.6528-.2476-1.2743-.5495-1.8722-.8923a.077.077 0 01-.0076-.1277c.1258-.0943.2517-.1923.3718-.2914a.0743.0743 0 01.0776-.0105c3.9278 1.7933 8.18 1.7933 12.0614 0a.0739.0739 0 01.0785.0095c.1202.099.246.1981.3728.2924a.077.077 0 01-.0066.1276 12.2986 12.2986 0 01-1.873.8914.0766.0766 0 00-.0407.1067c.3604.698.7719 1.3628 1.225 1.9932a.076.076 0 00.0842.0286c1.961-.6067 3.9495-1.5219 6.0023-3.0294a.077.077 0 00.0313-.0552c.5004-5.177-.8382-9.6739-3.5485-13.6604a.061.061 0 00-.0312-.0286zM8.02 15.3312c-1.1825 0-2.1569-1.0857-2.1569-2.419 0-1.3332.9555-2.4189 2.157-2.4189 1.2108 0 2.1757 1.0952 2.1568 2.419 0 1.3332-.9555 2.4189-2.1569 2.4189zm7.9748 0c-1.1825 0-2.1569-1.0857-2.1569-2.419 0-1.3332.9554-2.4189 2.1569-2.4189 1.2108 0 2.1757 1.0952 2.1568 2.419 0 1.3332-.946 2.4189-2.1568 2.4189Z"/></svg>
                Discord FREE
            </div>
        </div>

        <div class="grid-2">
            <div class="box">
                <div class="box-title">Subscription Status</div>
                <div class="box-val" id="countdown">23h 59m 59s</div>
            </div>
            <div class="box">
                <div class="box-title">Bound Hardware (HWID)</div>
                <div class="box-val-gray">
                    ${maskedIp} 
                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#f59e0b" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"><polyline points="20 6 9 17 4 12"></polyline></svg>
                </div>
            </div>
        </div>

        <div class="lic-container">
            <div class="lic-title">Your License Key</div>
            <div class="lic-key" id="licKey">${key}</div>
        </div>

        <button class="btn-green" onclick="copyKey()">
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="9" y="9" width="13" height="13" rx="2" ry="2"></rect><path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"></path></svg>
            <span id="copyText">Copy Script Key</span>
        </button>

        <div class="section-title">Activity Stats</div>
        <div class="stats-grid">
            <div class="stat-box">
                <svg class="stat-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="2" y="6" width="20" height="12" rx="2" ry="2"></rect><path d="M6 12h4"></path><path d="M8 10v4"></path><path d="M15 13h.01"></path><path d="M18 11h.01"></path></svg>
                <div>
                    <div class="stat-label">Last Game</div>
                    <div class="stat-text">${stats.game}</div>
                </div>
            </div>
            <div class="stat-box">
                <svg class="stat-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="4 17 10 11 4 5"></polyline><line x1="12" y1="19" x2="20" y2="19"></line></svg>
                <div>
                    <div class="stat-label">Executor</div>
                    <div class="stat-text">${stats.executor}</div>
                </div>
            </div>
        </div>

        <a href="https://discord.gg/nexohub" class="btn-green" style="margin-bottom: 12px; font-size: 15px; padding: 14px;">
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M5 12h14"></path><path d="M12 5l7 7-7 7"></path></svg>
            Go to Scripts
        </a>

        <a href="/api?reset=true" class="btn-dark" onclick="return confirm('Resetting HWID will clear your access and require you to get a new key. Proceed?');">
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M3 12a9 9 0 1 0 9-9 9.75 9.75 0 0 0-6.74 2.74L3 8"></path><path d="M3 3v5h5"></path></svg>
            Transfer Device (Reset HWID)
        </a>

    </div>

    <script>
        function copyKey() {
            navigator.clipboard.writeText('${key}');
            document.getElementById('copyText').textContent = 'Copied!';
            setTimeout(() => { document.getElementById('copyText').textContent = 'Copy Script Key'; }, 2000);
        }

        // Prosty timer do końca dnia UTC (zgodnie z życiem klucza API)
        function updateTimer() {
            const now = new Date();
            const endOfDay = new Date();
            endOfDay.setUTCHours(23, 59, 59, 999);
            
            let diff = endOfDay - now;
            if (diff <= 0) diff = 0;
            
            const hours = Math.floor((diff / (1000 * 60 * 60)) % 24);
            const minutes = Math.floor((diff / 1000 / 60) % 60);
            const seconds = Math.floor((diff / 1000) % 60);

            document.getElementById('countdown').textContent = hours + "h " + minutes + "m " + seconds + "s";
        }
        setInterval(updateTimer, 1000);
        updateTimer();
    </script>
</body>
</html>`;
}

// Ekran błędu / zablokowanego dostępu
function getErrorHTML(message) {
  return `<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>NexoHub — Notice</title>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;600;700&display=swap" rel="stylesheet">
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; font-family: 'Inter', sans-serif; }
        body { background: #0b0c0e; color: #fff; min-height: 100vh; display: flex; align-items: center; justify-content: center; }
        .card { width: 100%; max-width: 440px; padding: 40px; text-align: center; background: #0e1112; border: 1px solid #1a1e20; border-radius: 20px; box-shadow: 0 20px 40px rgba(0,0,0,0.5); }
        .icon-wrap { width: 64px; height: 64px; background: rgba(239, 68, 68, 0.1); border-radius: 16px; display: flex; align-items: center; justify-content: center; margin: 0 auto 24px; color: #ef4444; border: 1px solid rgba(239, 68, 68, 0.2); }
        h1 { font-size: 20px; margin-bottom: 12px; font-weight: 700; }
        .message { color: #828282; font-size: 14px; line-height: 1.6; margin-bottom: 30px; }
        .btn-dark { display: flex; align-items: center; justify-content: center; gap: 10px; width: 100%; background: #131517; color: #fff; border: 1px solid #272a2e; padding: 14px; border-radius: 10px; font-weight: 600; text-decoration: none; transition: 0.2s; }
        .btn-dark:hover { background: #1c1f22; border-color: #3b4046; }
    </style>
</head>
<body>
    <div class="card">
        <div class="icon-wrap"><svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"></path><line x1="12" y1="9" x2="12" y2="13"></line><line x1="12" y1="17" x2="12.01" y2="17"></line></svg></div>
        <h1>Action Denied</h1>
        <p class="message">${message}</p>
        <a href="https://discord.gg/nexohub" class="btn-dark">Support Server</a>
    </div>
</body>
</html>`;
}

module.exports = async (req, res) => {
  res.setHeader('Access-Control-Allow-Credentials', true);
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET,OPTIONS');
  
  if (req.method === 'OPTIONS') return res.status(200).end();

  // Pobranie IP klienta (działa bezpiecznie za proxy Vercela)
  const rawIp = req.headers['x-forwarded-for'] || req.socket.remoteAddress || 'unknown';
  const clientIp = rawIp.split(',')[0].trim();

  // Generujemy unikalny klucz dla DANEGO IP (IP-Lock)
  const currentKey = getDailyKey(clientIp);

  // === TRYB 1: Weryfikacja klucza w Roblox ===
  if (req.query.verify) {
    if (req.query.verify === currentKey) {
      
      // Zapisujemy prawdziwość wykonywania bezpośrednio z hookowanego klienta
      const exec = req.query.executor || "Unknown";
      const game = req.query.game || "Unknown";
      recentActivity.set(clientIp, { executor: exec, game: game });
      
      return res.status(200).json({ valid: true });
    } else {
      return res.status(403).json({ valid: false });
    }
  }

  // === TRYB 2: Generowanie klucza w Przeglądarce ===
  res.setHeader('Content-Type', 'text/html; charset=utf-8');

  // Sprawdzamy Referer
  const referer = (req.headers.referer || req.headers.referrer || '').toLowerCase();
  const isFromLinkvertise = referer.includes('linkvertise.com') || referer.includes('link-to.net') || referer.includes('link-center.net') || referer.includes('link-target.net') || referer.includes('direct-link.net');

  // Odczyt ciasteczek do systemu postępu i resetu
  const cookies = parseCookies(req.headers.cookie);
  const hasStage1Token = cookies['nexohub_stage_1'] === 'passed';
  const hasUsedReset = cookies['nexohub_reset_used'] === 'true';

  // === OBSŁUGA '/api?reset=true' ===
  if (req.query.reset === 'true') {
    if (hasUsedReset) {
      return res.status(403).send(getErrorHTML("You have already reset your HWID today. Please wait until tomorrow."));
    }
    
    // Udzielono resetu: 
    // - Wyczyszczono etap 1 (zmuszamy do zrobienia Linkvertise od nowa dla nowego IP)
    // - Ustawiono blokadę resetu na 24 godziny
    const resetCookieOptions = [
      'HttpOnly', 'Secure', 'SameSite=Lax', 'Path=/', `Max-Age=${24 * 60 * 60}`
    ];
    const clearStageOptions = [
      'HttpOnly', 'Secure', 'SameSite=Lax', 'Path=/', 'Max-Age=0'
    ];
    
    res.setHeader('Set-Cookie', [
      `nexohub_reset_used=true; ${resetCookieOptions.join('; ')}`,
      `nexohub_stage_1=; ${clearStageOptions.join('; ')}`
    ]);
    
    // Przenosimy użykownika od razu do 1 etapu z powiadomieniem
    return res.status(200).send(`
      <script>
        alert('Hardware ID has been reset! You must now generate a new key on your new IP.');
        window.location.href = "https://direct-link.net/1108008/MKwkmFy9Evql";
      </script>
    `);
  }

  // WERYFIKACJA PÓŁ-OSTATECZNA REFERERÓW
  if (!isFromLinkvertise) {
    return res.status(403).send(getErrorHTML("Direct skipping is blocked.<br>You must go through the executor's Get Key process."));
  }

  // WERYFIKACJA ETAPÓW LINKVERTISE
  if (!hasStage1Token) {
    // ETAP 1 ZALICZONY -> Nakaz zrobienia Etapu 2
    const options = [
      'HttpOnly', 'Secure', 'SameSite=Lax', 'Path=/', `Max-Age=${60 * 60}`
    ];
    res.setHeader('Set-Cookie', `nexohub_stage_1=passed; ${options.join('; ')}`);
    return res.status(200).send(getStage1CompleteHTML());
  } 
  else {
    // ETAP 2 ZALICZONY -> Sukces, dajemy klucz. Pamiętamy zablokowanie powrotu do Etapu 2 po klucz za darmo po paru minutach.
    res.setHeader('Set-Cookie', 'nexohub_stage_1=; Max-Age=0; Path=/; HttpOnly; Secure');
    return res.status(200).send(getSuccessHTML(currentKey, clientIp));
  }
};
