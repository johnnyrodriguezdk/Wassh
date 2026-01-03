#!/bin/bash
set -e

echo "=================================="
echo "   WASSH INSTALLER (RESET TOTAL)"
echo "=================================="

### VARIABLES
BASE_DIR="/opt/wassh"
BOT_DIR="$BASE_DIR/bot"
CONF_DIR="$BASE_DIR/config"
LOG_FILE="/var/log/wassh.log"
CMD_BIN="/usr/bin/wassh"

### 0) DETENER TODO
echo "[0/9] Deteniendo procesos anteriores..."
pkill -f wassh || true
pkill -f node || true

### 1) BORRAR INSTALACIÓN PREVIA
echo "[1/9] Eliminando instalación previa..."
rm -rf $BASE_DIR
rm -f $CMD_BIN

### 2) SISTEMA Y DEPENDENCIAS
echo "[2/9] Actualizando sistema..."
apt update -y
apt install -y curl git jq ca-certificates

### 3) NODEJS (FIX CONFLICTOS)
echo "[3/9] Instalando Node.js 20..."
apt remove -y nodejs libnode-dev || true
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt install -y nodejs

### 4) ESTRUCTURA
echo "[4/9] Creando estructura..."
mkdir -p $BOT_DIR
mkdir -p $CONF_DIR
mkdir -p $BASE_DIR/session
touch $LOG_FILE

### 5) JSON CONFIGURACIÓN
echo "[5/9] Creando JSON de configuración..."

cat > $CONF_DIR/bot.json <<EOF
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

### 6) BOT WHATSAPP
echo "[6/9] Instalando BOT WhatsApp..."

cat > $BOT_DIR/index.js <<'EOF'
import fs from 'fs'
import makeWASocket, { useMultiFileAuthState } from '@whiskeysockets/baileys'

const CONF = '/opt/wassh/config/bot.json'
const config = JSON.parse(fs.readFileSync(CONF))

async function startBot() {
  const { state, saveCreds } = await useMultiFileAuthState(config.session)

  const sock = makeWASocket({
    auth: state,
    browser: ['WASSH', 'Chrome', '1.0']
  })

  sock.ev.on('creds.update', saveCreds)

  if (!state.creds.registered && config.whatsapp) {
    const phone = config.whatsapp.replace(/\D/g, '')
    const code = await sock.requestPairingCode(phone)
    console.log('\n📲 CÓDIGO DE VINCULACIÓN:')
    console.log('➡️', code)
    console.log('\nWhatsApp > Dispositivos vinculados > Vincular con código\n')
  }

  sock.ev.on('connection.update', (u) => {
    if (u.connection === 'open') console.log('✅ BOT CONECTADO')
    if (u.connection === 'close') console.log('❌ Conexión cerrada')
  })
}

startBot()
EOF

cd $BOT_DIR
npm init -y >/dev/null
npm install @whiskeysockets/baileys >/dev/null

### 7) COMANDO WASSH
echo "[7/9] Creando comando wassh..."

cat > $CMD_BIN <<'EOF'
#!/bin/bash

CONF="/opt/wassh/config/bot.json"
BOT="/opt/wassh/bot/index.js"
LOG="/var/log/wassh.log"

menu() {
clear
echo "====== WASSH MANAGER ======"
echo "1) Configurar número WhatsApp"
echo "2) Configurar MercadoPago"
echo "3) Iniciar / Reiniciar bot"
echo "0) Salir"
echo
read -p "Opción: " op

case $op in
1)
 read -p "Número WhatsApp (549...): " num
 jq ".whatsapp=\"$num\"" $CONF > /tmp/bot.json && mv /tmp/bot.json $CONF
 echo "✅ Número guardado"
 ;;
2)
 read -p "MP Access Token: " token
 read -p "Precio TEST: " test
 read -p "Precio MES: " mes
 jq ".mp.access_token=\"$token\" | .mp.price_test=$test | .mp.price_month=$mes" $CONF > /tmp/bot.json && mv /tmp/bot.json $CONF
 echo "✅ MercadoPago guardado"
 ;;
3)
 pkill -f node || true
 node $BOT >> $LOG 2>&1 &
 echo "🤖 Bot iniciado"
 ;;
0)
 exit
 ;;
*)
 echo "Opción inválida"
 ;;
esac
read -p "ENTER para continuar..."
menu
}

menu
EOF

chmod +x $CMD_BIN

### 8) FINAL
echo "[8/9] Instalación finalizada"
echo
echo "👉 Ejecutar: wassh"
echo "👉 Configurar número"
echo "👉 Iniciar bot"
echo
echo "✅ WASSH INSTALADO CORRECTAMENTE"
