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

// Strona HTML z kluczem (sukces)
function getSuccessHTML(key) {
  return `
  <!DOCTYPE html>
  <html lang="pl">
  <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>NexoHub - Your Key</title>
      <style>
          * { margin: 0; padding: 0; box-sizing: border-box; }
          body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #0d0d0e; color: white; display: flex; flex-direction: column; align-items: center; justify-content: center; height: 100vh; }
          .container { background-color: #141416; padding: 40px 50px; border-radius: 14px; border: 1px solid #232326; text-align: center; box-shadow: 0 10px 40px rgba(0,0,0,0.6); max-width: 500px; width: 90%; }
          h1 { color: #ff2d41; margin-bottom: 10px; font-size: 22px; }
          .subtitle { color: #aaa; margin-bottom: 25px; font-size: 14px; }
          .key-box { background-color: #1a1a1c; border: 1px dashed #ff2d41; padding: 18px 30px; font-size: 26px; font-weight: bold; letter-spacing: 3px; margin: 20px 0; border-radius: 10px; color: #fff; user-select: all; cursor: pointer; transition: all 0.2s; }
          .key-box:hover { background-color: #222; border-color: #ff5068; }
          .copy-hint { color: #666; font-size: 12px; margin-top: 5px; }
          .info { font-size: 12px; color: #444; margin-top: 25px; }
          .checkmark { font-size: 40px; margin-bottom: 15px; }
      </style>
  </head>
  <body>
      <div class="container">
          <div class="checkmark">✅</div>
          <h1>Verification Complete!</h1>
          <p class="subtitle">Here is your daily access key (expires in 24h):</p>
          <div class="key-box" onclick="navigator.clipboard.writeText('${key}');this.style.borderColor='#00ff88';document.getElementById('hint').textContent='Copied to clipboard!'">${key}</div>
          <p class="copy-hint" id="hint">Click the key to copy it</p>
          <p class="info">Paste this key into the executor and click Submit.</p>
      </div>
  </body>
  </html>
  `;
}

// Strona HTML z błędem
function getErrorHTML(message) {
  return `
  <!DOCTYPE html>
  <html lang="pl">
  <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>NexoHub - Access Denied</title>
      <style>
          * { margin: 0; padding: 0; box-sizing: border-box; }
          body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #0d0d0e; color: white; display: flex; flex-direction: column; align-items: center; justify-content: center; height: 100vh; }
          .container { background-color: #141416; padding: 40px 50px; border-radius: 14px; border: 1px solid #2a1a1a; text-align: center; box-shadow: 0 10px 40px rgba(0,0,0,0.6); max-width: 500px; width: 90%; }
          h1 { color: #ff2d41; margin-bottom: 10px; font-size: 22px; }
          .message { color: #aaa; margin: 20px 0; font-size: 15px; line-height: 1.6; }
          .error-icon { font-size: 40px; margin-bottom: 15px; }
          .info { font-size: 12px; color: #444; margin-top: 25px; }
      </style>
  </head>
  <body>
      <div class="container">
          <div class="error-icon">❌</div>
          <h1>Access Denied</h1>
          <p class="message">${message}</p>
          <p class="info">Please use the Get Key button in the executor to get your key.</p>
      </div>
  </body>
  </html>
  `;
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
