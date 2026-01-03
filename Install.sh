#!/bin/bash
set -e

echo "=================================="
echo "   WASSH INSTALLER v2.1 (STABLE)"
echo "=================================="

BASE_DIR="/opt/wassh"
BOT_DIR="$BASE_DIR/bot"
CONF_DIR="$BASE_DIR/config"
SESSION_DIR="$BASE_DIR/session"
LOG_FILE="/var/log/wassh.log"
CMD_BIN="/usr/bin/wassh"

echo "[0/8] Deteniendo procesos..."
pkill -f "node.*index.js" 2>/dev/null || true
sleep 2

echo "[1/8] Eliminando instalación previa..."
rm -rf "$BASE_DIR"
rm -f "$CMD_BIN"
rm -f "$LOG_FILE"

echo "[2/8] Instalando dependencias..."
apt update -y
apt install -y curl git jq ca-certificates build-essential

echo "[3/8] Instalando Node.js 20..."
apt remove -y nodejs npm libnode-dev 2>/dev/null || true
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt install -y nodejs

echo "[4/8] Creando estructura..."
mkdir -p "$BOT_DIR" "$CONF_DIR" "$SESSION_DIR"
touch "$LOG_FILE"

echo "[5/8] Creando configuración..."
cat > "$CONF_DIR/bot.json" <<EOF
{
  "whatsapp": "",
  "session": "/opt/wassh/session",
  "mp": {
    "access_token": "",
    "price_test": 0,
    "price_month": 0
  }
}
EOF

echo "[6/8] Instalando bot WhatsApp..."
cat > "$BOT_DIR/package.json" <<EOF
{
  "name": "wassh-bot",
  "version": "2.1.0",
  "type": "module",
  "main": "index.js",
  "dependencies": {
    "@whiskeysockets/baileys": "^6.5.1"
  }
}
EOF

cat > "$BOT_DIR/index.js" <<'EOF'
import fs from 'fs'
import makeWASocket, { useMultiFileAuthState, Browsers } from '@whiskeysockets/baileys'

const CONF = '/opt/wassh/config/bot.json'
const config = JSON.parse(fs.readFileSync(CONF))

async function startBot() {
  const { state, saveCreds } = await useMultiFileAuthState(config.session)

  const sock = makeWASocket({
    auth: state,
    printQRInTerminal: true,
    browser: Browsers.ubuntu('Chrome')
  })

  sock.ev.on('creds.update', saveCreds)

  sock.ev.on('connection.update', ({ connection }) => {
    if (connection === 'open') {
      console.log('✅ WhatsApp conectado correctamente')
    }
    if (connection === 'close') {
      console.log('❌ Conexión cerrada')
    }
  })

  sock.ev.on('messages.upsert', async ({ messages }) => {
    const msg = messages[0]
    if (!msg.message || msg.key.fromMe) return

    const text =
      msg.message.conversation ||
      msg.message.extendedTextMessage?.text ||
      ''

    if (text.toLowerCase() === 'hola') {
      await sock.sendMessage(msg.key.remoteJid, {
        text: '👋 Hola, soy el bot WASSH'
      })
    }
  })
}

startBot()
EOF

cd "$BOT_DIR"
npm install --no-audit --no-fund

echo "[7/8] Creando comando wassh..."
cat > "$CMD_BIN" <<'EOF'
#!/bin/bash

CONF="/opt/wassh/config/bot.json"
BOT="/opt/wassh/bot/index.js"
LOG="/var/log/wassh.log"
SESSION="/opt/wassh/session"

menu() {
clear
echo "====== WASSH MANAGER ======"
echo "1) Iniciar bot (QR)"
echo "2) Detener bot"
echo "3) Configurar número WhatsApp"
echo "4) Reset sesión"
echo "5) Ver logs"
echo "0) Salir"
echo
read -p "Opción: " op

case $op in
1)
 pkill -f node 2>/dev/null
 node $BOT >> $LOG 2>&1 &
 echo "🤖 Bot iniciado"
 ;;
2)
 pkill -f node
 echo "🛑 Bot detenido"
 ;;
3)
 read -p "Número WhatsApp (549...): " num
 jq ".whatsapp=\"$num\"" $CONF > /tmp/w.json && mv /tmp/w.json $CONF
 echo "✅ Número guardado"
 ;;
4)
 pkill -f node
 rm -rf $SESSION/*
 echo "♻️ Sesión eliminada"
 ;;
5)
 tail -f $LOG
 ;;
0)
 exit
 ;;
esac
read -p "ENTER para continuar..."
menu
}

menu
EOF

chmod +x "$CMD_BIN"

echo "[8/8] Instalación completada"
echo
echo "👉 Ejecutar: wassh"
echo "👉 Opción 1 para escanear QR"
echo
echo "✅ WASSH LISTO Y ESTABLE"
