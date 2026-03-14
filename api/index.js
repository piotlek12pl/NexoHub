// api/index.js — NexoHub Key System with Linkvertise Referer Verification
// Vercel Serverless Function

// ===== KONFIGURACJA =====
const SECRET_SALT = "NEXOHUB_SECRET_SALT_2026";
// =========================

// Generuje unikalny klucz na dany dzień
function getDailyKey() {
  const date = new Date();
  const dateString = `${date.getUTCFullYear()}-${date.getUTCMonth() + 1}-${date.getUTCDate()}`;
  
  let hash = 0;
  const str = dateString + SECRET_SALT;
  for (let i = 0; i < str.length; i++) {
    hash = ((hash << 5) - hash) + str.charCodeAt(i);
    hash |= 0;
  }
  
  return "NEXO-" + Math.abs(hash).toString(16).toUpperCase();
}

// Strona HTML z kluczem (sukces) — PREMIUM DESIGN
function getSuccessHTML(key) {
  return `<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>NexoHub — Key System</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800&display=swap" rel="stylesheet">
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        
        body {
            font-family: 'Inter', -apple-system, BlinkMacSystemFont, sans-serif;
            background: #09090b;
            color: #fafafa;
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            overflow: hidden;
            position: relative;
        }

        /* Animated gradient background orbs */
        .bg-orb {
            position: fixed;
            border-radius: 50%;
            filter: blur(80px);
            opacity: 0.15;
            animation: float 8s ease-in-out infinite;
        }
        .bg-orb-1 {
            width: 400px; height: 400px;
            background: #ef4444;
            top: -100px; left: -100px;
            animation-delay: 0s;
        }
        .bg-orb-2 {
            width: 300px; height: 300px;
            background: #f97316;
            bottom: -80px; right: -80px;
            animation-delay: -4s;
        }
        .bg-orb-3 {
            width: 200px; height: 200px;
            background: #dc2626;
            top: 50%; left: 50%;
            transform: translate(-50%, -50%);
            animation-delay: -2s;
        }

        @keyframes float {
            0%, 100% { transform: translate(0, 0) scale(1); }
            33% { transform: translate(30px, -20px) scale(1.05); }
            66% { transform: translate(-20px, 15px) scale(0.95); }
        }

        .card {
            position: relative;
            z-index: 10;
            background: rgba(17, 17, 20, 0.85);
            backdrop-filter: blur(40px);
            -webkit-backdrop-filter: blur(40px);
            border: 1px solid rgba(255, 255, 255, 0.06);
            border-radius: 20px;
            padding: 48px 44px;
            max-width: 460px;
            width: 92%;
            text-align: center;
            box-shadow: 0 25px 60px rgba(0,0,0,0.5), 0 0 0 1px rgba(255,255,255,0.03) inset;
            animation: cardIn 0.6s cubic-bezier(0.16, 1, 0.3, 1) both;
        }

        @keyframes cardIn {
            from { opacity: 0; transform: translateY(30px) scale(0.96); }
            to { opacity: 1; transform: translateY(0) scale(1); }
        }

        .icon-wrap {
            width: 64px; height: 64px;
            background: linear-gradient(135deg, #16a34a, #22c55e);
            border-radius: 16px;
            display: flex;
            align-items: center;
            justify-content: center;
            margin: 0 auto 24px;
            font-size: 28px;
            box-shadow: 0 8px 24px rgba(34, 197, 94, 0.25);
            animation: iconPop 0.5s cubic-bezier(0.34, 1.56, 0.64, 1) 0.3s both;
        }

        @keyframes iconPop {
            from { opacity: 0; transform: scale(0.5); }
            to { opacity: 1; transform: scale(1); }
        }

        h1 {
            font-size: 22px;
            font-weight: 700;
            margin-bottom: 6px;
            letter-spacing: -0.3px;
        }

        .subtitle {
            color: #71717a;
            font-size: 14px;
            font-weight: 400;
            margin-bottom: 28px;
        }

        .key-container {
            position: relative;
            background: rgba(255,255,255,0.03);
            border: 1px solid rgba(255,255,255,0.08);
            border-radius: 12px;
            padding: 20px 24px;
            margin-bottom: 12px;
            cursor: pointer;
            transition: all 0.25s ease;
            animation: keySlide 0.5s cubic-bezier(0.16, 1, 0.3, 1) 0.5s both;
        }

        @keyframes keySlide {
            from { opacity: 0; transform: translateY(10px); }
            to { opacity: 1; transform: translateY(0); }
        }

        .key-container:hover {
            border-color: rgba(239, 68, 68, 0.4);
            background: rgba(239, 68, 68, 0.05);
        }

        .key-container:active {
            transform: scale(0.98);
        }

        .key-text {
            font-size: 28px;
            font-weight: 800;
            letter-spacing: 4px;
            color: #fafafa;
            font-family: 'Inter', monospace;
        }

        .key-label {
            font-size: 11px;
            text-transform: uppercase;
            letter-spacing: 1.5px;
            color: #52525b;
            margin-bottom: 8px;
            font-weight: 600;
        }

        .copy-toast {
            font-size: 12px;
            color: #71717a;
            margin-top: 8px;
            transition: all 0.3s ease;
            animation: keySlide 0.4s cubic-bezier(0.16, 1, 0.3, 1) 0.7s both;
        }
        .copy-toast.copied {
            color: #22c55e;
        }

        .divider {
            height: 1px;
            background: rgba(255,255,255,0.06);
            margin: 24px 0;
        }

        .footer-info {
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 6px;
            font-size: 12px;
            color: #3f3f46;
            animation: keySlide 0.4s cubic-bezier(0.16, 1, 0.3, 1) 0.8s both;
        }

        .footer-info svg {
            width: 14px; height: 14px;
            fill: #3f3f46;
        }

        .badge {
            display: inline-flex;
            align-items: center;
            gap: 5px;
            background: rgba(239, 68, 68, 0.1);
            border: 1px solid rgba(239, 68, 68, 0.2);
            color: #ef4444;
            font-size: 11px;
            font-weight: 600;
            padding: 4px 10px;
            border-radius: 100px;
            margin-bottom: 20px;
            letter-spacing: 0.5px;
            animation: keySlide 0.4s cubic-bezier(0.16, 1, 0.3, 1) 0.4s both;
        }
        .badge-dot {
            width: 6px; height: 6px;
            background: #ef4444;
            border-radius: 50%;
            animation: pulse 2s ease-in-out infinite;
        }
        @keyframes pulse {
            0%, 100% { opacity: 1; }
            50% { opacity: 0.4; }
        }
    </style>
</head>
<body>
    <div class="bg-orb bg-orb-1"></div>
    <div class="bg-orb bg-orb-2"></div>
    <div class="bg-orb bg-orb-3"></div>

    <div class="card">
        <div class="icon-wrap">✓</div>
        <h1>Verification Complete</h1>
        <p class="subtitle">Your daily access key has been generated</p>
        
        <div class="badge"><span class="badge-dot"></span> Expires in 24 hours</div>

        <div class="key-container" onclick="copyKey()">
            <div class="key-label">Your Key</div>
            <div class="key-text">${key}</div>
        </div>
        <p class="copy-toast" id="toast">Click the key to copy</p>

        <div class="divider"></div>
        <div class="footer-info">
            <svg viewBox="0 0 24 24"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"/></svg>
            Paste this key into the executor and click Submit
        </div>
    </div>

    <script>
        function copyKey() {
            navigator.clipboard.writeText('${key}');
            const toast = document.getElementById('toast');
            toast.textContent = '✓ Copied to clipboard!';
            toast.classList.add('copied');
            setTimeout(() => {
                toast.textContent = 'Click the key to copy';
                toast.classList.remove('copied');
            }, 2500);
        }
    </script>
</body>
</html>`;
}

// Strona HTML z błędem — PREMIUM DESIGN
function getErrorHTML(message) {
  return `<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>NexoHub — Access Denied</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800&display=swap" rel="stylesheet">
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        
        body {
            font-family: 'Inter', -apple-system, BlinkMacSystemFont, sans-serif;
            background: #09090b;
            color: #fafafa;
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            overflow: hidden;
            position: relative;
        }

        .bg-orb {
            position: fixed;
            border-radius: 50%;
            filter: blur(80px);
            opacity: 0.1;
            animation: float 8s ease-in-out infinite;
        }
        .bg-orb-1 {
            width: 350px; height: 350px;
            background: #ef4444;
            top: -100px; right: -100px;
            animation-delay: 0s;
        }
        .bg-orb-2 {
            width: 250px; height: 250px;
            background: #991b1b;
            bottom: -60px; left: -60px;
            animation-delay: -3s;
        }

        @keyframes float {
            0%, 100% { transform: translate(0, 0) scale(1); }
            33% { transform: translate(30px, -20px) scale(1.05); }
            66% { transform: translate(-20px, 15px) scale(0.95); }
        }

        .card {
            position: relative;
            z-index: 10;
            background: rgba(17, 17, 20, 0.85);
            backdrop-filter: blur(40px);
            -webkit-backdrop-filter: blur(40px);
            border: 1px solid rgba(255, 255, 255, 0.06);
            border-radius: 20px;
            padding: 48px 44px;
            max-width: 460px;
            width: 92%;
            text-align: center;
            box-shadow: 0 25px 60px rgba(0,0,0,0.5), 0 0 0 1px rgba(255,255,255,0.03) inset;
            animation: cardIn 0.6s cubic-bezier(0.16, 1, 0.3, 1) both;
        }

        @keyframes cardIn {
            from { opacity: 0; transform: translateY(30px) scale(0.96); }
            to { opacity: 1; transform: translateY(0) scale(1); }
        }

        .icon-wrap {
            width: 64px; height: 64px;
            background: linear-gradient(135deg, #dc2626, #ef4444);
            border-radius: 16px;
            display: flex;
            align-items: center;
            justify-content: center;
            margin: 0 auto 24px;
            font-size: 26px;
            box-shadow: 0 8px 24px rgba(239, 68, 68, 0.2);
            animation: iconPop 0.5s cubic-bezier(0.34, 1.56, 0.64, 1) 0.3s both;
        }

        @keyframes iconPop {
            from { opacity: 0; transform: scale(0.5); }
            to { opacity: 1; transform: scale(1); }
        }

        h1 {
            font-size: 22px;
            font-weight: 700;
            margin-bottom: 12px;
            letter-spacing: -0.3px;
        }

        .message {
            color: #71717a;
            font-size: 14px;
            line-height: 1.7;
            margin-bottom: 28px;
        }

        .info-box {
            background: rgba(255,255,255,0.03);
            border: 1px solid rgba(255,255,255,0.06);
            border-radius: 12px;
            padding: 16px 20px;
            font-size: 13px;
            color: #52525b;
            display: flex;
            align-items: center;
            gap: 10px;
            justify-content: center;
        }

        .info-box svg {
            width: 16px; height: 16px;
            fill: #52525b;
            flex-shrink: 0;
        }
    </style>
</head>
<body>
    <div class="bg-orb bg-orb-1"></div>
    <div class="bg-orb bg-orb-2"></div>

    <div class="card">
        <div class="icon-wrap">✕</div>
        <h1>Access Denied</h1>
        <p class="message">${message}</p>
        <div class="info-box">
            <svg viewBox="0 0 24 24"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm1 15h-2v-2h2v2zm0-4h-2V7h2v6z"/></svg>
            Use the Get Key button in the executor to get your key
        </div>
    </div>
</body>
</html>`;
}

module.exports = async (req, res) => {
  // Nagłówki CORS (dla zapytań z Robloxa)
  res.setHeader('Access-Control-Allow-Credentials', true);
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET,OPTIONS');
  
  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  const currentKey = getDailyKey();

  // === TRYB 1: Weryfikacja klucza z poziomu Robloxa ===
  if (req.query.verify) {
    if (req.query.verify === currentKey) {
      return res.status(200).json({ valid: true, message: "Key is correct" });
    } else {
      return res.status(403).json({ valid: false, message: "Invalid or expired key" });
    }
  }

  // === TRYB 2: Strona z kluczem ===
  res.setHeader('Content-Type', 'text/html; charset=utf-8');

  // Sprawdzamy Referer — czy użytkownik przyszedł z Linkvertise
  const referer = (req.headers.referer || req.headers.referrer || '').toLowerCase();
  
  if (referer.includes('linkvertise.com') || referer.includes('link-to.net') || referer.includes('link-center.net') || referer.includes('link-target.net')) {
    // Użytkownik przyszedł z Linkvertise — pokazujemy klucz!
    return res.status(200).send(getSuccessHTML(currentKey));
  } else {
    // Brak referera z Linkvertise — blokujemy dostęp
    return res.status(403).send(getErrorHTML(
      "Direct access is not allowed.<br>You must complete the Linkvertise steps to receive your key."
    ));
  }
};
