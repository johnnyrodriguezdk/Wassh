#!/bin/bash

export DEBIAN_FRONTEND=noninteractive
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
pkill -f wassh 2>/dev/null || true
pkill -f node 2>/dev/null || true

echo "[1/9] Eliminando instalación previa..."
rm -rf "$BASE"
rm -f "$BIN"

echo "[2/9] Actualizando índices APT..."
apt update -y || true

echo "[3/9] Instalando dependencias..."
apt install -y curl wget git jq nano build-essential || true

echo "[4/9] Instalando Node.js 20 (limpio)..."

apt remove -y nodejs libnode-dev >/dev/null 2>&1 || true
apt purge -y nodejs libnode-dev >/dev/null 2>&1 || true
apt autoremove -y >/dev/null 2>&1 || true
rm -rf /usr/include/node /usr/lib/node_modules

curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt install -y nodejs

echo "[5/9] Creando estructura..."
mkdir -p "$BASE"/{bot,config,data,session}

echo "[6/9] Creando JSON de configuración..."

cat > "$BASE/config/bot.json" <<EOF
{
  "bot_name": "WASSH BOT",
  "whatsapp": "",
  "session": "/opt/wassh/session"
}
EOF

cat > "$BASE/config/mp.json" <<EOF
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

cat > "$BASE/config/ssh.json" <<EOF
{
  "adduser_script": "/bin/adduser",
  "test_days": 1,
  "test_limit": 1,
  "default_limit": 2
}
EOF

echo "{}" > "$BASE/data/orders.json"
echo "{}" > "$BASE/data/users.json"

echo "[7/9] Instalando BOT WhatsApp..."

cd "$BASE/bot" || exit 1

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
    if (connection === 'open') console.log("✅ Bot conectado")
    if (connection === 'close') console.log("❌ Conexión cerrada")
  })

  sock.ev.on('creds.update', saveCreds)
}

startBot()
EOF

echo "[8/9] Creando comando wassh..."

cat > "$BIN" <<'EOF'
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
  jq ".whatsapp=\"$num\"" "$CONF" > /tmp/bot.json && mv /tmp/bot.json "$CONF"
  echo "✅ Número guardado"
;;
2)
  nano /opt/wassh/config/mp.json
;;
3)
  pkill -f node 2>/dev/null || true
  nohup node /opt/wassh/bot/index.js >/var/log/wassh.log 2>&1 &
  echo "🤖 Bot iniciado"
;;
0) exit ;;
esac
EOF

chmod +x "$BIN"

echo "[9/9] INSTALACIÓN COMPLETA"
echo
echo "👉 Ejecutar: wassh"
echo "👉 Configurar número"
echo "👉 Iniciar bot"
echo
