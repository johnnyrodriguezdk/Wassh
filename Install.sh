#!/bin/bash
set -e

clear
echo "=================================="
echo "   WASSH INSTALLER (RESET TOTAL)"
echo "=================================="

# Root check
if [ "$EUID" -ne 0 ]; then
  echo "❌ Ejecutar como root"
  exit 1
fi

BASE="/opt/wassh"
BIN="/usr/bin/wassh"

echo "[0/9] Deteniendo procesos anteriores..."
pkill -f wassh || true
pkill -f node || true

echo "[1/9] Eliminando instalación previa..."
rm -rf $BASE
rm -f $BIN

echo "[2/9] Actualizando sistema..."
apt update -y >/dev/null 2>&1
apt upgrade -y >/dev/null 2>&1

echo "[3/9] Instalando dependencias base..."
apt install -y curl wget git unzip jq build-essential >/dev/null 2>&1

echo "[4/9] Instalando Node.js 20..."
if ! node -v | grep -q "v20"; then
  curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
  apt install -y nodejs
fi

echo "[5/9] Creando estructura..."
mkdir -p $BASE/{bot,config,data}

echo "[6/9] Creando JSON base..."

cat > $BASE/config/bot.json <<EOF
{
  "bot_name": "WASSH BOT",
  "whatsapp": "",
  "session": "session"
}
EOF

cat > $BASE/config/mp.json <<EOF
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

cat > $BASE/config/ssh.json <<EOF
{
  "adduser_script": "/bin/adduser",
  "test_days": 1,
  "test_limit": 1,
  "default_limit": 2
}
EOF

echo "{}" > $BASE/data/orders.json
echo "{}" > $BASE/data/users.json

echo "[7/9] Instalando bot WhatsApp..."

cd $BASE/bot

cat > package.json <<EOF
{
  "name": "wassh",
  "version": "2.0.0",
  "type": "module",
  "dependencies": {
    "@whiskeysockets/baileys": "^6.7.2",
    "express": "^4.19.2",
    "mercadopago": "^1.5.17",
    "qrcode-terminal": "^0.12.0"
  }
}
EOF

npm install >/dev/null 2>&1

cat > index.js <<'EOF'
import fs from 'fs'
import makeWASocket, { useMultiFileAuthState } from '@whiskeysockets/baileys'
import qrcode from 'qrcode-terminal'

const BOTCONF = '/opt/wassh/config/bot.json'
const config = JSON.parse(fs.readFileSync(BOTCONF))

async function start() {
  if (!config.whatsapp) {
    console.log("⚠️ Configure el número usando: wassh")
    return
  }

  const { state, saveCreds } = await useMultiFileAuthState('/opt/wassh/session')

  const sock = makeWASocket({
    auth: state,
    printQRInTerminal: false
  })

  sock.ev.on('connection.update', ({ qr, connection }) => {
    if (qr) {
      console.log("📱 Escanee el QR:")
      qrcode.generate(qr, { small: true })
    }
    if (connection === 'open') {
      console.log("✅ Bot conectado correctamente")
    }
    if (connection === 'close') {
      console.log("❌ Conexión cerrada")
    }
  })

  sock.ev.on('creds.update', saveCreds)
}

start()
EOF

echo "[8/9] Creando comando wassh..."

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
  echo "✅ Número guardado"
;;
2)
  nano /opt/wassh/config/mp.json
;;
3)
  pkill -f node || true
  nohup node /opt/wassh/bot/index.js >/var/log/wassh.log 2>&1 &
  echo "♻️ Bot reiniciado"
;;
0)
  exit
;;
esac
EOF

chmod +x $BIN

echo "[9/9] INSTALACIÓN COMPLETA"
echo
echo "👉 Ejecutar: wassh"
echo "👉 Configurar número WhatsApp"
echo "👉 Reiniciar bot para mostrar QR"
echo
