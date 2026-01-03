#!/bin/bash
set -e

clear
echo "===================================="
echo "      WASSH FULL INSTALLER"
echo "===================================="

# Root
if [ "$EUID" -ne 0 ]; then
  echo "Ejecutar como root"
  exit 1
fi

BASE="/opt/wassh"
BIN="/usr/bin/wassh"

echo "[1/10] Deteniendo procesos previos..."
pkill -f wassh || true
pkill -f node || true

echo "[2/10] Eliminando instalación anterior..."
rm -rf $BASE
rm -f $BIN

echo "[3/10] Actualizando sistema..."
apt update -y && apt upgrade -y

echo "[4/10] Instalando dependencias..."
apt install -y curl wget git jq nano build-essential

echo "[5/10] Instalando Node.js 20..."
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt install -y nodejs

echo "[6/10] Creando estructura..."
mkdir -p $BASE/{bot,config,data,session}

echo "[7/10] Creando JSON de configuración..."

cat > $BASE/config/bot.json <<EOF
{
  "bot_name": "WASSH BOT",
  "whatsapp": "",
  "session": "/opt/wassh/session"
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
  }
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

echo "[8/10] Instalando BOT WhatsApp..."

cd $BASE/bot

cat > package.json <<EOF
{
  "name": "wassh-bot",
  "version": "1.0.0",
  "type": "module",
  "dependencies": {
    "@whiskeysockets/baileys": "^6.7.2",
    "qrcode-terminal": "^0.12.0"
  }
}
EOF

npm install

cat > index.js <<'EOF'
import fs from 'fs'
import makeWASocket, { useMultiFileAuthState } from '@whiskeysockets/baileys'
import qrcode from 'qrcode-terminal'

const CONF = '/opt/wassh/config/bot.json'
const config = JSON.parse(fs.readFileSync(CONF))

async function startBot() {
  if (!config.whatsapp) {
    console.log("⚠️ Configure el número con: wassh")
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
    if (connection === 'open') {
      console.log("✅ Bot conectado correctamente")
    }
    if (connection === 'close') {
      console.log("❌ Conexión cerrada")
    }
  })

  sock.ev.on('creds.update', saveCreds)

  sock.ev.on('messages.upsert', async ({ messages }) => {
    const msg = messages[0]
    if (!msg.message || msg.key.fromMe) return

    const text = msg.message.conversation || ""
    if (text === "menu") {
      await sock.sendMessage(msg.key.remoteJid, {
        text: "🟢 WASSH BOT\n\n1️⃣ Comprar SSH\n2️⃣ Test Gratis\n3️⃣ Info"
      })
    }
  })
}

startBot()
EOF

echo "[9/10] Creando comando wassh..."

cat > $BIN <<'EOF'
#!/bin/bash
CONF="/opt/wassh/config/bot.json"

clear
echo "====== WASSH MANAGER ======"
echo "1) Configurar número WhatsApp"
echo "2) Configurar MercadoPago"
echo "3) Iniciar / Reiniciar bot"
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
  pkill -f node || true
  nohup node /opt/wassh/bot/index.js >/var/log/wassh.log 2>&1 &
  echo "Bot iniciado"
;;
0) exit ;;
esac
EOF

chmod +x $BIN

echo "[10/10] INSTALACIÓN FINALIZADA"
echo
echo "👉 Ejecutar: wassh"
echo "👉 Configurar número"
echo "👉 Iniciar bot y escanear QR"
echo
