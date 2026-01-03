#!/bin/bash
set -e

clear
echo "==============================="
echo "      WASSH INSTALLER"
echo "==============================="

# Verificar root
if [ "$EUID" -ne 0 ]; then
  echo "Ejecutar como root"
  exit 1
fi

# Variables
BASE="/opt/wassh"
BOT="$BASE/bot"
CONF="$BASE/config"
DATA="$BASE/data"
BIN="/usr/bin/wassh"

echo "[1/8] Actualizando sistema..."
apt update -y && apt upgrade -y

echo "[2/8] Instalando dependencias..."
apt install -y curl wget git unzip build-essential

echo "[3/8] Instalando Node.js 20..."
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt install -y nodejs

echo "[4/8] Creando estructura..."
mkdir -p $BOT $CONF $DATA

echo "[5/8] Creando archivos JSON..."

cat > $CONF/bot.json <<EOF
{
  "bot_name": "WASSH BOT",
  "whatsapp": "",
  "session": "session"
}
EOF

cat > $CONF/mp.json <<EOF
{
  "access_token": "",
  "currency": "ARS",
  "prices": {
    "7": 500,
    "15": 900,
    "30": 1500
  },
  "webhook_port": 3333
}
EOF

cat > $CONF/ssh.json <<EOF
{
  "adduser_script": "/bin/adduser",
  "test_days": 1,
  "test_limit": 1,
  "default_limit": 2
}
EOF

echo "{}" > $DATA/orders.json
echo "{}" > $DATA/users.json

echo "[6/8] Instalando bot WhatsApp..."

cd $BOT

cat > package.json <<EOF
{
  "name": "wassh",
  "version": "1.0.0",
  "type": "module",
  "dependencies": {
    "@whiskeysockets/baileys": "^6.7.2",
    "express": "^4.19.2",
    "mercadopago": "^1.5.17",
    "qrcode-terminal": "^0.12.0"
  }
}
EOF

npm install

cat > index.js <<'EOF'
import fs from 'fs'
import makeWASocket, { useMultiFileAuthState, DisconnectReason } from '@whiskeysockets/baileys'
import qrcode from 'qrcode-terminal'

const config = JSON.parse(fs.readFileSync('/opt/wassh/config/bot.json'))

async function startBot() {
  if (!config.whatsapp) {
    console.log("⚠️ Configure el número desde el menú: wassh")
    return
  }

  const { state, saveCreds } = await useMultiFileAuthState(config.session)

  const sock = makeWASocket({
    auth: state,
    printQRInTerminal: false
  })

  sock.ev.on('connection.update', ({ qr, connection }) => {
    if (qr) {
      console.log("📱 Escanee el QR:")
      qrcode.generate(qr, { small: true })
    }
    if (connection === 'close') {
      console.log("❌ Conexión cerrada")
    }
    if (connection === 'open') {
      console.log("✅ Bot conectado")
    }
  })

  sock.ev.on('creds.update', saveCreds)
}

startBot()
EOF

echo "[7/8] Creando comando wassh..."

cat > $BIN <<'EOF'
#!/bin/bash

CONF="/opt/wassh/config/bot.json"

clear
echo "====== WASSH MANAGER ======"
echo "1) Configurar número WhatsApp"
echo "2) Configurar MercadoPago"
echo "3) Reiniciar bot"
echo "0) Salir"
read -p "Opción: " op

case $op in
1)
  read -p "Número WhatsApp (549...): " num
  jq ".whatsapp=\"$num\"" $CONF > /tmp/bot.json && mv /tmp/bot.json $CONF
  echo "Número guardado"
;;
2)
  nano /opt/wassh/config/mp.json
;;
3)
  pkill node || true
  node /opt/wassh/bot/index.js &
  echo "Bot reiniciado"
;;
0)
  exit
;;
esac
EOF

chmod +x $BIN

echo "[8/8] Instalación finalizada"
echo
echo "👉 Ejecutar: wassh"
echo "👉 Configurar número WhatsApp"
echo "👉 Luego reiniciar bot para mostrar QR"
echo
