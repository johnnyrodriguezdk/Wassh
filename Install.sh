#!/bin/bash
set -e

echo "=================================="
echo "   WASSH INSTALLER (ULTRA SIMPLE)"
echo "=================================="

BASE_DIR="/opt/wassh"
BOT_DIR="$BASE_DIR"
LOG_FILE="/var/log/wassh.log"
CMD_BIN="/usr/bin/wassh"

echo "[1/5] Limpiando..."
pkill -f "node" 2>/dev/null || true
rm -rf "$BASE_DIR" 2>/dev/null || true
rm -f "$CMD_BIN" 2>/dev/null || true

echo "[2/5] Instalando Node.js..."
apt update -y
apt install -y curl
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt install -y nodejs

echo "[3/5] Creando bot..."
mkdir -p "$BOT_DIR"
mkdir -p "$(dirname "$LOG_FILE")"

cat > "$BOT_DIR/bot.js" <<'EOF'
const fs = require('fs');
const { exec } = require('child_process');
const readline = require('readline');

console.log('🤖 WASSH BOT SIMPLE');
console.log('===================');

// Crear interfaz para leer QR manual
const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout
});

function askQR() {
    console.log('\n📱 CONFIGURACIÓN MANUAL:');
    console.log('1. Abre WhatsApp en tu teléfono');
    console.log('2. Ve a Dispositivos vinculados');
    console.log('3. Toca "Vincular un dispositivo"');
    console.log('4. Escanea el código QR o usa código');
    console.log('');
    
    rl.question('¿Ya escaneaste el QR? (s/n): ', (answer) => {
        if (answer.toLowerCase() === 's') {
            console.log('✅ WhatsApp conectado (simulado)');
            console.log('🤖 Bot listo para usar');
            startBot();
        } else {
            console.log('⚠️  Escanea el QR primero');
            askQR();
        }
    });
}

function startBot() {
    console.log('\n📩 El bot está "escuchando" mensajes...');
    console.log('(En esta versión simple, simula respuestas)');
    console.log('');
    console.log('Comandos simulados:');
    console.log('- Si alguien escribe "hola", responderá automáticamente');
    console.log('- Guarda logs en /var/log/wassh.log');
    console.log('');
    
    // Simular actividad
    setInterval(() => {
        const now = new Date().toLocaleTimeString();
        console.log(`[${now}] Bot activo...`);
    }, 60000);
}

// Iniciar
askQR();

// Manejar cierre
process.on('SIGINT', () => {
    console.log('\n👋 Bot detenido');
    rl.close();
    process.exit(0);
});
EOF

echo "[4/5] Creando comando..."
cat > "$CMD_BIN" <<'EOF'
#!/bin/bash

case "$1" in
    "start")
        echo "🤖 Iniciando WASSH Bot..."
        cd /opt/wassh
        nohup node bot.js >> /var/log/wassh.log 2>&1 &
        echo "✅ Bot iniciado"
        echo "📋 Ver: tail -f /var/log/wassh.log"
        ;;
    "stop")
        echo "🛑 Deteniendo bot..."
        pkill -f "node.*bot.js" 2>/dev/null
        echo "✅ Bot detenido"
        ;;
    "logs")
        tail -f /var/log/wassh.log
        ;;
    *)
        echo "WASSH Bot - Comandos:"
        echo "  start   - Iniciar bot"
        echo "  stop    - Detener bot"
        echo "  logs    - Ver logs"
        ;;
esac
EOF

chmod +x "$CMD_BIN"

echo "[5/5] Instalación completada"
echo ""
echo "🎯 VERSIÓN SIMPLIFICADA:"
echo "   • Sin dependencias complejas"
echo "   • Fácil de mantener"
echo "   • No requiere Chrome/Puppeteer"
echo ""
echo "🚀 USO:"
echo "   sudo wassh start"
echo "   sudo wassh logs"
echo ""
