#!/bin/bash
set -e

echo "=================================="
echo "   WASSH INSTALLER (WHATSAPP-WEB.JS)"
echo "=================================="

BASE_DIR="/opt/wassh"
BOT_DIR="$BASE_DIR/bot"
CONF_DIR="$BASE_DIR/config"
LOG_FILE="/var/log/wassh.log"
CMD_BIN="/usr/bin/wassh"
CHROME_DIR="$BASE_DIR/chrome"

echo "[0/8] Deteniendo procesos..."
pkill -f "node.*index.js" 2>/dev/null || true
pkill -f "chrome" 2>/dev/null || true
sleep 2

echo "[1/8] Eliminando instalación previa..."
rm -rf "$BASE_DIR" 2>/dev/null || true
rm -f "$CMD_BIN" 2>/dev/null || true
rm -f "$LOG_FILE" 2>/dev/null || true

echo "[2/8] Instalando dependencias..."
apt update -y
apt install -y curl git jq ca-certificates wget unzip

# Instalar Chrome/Chromium
echo "[3/8] Instalando Chrome..."
apt install -y chromium-browser chromium-chromedriver

# Instalar Node.js 18 (más compatible)
echo "[4/8] Instalando Node.js 18..."
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt install -y nodejs

echo "✅ Node.js $(node --version) instalado"

echo "[5/8] Creando estructura..."
mkdir -p "$BOT_DIR" "$CONF_DIR" "$CHROME_DIR"
mkdir -p "$(dirname "$LOG_FILE")"
touch "$LOG_FILE"
chmod 644 "$LOG_FILE"

echo "[6/8] Creando configuración..."
cat > "$CONF_DIR/bot.json" <<EOF
{
  "whatsapp": "",
  "session": "/opt/wassh/chrome/session",
  "headless": false,
  "puppeteer": {
    "args": ["--no-sandbox", "--disable-setuid-sandbox"]
  }
}
EOF

echo "[7/8] Instalando bot con whatsapp-web.js..."
cat > "$BOT_DIR/package.json" <<EOF
{
  "name": "wassh-bot",
  "version": "3.0.0",
  "main": "index.js",
  "dependencies": {
    "qrcode-terminal": "^0.12.0",
    "whatsapp-web.js": "^1.23.0"
  }
}
EOF

cat > "$BOT_DIR/index.js" <<'EOF'
const qrcode = require('qrcode-terminal');
const { Client, LocalAuth } = require('whatsapp-web.js');
const fs = require('fs');

// Cargar configuración
const configPath = '/opt/wassh/config/bot.json';
let config = {};
try {
    config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
} catch (error) {
    console.error('Error cargando configuración:', error.message);
    process.exit(1);
}

// Crear cliente
const client = new Client({
    authStrategy: new LocalAuth({
        dataPath: config.session
    }),
    puppeteer: {
        headless: config.headless || false,
        args: config.puppeteer?.args || [
            '--no-sandbox',
            '--disable-setuid-sandbox',
            '--disable-dev-shm-usage',
            '--disable-accelerated-2d-canvas',
            '--no-first-run',
            '--no-zygote',
            '--disable-gpu'
        ],
        executablePath: '/usr/bin/chromium'
    },
    qrTimeout: 0
});

// Generar QR
client.on('qr', qr => {
    console.log('\n' + '='.repeat(50));
    console.log('📲 ESCANEA EL CÓDIGO QR CON WHATSAPP');
    console.log('='.repeat(50));
    qrcode.generate(qr, { small: true });
    console.log('\n1. Abre WhatsApp en tu teléfono');
    console.log('2. Toca los 3 puntos > Dispositivos vinculados');
    console.log('3. Toca "Vincular un dispositivo"');
    console.log('4. Escanea el código QR de arriba');
    console.log('='.repeat(50) + '\n');
});

// Cuando esté listo
client.on('ready', () => {
    console.log('✅ WHATSAPP CONECTADO CORRECTAMENTE');
    console.log('🤖 Bot listo para recibir mensajes');
    
    // Mostrar información
    if (client.info) {
        console.log(`👤 Conectado como: ${client.info.pushname || 'Usuario'}`);
        console.log(`📱 Número: ${client.info.wid.user}`);
    }
});

// Mensajes entrantes
client.on('message', async message => {
    // Ignorar mensajes propios
    if (message.fromMe) return;
    
    const contact = await message.getContact();
    const senderName = contact.pushname || contact.name || 'Usuario';
    const messageBody = message.body.toLowerCase();
    
    console.log(`📩 Mensaje de ${senderName}: ${message.body}`);
    
    // Responder automáticamente
    if (messageBody.includes('hola') || messageBody.includes('buenas')) {
        await message.reply(`👋 Hola ${senderName}, soy el bot WASSH\n¿En qué puedo ayudarte?`);
        console.log(`✅ Respondí a ${senderName}`);
    }
});

// Manejo de errores
client.on('auth_failure', (msg) => {
    console.error('❌ Error de autenticación:', msg);
    console.log('🔄 Reiniciando en 10 segundos...');
    setTimeout(() => process.exit(1), 10000);
});

client.on('disconnected', (reason) => {
    console.log(`❌ Desconectado: ${reason}`);
    console.log('🔄 Reconectando...');
    client.destroy();
    client.initialize();
});

// Manejar cierre limpio
process.on('SIGINT', () => {
    console.log('\n👋 Bot detenido manualmente');
    client.destroy();
    process.exit(0);
});

// Iniciar cliente
console.log('🚀 Iniciando bot WhatsApp Web...');
console.log('📅 ' + new Date().toLocaleString());
console.log('🖥️  Node ' + process.version);
console.log('');

client.initialize();
EOF

cd "$BOT_DIR"
npm install --no-audit --no-fund

echo "[8/8] Creando comando wassh..."
cat > "$CMD_BIN" <<'EOF'
#!/bin/bash

CONF="/opt/wassh/config/bot.json"
BOT_DIR="/opt/wassh/bot"
LOG="/var/log/wassh.log"
SESSION="/opt/wassh/chrome/session"

start_bot() {
    echo "🤖 Iniciando bot WhatsApp Web..."
    
    # Detener si ya está corriendo
    pkill -f "node.*index.js" 2>/dev/null
    pkill -f "chrome" 2>/dev/null
    sleep 2
    
    # Iniciar
    cd "$BOT_DIR"
    nohup node index.js >> "$LOG" 2>&1 &
    
    echo "✅ Bot iniciado"
    echo ""
    echo "📱 ESCANEA EL CÓDIGO QR:"
    echo "1. Espera 5-10 segundos"
    echo "2. Ver el QR: tail -f $LOG"
    echo "3. Escanea con tu WhatsApp"
    echo ""
    echo "🔍 Monitorear: tail -f $LOG"
}

stop_bot() {
    echo "🛑 Deteniendo bot..."
    pkill -f "node.*index.js" 2>/dev/null
    pkill -f "chrome" 2>/dev/null
    sleep 2
    echo "✅ Bot detenido"
}

view_logs() {
    echo "📋 Últimas 30 líneas:"
    echo "---------------------"
    tail -n 30 "$LOG"
    echo "---------------------"
    echo "Ver QR en tiempo real: tail -f $LOG"
}

config_headless() {
    echo "🖥️ Modo Headless"
    echo "Headless = sin interfaz gráfica (recomendado para servidor)"
    current=$(jq -r '.headless // "false"' "$CONF" 2>/dev/null)
    echo "Actual: $current"
    
    read -p "¿Usar modo headless? (s/n): " choice
    if [[ "$choice" == "s" || "$choice" == "S" ]]; then
        jq '.headless=true' "$CONF" > /tmp/wassh_conf.json && mv /tmp/wassh_conf.json "$CONF"
        echo "✅ Modo headless activado"
    else
        jq '.headless=false' "$CONF" > /tmp/wassh_conf.json && mv /tmp/wassh_conf.json "$CONF"
        echo "✅ Modo con interfaz activado"
    fi
}

reset_session() {
    echo "🗑️ Resetear sesión"
    echo "Esto eliminará la conexión actual."
    echo "Necesitarás escanear QR nuevamente."
    read -p "¿Continuar? (s/n): " confirm
    
    if [[ "$confirm" == "s" || "$confirm" == "S" ]]; then
        stop_bot
        sleep 2
        rm -rf "$SESSION" 2>/dev/null
        echo "✅ Sesión eliminada"
        read -p "¿Iniciar bot ahora? (s/n): " start_now
        if [[ "$start_now" == "s" || "$start_now" == "S" ]]; then
            start_bot
        fi
    else
        echo "❌ Cancelado"
    fi
}

check_status() {
    if pgrep -f "node.*index.js" > /dev/null; then
        echo "🔵 Estado: BOT EN EJECUCIÓN"
        
        # Verificar si Chrome está corriendo
        if pgrep -f "chrome" > /dev/null; then
            echo "🌐 Chrome: ACTIVO"
        else
            echo "🌐 Chrome: INACTIVO"
        fi
        
        # Mostrar últimos logs
        echo ""
        echo "📄 Últimas 3 líneas de log:"
        tail -n 3 "$LOG" 2>/dev/null || echo "No hay logs"
    else
        echo "🔴 Estado: BOT DETENIDO"
    fi
}

menu() {
    while true; do
        clear
        echo "=================================="
        echo "     WASSH WEB MANAGER"
        echo "=================================="
        echo ""
        
        check_status
        echo ""
        
        echo "1) 🚀 Iniciar bot (Mostrar QR)"
        echo "2) 🛑 Detener bot"
        echo "3) 🔄 Reiniciar bot"
        echo "4) 🖥️ Configurar modo headless"
        echo "5) 📋 Ver logs/QR"
        echo "6) 🗑️ Reset sesión"
        echo "0) ❌ Salir"
        echo ""
        read -p "Selecciona [0-6]: " op
        
        case $op in
            1) start_bot ;;
            2) stop_bot ;;
            3) 
                stop_bot
                sleep 2
                start_bot
                ;;
            4) config_headless ;;
            5) view_logs ;;
            6) reset_session ;;
            0) 
                echo "👋 ¡Hasta luego!"
                exit 0
                ;;
            *) echo "❌ Opción inválida" ;;
        esac
        
        if [ "$op" != "0" ]; then
            echo ""
            read -p "Presiona ENTER para continuar..."
        fi
    done
}

# Argumentos
case "$1" in
    "start") start_bot ;;
    "stop") stop_bot ;;
    "restart") 
        stop_bot
        sleep 2
        start_bot
        ;;
    "logs") view_logs ;;
    "status") check_status ;;
    "reset") reset_session ;;
    "") menu ;;
    *)
        echo "Uso: wassh [comando]"
        echo "Comandos: start, stop, restart, logs, status, reset"
        exit 1
        ;;
esac
EOF

chmod +x "$CMD_BIN"

echo ""
echo "=========================================="
echo "✅ INSTALACIÓN COMPLETADA"
echo "=========================================="
echo ""
echo "🎯 VENTAJAS DE WHATSAPP-WEB.JS:"
echo "   • Más estable que Baileys"
echo "   • Usa Chrome real (más compatible)"
echo "   • Reconexión automática"
echo "   • Sesión persistente"
echo "   • Fácil de depurar"
echo ""
echo "🚀 USO RÁPIDO:"
echo "1. Ejecuta: sudo wassh"
echo "2. Inicia bot (Opción 1)"
echo "3. Espera 10 segundos"
echo "4. Ver QR: tail -f /var/log/wassh.log"
echo "5. Escanea con tu WhatsApp"
echo ""
echo "⚠️  NOTA: La primera vez puede tardar en cargar Chrome"
echo "    Si no ves el QR en 30 segundos, reinicia el bot"
echo ""
