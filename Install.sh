#!/bin/bash
set -e

echo "=================================="
echo "  BOT VENTAS SSH - BASE FUNCIONAL"
echo "=================================="

# Variables
INSTALL_DIR="/opt/wassh"
LOG_FILE="/var/log/wassh.log"

# 1. Limpiar instalación previa
echo "[1/8] Limpiando instalación anterior..."
pkill -f "node.*wassh" 2>/dev/null || true
rm -rf "$INSTALL_DIR" 2>/dev/null || true
mkdir -p "$INSTALL_DIR"

# 2. Instalar Node.js 18
echo "[2/8] Instalando Node.js 18..."
apt update -y
apt install -y curl git jq
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt install -y nodejs

echo "✅ Node $(node --version) instalado"

# 3. Crear estructura del bot
echo "[3/8] Creando estructura del bot..."
cd "$INSTALL_DIR"

# package.json básico
cat > package.json <<'EOF'
{
  "name": "wassh-bot",
  "version": "1.0.0",
  "main": "index.js",
  "dependencies": {
    "whatsapp-web.js": "^1.23.0",
    "qrcode-terminal": "^0.12.0",
    "express": "^4.18.2",
    "lowdb": "^5.1.0",
    "moment": "^2.29.4"
  },
  "scripts": {
    "start": "node index.js",
    "dev": "nodemon index.js"
  }
}
EOF

# 4. Crear index.js principal (BASE FUNCIONAL)
echo "[4/8] Creando bot base funcional..."
cat > index.js <<'EOF'
const qrcode = require('qrcode-terminal');
const { Client, LocalAuth } = require('whatsapp-web.js');
const express = require('express');
const low = require('lowdb');
const FileSync = require('lowdb/adapters/FileSync');
const moment = require('moment');
const fs = require('fs');

// Configuración
const PORT = 9000;
const SESSION_PATH = './session';

// Base de datos
const adapter = new FileSync('database.json');
const db = low(adapter);

// Inicializar DB con estructura
db.defaults({
    users: [],
    sales: [],
    plans: [
        { id: 'basic', name: 'Básico 30 días', price: 1000, days: 30, devices: 1 },
        { id: 'premium', name: 'Premium 60 días', price: 2000, days: 60, devices: 3 },
        { id: 'vip', name: 'VIP 90 días', price: 3000, days: 90, devices: 5 }
    ],
    config: {
        admin: '5491122334455',
        ssh_host: 'tussh.com',
        ssh_port: '22'
    }
}).write();

// Web server para QR
const app = express();
app.get('/qr', (req, res) => {
    res.send(`
        <html>
        <body style="text-align: center; padding: 50px;">
            <h2>📱 Escanea este QR con WhatsApp</h2>
            <p>WhatsApp > Ajustes > Dispositivos vinculados</p>
            <img src="/qrcode" width="300">
            <p><a href="/">Volver</a></p>
        </body>
        </html>
    `);
});

app.get('/qrcode', (req, res) => {
    if (global.qrCode) {
        qrcode.generate(global.qrCode, { small: false }, (qrcode) => {
            res.set('Content-Type', 'text/html');
            res.send(`<pre>${qrcode}</pre>`);
        });
    } else {
        res.send('QR no disponible aún. Espera unos segundos.');
    }
});

app.get('/', (req, res) => {
    res.send(`
        <h1>🤖 WASSH Bot Panel</h1>
        <p><a href="/qr">Escanear QR</a></p>
        <p><a href="/stats">Estadísticas</a></p>
        <p>Bot activo: ${client ? '✅ Sí' : '❌ No'}</p>
    `);
});

app.get('/stats', (req, res) => {
    const users = db.get('users').value().length;
    const sales = db.get('sales').value().length;
    res.json({ users, sales, status: 'active' });
});

app.listen(PORT, () => {
    console.log(`🌐 Web server: http://localhost:${PORT}`);
});

// WhatsApp Client
const client = new Client({
    authStrategy: new LocalAuth({ clientId: "wassh-bot" }),
    puppeteer: {
        headless: true,
        args: ['--no-sandbox', '--disable-setuid-sandbox']
    }
});

// Generar QR
client.on('qr', qr => {
    console.log('\n' + '='.repeat(50));
    console.log('📲 ESCANEA EL CÓDIGO QR CON WHATSAPP');
    console.log('='.repeat(50));
    console.log('\nO visita: http://localhost:9000/qr\n');
    qrcode.generate(qr, { small: true });
    global.qrCode = qr;
});

// Cuando esté listo
client.on('ready', () => {
    console.log('✅ WHATSAPP CONECTADO');
    console.log('🤖 Bot listo para ventas SSH');
    
    // Enviar mensaje de bienvenida al admin
    const admin = db.get('config.admin').value();
    if (admin) {
        client.sendMessage(admin + '@c.us', 
            `✅ Bot WASSH iniciado\n📅 ${moment().format('DD/MM/YYYY HH:mm')}\n👥 Usuarios: ${db.get('users').value().length}`
        );
    }
});

// MENÚ PRINCIPAL ESTILO TELEGRAM
const mainMenu = `*🤖 WASSH VPN - MENÚ PRINCIPAL*

*1*️⃣ *PLANES Y PRECIOS*
*2*️⃣ *COMPRAR SERVICIO*
*3*️⃣ *MI CUENTA / RENOVAR*
*4*️⃣ *SOPORTE TÉCNICO*
*5*️⃣ *INFORMACIÓN*

*0*️⃣ *SALIR*

_Escribe el número de la opción_`;

const plansMenu = `*📋 PLANES DISPONIBLES*

*1*️⃣ *PLAN BÁSICO*
💰 Precio: $1000
⏳ Duración: 30 días
📱 Dispositivos: 1

*2*️⃣ *PLAN PREMIUM* 
💰 Precio: $2000  
⏳ Duración: 60 días
📱 Dispositivos: 3

*3*️⃣ *PLAN VIP*
💰 Precio: $3000
⏳ Duración: 90 días
📱 Dispositivos: 5

*9*️⃣ *VOLVER AL MENÚ*
*0*️⃣ *SALIR*`;

// Manejar mensajes
client.on('message', async message => {
    if (message.fromMe) return;
    
    const userNumber = message.from.split('@')[0];
    const userText = message.body.toLowerCase().trim();
    
    // Registrar usuario
    const userExists = db.get('users').find({ number: userNumber }).value();
    if (!userExists) {
        db.get('users').push({
            number: userNumber,
            name: message._data.notifyName || 'Usuario',
            joined: moment().format(),
            plan: null,
            expiry: null,
            credentials: null
        }).write();
    }
    
    // MENÚ PRINCIPAL (estilo Telegram)
    if (userText === 'menu' || userText === 'hola' || userText === 'inicio') {
        await message.reply(mainMenu);
        return;
    }
    
    // Opción 1: Planes y precios
    if (userText === '1' || userText === 'planes') {
        await message.reply(plansMenu);
        return;
    }
    
    // Opción 2: Comprar servicio
    if (userText === '2' || userText.startsWith('comprar')) {
        await message.reply(`*💳 MÉTODOS DE PAGO*

1️⃣ *TRANSFERENCIA BANCARIA*
🏦 Banco: Tu Banco
📊 CBU: 0000000000000000000
👤 Nombre: Tu Nombre

2️⃣ *MERCADO PAGO*
🔗 Link: https://mpago.la/tucodigo
👤 Alias: tu.alias.mp

3️⃣ *CRIPTOMONEDAS*
💰 USDT (TRC20): TU_DIRECCION
💰 BTC: TU_DIRECCION

*📝 INSTRUCCIONES:*
1. Realiza el pago
2. Envía el comprobante aquí
3. Recibirás tus credenciales en minutos

*9*️⃣ VOLVER AL MENÚ`);
        return;
    }
    
    // Opción 3: Mi cuenta
    if (userText === '3' || userText.includes('mi cuenta')) {
        const user = db.get('users').find({ number: userNumber }).value();
        
        if (user && user.plan) {
            const daysLeft = moment(user.expiry).diff(moment(), 'days');
            await message.reply(`*📊 TU CUENTA*

👤 Usuario SSH: *${user.credentials?.user || 'No asignado'}*
🔑 Contraseña: *${user.credentials?.pass || 'No asignada'}*
📅 Expira: *${user.expiry || 'No activo'}*
⏳ Días restantes: *${daysLeft > 0 ? daysLeft : 'VENCIDO'}*

🔄 *RENOVAR:* Envía "renovar"`);
        } else {
            await message.reply(`❌ *NO TIENES SERVICIO ACTIVO*

Para adquirir un plan:
1. Escribe *1* para ver planes
2. Elige el que prefieras
3. Realiza el pago

*9*️⃣ VOLVER AL MENÚ`);
        }
        return;
    }
    
    // Opción 4: Soporte
    if (userText === '4' || userText.includes('soporte')) {
        await message.reply(`*🛠️ SOPORTE TÉCNICO*

📞 *Contacto directo:* +54 9 11 2233-4455
🕒 *Horario:* 9:00 a 21:00 hs

*Problemas comunes:*
🔹 *No me conecta:* Verifica usuario/contraseña
🔹 *Lento:* Prueba otro servidor
🔹 *App no funciona:* Usa OpenVPN o SSTP

*9*️⃣ VOLVER AL MENÚ`);
        return;
    }
    
    // Opción 5: Información
    if (userText === '5' || userText.includes('info')) {
        await message.reply(`*ℹ️ INFORMACIÓN WASSH VPN*

🚀 *Velocidad garantizada*
🔒 *Cifrado militar AES-256*
🌐 *Servidores en 5 países*
📱 *Apps para iOS y Android*

✅ *Garantía de reembolso 24h*
✅ *Soporte 24/7*
✅ *Sin límite de ancho de banda*

📲 *Descarga apps:*
Android: https://play.google.com/...
iOS: https://apps.apple.com/...

*9*️⃣ VOLVER AL MENÚ`);
        return;
    }
    
    // Volver al menú
    if (userText === '9' || userText === 'volver') {
        await message.reply(mainMenu);
        return;
    }
    
    // Salir
    if (userText === '0' || userText === 'salir') {
        await message.reply('👋 ¡Gracias por contactarnos! Escribe *menu* cuando quieras.');
        return;
    }
    
    // ADMIN COMMANDS
    if (userNumber === db.get('config.admin').value()) {
        if (userText.startsWith('/add')) {
            const parts = userText.split(' ');
            if (parts.length === 4) {
                const [, user, pass, days] = parts;
                db.get('users').find({ number: user }).assign({
                    credentials: { user, pass },
                    expiry: moment().add(days, 'days').format(),
                    plan: 'admin_added'
                }).write();
                
                // Crear usuario SSH (simulado)
                console.log(`[ADMIN] Creando usuario SSH: ${user}:${pass} por ${days} días`);
                
                await message.reply(`✅ Usuario creado:
👤 User: ${user}
🔑 Pass: ${pass}
📅 Días: ${days}
🔗 SSH: ${db.get('config.ssh_host').value()}:${db.get('config.ssh_port').value()}`);
                
                // Enviar credenciales al usuario
                const userMsg = `*✅ TU SERVICIO SSH ESTÁ LISTO*

👤 *Usuario:* \`${user}\`
🔑 *Contraseña:* \`${pass}\`
🔗 *Servidor:* ${db.get('config.ssh_host').value()}
⚡️ *Puerto:* ${db.get('config.ssh_port').value()}
📅 *Expira:* ${moment().add(days, 'days').format('DD/MM/YYYY')}

📱 *App recomendada:* HTTP Injector
🌐 *Configuración:* SSH + Proxy

*⚠️ NO COMPARTAS TUS CREDENCIALES*`;
                
                client.sendMessage(user + '@c.us', userMsg);
            }
            return;
        }
        
        if (userText === '/stats') {
            const users = db.get('users').value().length;
            const sales = db.get('sales').value().length;
            await message.reply(`📊 *ESTADÍSTICAS*
👥 Usuarios: ${users}
💰 Ventas: ${sales}
🔄 Activo: ${moment().format('DD/MM HH:mm')}`);
            return;
        }
    }
    
    // Respuesta por defecto
    if (!['1','2','3','4','5','9','0'].includes(userText)) {
        await message.reply(`🤖 No entendí tu mensaje.

Escribe *menu* para ver las opciones disponibles.

O elige una opción:
*1* - Planes y precios
*2* - Comprar servicio  
*3* - Mi cuenta
*4* - Soporte técnico
*5* - Información`);
    }
});

// Manejar errores
client.on('auth_failure', () => {
    console.log('❌ Error de autenticación. Reiniciando...');
    setTimeout(() => process.exit(1), 5000);
});

client.on('disconnected', () => {
    console.log('❌ Desconectado. Reiniciando...');
    setTimeout(() => process.exit(1), 5000);
});

// Iniciar
console.log('🚀 Iniciando WASSH Bot...');
console.log('📅 ' + moment().format('DD/MM/YYYY HH:mm:ss'));
client.initialize();

// Mantener vivo
setInterval(() => {
    console.log('[HEARTBEAT] Bot activo -', moment().format('HH:mm:ss'));
}, 300000); // 5 minutos
EOF

# 5. Crear archivos de configuración
echo "[5/8] Creando archivos de configuración..."

# database.json inicial
cat > database.json <<'EOF'
{
  "users": [],
  "sales": [],
  "plans": [
    {
      "id": "basic",
      "name": "Básico 30 días",
      "price": 1000,
      "days": 30,
      "devices": 1
    },
    {
      "id": "premium", 
      "name": "Premium 60 días",
      "price": 2000,
      "days": 60,
      "devices": 3
    },
    {
      "id": "vip",
      "name": "VIP 90 días",
      "price": 3000,
      "days": 90,
      "devices": 5
    }
  ],
  "config": {
    "admin": "5491122334455",
    "ssh_host": "tussh.com",
    "ssh_port": "22",
    "payment_methods": {
      "transfer": "Banco: Tu Banco\nCBU: 0000000000000000000",
      "mercadopago": "Alias: tu.alias.mp",
      "crypto": "USDT: TU_DIRECCION"
    }
  }
}
EOF

# .env básico
cat > .env <<'EOF'
# Configuración básica
BOT_NAME=WASSH_SSH_BOT
ADMIN_NUMBER=5491122334455

# Email (opcional)
MAIL_HOST=smtp.gmail.com
MAIL_PORT=465
MAIL_USER=tu@gmail.com
MAIL_PASS=tu_password_app

# SSH Server
SSH_HOST=tu.servidor.com
SSH_PORT=22
SSH_USER=root

# Web Server
PORT=9000
HOST=0.0.0.0
EOF

# 6. Instalar dependencias
echo "[6/8] Instalando dependencias npm..."
npm install --no-audit --no-fund

# 7. Crear script de servicio
echo "[7/8] Creando servicio systemd..."

cat > /etc/systemd/system/wasshbot.service <<EOF
[Unit]
Description=WASSH Bot de Ventas SSH
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=$INSTALL_DIR
ExecStart=/usr/bin/npm start
Restart=always
RestartSec=10
StandardOutput=append:$LOG_FILE
StandardError=append:$LOG_FILE
Environment=NODE_ENV=production

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload

# 8. Crear comando wassh
echo "[8/8] Creando comando wassh..."

cat > /usr/bin/wassh <<'EOF'
#!/bin/bash

INSTALL_DIR="/opt/wassh"
LOG_FILE="/var/log/wassh.log"

case "$1" in
    "start")
        echo "🤖 Iniciando WASSH Bot..."
        systemctl start wasshbot
        echo "✅ Bot iniciado"
        echo "🌐 Web: http://localhost:9000"
        echo "📱 QR: http://localhost:9000/qr"
        echo "📋 Logs: tail -f $LOG_FILE"
        ;;
    "stop")
        echo "🛑 Deteniendo bot..."
        systemctl stop wasshbot
        echo "✅ Bot detenido"
        ;;
    "restart")
        echo "🔄 Reiniciando bot..."
        systemctl restart wasshbot
        echo "✅ Bot reiniciado"
        ;;
    "status")
        systemctl status wasshbot --no-pager
        ;;
    "logs")
        tail -f "$LOG_FILE"
        ;;
    "qr")
        echo "📱 Mostrando QR..."
        echo "Accede a: http://localhost:9000/qr"
        echo "O mira los logs para verlo en terminal"
        ;;
    "config")
        echo "⚙️  Editando configuración..."
        nano "$INSTALL_DIR/.env"
        ;;
    "menu")
        echo "🤖 MENÚ WASSH BOT:"
        echo "  start     - Iniciar bot"
        echo "  stop      - Detener bot"
        echo "  restart   - Reiniciar bot"
        echo "  status    - Ver estado"
        echo "  logs      - Ver logs en tiempo real"
        echo "  qr        - Mostrar QR code"
        echo "  config    - Editar configuración"
        echo "  (sin comando) - Mostrar este menú"
        ;;
    *)
        echo "🤖 WASSH BOT - Bot de Ventas SSH"
        echo "================================="
        echo ""
        echo "📋 COMANDOS DISPONIBLES:"
        echo "  wassh start     - Iniciar bot"
        echo "  wassh stop      - Detener bot"
        echo "  wassh restart   - Reiniciar bot"
        echo "  wassh status    - Ver estado"
        echo "  wassh logs      - Ver logs (QR aquí)"
        echo "  wassh qr        - Acceder al QR web"
        echo "  wassh config    - Editar configuración"
        echo ""
        echo "🚀 INICIO RÁPIDO:"
        echo "  1. wassh start"
        echo "  2. wassh logs  (ver QR en terminal)"
        echo "  3. Escanear QR con WhatsApp"
        echo "  4. Escribe 'menu' en WhatsApp"
        echo ""
        echo "📞 Soporte: contacta al administrador"
        ;;
esac
EOF

chmod +x /usr/bin/wassh

echo ""
echo "=========================================="
echo "✅ INSTALACIÓN COMPLETADA"
echo "=========================================="
echo ""
echo "🚀 INICIO INMEDIATO:"
echo "1. Iniciar bot:"
echo "   wassh start"
echo ""
echo "2. Ver QR para vincular WhatsApp:"
echo "   wassh logs"
echo "   O visita: http://localhost:9000/qr"
echo ""
echo "3. Una vez vinculado, escribe 'menu' en WhatsApp"
echo ""
echo "🔧 CONFIGURACIÓN BÁSICA:"
echo "   wassh config  # Editar .env"
echo "   nano /opt/wassh/database.json  # Editar planes"
echo ""
echo "📊 ESTADO DEL BOT:"
echo "   wassh status"
echo ""
echo "🎯 MENÚ WHATSAPP DISPONIBLE:"
echo "   • 1 - Planes y precios"
echo "   • 2 - Comprar servicio"
echo "   • 3 - Mi cuenta / Renovar"
echo "   • 4 - Soporte técnico"
echo "   • 5 - Información"
echo "   • 9 - Volver al menú"
echo "   • 0 - Salir"
echo ""
echo "🔐 COMANDOS ADMIN:"
echo "   /add [numero] [password] [dias]"
echo "   /stats"
echo ""
