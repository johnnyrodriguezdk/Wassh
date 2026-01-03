#!/bin/bash
set -e

echo "=================================="
echo "   WASSH INSTALLER (RESET TOTAL)"
echo "=================================="

# Verificar si se ejecuta como root
if [[ $EUID -ne 0 ]]; then
   echo "❌ Este script debe ejecutarse como root (sudo)"
   exit 1
fi

### VARIABLES
BASE_DIR="/opt/wassh"
BOT_DIR="$BASE_DIR/bot"
CONF_DIR="$BASE_DIR/config"
LOG_FILE="/var/log/wassh.log"
CMD_BIN="/usr/bin/wassh"

### 0) DETENER TODO
echo "[0/9] Deteniendo procesos anteriores..."
pkill -f "wassh" || true
pkill -f "node.*index.js" || true
sleep 2

### 1) BORRAR INSTALACIÓN PREVIA
echo "[1/9] Eliminando instalación previa..."
rm -rf "$BASE_DIR" 2>/dev/null || true
rm -f "$CMD_BIN" 2>/dev/null || true

### 2) SISTEMA Y DEPENDENCIAS
echo "[2/9] Actualizando sistema..."
apt update -y
apt install -y curl git jq ca-certificates

### 3) NODEJS (FIX CONFLICTOS)
echo "[3/9] Instalando Node.js 20..."
apt remove -y nodejs libnode-dev npm 2>/dev/null || true
rm -rf /etc/apt/sources.list.d/nodesource.list 2>/dev/null || true
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt install -y nodejs
echo "✅ Node.js $(node --version) instalado"

### 4) ESTRUCTURA
echo "[4/9] Creando estructura..."
mkdir -p "$BOT_DIR"
mkdir -p "$CONF_DIR"
mkdir -p "$BASE_DIR/session"
touch "$LOG_FILE"
chmod 644 "$LOG_FILE"

### 5) JSON CONFIGURACIÓN
echo "[5/9] Creando JSON de configuración..."

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

### 6) BOT WHATSAPP (CÓDIGO CORREGIDO)
echo "[6/9] Instalando BOT WhatsApp..."

# Crear package.json primero
cat > "$BOT_DIR/package.json" <<EOF
{
  "name": "wassh-bot",
  "version": "1.0.0",
  "type": "module",
  "main": "index.js",
  "scripts": {
    "start": "node index.js"
  },
  "dependencies": {
    "@whiskeysockets/baileys": "^6.5.0"
  }
}
EOF

# Código del bot CORREGIDO
cat > "$BOT_DIR/index.js" <<'EOF'
import fs from 'fs'
import { makeWASocket } from '@whiskeysockets/baileys'
import * as baileys from '@whiskeysockets/baileys'

const CONF = '/opt/wassh/config/bot.json'
let config = {}

try {
  const configData = fs.readFileSync(CONF, 'utf8')
  config = JSON.parse(configData)
} catch (error) {
  console.error('❌ Error leyendo configuración:', error.message)
  process.exit(1)
}

async function startBot() {
  try {
    const { state, saveCreds } = await baileys.useMultiFileAuthState(config.session)

    const sock = makeWASocket({
      auth: state,
      printQRInTerminal: false,
      browser: ['WASSH', 'Chrome', '1.0']
    })

    sock.ev.on('creds.update', saveCreds)

    sock.ev.on('connection.update', (update) => {
      const { connection, qr } = update
      
      if (qr) {
        console.log('\n📲 ESCANEA EL CÓDIGO QR CON WHATSAPP')
        console.log('➡️ WhatsApp > Ajustes > Dispositivos vinculados > Vincular un dispositivo\n')
      }
      
      if (connection === 'open') {
        console.log('✅ BOT CONECTADO A WHATSAPP')
      }
      
      if (connection === 'close') {
        console.log('❌ Conexión cerrada, reintentando...')
        setTimeout(startBot, 5000)
      }
    })

    // Solicitar código de vinculación si no está registrado
    if (!state.creds.registered && config.whatsapp) {
      try {
        const phone = config.whatsapp.replace(/\D/g, '')
        const code = await sock.requestPairingCode(phone)
        console.log('\n📲 CÓDIGO DE VINCULACIÓN:')
        console.log('➡️', code)
        console.log('\nWhatsApp > Dispositivos vinculados > Vincular con código\n')
      } catch (error) {
        console.error('Error solicitando código:', error.message)
      }
    }

  } catch (error) {
    console.error('❌ Error iniciando bot:', error.message)
    setTimeout(startBot, 10000)
  }
}

startBot()
EOF

cd "$BOT_DIR"
npm install

### 7) COMANDO WASSH (MEJORADO)
echo "[7/9] Creando comando wassh..."

cat > "$CMD_BIN" <<'EOF'
#!/bin/bash

CONF="/opt/wassh/config/bot.json"
BOT_DIR="/opt/wassh/bot"
LOG="/var/log/wassh.log"

check_root() {
  if [[ $EUID -eq 0 ]]; then
    echo "⚠️  No se recomienda ejecutar como root. Usa sudo solo cuando sea necesario."
  fi
}

start_bot() {
  echo "🤖 Iniciando bot WhatsApp..."
  pkill -f "node.*index.js" 2>/dev/null || true
  cd "$BOT_DIR"
  nohup node index.js >> "$LOG" 2>&1 &
  sleep 2
  echo "✅ Bot iniciado en segundo plano"
  echo "📋 Ver logs: tail -f $LOG"
}

stop_bot() {
  echo "🛑 Deteniendo bot..."
  pkill -f "node.*index.js" 2>/dev/null || true
  echo "✅ Bot detenido"
}

view_logs() {
  echo "📋 Últimas 50 líneas del log:"
  echo "------------------------------"
  tail -n 50 "$LOG"
  echo "------------------------------"
  echo "Ver en tiempo real: tail -f $LOG"
}

config_whatsapp() {
  echo "📱 CONFIGURAR WHATSAPP"
  echo "----------------------"
  current=$(jq -r '.whatsapp // empty' "$CONF" 2>/dev/null || echo "")
  if [[ -n "$current" ]]; then
    echo "Número actual: $current"
  fi
  read -p "Número WhatsApp (54911xxxxxxxx): " num
  if [[ -z "$num" ]]; then
    echo "⚠️  No se modificó"
    return
  fi
  if ! jq ".whatsapp=\"$num\"" "$CONF" > "/tmp/bot.json.tmp"; then
    echo "❌ Error actualizando configuración"
    return
  fi
  mv "/tmp/bot.json.tmp" "$CONF"
  echo "✅ Número guardado: $num"
}

config_mercadopago() {
  echo "💰 CONFIGURAR MERCADO PAGO"
  echo "--------------------------"
  current_token=$(jq -r '.mp.access_token // empty' "$CONF" 2>/dev/null || echo "")
  if [[ -n "$current_token" ]]; then
    echo "Token actual: ${current_token:0:20}..."
  fi
  
  read -p "Access Token MP: " token
  read -p "Precio TEST (ej: 100): " test
  read -p "Precio MES (ej: 1000): " mes
  
  # Validar números
  if ! [[ "$test" =~ ^[0-9]+$ ]]; then
    echo "❌ Precio TEST debe ser número"
    return
  fi
  if ! [[ "$mes" =~ ^[0-9]+$ ]]; then
    echo "❌ Precio MES debe ser número"
    return
  fi
  
  if jq ".mp.access_token=\"$token\" | .mp.price_test=$test | .mp.price_month=$mes" "$CONF" > "/tmp/bot.json.tmp"; then
    mv "/tmp/bot.json.tmp" "$CONF"
    echo "✅ MercadoPago configurado"
    echo "   Token: ${token:0:20}..."
    echo "   TEST: \$$test"
    echo "   MES: \$$mes"
  else
    echo "❌ Error guardando configuración"
  fi
}

view_config() {
  echo "⚙️  CONFIGURACIÓN ACTUAL"
  echo "-----------------------"
  if [[ -f "$CONF" ]]; then
    jq . "$CONF"
  else
    echo "❌ Archivo de configuración no encontrado"
  fi
}

menu() {
  while true; do
    clear
    echo "=================================="
    echo "        WASSH MANAGER v1.0"
    echo "=================================="
    echo
    echo "1) 🚀 Iniciar bot"
    echo "2) 🛑 Detener bot"
    echo "3) 📱 Configurar WhatsApp"
    echo "4) 💰 Configurar MercadoPago"
    echo "5) 📋 Ver logs"
    echo "6) ⚙️  Ver configuración"
    echo "7) 🔄 Reiniciar bot"
    echo "0) ❌ Salir"
    echo
    read -p "Selecciona una opción [0-7]: " op

    case $op in
      1) start_bot ;;
      2) stop_bot ;;
      3) config_whatsapp ;;
      4) config_mercadopago ;;
      5) view_logs ;;
      6) view_config ;;
      7) 
        stop_bot
        sleep 1
        start_bot
        ;;
      0) 
        echo "👋 ¡Hasta luego!"
        exit 0
        ;;
      *) 
        echo "❌ Opción inválida"
        ;;
    esac
    
    if [[ "$op" != "0" ]]; then
      echo
      read -p "Presiona ENTER para continuar..."
    fi
  done
}

check_root
menu
EOF

chmod +x "$CMD_BIN"

### 8) FINAL
echo "[8/9] Configurando permisos..."
chown -R $SUDO_USER:$SUDO_USER "$BASE_DIR" 2>/dev/null || true
chown $SUDO_USER "$LOG_FILE" 2>/dev/null || true

echo "[9/9] Instalación completada ✅"
echo
echo "=========================================="
echo "📦 INSTALACIÓN COMPLETADA CORRECTAMENTE"
echo "=========================================="
echo
echo "COMANDOS DISPONIBLES:"
echo "➡️  wassh          - Menú principal de administración"
echo "➡️  sudo wassh     - Si necesitas permisos root"
echo
echo "PRIMEROS PASOS:"
echo "1. Ejecuta: wassh"
echo "2. Configura tu número WhatsApp (Opción 3)"
echo "3. Inicia el bot (Opción 1)"
echo "4. Escanea el código QR con tu WhatsApp"
echo
echo "📝 Los logs se guardan en: $LOG_FILE"
echo "⚙️  Configuración en: $CONF_DIR/bot.json"
echo
