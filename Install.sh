#!/bin/bash
set -e

echo "=================================="
echo "   WASSH INSTALLER v2.2 (STABLE)"
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
rm -rf "$BASE_DIR" 2>/dev/null || true
rm -f "$CMD_BIN" 2>/dev/null || true
rm -f "$LOG_FILE" 2>/dev/null || true

echo "[2/8] Instalando dependencias..."
apt update -y
apt install -y curl git jq ca-certificates build-essential

echo "[3/8] Instalando Node.js 20..."
apt remove -y nodejs npm libnode-dev 2>/dev/null || true
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt install -y nodejs

echo "✅ Node.js $(node --version) instalado"

echo "[4/8] Creando estructura..."
mkdir -p "$BOT_DIR" "$CONF_DIR" "$SESSION_DIR"
mkdir -p "$(dirname "$LOG_FILE")"
touch "$LOG_FILE"
chmod 644 "$LOG_FILE"

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
  "version": "2.2.0",
  "type": "module",
  "main": "index.js",
  "dependencies": {
    "@whiskeysockets/baileys": "^6.5.1"
  }
}
EOF

cat > "$BOT_DIR/index.js" <<'EOF'
import fs from 'fs'
import makeWASocket, { useMultiFileAuthState, Browsers, DisconnectReason } from '@whiskeysockets/baileys'

const CONF = '/opt/wassh/config/bot.json'
const config = JSON.parse(fs.readFileSync(CONF, 'utf8'))

async function startBot() {
  console.log('🚀 Iniciando bot WhatsApp...')
  
  const { state, saveCreds } = await useMultiFileAuthState(config.session)

  const sock = makeWASocket({
    auth: state,
    printQRInTerminal: true,
    browser: Browsers.ubuntu('Chrome'),
    logger: { level: 'warn' }
  })

  sock.ev.on('creds.update', saveCreds)

  sock.ev.on('connection.update', (update) => {
    const { connection, lastDisconnect, qr } = update
    
    if (qr) {
      console.log('\n📲 ESCANEA EL CÓDIGO QR CON WHATSAPP')
      console.log('1. Abre WhatsApp en tu teléfono')
      console.log('2. Ve a Ajustes > Dispositivos vinculados')
      console.log('3. Toca "Vincular un dispositivo"')
      console.log('4. Escanea el código QR de arriba\n')
    }
    
    if (connection === 'open') {
      console.log('✅ CONECTADO A WHATSAPP')
      console.log('🤖 Bot listo para recibir mensajes')
    }
    
    if (connection === 'close') {
      console.log('❌ Conexión cerrada')
      const shouldReconnect = lastDisconnect?.error?.output?.statusCode !== DisconnectReason.loggedOut
      if (shouldReconnect) {
        console.log('🔄 Reconectando en 5 segundos...')
        setTimeout(startBot, 5000)
      }
    }
  })

  sock.ev.on('messages.upsert', async ({ messages }) => {
    const msg = messages[0]
    if (!msg.message || msg.key.fromMe) return

    const text = msg.message.conversation || msg.message.extendedTextMessage?.text || ''
    const sender = msg.pushName || 'Usuario'

    console.log(`📩 Mensaje de ${sender}: ${text}`)

    if (text.toLowerCase().includes('hola')) {
      await sock.sendMessage(msg.key.remoteJid, {
        text: `👋 Hola ${sender}, soy el bot WASSH\n¿En qué puedo ayudarte?`
      })
      console.log(`✅ Respondí a ${sender}`)
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
BOT_DIR="/opt/wassh/bot"
LOG="/var/log/wassh.log"
SESSION="/opt/wassh/session"

start_bot() {
    echo "🤖 Iniciando bot WhatsApp..."
    pkill -f "node.*index.js" 2>/dev/null
    cd "$BOT_DIR"
    nohup node index.js >> "$LOG" 2>&1 &
    echo "✅ Bot iniciado"
    echo "📱 Escanea el QR que aparece en los logs:"
    echo "   tail -f $LOG"
}

stop_bot() {
    echo "🛑 Deteniendo bot..."
    pkill -f "node.*index.js" 2>/dev/null
    echo "✅ Bot detenido"
}

view_logs() {
    echo "📋 Últimas 30 líneas de logs:"
    echo "-----------------------------"
    tail -n 30 "$LOG"
    echo "-----------------------------"
    echo "Ver en tiempo real: tail -f $LOG"
}

config_whatsapp() {
    echo "📱 Configurar número WhatsApp"
    current=$(jq -r '.whatsapp // ""' "$CONF" 2>/dev/null)
    if [ -n "$current" ]; then
        echo "Número actual: $current"
    fi
    read -p "Número WhatsApp (54911...): " num
    if [ -n "$num" ]; then
        jq ".whatsapp=\"$num\"" "$CONF" > /tmp/wassh_tmp.json && mv /tmp/wassh_tmp.json "$CONF"
        echo "✅ Número guardado"
    else
        echo "⚠️ No se modificó"
    fi
}

reset_session() {
    echo "🗑️ Resetear sesión"
    echo "Esto eliminará la conexión actual y necesitarás escanear QR nuevamente."
    read -p "¿Continuar? (s/n): " confirm
    if [[ "$confirm" == "s" || "$confirm" == "S" ]]; then
        stop_bot
        sleep 2
        rm -rf "$SESSION"/*
        echo "✅ Sesión eliminada"
        read -p "¿Iniciar bot ahora? (s/n): " start_now
        if [[ "$start_now" == "s" || "$start_now" == "S" ]]; then
            start_bot
        fi
    else
        echo "❌ Cancelado"
    fi
}

menu() {
    clear
    echo "=================================="
    echo "         WASSH MANAGER v2.2"
    echo "=================================="
    echo ""
    
    # Estado
    if pgrep -f "node.*index.js" > /dev/null; then
        echo "🔵 Estado: BOT EN EJECUCIÓN"
    else
        echo "🔴 Estado: BOT DETENIDO"
    fi
    
    echo ""
    echo "1) 🚀 Iniciar bot (Mostrar QR)"
    echo "2) 🛑 Detener bot"
    echo "3) 🔄 Reiniciar bot"
    echo "4) 📱 Configurar WhatsApp"
    echo "5) 📋 Ver logs"
    echo "6) 🗑️ Reset sesión"
    echo "0) ❌ Salir"
    echo ""
    read -p "Selecciona una opción [0-6]: " op
    
    case $op in
    1)
        start_bot
        ;;
    2)
        stop_bot
        ;;
    3)
        stop_bot
        sleep 2
        start_bot
        ;;
    4)
        config_whatsapp
        ;;
    5)
        view_logs
        ;;
    6)
        reset_session
        ;;
    0)
        echo "👋 ¡Hasta luego!"
        exit 0
        ;;
    *)
        echo "❌ Opción inválida"
        ;;
    esac
    
    if [ "$op" != "0" ]; then
        echo ""
        read -p "Presiona ENTER para continuar..."
        menu
    fi
}

# Manejo de argumentos
case "$1" in
    "start")
        start_bot
        ;;
    "stop")
        stop_bot
        ;;
    "restart")
        stop_bot
        sleep 2
        start_bot
        ;;
    "logs")
        view_logs
        ;;
    "config")
        config_whatsapp
        ;;
    "reset")
        reset_session
        ;;
    "")
        menu
        ;;
    *)
        echo "Uso: wassh [comando]"
        echo "Comandos: start, stop, restart, logs, config, reset"
        exit 1
        ;;
esac
EOF

chmod +x "$CMD_BIN"

echo "[8/8] Instalación completada ✅"
echo ""
echo "=========================================="
echo "📦 INSTALACIÓN LISTA"
echo "=========================================="
echo ""
echo "🎯 USO RÁPIDO:"
echo "1. Ejecuta: sudo wassh"
echo "2. Configura número (Opción 4)"
echo "3. Inicia bot (Opción 1)"
echo "4. Escanea el QR que aparece en los logs"
echo ""
echo "📋 COMANDOS DIRECTOS:"
echo "   sudo wassh start      # Iniciar bot"
echo "   sudo wassh stop       # Detener bot"
echo "   sudo wassh logs       # Ver logs/QR"
echo "   tail -f /var/log/wassh.log  # Ver en tiempo real"
echo ""
echo "🤖 El bot responderá automáticamente a 'hola'"
echo ""
