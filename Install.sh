#!/bin/bash
set -e

DIR="/root/ssh-wa-bot"

echo "======================================"
echo "      WASSH BOT - INSTALADOR"
echo "======================================"

# 🔹 Dependencias base
apt update -y
apt install -y curl git jq

# 🔹 Node.js 20
if ! command -v node >/dev/null; then
  curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
  apt install -y nodejs
fi

# 🔹 PM2
if ! command -v pm2 >/dev/null; then
  npm install -g pm2
fi

# 🔹 Crear directorio
mkdir -p $DIR
cd $DIR

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
    "numero_admin": "5493810000000"
  },
  "mercadopago": {
    "token": ""
  },
  "vps": {
    "ip": "127.0.0.1",
    "puerto": "22"
  }
}
EOF

# ===============================
# index.js
# ===============================
cat > index.js <<'EOF'
import makeWASocket from '@whiskeysockets/baileys'
import fs from 'fs'
import qrcode from 'qrcode-terminal'

const config = JSON.parse(fs.readFileSync('./config.json'))

console.log('▶ Iniciando bot WhatsApp...')

const sock = makeWASocket({
  printQRInTerminal: false
})

sock.ev.on('connection.update', (update) => {
  if (update.qr) {
    qrcode.generate(update.qr, { small: true })
  }
  if (update.connection === 'close') {
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

  if (cmd === 'menu') {
    await sock.sendMessage(jid, {
      text:
`📡 SSH PREMIUM

1️⃣ Comprar
2️⃣ Crear Usuario
3️⃣ Test

Escribí la opción`
    })
  }
})
EOF

# ===============================
# wassh.sh (menú VPS)
# ===============================
cat > wassh.sh <<'EOF'
#!/bin/bash
CONFIG="/root/ssh-wa-bot/config.json"

clear
while true; do
  echo "=============================="
  echo "        WASSH BOT"
  echo "=============================="
  echo "1) Cambiar WhatsApp admin"
  echo "2) Configurar MercadoPago"
  echo "3) Configurar IP VPS"
  echo "4) Estado del bot"
  echo "5) Reiniciar bot"
  echo "0) Salir"
  echo "=============================="
  read -p "Opción: " op

  case $op in
    1)
      read -p "Nuevo número (549...): " num
      jq ".whatsapp.numero_admin=\"$num\"" $CONFIG > tmp && mv tmp $CONFIG
      ;;
    2)
      read -p "Token MercadoPago: " tok
      jq ".mercadopago.token=\"$tok\"" $CONFIG > tmp && mv tmp $CONFIG
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
ln -sf $DIR/wassh.sh /usr/bin/wassh

# 🔹 Instalar dependencias JS
npm install

# 🔹 Iniciar bot
pm2 start index.js --name wa-bot
pm2 save

echo ""
echo "======================================"
echo " ✔ INSTALACIÓN COMPLETA"
echo "======================================"
echo "📱 Escaneá el QR"
echo "🧩 Abrir menú VPS: wassh"
echo "📜 Logs: pm2 logs wa-bot"
echo ""
