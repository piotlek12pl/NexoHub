// api/index.js — NexoHub Key System (Two-Stage Verification)
// Vercel Serverless Function

// ===== KONFIGURACJA =====
const SECRET_SALT = "NEXOHUB_SECRET_SALT_2026";
const STAGE_2_LINK = "https://link-center.net/1108008/RVJqaSOOpHPX"; // Link do drugiego etapu Linkvertise
// =========================

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

// Ekran dla ukończonego STAGE 1 (informuje o STAGE 2)
function getStage1CompleteHTML() {
  return `<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>NexoHub — Stage 1 Complete</title>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;600;700&display=swap" rel="stylesheet">
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; font-family: 'Inter', sans-serif; }
        body { background: #09090b; color: #fafafa; display: flex; align-items: center; justify-content: center; min-height: 100vh; overflow: hidden; }
        .bg-orb { position: fixed; border-radius: 50%; filter: blur(80px); opacity: 0.15; animation: float 8s ease-in-out infinite; }
        .bg-orb-1 { width: 400px; height: 400px; background: #3b82f6; top: -100px; left: -100px; }
        .bg-orb-2 { width: 300px; height: 300px; background: #8b5cf6; bottom: -80px; right: -80px; animation-delay: -4s; }
        @keyframes float { 0%, 100% { transform: translate(0, 0) scale(1); } 50% { transform: translate(20px, -15px) scale(1.05); } }
        .card { position: relative; z-index: 10; background: rgba(17, 17, 20, 0.85); backdrop-filter: blur(40px); border: 1px solid rgba(255, 255, 255, 0.06); border-radius: 20px; padding: 48px; max-width: 460px; width: 92%; text-align: center; box-shadow: 0 25px 60px rgba(0,0,0,0.5); animation: cardIn 0.6s cubic-bezier(0.16, 1, 0.3, 1) both; }
        @keyframes cardIn { from { opacity: 0; transform: translateY(30px) scale(0.96); } to { opacity: 1; transform: translateY(0) scale(1); } }
        .icon-wrap { width: 64px; height: 64px; background: linear-gradient(135deg, #3b82f6, #60a5fa); border-radius: 16px; display: flex; align-items: center; justify-content: center; margin: 0 auto 24px; font-size: 28px; box-shadow: 0 8px 24px rgba(59, 130, 246, 0.25); }
        h1 { font-size: 22px; margin-bottom: 8px; }
        .subtitle { color: #a1a1aa; font-size: 14px; margin-bottom: 30px; line-height: 1.5; }
        .progress-bar { width: 100%; height: 6px; background: rgba(255,255,255,0.1); border-radius: 10px; margin-bottom: 30px; overflow: hidden; position: relative; }
        .progress-fill { position: absolute; left: 0; top: 0; bottom: 0; width: 50%; background: #3b82f6; border-radius: 10px; box-shadow: 0 0 10px #3b82f6; }
        .btn { display: inline-block; background: #fafafa; color: #09090b; text-decoration: none; font-weight: 600; padding: 14px 28px; border-radius: 12px; font-size: 15px; transition: all 0.2s; cursor: pointer; border: none; width: 100%; }
        .btn:hover { transform: scale(1.02); background: #f4f4f5; }
    </style>
</head>
<body>
    <div class="bg-orb bg-orb-1"></div><div class="bg-orb bg-orb-2"></div>
    <div class="card">
        <div class="icon-wrap">1/2</div>
        <h1>Stage 1 Complete!</h1>
        <div class="progress-bar"><div class="progress-fill"></div></div>
        <p class="subtitle">You have successfully completed the first step.<br>Click the button below to complete the final stage and get your key.</p>
        <a href="${STAGE_2_LINK}" class="btn">Proceed to Stage 2</a>
    </div>
</body>
</html>`;
}

// Ekran dla ukończonego STAGE 2 (sukces, pokazuje klucz)
function getSuccessHTML(key) {
  return `<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>NexoHub — Key System</title>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;600;700&display=swap" rel="stylesheet">
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; font-family: 'Inter', sans-serif; }
        body { background: #09090b; color: #fafafa; display: flex; align-items: center; justify-content: center; min-height: 100vh; overflow: hidden; }
        .bg-orb { position: fixed; border-radius: 50%; filter: blur(80px); opacity: 0.15; animation: float 8s ease-in-out infinite; }
        .bg-orb-1 { width: 400px; height: 400px; background: #ef4444; top: -100px; left: -100px; }
        .bg-orb-2 { width: 300px; height: 300px; background: #f97316; bottom: -80px; right: -80px; animation-delay: -4s; }
        @keyframes float { 0%, 100% { transform: translate(0, 0) scale(1); } 50% { transform: translate(30px, -20px) scale(1.05); } }
        .card { position: relative; z-index: 10; background: rgba(17, 17, 20, 0.85); backdrop-filter: blur(40px); border: 1px solid rgba(255, 255, 255, 0.06); border-radius: 20px; padding: 48px; max-width: 460px; width: 92%; text-align: center; box-shadow: 0 25px 60px rgba(0,0,0,0.5); animation: cardIn 0.6s both; }
        @keyframes cardIn { from { opacity: 0; transform: translateY(30px) scale(0.96); } to { opacity: 1; transform: translateY(0) scale(1); } }
        .icon-wrap { width: 64px; height: 64px; background: linear-gradient(135deg, #16a34a, #22c55e); border-radius: 16px; display: flex; align-items: center; justify-content: center; margin: 0 auto 24px; font-size: 28px; box-shadow: 0 8px 24px rgba(34, 197, 94, 0.25); }
        h1 { font-size: 22px; margin-bottom: 6px; }
        .subtitle { color: #71717a; font-size: 14px; margin-bottom: 20px; }
        .progress-bar { width: 100%; height: 6px; background: rgba(255,255,255,0.1); border-radius: 10px; margin-bottom: 20px; overflow: hidden; position: relative; }
        .progress-fill { position: absolute; left: 0; top: 0; bottom: 0; width: 100%; background: #22c55e; border-radius: 10px; box-shadow: 0 0 10px #22c55e; }
        .key-container { background: rgba(255,255,255,0.03); border: 1px solid rgba(255,255,255,0.08); border-radius: 12px; padding: 20px; margin-bottom: 12px; cursor: pointer; transition: all 0.2s; }
        .key-container:hover { border-color: rgba(239, 68, 68, 0.4); background: rgba(239, 68, 68, 0.05); }
        .key-text { font-size: 24px; font-weight: 700; letter-spacing: 3px; color: #fafafa; font-family: monospace; }
        .copy-toast { font-size: 12px; color: #71717a; transition: color 0.3s; }
        .copy-toast.copied { color: #22c55e; }
    </style>
</head>
<body>
    <div class="bg-orb bg-orb-1"></div><div class="bg-orb bg-orb-2"></div>
    <div class="card">
        <div class="icon-wrap">✓</div>
        <h1>All Stages Complete</h1>
        <p class="subtitle">Your daily access key is ready</p>
        <div class="progress-bar"><div class="progress-fill"></div></div>
        <div class="key-container" onclick="copyKey()">
            <div class="key-text">${key}</div>
        </div>
        <p class="copy-toast" id="toast">Click the key to copy</p>
    </div>
    <script>
        function copyKey() {
            navigator.clipboard.writeText('${key}');
            document.getElementById('toast').textContent = '✓ Copied to clipboard!';
            document.getElementById('toast').classList.add('copied');
            setTimeout(() => { document.getElementById('toast').textContent = 'Click the key to copy'; document.getElementById('toast').classList.remove('copied'); }, 2500);
        }
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
    <title>NexoHub — Access Denied</title>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;600;700&display=swap" rel="stylesheet">
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; font-family: 'Inter', sans-serif; }
        body { background: #09090b; color: #fafafa; display: flex; align-items: center; justify-content: center; min-height: 100vh; overflow: hidden; }
        .bg-orb { position: fixed; border-radius: 50%; filter: blur(80px); opacity: 0.1; animation: float 8s infinite; }
        .bg-orb-1 { width: 350px; height: 350px; background: #ef4444; top: -100px; right: -100px; }
        .card { position: relative; z-index: 10; background: rgba(17, 17, 20, 0.85); backdrop-filter: blur(40px); border: 1px solid rgba(255, 255, 255, 0.06); border-radius: 20px; padding: 48px; max-width: 460px; width: 92%; text-align: center; animation: cardIn 0.6s both; }
        @keyframes cardIn { from { opacity: 0; transform: translateY(30px) scale(0.96); } to { opacity: 1; transform: translateY(0) scale(1); } }
        .icon-wrap { width: 64px; height: 64px; background: linear-gradient(135deg, #dc2626, #ef4444); border-radius: 16px; display: flex; align-items: center; justify-content: center; margin: 0 auto 24px; font-size: 26px; }
        h1 { font-size: 22px; margin-bottom: 12px; }
        .message { color: #71717a; font-size: 14px; line-height: 1.6; }
    </style>
</head>
<body>
    <div class="bg-orb bg-orb-1"></div>
    <div class="card">
        <div class="icon-wrap">✕</div>
        <h1>Access Denied</h1>
        <p class="message">${message}</p>
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

  // Odczyt lub utworzenie ciasteczka "stage1_passed" (chroni przed omijaniem pierwszego linku)
  const cookies = parseCookies(req.headers.cookie);
  const hasStage1Token = cookies['nexohub_stage_1'] === 'passed';

  if (!isFromLinkvertise) {
    // Ktoś wszedł z palca
    return res.status(403).send(getErrorHTML(
      "Direct skipping is blocked.<br>You must go through the executor's Get Key process."
    ));
  }

  // WERYFIKACJA ETAPÓW
  if (!hasStage1Token) {
    // -------------------------------------------------------------
    // ETAP 1 (Pierwszy Linkvertise ukończony - użytkownik tu trafia)
    // Ustawiamy ciastko "stage_1 passed" ważne przez 1 godzinę.
    // -------------------------------------------------------------
    const options = [
      'HttpOnly',               // Ciastko nie do odczytu przez JS użytkownika (bezpieczeństwo)
      'Secure',                 // Wymaga HTTPS
      'SameSite=Lax',           // Zabezpiecza przed pewnymi atakami, pozwala na dołączanie ciastka po redirectach
      'Path=/',                 // Ważne w całej domenie
      `Max-Age=${60 * 60}`      // Traci ważność po 1 godzinie (jeśli nie zacznie Stage 2, traci postęp)
    ];
    
    res.setHeader('Set-Cookie', `nexohub_stage_1=passed; ${options.join('; ')}`);
    
    // Zwracamy ekran STAGE 1, nakazujący klinąć w STAGE 2 Link
    return res.status(200).send(getStage1CompleteHTML());
  } 
  else {
    // -------------------------------------------------------------
    // ETAP 2 (Drugi Linkvertise ukończony + użytkownik miał ciastko z Etapu 1)
    // Sukces - pokazujemy ostateczny klucz i USUWAMY ciastko, żeby następnym razem 
    // znowu musiał przejść proces od nowa.
    // -------------------------------------------------------------
    res.setHeader('Set-Cookie', 'nexohub_stage_1=; Max-Age=0; Path=/; HttpOnly; Secure');
    
    return res.status(200).send(getSuccessHTML(currentKey));
  }
};
