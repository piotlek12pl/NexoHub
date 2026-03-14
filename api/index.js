// api/generateKey.js
// Ten plik będzie działał na Vercel jako Serverless Function

// Prosty sposób na wygenerowanie dzisiejszego klucza na podstawie daty i tajnego "Solu"
function getDailyKey() {
  const date = new Date();
  const dateString = `${date.getUTCFullYear()}-${date.getUTCMonth() + 1}-${date.getUTCDate()}`;
  
  // Tworzymy unikalny klucz dla danego dnia
  // W prawdziwym środowisku użylibyśmy modułu "crypto" do hashowania
  // Ale dla prostoty i braku zależności zrobimy to prosto:
  
  let hash = 0;
  const str = dateString + "NEXOHUB_SECRET_SALT_2026"; 
  for (let i = 0; i < str.length; i++) {
    hash = ((hash << 5) - hash) + str.charCodeAt(i);
    hash |= 0; // Convert to 32bit integer
  }
  
  // Zwracamy przyjazny dla użytkownika klucz
  return "NEXO-" + Math.abs(hash).toString(16).toUpperCase();
}

module.exports = (req, res) => {
  // Ustawiamy nagłówki CORS, aby skrypt z Robloxa mógł to odczytać
  res.setHeader('Access-Control-Allow-Credentials', true)
  res.setHeader('Access-Control-Allow-Origin', '*')
  res.setHeader('Access-Control-Allow-Methods', 'GET,OPTIONS')
  
  if (req.method === 'OPTIONS') {
    res.status(200).end()
    return
  }

  // Odczytujemy dzienny klucz
  const currentKey = getDailyKey();

  // Sprawdzamy czy to zapytanie o WERYFIKACJĘ klucza (z poziomu Robloxa)
  if (req.query.verify) {
    if (req.query.verify === currentKey) {
      return res.status(200).json({ valid: true, message: "Key is correct" });
    } else {
      return res.status(403).json({ valid: false, message: "Invalid or expired key" });
    }
  }

  // Domyślne zapytanie - GENEROWANIE strony ze zdobytym kluczem (Po przyjściu z Linkvertise)
  const htmlDoc = `
  <!DOCTYPE html>
  <html lang="pl">
  <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>NexoHub - Your Key</title>
      <style>
          body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #0d0d0e; color: white; display: flex; flex-direction: column; align-items: center; justify-content: center; height: 100vh; margin: 0; }
          .container { background-color: #141416; padding: 40px; border-radius: 12px; border: 1px solid #232326; text-align: center; box-shadow: 0 10px 30px rgba(0,0,0,0.5); }
          h1 { color: #ff2d41; margin-top: 0; }
          .key-box { background-color: #1a1a1c; border: 1px dashed #444; padding: 15px 30px; font-size: 24px; font-weight: bold; letter-spacing: 2px; margin: 20px 0; border-radius: 8px; color: #fff; user-select: all; }
          p { color: #aaa; margin-bottom: 5px; }
          .info { font-size: 12px; color: #666; margin-top: 20px; }
      </style>
  </head>
  <body>
      <div class="container">
          <h1>Thank you for supporting NexoHub!</h1>
          <p>Here is your daily access key (expires in 24h):</p>
          <div class="key-box">${currentKey}</div>
          <p>Copy this key and paste it into the executor.</p>
          <div class="info">This key is generated uniquely for today and will automatically expire.</div>
      </div>
  </body>
  </html>
  `;
  
  res.setHeader('Content-Type', 'text/html; charset=utf-8');
  res.status(200).send(htmlDoc);
};
