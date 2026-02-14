#!/bin/bash
# ================================================
# BOT WHATSAPP - INSTALACIÓN ÚNICA EN /sshbot
# ================================================
# CARACTERÍSTICAS:
# ✅ SIEMPRE instala en /sshbot (borra y sobrescribe)
# ✅ Una sola carpeta para TODAS las versiones
# ✅ Limpieza total antes de instalar
# ✅ Menú completo con INFO editable
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

# Banner
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
║           🤖 BOT WHATSAPP - INSTALACIÓN ÚNICA               ║
║     ✅ SIEMPRE EN /sshbot · ✅ SOBRESCRIBE ANTERIOR         ║
║     ✅ UNA SOLA CARPETA PARA TODAS LAS VERSIONES            ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
BANNER
echo -e "${NC}"

echo -e "${GREEN}✅ CARACTERÍSTICAS:${NC}"
echo -e "  📁 ${CYAN}Carpeta única:${NC} /sshbot (siempre ahí)"
echo -e "  🗑️  ${RED}Limpieza total:${NC} Borra instalación anterior"
echo -e "  📱 ${PURPLE}Menú completo:${NC} 1=INFO · 2=PRECIOS · 3=COMPRAR · 4=RENOVAR · 5=APP · 6=SOPORTE"
echo -e "  🔐 ${YELLOW}Usuarios terminan en 'j' · Pass: 12345${NC}"
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
# LIMPIEZA TOTAL - BORRAR TODO LO ANTERIOR
# ================================================
echo -e "\n${CYAN}${BOLD}🧹 LIMPIEZA TOTAL - BORRANDO INSTALACIÓN ANTERIOR...${NC}"

# Detener procesos
echo -e "${YELLOW}Deteniendo procesos del bot...${NC}"
pm2 delete ssh-bot 2>/dev/null || true
pm2 delete sshbot 2>/dev/null || true
pm2 delete tienda-libre-ar-bot 2>/dev/null || true
pm2 delete bot-personalizado 2>/dev/null || true
pm2 kill 2>/dev/null || true

# Matar procesos relacionados
pkill -f node 2>/dev/null || true
pkill -f chrome 2>/dev/null || true
pkill -f chromium 2>/dev/null || true

# ELIMINAR TODAS LAS CARPETAS POSIBLES DE INSTALACIONES ANTERIORES
echo -e "${YELLOW}Eliminando todas las carpetas de instalaciones anteriores...${NC}"
rm -rf /sshbot 2>/dev/null || true
rm -rf /opt/ssh-bot 2>/dev/null || true
rm -rf /root/ssh-bot 2>/dev/null || true
rm -rf /opt/sshbot-pro 2>/dev/null || true
rm -rf /root/sshbot-pro 2>/dev/null || true
rm -rf /root/ssh-bot-whatsapp 2>/dev/null || true
rm -rf /root/servertuc* 2>/dev/null || true
rm -rf /root/tienda* 2>/dev/null || true
rm -rf /root/bot* 2>/dev/null || true

# Limpiar sesiones de WhatsApp
echo -e "${YELLOW}Limpiando sesiones de WhatsApp...${NC}"
rm -rf /root/.wppconnect 2>/dev/null || true
rm -rf /root/.wwebjs_auth 2>/dev/null || true
rm -rf /root/.wwebjs_cache 2>/dev/null || true

# Limpiar logs
rm -rf /root/.pm2/logs/* 2>/dev/null || true

echo -e "${GREEN}✅ Limpieza completada. Todo listo para instalar en /sshbot${NC}\n"

# ================================================
# CREAR ESTRUCTURA EN /sshbot
# ================================================
echo -e "${CYAN}${BOLD}📁 CREANDO ESTRUCTURA EN /sshbot...${NC}"

# Crear directorios
mkdir -p "$INSTALL_DIR"/{data,config,sessions,logs,qr_codes}
mkdir -p /root/.wppconnect
chmod -R 755 "$INSTALL_DIR"
chmod -R 700 /root/.wppconnect

echo -e "${GREEN}✅ Estructura creada en /sshbot${NC}\n"

# ================================================
# CONFIGURACIÓN DEL BOT
# ================================================
echo -e "${CYAN}${BOLD}⚙️ CONFIGURACIÓN DEL BOT${NC}"

# NOMBRE DEL BOT
read -p "📝 NOMBRE PARA TU BOT (ej: TIENDA LIBRE|AR): " BOT_NAME
BOT_NAME=${BOT_NAME:-"TIENDA LIBRE|AR"}

# Link de la APP (Android)
read -p "📲 Link de descarga para Android (APP): " APP_LINK
APP_LINK=${APP_LINK:-"https://www.mediafire.com/file/p8kgthxbsid7xws/MAJ/DNI_AND_FIL"}

# Número de soporte
read -p "🆘 Número de WhatsApp para soporte (con código país): " SUPPORT_NUMBER
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

# TEXTO DE INFORMACIÓN
echo -e "\n${YELLOW}📢 TEXTO DE INFORMACIÓN (lo que verán los usuarios):${NC}"
echo "Escribe el texto que aparecerá en la opción 1 (INFO)"
echo "Puedes usar *asteriscos* para negrita"
echo "Deja una línea en blanco y presiona Ctrl+D cuando termines:"
echo "--------------------------------------------------------"

# Leer texto multilínea
INFO_TEXT=$(cat)

# Si no se ingresó texto, usar uno por defecto
if [ -z "$INFO_TEXT" ]; then
    INFO_TEXT="*📢 INFORMACIÓN DEL BOT*

🔐 *TODOS LOS USUARIOS:*
• Contraseña: *12345* (fija para todos)
• Usuario termina en *'j'*

🌐 *SERVIDOR:*
• IP: $SERVER_IP
• Puerto: 22

⏰ *PRUEBA GRATIS:*
• $TEST_HOURS horas

💳 *PAGOS:*
• MercadoPago integrado"
fi

# Detectar IP
echo -e "\n${CYAN}🔍 Detectando IP...${NC}"
SERVER_IP=$(curl -4 -s --max-time 10 ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}' || echo "127.0.0.1")
if [[ -z "$SERVER_IP" || "$SERVER_IP" == "127.0.0.1" ]]; then
    read -p "📝 Ingresa la IP del servidor manualmente: " SERVER_IP
fi
echo -e "${GREEN}✅ IP: ${CYAN}$SERVER_IP${NC}\n"

# Confirmar instalación
echo -e "${YELLOW}⚠️  RESUMEN DE CONFIGURACIÓN:${NC}"
echo -e "   • Carpeta única: ${CYAN}/sshbot${NC}"
echo -e "   • Nombre del bot: ${CYAN}$BOT_NAME${NC}"
echo -e "   • Contraseña fija: ${CYAN}12345${NC}"
echo -e "   • Usuarios terminan en: ${CYAN}j${NC}"
echo -e "   • Soporte: ${CYAN}$SUPPORT_NUMBER${NC}"
echo -e "   • APP Android: ${CYAN}$APP_LINK${NC}"
echo -e "   • Precios: 7d=$${PRICE_7D} · 15d=$${PRICE_15D} · 30d=$${PRICE_30D} · 50d=$${PRICE_50D}${NC}"

read -p "$(echo -e "${YELLOW}¿Continuar con la instalación? (s/N): ${NC}")" -n 1 -r
echo
if [[ ! $REPLY =~ ^[Ss]$ ]]; then
    echo -e "${RED}❌ Cancelado${NC}"
    exit 0
fi

# ================================================
# GUARDAR CONFIGURACIÓN
# ================================================
echo -e "\n${CYAN}💾 Guardando configuración...${NC}"

# Guardar texto de información
echo "$INFO_TEXT" > "$INFO_FILE"

# Configuración JSON
cat > "$CONFIG_FILE" << EOF
{
    "bot": {
        "name": "$BOT_NAME",
        "version": "3.0-UNICA-CARPETA",
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

echo -e "${GREEN}✅ Configuración guardada en /sshbot/config/${NC}"

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

echo -e "${GREEN}✅ Base de datos creada en /sshbot/data/${NC}"

# ================================================
# CREAR PACKAGE.JSON
# ================================================
echo -e "\n${CYAN}📦 Creando package.json...${NC}"

cd "$INSTALL_DIR"

cat > package.json << 'PKGEOF'
{
    "name": "sshbot-unico",
    "version": "1.0.0",
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

echo -e "${YELLOW}📦 Instalando dependencias de Node.js (esto puede tomar varios minutos)...${NC}"
npm install --silent 2>&1 | grep -v "npm WARN" || true

echo -e "${GREEN}✅ Dependencias instaladas en /sshbot/node_modules/${NC}"

# ================================================
# CREAR BOT.JS (VERSIÓN CORREGIDA CON RUTA /sshbot)
# ================================================
echo -e "\n${CYAN}🤖 Creando bot.js...${NC}"

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
// RUTAS FIJAS EN /sshbot
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
        console.error(chalk.yellow('Buscando en:'), CONFIG_FILE);
        process.exit(1);
    }
}

let config = loadConfig();
const db = new sqlite3.Database(DB_FILE);

// Función para leer el archivo de información
function getInfoMessage() {
    try {
        if (fs.existsSync(INFO_FILE)) {
            return fs.readFileSync(INFO_FILE, 'utf8');
        }
    } catch (error) {
        console.error('Error leyendo archivo info:', error);
    }
    
    // Texto por defecto
    return `*📢 INFORMACIÓN DEL BOT*

🔐 *TODOS LOS USUARIOS:*
• Contraseña: *12345* (fija)
• Usuario termina en *'j'*

🌐 *SERVIDOR:*
• IP: ${config.bot.server_ip}
• Puerto: 22

⏰ *PRUEBA GRATIS:*
• ${config.bot.test_hours} horas

💳 *PAGOS:*
• MercadoPago integrado`;
}

console.log(chalk.cyan.bold('\n╔══════════════════════════════════════════════════════════════╗'));
console.log(chalk.cyan.bold(`║           ${config.bot.name.padEnd(42)}║`));
console.log(chalk.cyan.bold('║     ✅ INSTALACIÓN ÚNICA EN /sshb ot · ✅ MENÚ COMPLETO       ║'));
console.log(chalk.cyan.bold('╚══════════════════════════════════════════════════════════════╝\n'));

// ==============================================
// MERCADOPAGO SDK V2.X
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
        console.log(chalk.yellow('⚠️ MercadoPago NO configurado (usa botwa mercadopago)'));
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
    return `user${timestamp}${random}j`; // TERMINA EN 'j'
}

async function createSSHUser(username, days = 0, maxConnections = 1) {
    try {
        const password = '12345'; // CONTRASEÑA FIJA
        const expiryDate = days > 0 ? 
            moment().add(days, 'days').format('YYYY-MM-DD HH:mm:ss') : 
            moment().add(config.bot.test_hours, 'hours').format('YYYY-MM-DD HH:mm:ss');
        
        await execPromise(`useradd -M -s /bin/false -e $(date -d "${expiryDate}" +%Y-%m-%d) ${username} 2>/dev/null || true`);
        await execPromise(`echo "${username}:${password}" | chpasswd`);
        
        return { success: true, username, password, expires: expiryDate };
    } catch (error) {
        console.error('Error creando usuario SSH:', error);
        return { success: false, error: error.message };
    }
}

async function renewSSHUser(username, days) {
    try {
        const newExpiry = moment().add(days, 'days').format('YYYY-MM-DD');
        await execPromise(`chage -E $(date -d "${newExpiry}" +%Y-%m-%d) ${username}`);
        
        db.run(`UPDATE users SET expires_at = ? WHERE username = ?`, 
            [moment().add(days, 'days').format('YYYY-MM-DD HH:mm:ss'), username]);
        
        return { success: true, newExpiry };
    } catch (error) {
        console.error('Error renovando usuario:', error);
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
        console.error('Error creando pago MP:', error);
        return { success: false, error: error.message };
    }
}

// ==============================================
// MENSAJES DEL BOT
// ==============================================
function getMainMenuMessage() {
    return `🕋 BIENVENIDO A ${config.bot.name}

1 ⁃📢 INFORMACIÓN
2 ⁃🏷️ PRECIOS
3 ⁃🛍️ COMPRAR USUARIO
4 ⁃🔄 RENOVAR USUARIO
5 ⁃📲 DESCARGAR APLICACION
6 ⁃👥 HABLAR CON UN REPRESENTANTE

👉 Escribe una opción`;
}

function getPricesMessage() {
    return `*🏷️ PRECIOS (ARS)*

🔸 *7 días* → $${config.prices.price_7d}
🔸 *15 días* → $${config.prices.price_15d}
🔸 *30 días* → $${config.prices.price_30d}
🔸 *50 días* → $${config.prices.price_50d}

💳 *MercadoPago - Pago automático*

_Escribe *menu* para volver_`;
}

function getPlansToBuyMessage() {
    return `*🛍️ COMPRAR USUARIO*

*Elige un plan:*

🔸 *1* - 7 días ($${config.prices.price_7d})
🔸 *2* - 15 días ($${config.prices.price_15d})
🔸 *3* - 30 días ($${config.prices.price_30d})
🔸 *4* - 50 días ($${config.prices.price_50d})

*0* - Volver al menú principal

👉 Responde con el número del plan:`;
}

function getAndroidPromptMessage() {
    return `*📲 ¿QUÉ TIPO DE DISPOSITIVO USAS?*

🔘 *1* - Android (Recibir link de descarga)
🔘 *2* - Apple/iPhone (Contactar a representante)

_Elige 1 o 2:_`;
}

function getPlanDetails(planNumber) {
    const plans = {
        1: { name: '7 días', days: 7, price: config.prices.price_7d },
        2: { name: '15 días', days: 15, price: config.prices.price_15d },
        3: { name: '30 días', days: 30, price: config.prices.price_30d },
        4: { name: '50 días', days: 50, price: config.prices.price_50d }
    };
    return plans[planNumber] || null;
}

// ==============================================
// MANEJADOR DE MENSAJES
// ==============================================
async function handleMessage(message) {
    const phone = message.from.replace('@c.us', '');
    const text = message.body || '';
    const userState = await getUserState(phone);
    
    console.log(chalk.blue(`📱 ${phone}: "${text}" (Estado: ${userState.state})`));
    
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
            await handleBuyingPlan(phone, text, message.from, userState.data);
            break;
        case 'confirm_payment':
            await handlePaymentConfirmation(phone, text, message.from, userState.data);
            break;
        case 'selecting_renew_account':
            await handleAccountSelectionForRenew(phone, text, message.from, userState.data);
            break;
        case 'selecting_renew_plan':
            await handleRenewPlanSelection(phone, text, message.from, userState.data);
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
            const infoMessage = getInfoMessage();
            await client.sendText(from, infoMessage + '\n\n_Escribe *menu* para volver_');
            await setUserState(phone, 'main_menu');
            break;
        case '2':
            await client.sendText(from, getPricesMessage());
            await setUserState(phone, 'main_menu');
            break;
        case '3':
            await setUserState(phone, 'buying_plan', {});
            await client.sendText(from, getPlansToBuyMessage());
            break;
        case '4':
            await handleRenewStart(phone, from);
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

async function handleBuyingPlan(phone, text, from, data) {
    const planNumber = parseInt(text);
    
    if (planNumber >= 1 && planNumber <= 4) {
        const plan = getPlanDetails(planNumber);
        if (plan) {
            await setUserState(phone, 'confirm_payment', { plan });
            
            const msg = `*🛍️ CONFIRMAR COMPRA*

*Plan:* ${plan.name}
*Precio:* $${plan.price} ARS

¿Deseas continuar?

🔘 *1* - Sí, generar pago
🔘 *2* - No, elegir otro plan
🔘 *0* - Menú principal

👉 Responde:`;
            await client.sendText(from, msg);
        }
    } else {
        await client.sendText(from, `❌ Plan no válido. Elige 1-4.\n\n${getPlansToBuyMessage()}`);
    }
}

async function handlePaymentConfirmation(phone, text, from, data) {
    if (text === '1') {
        const payment = await createMercadoPagoPayment(phone, data.plan.name, data.plan.days, data.plan.price);
        
        if (payment.success) {
            await client.sendText(from, `*✅ PAGO GENERADO*

*Enlace de pago:* 
${payment.paymentUrl}

*Instrucciones:*
1. Haz clic en el enlace
2. Completa el pago con MercadoPago
3. Al aprobarse, recibirás automáticamente:
   • Usuario (termina en 'j')
   • Contraseña: 12345
   • IP del servidor

_Escribe *menu* para volver_`);
            
            await setUserState(phone, 'main_menu');
        } else {
            await client.sendText(from, `❌ Error: ${payment.error}\n\nEscribe *menu* para volver.`);
            await setUserState(phone, 'main_menu');
        }
    } else if (text === '2') {
        await setUserState(phone, 'buying_plan', {});
        await client.sendText(from, getPlansToBuyMessage());
    } else if (text === '0') {
        await setUserState(phone, 'main_menu');
        await client.sendText(from, getMainMenuMessage());
    } else {
        await client.sendText(from, `Opción no válida. Elige:\n🔘 *1* - Sí\n🔘 *2* - No\n🔘 *0* - Menú principal`);
    }
}

async function handleRenewStart(phone, from) {
    db.all(`SELECT username, expires_at FROM users WHERE phone = ? AND status = 1 ORDER BY created_at DESC`, [phone], async (err, rows) => {
        if (err || !rows || rows.length === 0) {
            await client.sendText(from, `*🔄 RENOVAR USUARIO*

No tienes cuentas activas para renovar.

Primero debes comprar un usuario con la opción *3*.

_Escribe *menu* para volver_`);
            await setUserState(phone, 'main_menu');
            return;
        }
        
        let msg = `*🔄 TUS CUENTAS ACTIVAS*\n\n`;
        const accounts = [];
        
        rows.forEach((acc, i) => {
            const expires = moment(acc.expires_at).format('DD/MM/YYYY HH:mm');
            accounts.push({ username: acc.username, expires: acc.expires_at });
            msg += `*${i+1}.* 👤 ${acc.username}\n   ⏰ Expira: ${expires}\n\n`;
        });
        
        msg += `👉 Responde con el *número* de la cuenta que quieres renovar\n`;
        msg += `O *0* para volver al menú principal`;
        
        await setUserState(phone, 'selecting_renew_account', { accounts });
        await client.sendText(from, msg);
    });
}

async function handleAccountSelectionForRenew(phone, text, from, data) {
    const accountIndex = parseInt(text) - 1;
    
    if (text === '0') {
        await setUserState(phone, 'main_menu');
        await client.sendText(from, getMainMenuMessage());
        return;
    }
    
    if (data && data.accounts && accountIndex >= 0 && accountIndex < data.accounts.length) {
        const selectedAccount = data.accounts[accountIndex];
        
        await setUserState(phone, 'selecting_renew_plan', { 
            username: selectedAccount.username
        });
        
        await client.sendText(from, `*🔄 RENOVAR ${selectedAccount.username}*

*Elige el plan de renovación:*

🔸 *1* - 7 días ($${config.prices.price_7d})
🔸 *2* - 15 días ($${config.prices.price_15d})
🔸 *3* - 30 días ($${config.prices.price_30d})
🔸 *4* - 50 días ($${config.prices.price_50d})

*0* - Cancelar

👉 Responde:`);
    } else {
        await client.sendText(from, `❌ Número no válido. Elige una opción del 1 al ${data.accounts.length} o *0* para volver.`);
    }
}

async function handleRenewPlanSelection(phone, text, from, data) {
    const planNumber = parseInt(text);
    
    if (text === '0') {
        await setUserState(phone, 'main_menu');
        await client.sendText(from, getMainMenuMessage());
        return;
    }
    
    const plans = {
        1: { days: 7, price: config.prices.price_7d, name: '7 días' },
        2: { days: 15, price: config.prices.price_15d, name: '15 días' },
        3: { days: 30, price: config.prices.price_30d, name: '30 días' },
        4: { days: 50, price: config.prices.price_50d, name: '50 días' }
    };
    
    const plan = plans[planNumber];
    
    if (plan && data && data.username) {
        const payment = await createMercadoPagoPayment(phone, `RENOVACIÓN ${data.username}`, plan.days, plan.price);
        
        if (payment.success) {
            await client.sendText(from, `*✅ PAGO PARA RENOVACIÓN GENERADO*

*Usuario a renovar:* ${data.username}
*Plan:* ${plan.name}
*Monto:* $${plan.price} ARS

*Enlace de pago:* 
${payment.paymentUrl}

*Importante:* Al aprobarse el pago, la cuenta se renovará automáticamente por ${plan.days} días adicionales.

_Escribe *menu* para volver_`);
            
            await setUserState(phone, 'main_menu');
        } else {
            await client.sendText(from, `❌ Error: ${payment.error}\n\nEscribe *menu* para volver.`);
            await setUserState(phone, 'main_menu');
        }
    } else {
        await client.sendText(from, `❌ Plan no válido. Elige 1-4 o *0* para cancelar.`);
    }
}

async function handleOSSelection(phone, text, from) {
    if (text === '1') {
        await client.sendText(from, `*📲 DESCARGA PARA ANDROID*

Link: ${config.links.app_android}

*Instrucciones:*
1. Descarga el archivo APK
2. Habilita "fuentes desconocidas" en tu Android
3. Instala la aplicación
4. Configura con los datos que te proporcionamos

*¿Necesitas ayuda?* Contacta a representante: ${config.links.support}

_Escribe *menu* para volver_`);
        await setUserState(phone, 'main_menu');
        
    } else if (text === '2') {
        await client.sendText(from, `*🍎 APPLE/IPHONE*

Para dispositivos Apple, contacta a nuestro representante:

${config.links.support}

Te guiarán paso a paso en la configuración específica para iPhone.

_Escribe *menu* para volver_`);
        await setUserState(phone, 'main_menu');
        
    } else {
        await client.sendText(from, `❌ Opción no válida. Elige:\n🔘 *1* - Android\n🔘 *2* - Apple/iPhone`);
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
                console.log(chalk.gray(`  ➤ Usuario ${user.username} eliminado`));
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
        console.log(chalk.cyan(`🚀 Iniciando ${config.bot.name}...`));
        
        const chromePath = config.paths.chromium;
        if (!fs.existsSync(chromePath)) {
            console.error(chalk.red(`❌ Chrome no encontrado`));
            process.exit(1);
        }
        
        setupCleanupCron();
        
        client = await wppconnect.create({
            session: 'sshbot-unico',
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
                console.log(chalk.cyan('2. Escanea este código QR'));
                console.log(chalk.cyan('3. El bot mostrará el menú completo\n'));
                
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
                console.log(chalk.green(`\n✅ ${config.bot.name} LISTO`));
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
        
        console.log(chalk.green.bold(`\n✅ ${config.bot.name} INICIADO CORRECTAMENTE!`));
        iniciando = false;
        
    } catch (error) {
        console.error(chalk.red('❌ Error iniciando bot:'), error.message);
        iniciando = false;
        process.exit(1);
    }
}

startBot();
BOTEOF

echo -e "${GREEN}✅ Bot.js creado en /sshbot/bot.js${NC}"

# ================================================
# CREAR SCRIPT DE CONTROL 'botwa'
# ================================================
echo -e "\n${CYAN}${BOLD}⚙️ Creando script de control 'botwa'...${NC}"

cat > "/usr/local/bin/botwa" << 'CONTROLEOF'
#!/bin/bash
BOLD='\033[1m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; CYAN='\033[0;36m'; NC='\033[0m'

BASE_DIR="/sshbot"
CONFIG_FILE="$BASE_DIR/config/config.json"
INFO_FILE="$BASE_DIR/config/info.txt"

case "$1" in
    menu|"")
        echo -e "${CYAN}${BOLD}===== 🤖 BOT ADMINISTRABLE =====${NC}"
        echo -e "${GREEN}Comandos disponibles:${NC}"
        echo -e "  ${YELLOW}botwa menu${NC}       - Mostrar este menú"
        echo -e "  ${YELLOW}botwa edit info${NC}   - Editar texto de INFORMACIÓN"
        echo -e "  ${YELLOW}botwa edit precios${NC} - Editar precios"
        echo -e "  ${YELLOW}botwa edit soporte${NC} - Editar número de soporte"
        echo -e "  ${YELLOW}botwa edit app${NC}     - Editar link de la APP"
        echo -e "  ${YELLOW}botwa logs${NC}        - Ver logs/QR"
        echo -e "  ${YELLOW}botwa restart${NC}     - Reiniciar bot"
        echo -e "  ${YELLOW}botwa stop${NC}        - Detener bot"
        echo -e "  ${YELLOW}botwa start${NC}       - Iniciar bot"
        echo -e "  ${YELLOW}botwa mercadopago${NC} - Configurar MP"
        echo -e "  ${YELLOW}botwa show info${NC}    - Ver texto actual de información"
        echo -e "\n📁 Instalación única en: ${CYAN}/sshbot${NC}"
        ;;
        
    edit)
        case "$2" in
            info)
                echo -e "${CYAN}📝 Editando texto de INFORMACIÓN${NC}"
                echo -e "${YELLOW}Texto actual:${NC}"
                echo "--------------------------------------------------------"
                cat "$INFO_FILE"
                echo "--------------------------------------------------------"
                echo -e "${GREEN}Escribe el nuevo texto (Ctrl+D para guardar):${NC}"
                cat > "$INFO_FILE"
                echo -e "${GREEN}✅ Texto de información actualizado${NC}"
                echo -e "${YELLOW}Reinicia el bot: botwa restart${NC}"
                ;;
                
            precios)
                echo -e "${CYAN}💰 Editando precios${NC}"
                source <(jq -r '.prices | to_entries[] | "\(.key)=\(.value)"' "$CONFIG_FILE")
                echo -e "${YELLOW}Precio actual 7 días: $price_7d${NC}"
                read -p "Nuevo precio 7 días: " new_7d
                echo -e "${YELLOW}Precio actual 15 días: $price_15d${NC}"
                read -p "Nuevo precio 15 días: " new_15d
                echo -e "${YELLOW}Precio actual 30 días: $price_30d${NC}"
                read -p "Nuevo precio 30 días: " new_30d
                echo -e "${YELLOW}Precio actual 50 días: $price_50d${NC}"
                read -p "Nuevo precio 50 días: " new_50d
                
                jq --arg p7 "${new_7d:-$price_7d}" \
                   --arg p15 "${new_15d:-$price_15d}" \
                   --arg p30 "${new_30d:-$price_30d}" \
                   --arg p50 "${new_50d:-$price_50d}" \
                   '.prices.price_7d = ($p7|tonumber) | 
                    .prices.price_15d = ($p15|tonumber) | 
                    .prices.price_30d = ($p30|tonumber) | 
                    .prices.price_50d = ($p50|tonumber)' \
                   "$CONFIG_FILE" > /tmp/config.tmp && mv /tmp/config.tmp "$CONFIG_FILE"
                
                echo -e "${GREEN}✅ Precios actualizados${NC}"
                echo -e "${YELLOW}Reinicia el bot: botwa restart${NC}"
                ;;
                
            soporte)
                echo -e "${CYAN}🆘 Editando número de soporte${NC}"
                CURRENT_SUPPORT=$(jq -r '.links.support' "$CONFIG_FILE" | sed 's|https://wa.me/||')
                echo -e "${YELLOW}Número actual: $CURRENT_SUPPORT${NC}"
                read -p "Nuevo número de WhatsApp (con código país): " new_support
                if [ -n "$new_support" ]; then
                    jq --arg s "https://wa.me/$new_support" '.links.support = $s' "$CONFIG_FILE" > /tmp/config.tmp && mv /tmp/config.tmp "$CONFIG_FILE"
                    echo -e "${GREEN}✅ Número de soporte actualizado${NC}"
                    echo -e "${YELLOW}Reinicia el bot: botwa restart${NC}"
                fi
                ;;
                
            app)
                echo -e "${CYAN}📲 Editando link de la APP${NC}"
                CURRENT_APP=$(jq -r '.links.app_android' "$CONFIG_FILE")
                echo -e "${YELLOW}Link actual: $CURRENT_APP${NC}"
                read -p "Nuevo link de descarga Android: " new_app
                if [ -n "$new_app" ]; then
                    jq --arg a "$new_app" '.links.app_android = $a' "$CONFIG_FILE" > /tmp/config.tmp && mv /tmp/config.tmp "$CONFIG_FILE"
                    echo -e "${GREEN}✅ Link de APP actualizado${NC}"
                    echo -e "${YELLOW}Reinicia el bot: botwa restart${NC}"
                fi
                ;;
                
            *)
                echo -e "${RED}❌ Opción no válida. Usa: botwa edit {info|precios|soporte|app}${NC}"
                ;;
        esac
        ;;
        
    show)
        if [ "$2" == "info" ]; then
            echo -e "${CYAN}📢 TEXTO DE INFORMACIÓN ACTUAL:${NC}"
            echo "--------------------------------------------------------"
            cat "$INFO_FILE"
            echo "--------------------------------------------------------"
        else
            jq '.' "$CONFIG_FILE"
        fi
        ;;
        
    logs)
        pm2 logs sshbot-unico --lines 50
        ;;
        
    restart)
        echo -e "${CYAN}🔄 Reiniciando bot...${NC}"
        pm2 restart sshbot-unico
        ;;
        
    stop)
        echo -e "${YELLOW}⏹️ Deteniendo bot...${NC}"
        pm2 stop sshbot-unico
        ;;
        
    start)
        echo -e "${GREEN}▶️ Iniciando bot...${NC}"
        cd "$BASE_DIR"
        pm2 start bot.js --name sshbot-unico --time
        pm2 save
        ;;
        
    mercadopago)
        echo -e "${CYAN}💰 Configurar MercadoPago:${NC}"
        read -p "Access Token: " token
        jq --arg t "$token" '.mercadopago.access_token = $t | .mercadopago.enabled = true' "$CONFIG_FILE" > /tmp/config.tmp && mv /tmp/config.tmp "$CONFIG_FILE"
        echo -e "${GREEN}✅ Token guardado. Reinicia: botwa restart${NC}"
        ;;
        
    clean)
        echo -e "${YELLOW}🧹 Limpiando sesión de WhatsApp...${NC}"
        pm2 stop sshbot-unico 2>/dev/null
        rm -rf /root/.wppconnect/sshbot-unico/*
        echo -e "${GREEN}✅ Sesión limpiada. Reinicia: botwa restart${NC}"
        ;;
        
    fix)
        echo -e "${YELLOW}🔧 Aplicando fix completo...${NC}"
        pm2 stop sshbot-unico 2>/dev/null
        pkill -f chrome 2>/dev/null
        rm -rf /root/.wppconnect/sshbot-unico/*
        cd "$BASE_DIR"
        pm2 start bot.js --name sshbot-unico -f --time
        echo -e "${GREEN}✅ Fix aplicado. Espera el QR con: botwa logs${NC}"
        ;;
        
    *)
        echo -e "${RED}❌ Comando no reconocido. Usa 'botwa menu' para ver opciones.${NC}"
        ;;
esac
CONTROLEOF

chmod +x /usr/local/bin/botwa

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
pm2 start bot.js --name sshbot-unico --time
pm2 save

echo -e "${GREEN}"
cat << "SUCCESS"
╔══════════════════════════════════════════════════════════════╗
║     🎉 INSTALACIÓN COMPLETADA CON ÉXITO! 🎉                 ║
╚══════════════════════════════════════════════════════════════╝
SUCCESS
echo -e "${NC}"

echo -e "${YELLOW}📋 INSTALACIÓN ÚNICA EN /sshbot:${NC}"
echo -e "   • Carpeta: ${CYAN}/sshbot${NC} (siempre aquí)"
echo -e "   • Nombre del bot: ${CYAN}$BOT_NAME${NC}"
echo -e "   • Contraseña fija: ${CYAN}12345${NC}"
echo -e "   • Usuarios terminan en: ${CYAN}j${NC}"
echo -e "   • Soporte: ${CYAN}$SUPPORT_NUMBER${NC}"
echo -e "   • APP Android: ${CYAN}$APP_LINK${NC}"
echo -e "   • Precios: 7d=$${PRICE_7D} · 15d=$${PRICE_15D} · 30d=$${PRICE_30D} · 50d=$${PRICE_50D}${NC}"

echo -e "\n${CYAN}🖥️  COMANDOS DESDE VPS (USA 'botwa'):${NC}"
echo -e "  ${GREEN}botwa menu${NC}           - Ver todos los comandos"
echo -e "  ${GREEN}botwa edit info${NC}      - Editar texto de INFORMACIÓN"
echo -e "  ${GREEN}botwa edit precios${NC}   - Editar precios"
echo -e "  ${GREEN}botwa edit soporte${NC}   - Editar número soporte"
echo -e "  ${GREEN}botwa edit app${NC}       - Editar link APP"
echo -e "  ${GREEN}botwa logs${NC}           - Ver QR y logs"
echo -e "  ${GREEN}botwa fix${NC}            - Reparar si hay errores"

echo -e "\n${CYAN}📱 EN WHATSAPP (MENÚ COMPLETO):${NC}"
echo -e "  • 1 ⁃📢 INFORMACIÓN (texto editable desde VPS)"
echo -e "  • 2 ⁃🏷️ PRECIOS (editables desde VPS)"
echo -e "  • 3 ⁃🛍️ COMPRAR USUARIO"
echo -e "  • 4 ⁃🔄 RENOVAR USUARIO"
echo -e "  • 5 ⁃📲 DESCARGAR APP (pregunta Android/Apple)"
echo -e "  • 6 ⁃👥 HABLAR CON REPRESENTANTE"

echo -e "\n${YELLOW}📢 MOSTRANDO LOGS (ESPERA EL QR)...${NC}"
sleep 2
pm2 logs sshbot-unico --lines 15 --nostream

echo -e "\n${CYAN}══════════════════════════════════════════════════════════════${NC}"
echo -e "${BOLD}✅ INSTALACIÓN ÚNICA EN /sshbot - TODAS LAS VERSIONES AQUÍ${NC}"
echo -e "${CYAN}══════════════════════════════════════════════════════════════${NC}"
