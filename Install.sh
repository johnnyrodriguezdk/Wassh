#!/bin/bash
# ================================================
# LIBRE|AR CHATBOT - VERSIÓN PREMIUM
# ================================================
# CARACTERÍSTICAS:
# ✅ Panel VPS estilo original con estadísticas
# ✅ Submenús mejorados con emojis y textos personalizados
# ✅ Información detallada del servicio
# ✅ Comando 'sshbot' para el panel
# ✅ Instalación única en /sshbot
# ================================================

set -e

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m'

# Banner de instalación
clear
echo -e "${CYAN}${BOLD}"
cat << "BANNER"
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║     ████████╗██╗███████╗███╗   ██╗██████╗  █████╗          ║
║     ╚══██╔══╝██║██╔════╝████╗  ██║██╔══██╗██╔══██╗         ║
║        ██║   ██║█████╗  ██╔██╗ ██║██║  ██║███████║         ║
║        ██║   ██║██╔══╝  ██║╚██╗██║██║  ██║██╔══██║         ║
║        ██║   ██║███████╗██║ ╚████║██████╔╝██║  ██║         ║
║        ╚═╝   ╚═╝╚══════╝╚═╝  ╚═══╝╚═════╝ ╚═╝  ╚═╝         ║
╠══════════════════════════════════════════════════════════════╣
║                                                              ║
║              🎛️  LIBRE|AR CHATBOT - PREMIUM                ║
║           ✅ PANEL VPS ESTILO ORIGINAL                      ║
║           ✅ SUBMENÚS MEJORADOS CON TEXTOS PERSONALIZADOS   ║
║           ✅ COMANDO 'ss hbot' PARA EL PANEL                ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
BANNER
echo -e "${NC}"

echo -e "${GREEN}✅ CARACTERÍSTICAS MEJORADAS:${NC}"
echo -e "  🖥️  ${CYAN}Panel VPS:${NC} Estilo original con estadísticas"
echo -e "  📱 ${PURPLE}WhatsApp:${NC} Submenús con textos personalizados"
echo -e "  🔥 ${YELLOW}Información:${NC} Texto detallado del servicio"
echo -e "  🛒 ${GREEN}Compras:${NC} Submenú mejorado con transferencia a representante"
echo -e "${CYAN}══════════════════════════════════════════════════════════════${NC}\n"

# Verificar root
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}❌ Debes ejecutar como root${NC}"
    echo -e "${YELLOW}Usa: sudo bash $0${NC}"
    exit 1
fi

# ================================================
# CARPETA ÚNICA: /sshbot
# ================================================
INSTALL_DIR="/sshbot"
USER_HOME="$INSTALL_DIR"
DB_FILE="$INSTALL_DIR/data/users.db"
CONFIG_FILE="$INSTALL_DIR/config/config.json"
INFO_FILE="$INSTALL_DIR/config/info.txt"

# ================================================
# LIMPIEZA TOTAL
# ================================================
echo -e "\n${CYAN}${BOLD}🧹 LIMPIEZA TOTAL - BORRANDO INSTALACIÓN ANTERIOR...${NC}"

# Detener procesos
pm2 delete sshbot 2>/dev/null || true
pm2 delete sshbot-unico 2>/dev/null || true
pm2 delete tienda-libre-ar-bot 2>/dev/null || true
pm2 kill 2>/dev/null || true
pkill -f node 2>/dev/null || true
pkill -f chrome 2>/dev/null || true

# Eliminar carpetas
rm -rf /sshbot 2>/dev/null || true
rm -rf /opt/ssh-bot 2>/dev/null || true
rm -rf /root/ssh-bot 2>/dev/null || true
rm -rf /root/.wppconnect 2>/dev/null || true
rm -rf /root/.pm2/logs/* 2>/dev/null || true

echo -e "${GREEN}✅ Limpieza completada${NC}\n"

# ================================================
# CREAR ESTRUCTURA
# ================================================
echo -e "${CYAN}${BOLD}📁 CREANDO ESTRUCTURA EN /sshbot...${NC}"
mkdir -p "$INSTALL_DIR"/{data,config,sessions,logs,qr_codes}
mkdir -p /root/.wppconnect
chmod -R 755 "$INSTALL_DIR"
chmod -R 700 /root/.wppconnect
echo -e "${GREEN}✅ Estructura creada${NC}\n"

# ================================================
# CONFIGURACIÓN DEL BOT
# ================================================
echo -e "${CYAN}${BOLD}⚙️ CONFIGURACIÓN DEL BOT${NC}"

# NOMBRE DEL BOT
read -p "📝 NOMBRE PARA TU BOT (ej: LIBRE|AR): " BOT_NAME
BOT_NAME=${BOT_NAME:-"LIBRE|AR"}

# Link de la APP
read -p "📲 Link de descarga para Android (APP): " APP_LINK
APP_LINK=${APP_LINK:-"https://www.mediafire.com/file/p8kgthxbsid7xws/MAJ/DNI_AND_FIL"}

# Número de soporte
read -p "🆘 Número de WhatsApp para representante (con código país): " SUPPORT_NUMBER
SUPPORT_NUMBER=${SUPPORT_NUMBER:-"543435071016"}

# Precios
echo -e "\n${YELLOW}💰 CONFIGURACIÓN DE PRECIOS (en ARS):${NC}"
read -p "Precio 7 días (Enter para 3000): " PRICE_7D
PRICE_7D=${PRICE_7D:-3000}
read -p "Precio 15 días (Enter para 4000): " PRICE_15D
PRICE_15D=${PRICE_15D:-4000}
read -p "Precio 30 días (Enter para 7000): " PRICE_30D
PRICE_30D=${PRICE_30D:-7000}
read -p "Precio 50 días (Enter para 9700): " PRICE_50D
PRICE_50D=${PRICE_50D:-9700}

# Horas de prueba
read -p "⏰ Horas de prueba gratis (Enter para 2): " TEST_HOURS
TEST_HOURS=${TEST_HOURS:-2}

# Detectar IP
echo -e "\n${CYAN}🔍 Detectando IP...${NC}"
SERVER_IP=$(curl -4 -s --max-time 10 ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}' || echo "127.0.0.1")
if [[ -z "$SERVER_IP" || "$SERVER_IP" == "127.0.0.1" ]]; then
    read -p "📝 Ingresa la IP del servidor manualmente: " SERVER_IP
fi
echo -e "${GREEN}✅ IP: ${CYAN}$SERVER_IP${NC}\n"

# ================================================
# TEXTO DE INFORMACIÓN PERSONALIZADO
# ================================================
cat > "$INFO_FILE" << 'EOF'
🔥 INTERNET ILIMITADO ⚡📱
_______

Es una aplicación que te permite conectar y navegar en internet de manera ilimitada/infinita. Sin necesidad de tener saldo/crédito o MG/GB.
_______

📢 Te ofrecemos internet Ilimitado para la empresa PERSONAL, tanto ABONO como PREPAGO a través de nuestra aplicación!

❓ Cómo funciona? Instalamos y configuramos nuestra app para que tengas acceso al servicio, una vez instalada puedes usar todo el internet que quieras sin preocuparte por tus datos!

📲 Probamos que todo funcione correctamente para que recién puedas abonar vía transferencia!

⚙️ Tienes soporte técnico por los 30 días que contrates por cualquier inconveniente! 

⚠️ Nos hacemos cargo de cualquier problema!
EOF

# ================================================
# GUARDAR CONFIGURACIÓN
# ================================================
cat > "$CONFIG_FILE" << EOF
{
    "bot": {
        "name": "$BOT_NAME",
        "version": "4.0-PREMIUM",
        "server_ip": "$SERVER_IP",
        "default_password": "12345",
        "test_hours": $TEST_HOURS,
        "info_file": "$INFO_FILE"
    },
    "prices": {
        "test_hours": $TEST_HOURS,
        "price_7d": $PRICE_7D,
        "price_15d": $PRICE_15D,
        "price_30d": $PRICE_30D,
        "price_50d": $PRICE_50D,
        "currency": "ARS"
    },
    "mercadopago": {
        "access_token": "",
        "enabled": false,
        "public_key": ""
    },
    "links": {
        "app_android": "$APP_LINK",
        "support": "https://wa.me/$SUPPORT_NUMBER"
    },
    "paths": {
        "database": "$DB_FILE",
        "chromium": "/usr/bin/google-chrome",
        "qr_codes": "$INSTALL_DIR/qr_codes",
        "sessions": "/root/.wppconnect"
    }
}
EOF

# ================================================
# CREAR BASE DE DATOS
# ================================================
echo -e "\n${CYAN}🗄️ Creando base de datos...${NC}"
sqlite3 "$DB_FILE" << 'SQL'
CREATE TABLE users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    phone TEXT,
    username TEXT UNIQUE,
    password TEXT DEFAULT '12345',
    tipo TEXT DEFAULT 'test',
    expires_at DATETIME,
    max_connections INTEGER DEFAULT 1,
    status INTEGER DEFAULT 1,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE daily_tests (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    phone TEXT,
    date DATE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(phone, date)
);
CREATE TABLE payments (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    payment_id TEXT UNIQUE,
    phone TEXT,
    plan TEXT,
    days INTEGER,
    amount REAL,
    status TEXT DEFAULT 'pending',
    payment_url TEXT,
    qr_code TEXT,
    preference_id TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    approved_at DATETIME
);
CREATE TABLE logs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    type TEXT,
    message TEXT,
    data TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE user_state (
    phone TEXT PRIMARY KEY,
    state TEXT DEFAULT 'main_menu',
    data TEXT,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_users_phone ON users(phone);
CREATE INDEX idx_users_status ON users(status);
CREATE INDEX idx_payments_status ON payments(status);
CREATE INDEX idx_payments_preference ON payments(preference_id);
SQL
echo -e "${GREEN}✅ Base de datos creada${NC}"

# ================================================
# INSTALAR DEPENDENCIAS
# ================================================
echo -e "\n${CYAN}📦 Instalando dependencias del sistema...${NC}"
apt-get update -y
apt-get upgrade -y

# Node.js 18.x
echo -e "${YELLOW}📦 Instalando Node.js 18.x...${NC}"
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt-get install -y nodejs gcc g++ make

# Chrome
echo -e "${YELLOW}🌐 Instalando Google Chrome...${NC}"
wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | apt-key add -
echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list
apt-get update -y
apt-get install -y google-chrome-stable

# Dependencias del sistema
echo -e "${YELLOW}⚙️ Instalando utilidades...${NC}"
apt-get install -y \
    git curl wget sqlite3 jq \
    build-essential libcairo2-dev \
    libpango1.0-dev libjpeg-dev \
    libgif-dev librsvg2-dev \
    python3 python3-pip ffmpeg \
    unzip cron ufw

# Configurar firewall
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 8001/tcp
ufw allow 3000/tcp
ufw --force enable

# PM2
npm install -g pm2
pm2 update
echo -e "${GREEN}✅ Dependencias instaladas${NC}"

# ================================================
# CREAR PACKAGE.JSON E INSTALAR MÓDULOS
# ================================================
echo -e "\n${CYAN}📦 Instalando módulos de Node.js...${NC}"
cd "$INSTALL_DIR"

cat > package.json << 'PKGEOF'
{
    "name": "libre-ar-chatbot",
    "version": "4.0.0",
    "main": "bot.js",
    "dependencies": {
        "@wppconnect-team/wppconnect": "^1.24.0",
        "qrcode-terminal": "^0.12.0",
        "qrcode": "^1.5.3",
        "moment": "^2.30.1",
        "sqlite3": "^5.1.7",
        "chalk": "^4.1.2",
        "node-cron": "^3.0.3",
        "mercadopago": "^2.0.15",
        "axios": "^1.6.5",
        "sharp": "^0.33.2"
    }
}
PKGEOF

npm install --silent 2>&1 | grep -v "npm WARN" || true
echo -e "${GREEN}✅ Módulos instalados${NC}"

# ================================================
# CREAR BOT.JS CON MENSAJES PERSONALIZADOS
# ================================================
echo -e "\n${CYAN}🤖 Creando bot.js con mensajes personalizados...${NC}"

cat > "bot.js" << 'BOTEOF'
const wppconnect = require('@wppconnect-team/wppconnect');
const qrcode = require('qrcode-terminal');
const QRCode = require('qrcode');
const moment = require('moment');
const sqlite3 = require('sqlite3').verbose();
const { exec } = require('child_process');
const util = require('util');
const chalk = require('chalk');
const cron = require('node-cron');
const fs = require('fs');
const path = require('path');
const axios = require('axios');

const execPromise = util.promisify(exec);
moment.locale('es');

// ==============================================
// RUTAS FIJAS
// ==============================================
const BASE_PATH = '/sshbot';
const CONFIG_FILE = path.join(BASE_PATH, 'config/config.json');
const DB_FILE = path.join(BASE_PATH, 'data/users.db');
const INFO_FILE = path.join(BASE_PATH, 'config/info.txt');

// Cargar configuración
function loadConfig() {
    try {
        delete require.cache[require.resolve(CONFIG_FILE)];
        return require(CONFIG_FILE);
    } catch (error) {
        console.error(chalk.red('❌ Error cargando configuración:'), error.message);
        process.exit(1);
    }
}

let config = loadConfig();
const db = new sqlite3.Database(DB_FILE);

// Función para leer información
function getInfoMessage() {
    try {
        if (fs.existsSync(INFO_FILE)) {
            return fs.readFileSync(INFO_FILE, 'utf8');
        }
    } catch (error) {
        console.error('Error leyendo info:', error);
    }
    return `*📢 INFORMACIÓN DEL BOT*`;
}

console.log(chalk.cyan.bold('\n╔══════════════════════════════════════════════════════════════╗'));
console.log(chalk.cyan.bold(`║           🎛️  ${config.bot.name} CHATBOT - PREMIUM            ║`));
console.log(chalk.cyan.bold('╚══════════════════════════════════════════════════════════════╝\n'));

// ==============================================
// MERCADOPAGO
// ==============================================
let mpEnabled = false;
let mpClient = null;
let mpPreference = null;

function initMercadoPago() {
    config = loadConfig();
    if (config.mercadopago.access_token && config.mercadopago.access_token !== '') {
        try {
            const { MercadoPagoConfig, Preference } = require('mercadopago');
            mpClient = new MercadoPagoConfig({ 
                accessToken: config.mercadopago.access_token,
                options: { timeout: 5000 }
            });
            mpPreference = new Preference(mpClient);
            mpEnabled = true;
            console.log(chalk.green('✅ MercadoPago SDK v2.x ACTIVO'));
        } catch (error) {
            console.log(chalk.red('❌ Error MP:'), error.message);
            mpEnabled = false;
        }
    } else {
        console.log(chalk.yellow('⚠️ MercadoPago NO configurado'));
    }
}
initMercadoPago();

// ==============================================
// SISTEMA DE ESTADOS
// ==============================================
function getUserState(phone) {
    return new Promise((resolve) => {
        db.get('SELECT state, data FROM user_state WHERE phone = ?', [phone], (err, row) => {
            if (err || !row) resolve({ state: 'main_menu', data: null });
            else resolve({ state: row.state || 'main_menu', data: row.data ? JSON.parse(row.data) : null });
        });
    });
}

function setUserState(phone, state, data = null) {
    return new Promise((resolve) => {
        const dataStr = data ? JSON.stringify(data) : null;
        db.run(`INSERT OR REPLACE INTO user_state (phone, state, data, updated_at) VALUES (?, ?, ?, CURRENT_TIMESTAMP)`, [phone, state, dataStr], (err) => resolve(!err));
    });
}

// ==============================================
// FUNCIONES SSH
// ==============================================
function generateSSHUsername(phone) {
    const timestamp = Date.now().toString().slice(-6);
    const random = Math.floor(Math.random() * 90) + 10;
    return `user${timestamp}${random}j`;
}

async function createSSHUser(username, days = 0) {
    try {
        const password = '12345';
        const expiryDate = days > 0 ? 
            moment().add(days, 'days').format('YYYY-MM-DD HH:mm:ss') : 
            moment().add(config.bot.test_hours, 'hours').format('YYYY-MM-DD HH:mm:ss');
        
        await execPromise(`useradd -M -s /bin/false -e $(date -d "${expiryDate}" +%Y-%m-%d) ${username} 2>/dev/null || true`);
        await execPromise(`echo "${username}:${password}" | chpasswd`);
        
        return { success: true, username, password, expires: expiryDate };
    } catch (error) {
        return { success: false, error: error.message };
    }
}

// ==============================================
// FUNCIONES MP
// ==============================================
async function createMercadoPagoPayment(phone, planName, days, amount) {
    if (!mpEnabled) return { success: false, error: 'MercadoPago no configurado' };
    try {
        const paymentId = `MP-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
        const preferenceData = {
            items: [{
                title: `${config.bot.name} - ${planName}`,
                description: `Plan ${days} días`,
                quantity: 1,
                currency_id: 'ARS',
                unit_price: parseFloat(amount)
            }],
            payer: { phone: { number: phone.replace('+', '') } },
            external_reference: paymentId,
            auto_return: 'approved'
        };
        const preference = await mpPreference.create({ body: preferenceData });
        
        db.run(`INSERT INTO payments (payment_id, phone, plan, days, amount, status, payment_url, preference_id) VALUES (?, ?, ?, ?, ?, 'pending', ?, ?)`, 
            [paymentId, phone, planName, days, amount, preference.init_point, preference.id]);
        
        return { success: true, paymentId, paymentUrl: preference.init_point };
    } catch (error) {
        return { success: false, error: error.message };
    }
}

// ==============================================
// MENSAJES PERSONALIZADOS
// ==============================================
function getMainMenuMessage() {
    return `⚙️ *${config.bot.name} ChatBot* 🧑‍💻
             ⸻↓⸻

🛍️ *MENÚ PRINCIPAL*

1 ⁃📢 INFORMACIÓN
2 ⁃🏷️ PRECIOS
3 ⁃🛍️ COMPRAR USUARIO
4 ⁃🔄 RENOVAR USUARIO
5 ⁃📲 DESCARGAR APLICACION
6 ⁃👥 HABLAR CON REPRESENTANTE

👉 Escribe una opción`;
}

function getPricesMessage() {
    return `*🏷️ PRECIOS (ARS)*

🛒 *PLANES DISPONIBLES:*
    
7 días → $${config.prices.price_7d}
15 días → $${config.prices.price_15d}
30 días → $${config.prices.price_30d}
50 días → $${config.prices.price_50d}

💳 *MercadoPago - Pago automático*

_Escribe *menu* para volver_`;
}

function getPlansToBuyMessage() {
    return `⚙️ *${config.bot.name} ChatBot* 🧑‍💻
             ⸻↓⸻

🛍️ ¡A continuación se muestran los planes disponibles! 🛍️

🛒 ⁃ 1 - 7 días - $${config.prices.price_7d}
🛒 ⁃ 2 - 15 días - $${config.prices.price_15d}
🛒 ⁃ 3 - 30 días - $${config.prices.price_30d}
🛒 ⁃ 4 - 50 días - $${config.prices.price_50d}

¿Estás interesado en alguno de estos planes? Si es así, puedo transferirte con un representante para completar la venta.

👉 Escribe *menu* para volver`;
}

function getAndroidPromptMessage() {
    return `*📲 ¿QUÉ TIPO DE DISPOSITIVO USAS?*

🔘 *1* - Android (Recibir link de descarga)
🔘 *2* - Apple/iPhone (Contactar a representante)

_Elige 1 o 2:_`;
}

// ==============================================
// MANEJADOR DE MENSAJES
// ==============================================
async function handleMessage(message) {
    const phone = message.from.replace('@c.us', '');
    const text = message.body || '';
    const userState = await getUserState(phone);
    
    console.log(chalk.blue(`📱 ${phone}: "${text}"`));
    
    if (text.toLowerCase() === 'menu' || text === '0') {
        await setUserState(phone, 'main_menu');
        await client.sendText(message.from, getMainMenuMessage());
        return;
    }
    
    switch (userState.state) {
        case 'main_menu':
            await handleMainMenu(phone, text, message.from);
            break;
        case 'buying_plan':
            await handleBuyingPlan(phone, text, message.from);
            break;
        case 'waiting_os':
            await handleOSSelection(phone, text, message.from);
            break;
        default:
            await setUserState(phone, 'main_menu');
            await client.sendText(message.from, getMainMenuMessage());
    }
}

async function handleMainMenu(phone, text, from) {
    switch (text) {
        case '1':
            await client.sendText(from, getInfoMessage() + '\n\n_Escribe *menu* para volver_');
            await setUserState(phone, 'main_menu');
            break;
        case '2':
            await client.sendText(from, getPricesMessage());
            await setUserState(phone, 'main_menu');
            break;
        case '3':
            await setUserState(phone, 'buying_plan');
            await client.sendText(from, getPlansToBuyMessage());
            break;
        case '4':
            await client.sendText(from, `*🔄 RENOVAR USUARIO*\n\nPara renovar, contacta a nuestro representante:\n${config.links.support}\n\n_Escribe *menu* para volver_`);
            await setUserState(phone, 'main_menu');
            break;
        case '5':
            await setUserState(phone, 'waiting_os');
            await client.sendText(from, getAndroidPromptMessage());
            break;
        case '6':
            await client.sendText(from, `*👥 REPRESENTANTE*\n\nContacta con nosotros:\n${config.links.support}\n\n_Escribe *menu* para volver_`);
            await setUserState(phone, 'main_menu');
            break;
        default:
            await client.sendText(from, `❌ Opción no válida. Elige 1-6.\n\n${getMainMenuMessage()}`);
    }
}

async function handleBuyingPlan(phone, text, from) {
    const planNumber = parseInt(text);
    
    if (planNumber >= 1 && planNumber <= 4) {
        const plans = {
            1: { name: '7 días', days: 7, price: config.prices.price_7d },
            2: { name: '15 días', days: 15, price: config.prices.price_15d },
            3: { name: '30 días', days: 30, price: config.prices.price_30d },
            4: { name: '50 días', days: 50, price: config.prices.price_50d }
        };
        
        const plan = plans[planNumber];
        
        await client.sendText(from, `*🛒 SOLICITUD DE COMPRA*

Has elegido el plan: *${plan.name}*
Precio: *$${plan.price} ARS*

Te transferiré con un representante para completar la venta.

🆘 *REPRESENTANTE:*
${config.links.support}

_Escribe *menu* para volver_`);
        
        await setUserState(phone, 'main_menu');
    } else {
        await client.sendText(from, `❌ Plan no válido. Elige 1-4.\n\n${getPlansToBuyMessage()}`);
    }
}

async function handleOSSelection(phone, text, from) {
    if (text === '1') {
        await client.sendText(from, `*📲 DESCARGA PARA ANDROID*

Link: ${config.links.app_android}

*Instrucciones:*
1. Descarga el archivo APK
2. Habilita "fuentes desconocidas"
3. Instala la aplicación

_Escribe *menu* para volver_`);
        await setUserState(phone, 'main_menu');
    } else if (text === '2') {
        await client.sendText(from, `*🍎 APPLE/IPHONE*

Contacta a nuestro representante:
${config.links.support}

Te guiarán en la configuración.

_Escribe *menu* para volver_`);
        await setUserState(phone, 'main_menu');
    } else {
        await client.sendText(from, `❌ Opción no válida. Elige 1 o 2.`);
    }
}

// ==============================================
// CRON JOBS
// ==============================================
function setupCleanupCron() {
    cron.schedule('*/15 * * * *', async () => {
        console.log(chalk.yellow('🧹 Limpiando usuarios expirados...'));
        const now = moment().format('YYYY-MM-DD HH:mm:ss');
        db.all(`SELECT username FROM users WHERE expires_at < ? AND status = 1`, [now], async (err, expiredUsers) => {
            if (err || !expiredUsers) return;
            for (const user of expiredUsers) {
                await execPromise(`pkill -u ${user.username} 2>/dev/null || true`);
                await execPromise(`userdel ${user.username} 2>/dev/null || true`);
                db.run(`UPDATE users SET status = 0 WHERE username = ?`, [user.username]);
            }
        });
    });
}

// ==============================================
// INICIO DEL BOT
// ==============================================
let client = null;
let iniciando = false;

async function startBot() {
    if (iniciando) return;
    iniciando = true;
    
    try {
        console.log(chalk.cyan(`🚀 Iniciando ${config.bot.name} ChatBot...`));
        
        const chromePath = config.paths.chromium;
        if (!fs.existsSync(chromePath)) {
            console.error(chalk.red(`❌ Chrome no encontrado`));
            process.exit(1);
        }
        
        setupCleanupCron();
        
        client = await wppconnect.create({
            session: 'libre-ar-chatbot',
            folderNameToken: config.paths.sessions,
            puppeteerOptions: {
                executablePath: chromePath,
                headless: 'new',
                args: ['--no-sandbox', '--disable-setuid-sandbox', '--disable-dev-shm-usage']
            },
            disableWelcome: true,
            logQR: true,
            autoClose: 0,
            catchQR: (base64Qr, asciiQR) => {
                console.log(chalk.yellow('\n══════════════════════════════════════════════════'));
                console.log(chalk.yellow('📱 ESCANEA ESTE QR CON WHATSAPP WEB:'));
                console.log(chalk.yellow('══════════════════════════════════════════════════\n'));
                console.log(asciiQR);
                console.log(chalk.cyan('\n1. Abre WhatsApp → Menú → WhatsApp Web'));
                console.log(chalk.cyan('2. Escanea este código QR\n'));
                
                const qrImagePath = `/sshbot/qr_codes/qr-${Date.now()}.png`;
                QRCode.toFile(qrImagePath, base64Qr, { width: 300 }, (err) => {
                    if (!err) console.log(chalk.green(`✅ QR guardado en: ${qrImagePath}`));
                });
            }
        });
        
        console.log(chalk.green('✅ WhatsApp conectado exitosamente!'));
        
        client.onStateChange((state) => {
            const states = {
                'CONNECTED': chalk.green('✅ Conectado'),
                'PAIRING': chalk.cyan('📱 Emparejando...'),
                'UNPAIRED': chalk.yellow('📱 Esperando QR...')
            };
            console.log(chalk.blue(`🔁 Estado: ${states[state] || state}`));
            
            if (state === 'CONNECTED') {
                console.log(chalk.green(`\n✅ ${config.bot.name} ChatBot LISTO`));
                console.log(chalk.cyan('💬 Envía "menu" al número del bot\n'));
            }
        });
        
        client.onMessage(async (message) => {
            try {
                if (message.from === 'status@broadcast' || message.isGroupMsg) return;
                if (!message.body) return;
                await handleMessage(message);
            } catch (error) {
                console.error(chalk.red('❌ Error en mensaje:'), error);
            }
        });
        
        console.log(chalk.green.bold(`\n✅ ${config.bot.name} ChatBot INICIADO!`));
        iniciando = false;
        
    } catch (error) {
        console.error(chalk.red('❌ Error iniciando bot:'), error.message);
        iniciando = false;
        process.exit(1);
    }
}

startBot();
BOTEOF

echo -e "${GREEN}✅ Bot.js creado con mensajes personalizados${NC}"

# ================================================
# CREAR SCRIPT SSHCONFIG PARA ESTADÍSTICAS
# ================================================
echo -e "\n${CYAN}${BOLD}⚙️ Creando script de configuración SSH...${NC}"

cat > /usr/local/bin/sshconfig << 'EOF'
#!/bin/bash
# Configuración SSH para usuarios
case "$1" in
    list)
        cut -d: -f1 /etc/passwd | grep -E "^user" | while read user; do
            expires=$(chage -l "$user" | grep "Account expires" | cut -d: -f2)
            echo "$user | Expira: $expires"
        done
        ;;
    delete)
        userdel "$2" 2>/dev/null && echo "✅ Usuario $2 eliminado"
        ;;
    *)
        echo "Uso: sshconfig {list|delete USER}"
        ;;
esac
EOF
chmod +x /usr/local/bin/sshconfig

# ================================================
# CREAR SCRIPT SSH BOT (PANEL PRINCIPAL)
# ================================================
echo -e "\n${CYAN}${BOLD}⚙️ Creando script 'sshbot' para el panel...${NC}"

cat > /usr/local/bin/sshbot << 'EOF'
#!/bin/bash
# ================================================
# PANEL SSH BOT PRO - LIBRE|AR CHATBOT
# ================================================

BOLD='\033[1m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

BASE_DIR="/sshbot"
CONFIG_FILE="$BASE_DIR/config/config.json"
DB_FILE="$BASE_DIR/data/users.db"

# Función para obtener estadísticas
get_stats() {
    # Usuarios activos/totales
    TOTAL_USERS=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM users;" 2>/dev/null || echo "0")
    ACTIVE_USERS=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM users WHERE status=1 AND expires_at > datetime('now');" 2>/dev/null || echo "0")
    
    # Pagos
    PENDING_PAY=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM payments WHERE status='pending';" 2>/dev/null || echo "0")
    APPROVED_PAY=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM payments WHERE status='approved';" 2>/dev/null || echo "0")
    
    # IP y configuración
    SERVER_IP=$(jq -r '.bot.server_ip' "$CONFIG_FILE" 2>/dev/null || echo "Desconocida")
    BOT_NAME=$(jq -r '.bot.name' "$CONFIG_FILE" 2>/dev/null || echo "LIBRE|AR")
    
    # Precios
    P7=$(jq -r '.prices.price_7d' "$CONFIG_FILE" 2>/dev/null || echo "3000")
    P15=$(jq -r '.prices.price_15d' "$CONFIG_FILE" 2>/dev/null || echo "4000")
    P30=$(jq -r '.prices.price_30d' "$CONFIG_FILE" 2>/dev/null || echo "7000")
    P50=$(jq -r '.prices.price_50d' "$CONFIG_FILE" 2>/dev/null || echo "9700")
    
    # MP Status
    MP_TOKEN=$(jq -r '.mercadopago.access_token' "$CONFIG_FILE" 2>/dev/null || echo "")
    if [[ -n "$MP_TOKEN" && "$MP_TOKEN" != "" ]]; then
        MP_STATUS="${GREEN}✅ CONFIGURADO${NC}"
    else
        MP_STATUS="${RED}❌ NO CONFIGURADO${NC}"
    fi
    
    # Bot status
    if pm2 list | grep -q "libre-ar-chatbot.*online"; then
        BOT_STATUS="${GREEN}● ACTIVO${NC}"
    else
        BOT_STATUS="${RED}● INACTIVO${NC}"
    fi
    
    # Mostrar panel
    clear
    echo -e "${CYAN}${BOLD}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                🎛️  PANEL SSH BOT PRO - COMPLETO            ║"
    echo "║                  💰 MERCADOPAGO INTEGRADO                   ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    echo -e "${YELLOW}📊 ESTADO DEL SISTEMA${NC}"
    echo -e "  Bot: $BOT_STATUS"
    echo -e "  Usuarios: $ACTIVE_USERS/$TOTAL_USERS activos/total"
    echo -e "  Pagos: $PENDING_PAY pendientes | $APPROVED_PAY aprobados"
    echo -e "  MercadoPago: $MP_STATUS"
    echo -e "  IP: $SERVER_IP"
    echo -e "  Contraseña: 12345 (FIJA)"
    
    echo -e "\n${BLUE}💰 PRECIOS ACTUALES:${NC}"
    echo -e "  DIARIOS:"
    echo -e "    7 días: $ $P7 ARS"
    echo -e "    15 días: $ $P15 ARS"
    echo -e "  MENSUALES:"
    echo -e "    30 días: $ $P30 ARS"
    echo -e "    50 días: $ $P50 ARS"
    
    echo -e "\n${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}[1]${NC} 🚀  Iniciar/Reiniciar bot"
    echo -e "${CYAN}[2]${NC} 🛑  Detener bot"
    echo -e "${CYAN}[3]${NC} 📱  Ver logs y QR"
    echo -e "${CYAN}[4]${NC} 👤  Crear usuario manual"
    echo -e "${CYAN}[5]${NC} 👥  Listar usuarios"
    echo -e "${CYAN}[6]${NC} 💰  Cambiar precios"
    echo -e "${CYAN}[7]${NC} 🔑  Configurar MercadoPago"
    echo -e "${CYAN}[8]${NC} 🧪  Test MercadoPago"
    echo -e "${CYAN}[9]${NC} 📊  Ver estadísticas"
    echo -e "${CYAN}[10]${NC} 🔄 Limpiar sesión"
    echo -e "${CYAN}[11]${NC} 💳 Ver pagos"
    echo -e "${CYAN}[12]${NC} ⚙️  Ver configuración"
    echo -e "${CYAN}[0]${NC} 🚪  Salir"
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "👉 Selecciona: \c"
}

# Manejar opciones
case "$1" in
    menu|"")
        while true; do
            get_stats
            read option
            case $option in
                1)
                    echo -e "${GREEN}▶️ Iniciando/Reiniciando bot...${NC}"
                    cd "$BASE_DIR"
                    pm2 restart libre-ar-chatbot 2>/dev/null || pm2 start bot.js --name libre-ar-chatbot --time
                    pm2 save
                    sleep 2
                    ;;
                2)
                    echo -e "${YELLOW}⏹️ Deteniendo bot...${NC}"
                    pm2 stop libre-ar-chatbot
                    sleep 2
                    ;;
                3)
                    echo -e "${CYAN}📱 Mostrando logs...${NC}"
                    pm2 logs libre-ar-chatbot --lines 20
                    ;;
                4)
                    echo -e "${CYAN}👤 Crear usuario manual${NC}"
                    read -p "Username: " username
                    read -p "Días (0 para prueba): " days
                    cd "$BASE_DIR"
                    node -e "
                        const { exec } = require('child_process');
                        const username = '$username';
                        const days = $days;
                        const expiryDate = days > 0 ? 
                            new Date(Date.now() + days*24*60*60*1000).toISOString() : 
                            new Date(Date.now() + 2*60*60*1000).toISOString();
                        exec(\`useradd -M -s /bin/false -e \$(date -d \"\${expiryDate}\" +%Y-%m-%d) \${username} && echo \"\${username}:12345\" | chpasswd\`, (err) => {
                            if(err) console.log('❌ Error:', err.message);
                            else console.log('✅ Usuario creado: ' + username + ' (pass: 12345)');
                        });
                    " 2>/dev/null
                    read -p "Presiona Enter para continuar..."
                    ;;
                5)
                    echo -e "${CYAN}👥 Usuarios SSH:${NC}"
                    echo -e "${YELLOW}USUARIO | EXPIRA | ESTADO${NC}"
                    sqlite3 "$DB_FILE" "SELECT username, expires_at, CASE WHEN status=1 THEN 'Activo' ELSE 'Inactivo' END FROM users ORDER BY created_at DESC LIMIT 20;" -column
                    read -p "Presiona Enter para continuar..."
                    ;;
                6)
                    echo -e "${CYAN}💰 Cambiar precios${NC}"
                    source <(jq -r '.prices | to_entries[] | "\(.key)=\(.value)"' "$CONFIG_FILE")
                    read -p "Precio 7 días [$price_7d]: " new7
                    read -p "Precio 15 días [$price_15d]: " new15
                    read -p "Precio 30 días [$price_30d]: " new30
                    read -p "Precio 50 días [$price_50d]: " new50
                    jq --arg p7 "${new7:-$price_7d}" \
                       --arg p15 "${new15:-$price_15d}" \
                       --arg p30 "${new30:-$price_30d}" \
                       --arg p50 "${new50:-$price_50d}" \
                       '.prices.price_7d = ($p7|tonumber) | 
                        .prices.price_15d = ($p15|tonumber) | 
                        .prices.price_30d = ($p30|tonumber) | 
                        .prices.price_50d = ($p50|tonumber)' \
                       "$CONFIG_FILE" > /tmp/config.tmp && mv /tmp/config.tmp "$CONFIG_FILE"
                    echo -e "${GREEN}✅ Precios actualizados${NC}"
                    sleep 2
                    ;;
                7)
                    echo -e "${CYAN}🔑 Configurar MercadoPago${NC}"
                    read -p "Access Token: " token
                    jq --arg t "$token" '.mercadopago.access_token = $t | .mercadopago.enabled = true' "$CONFIG_FILE" > /tmp/config.tmp && mv /tmp/config.tmp "$CONFIG_FILE"
                    echo -e "${GREEN}✅ Token guardado. Reinicia el bot con opción 1${NC}"
                    sleep 2
                    ;;
                8)
                    echo -e "${CYAN}🧪 Test MercadoPago${NC}"
                    TOKEN=$(jq -r '.mercadopago.access_token' "$CONFIG_FILE")
                    if [[ -n "$TOKEN" && "$TOKEN" != "" ]]; then
                        echo -e "${GREEN}✅ Token configurado: ${TOKEN:0:20}...${NC}"
                    else
                        echo -e "${RED}❌ Token no configurado${NC}"
                    fi
                    read -p "Presiona Enter para continuar..."
                    ;;
                9)
                    echo -e "${CYAN}📊 Estadísticas detalladas${NC}"
                    echo -e "\n${YELLOW}USUARIOS POR TIPO:${NC}"
                    sqlite3 "$DB_FILE" "SELECT tipo, COUNT(*) FROM users GROUP BY tipo;" -column
                    echo -e "\n${YELLOW}PAGOS POR ESTADO:${NC}"
                    sqlite3 "$DB_FILE" "SELECT status, COUNT(*), SUM(amount) FROM payments GROUP BY status;" -column
                    read -p "Presiona Enter para continuar..."
                    ;;
                10)
                    echo -e "${YELLOW}🔄 Limpiando sesión...${NC}"
                    pm2 stop libre-ar-chatbot
                    rm -rf /root/.wppconnect/libre-ar-chatbot/*
                    echo -e "${GREEN}✅ Sesión limpiada. Reinicia con opción 1${NC}"
                    sleep 2
                    ;;
                11)
                    echo -e "${CYAN}💳 Últimos pagos:${NC}"
                    sqlite3 "$DB_FILE" "SELECT payment_id, phone, plan, amount, status, created_at FROM payments ORDER BY created_at DESC LIMIT 10;" -column
                    read -p "Presiona Enter para continuar..."
                    ;;
                12)
                    echo -e "${CYAN}⚙️ Configuración actual:${NC}"
                    jq '.' "$CONFIG_FILE"
                    read -p "Presiona Enter para continuar..."
                    ;;
                0)
                    echo -e "${GREEN}👋 Hasta luego!${NC}"
                    exit 0
                    ;;
                *)
                    echo -e "${RED}Opción no válida${NC}"
                    sleep 1
                    ;;
            esac
        done
        ;;
    logs)
        pm2 logs libre-ar-chatbot --lines 50
        ;;
    restart)
        cd "$BASE_DIR"
        pm2 restart libre-ar-chatbot
        ;;
    stop)
        pm2 stop libre-ar-chatbot
        ;;
    start)
        cd "$BASE_DIR"
        pm2 start bot.js --name libre-ar-chatbot --time
        pm2 save
        ;;
    fix)
        echo -e "${YELLOW}🔧 Aplicando fix...${NC}"
        pm2 stop libre-ar-chatbot
        pkill -f chrome
        rm -rf /root/.wppconnect/libre-ar-chatbot/*
        cd "$BASE_DIR"
        pm2 start bot.js --name libre-ar-chatbot -f --time
        echo -e "${GREEN}✅ Fix aplicado. Espera el QR con: sshbot logs${NC}"
        ;;
    *)
        echo -e "${CYAN}Uso: sshbot {menu|logs|restart|stop|start|fix}${NC}"
        ;;
esac
EOF

chmod +x /usr/local/bin/sshbot

# ================================================
# CONFIGURAR PM2
# ================================================
echo -e "\n${CYAN}${BOLD}⚙️ Configurando PM2...${NC}"
pm2 startup
pm2 save

# ================================================
# INICIAR BOT
# ================================================
echo -e "\n${CYAN}${BOLD}🚀 Iniciando bot...${NC}"
cd "$INSTALL_DIR"
pm2 start bot.js --name libre-ar-chatbot --time
pm2 save

# ================================================
# MOSTRAR PANEL DE BIENVENIDA
# ================================================
clear
echo -e "${GREEN}${BOLD}"
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║     🎉 INSTALACIÓN COMPLETADA CON ÉXITO! 🎉                 ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

echo -e "${YELLOW}📋 CONFIGURACIÓN:${NC}"
echo -e "   • Bot: ${CYAN}$BOT_NAME ChatBot${NC}"
echo -e "   • Contraseña fija: ${CYAN}12345${NC}"
echo -e "   • Usuarios terminan en: ${CYAN}j${NC}"
echo -e "   • Representante: ${CYAN}$SUPPORT_NUMBER${NC}"
echo -e "   • IP Servidor: ${CYAN}$SERVER_IP${NC}"

echo -e "\n${CYAN}🖥️  COMANDO PRINCIPAL:${NC}"
echo -e "   ${GREEN}sshbot${NC} - Abre el panel de control completo"

echo -e "\n${PURPLE}📋 OPCIONES DEL PANEL:${NC}"
echo -e "   [1] 🚀 Iniciar/Reiniciar bot"
echo -e "   [2] 🛑 Detener bot"
echo -e "   [3] 📱 Ver logs y QR"
echo -e "   [4] 👤 Crear usuario manual"
echo -e "   [5] 👥 Listar usuarios"
echo -e "   [6] 💰 Cambiar precios"
echo -e "   [7] 🔑 Configurar MercadoPago"
echo -e "   [10] 🔄 Limpiar sesión"

echo -e "\n${YELLOW}📢 EJECUTA AHORA:${NC}"
echo -e "   ${GREEN}sshbot${NC} - Para abrir el panel"

echo -e "\n${CYAN}══════════════════════════════════════════════════════════════${NC}"
echo -e "${BOLD}✅ LIBRE|AR CHATBOT - VERSIÓN PREMIUM CON PANEL COMPLETO${NC}"
echo -e "${CYAN}══════════════════════════════════════════════════════════════${NC}"
