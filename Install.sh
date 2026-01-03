#!/bin/bash
set -e

BOT_DIR="/root/ssh-wa-bot"

echo "======================================"
echo "     WASSH BOT - INSTALADOR FINAL"
echo "======================================"

sleep 1

# ===============================
# Dependencias base
# ===============================
apt update -y
apt install -y curl git jq

# ===============================
# Node.js 20
# ===============================
if ! command -v node >/dev/null; then
  curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
  apt install -y nodejs
fi

# ===============================
# PM2
# ===============================
if ! command -v pm2 >/dev/null; then
  npm install -g pm2
fi

# ===============================
# Crear carpeta
# ===============================
mkdir -p $BOT_DIR
cd $BOT_DIR

# ===============================
# package.json
# ===============================
cat > package.json <<'EOF'
{
  "name": "wassh-bot",
  "version": "1.0.0",
  "type": "module",
  "dependencies": {
    "@whiskeysockets/baileys": "^6.7.7",
    "qrcode-terminal": "^0.12.0"
  }
}
EOF

# ===============================
# config.json
# ===============================
cat > config.json <<'EOF'
{
  "whatsapp": {
    "admin": "5493810000000"
  },
  "mercadopago": {
    "token": ""
  },
  "vps": {
    "ip": "127.0.0.1"
  }
}
EOF

# ===============================
# index.js (QR + menú tipo Movistar)
# ===============================
cat > index.js <<'EOF'
import makeWASocket from '@whiskeysockets/baileys'
import qrcode from 'qrcode-terminal'
import fs from 'fs'

const config = JSON.parse(fs.readFileSync('./config.json'))

console.log('▶ Iniciando bot WhatsApp...')

const sock = makeWASocket({
  printQRInTerminal: false,
  browser: ['WASSH', 'Chrome', '1.0']
})

sock.ev.on('connection.update', (update) => {
  const { connection, qr } = update

  if (qr) {
    console.log('\n📲 ESCANEÁ ESTE QR:\n')
    qrcode.generate(qr, { small: true })
  }

  if (connection === 'open') {
    console.log('✅ Bot conectado correctamente')
  }

  if (connection === 'close') {
    console.log('❌ Conexión cerrada')
  }
})

sock.ev.on('messages.upsert', async ({ messages }) => {
  const msg = messages[0]
  if (!msg.message) return

  const jid = msg.key.remoteJid
  const text =
    msg.message.conversation ||
    msg.message.extendedTextMessage?.text ||
    ''

  const cmd = text.toLowerCase().trim()

  if (cmd === 'menu' || cmd === 'hola') {
    await sock.sendMessage(jid, {
      text:
`📡 *WASSH SSH PREMIUM*

🟢 *SERVICIOS*
━━━━━━━━━━━━━━
1️⃣ Comprar
2️⃣ Crear Usuario
3️⃣ Test Gratis

🆘 Soporte
━━━━━━━━━━━━━━
📲 WhatsApp Admin

✍️ Escribí una opción`
    })
  }
})
EOF

# ===============================
# Menú VPS (wassh)
# ===============================
cat > wassh.sh <<'EOF'
#!/bin/bash
CONFIG="/root/ssh-wa-bot/config.json"

while true; do
  clear
  echo "=============================="
  echo "        WASSH VPS MENU"
  echo "=============================="
  echo "1) Cambiar WhatsApp admin"
  echo "2) Configurar MercadoPago"
  echo "3) Configurar IP VPS"
  echo "4) Ver estado bot"
  echo "5) Reiniciar bot"
  echo "0) Salir"
  echo "=============================="
  read -p "Opción: " op

  case $op in
    1)
      read -p "Nuevo número (549...): " n
      jq ".whatsapp.admin=\"$n\"" $CONFIG > tmp && mv tmp $CONFIG
      ;;
    2)
      read -p "Token MercadoPago: " t
      jq ".mercadopago.token=\"$t\"" $CONFIG > tmp && mv tmp $CONFIG
      ;;
    3)
      read -p "IP VPS: " ip
      jq ".vps.ip=\"$ip\"" $CONFIG > tmp && mv tmp $CONFIG
      ;;
    4)
      pm2 status wa-bot
      read -p "Enter..."
      ;;
    5)
      pm2 restart wa-bot
      ;;
    0)
      exit
      ;;
  esac
done
EOF

chmod +x wassh.sh
ln -sf $BOT_DIR/wassh.sh /usr/bin/wassh

# ===============================
# Instalar dependencias JS
# ===============================
npm install

# ===============================
# MOSTRAR QR (PRIMER LOGIN)
# ===============================
echo ""
echo "======================================"
echo " 📲 ESCANEÁ EL QR A CONTINUACIÓN"
echo " Cuando conecte, presioná CTRL+C"
echo "======================================"
echo ""

node index.js || true

# ===============================
# Iniciar con PM2
# ===============================
pm2 start index.js --name wa-bot
pm2 save

echo ""
echo "======================================"
echo " ✅ INSTALACIÓN COMPLETA"
echo "======================================"
echo "📱 Bot activo"
echo "🧩 Menú VPS: wassh"
echo "📜 Logs: pm2 logs wa-bot"
echo ""
