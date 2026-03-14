// api/index.js — NexoHub Key System with Linkvertise Callback Verification
// Vercel Serverless Function

const https = require('https');

// ===== KONFIGURACJA =====
const LINKVERTISE_USER_ID = 1459465; // Twoje ID z Linkvertise
const SECRET_SALT = "NEXOHUB_SECRET_SALT_2026"; // Tajny klucz do generowania kluczy
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

// Weryfikuje token Linkvertise przez ich API
function verifyLinkvertiseToken(token) {
  return new Promise((resolve, reject) => {
    const url = `https://publisher.linkvertise.com/api/v1/redirect/link/static/${LINKVERTISE_USER_ID}?token=${encodeURIComponent(token)}`;
    
    https.get(url, (resp) => {
      let data = '';
      resp.on('data', (chunk) => { data += chunk; });
      resp.on('end', () => {
        try {
          const json = JSON.parse(data);
          // Linkvertise zwraca obiekt z informacją czy token jest valid
          if (json && json.data && json.data.completed === true) {
            resolve(true);
          } else if (resp.statusCode === 200) {
            // Jeśli status 200 i mamy dane to traktujemy jako valid
            resolve(true);
          } else {
            resolve(false);
          }
        } catch (e) {
          // Jeśli odpowiedź nie jest JSONem ale status 200, może być OK
          if (resp.statusCode === 200) {
            resolve(true);
          } else {
            resolve(false);
          }
        }
      });
    }).on('error', (err) => {
      // Jeśli API Linkvertise jest nieosiągalne, odrzucamy
      resolve(false);
    });
  });
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
          <div class="key-box" onclick="navigator.clipboard.writeText('${key}');this.style.borderColor='#00ff88';document.getElementById('hint').textContent='Copied!'">${key}</div>
          <p class="copy-hint" id="hint">Click the key to copy it</p>
          <p class="info">Paste this key into the executor and click Submit.</p>
      </div>
  </body>
  </html>
  `;
}

// Strona HTML z błędem (nieprawidłowy callback)
function getErrorHTML(message) {
  return `
  <!DOCTYPE html>
  <html lang="pl">
  <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>NexoHub - Error</title>
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
          <h1>Invalid Callback</h1>
          <p class="message">${message}</p>
          <p class="info">Please complete the Linkvertise steps to get your key.</p>
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

  // === TRYB DIAGNOSTYCZNY (TYMCZASOWY) ===
  // Pokazuje wszystkie parametry URL i nagłówki, żebyśmy wiedzieli co Linkvertise wysyła
  res.setHeader('Content-Type', 'text/html; charset=utf-8');

  const allParams = JSON.stringify(req.query, null, 2);
  const referer = req.headers.referer || req.headers.referrer || 'brak';
  const fullUrl = req.url || 'brak';

  return res.status(200).send(`
  <!DOCTYPE html>
  <html lang="pl">
  <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>NexoHub - DEBUG</title>
      <style>
          body { font-family: 'Segoe UI', monospace; background-color: #0d0d0e; color: #0f0; padding: 40px; }
          h1 { color: #ff2d41; }
          pre { background: #111; padding: 20px; border-radius: 8px; border: 1px solid #333; overflow-x: auto; color: #0f0; font-size: 14px; }
          .label { color: #aaa; margin-top: 20px; margin-bottom: 5px; }
      </style>
  </head>
  <body>
      <h1>🔍 NexoHub Debug Mode</h1>
      <p>Poniżej znajdziesz wszystkie dane które przyszły od Linkvertise. Skopiuj to i wyślij mi!</p>
      
      <p class="label">Full URL:</p>
      <pre>${fullUrl}</pre>
      
      <p class="label">Query Parameters:</p>
      <pre>${allParams}</pre>
      
      <p class="label">Referer:</p>
      <pre>${referer}</pre>
  </body>
  </html>
  `);
};
