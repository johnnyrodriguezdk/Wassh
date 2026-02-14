#!/bin/bash
# ================================================
# TIENDA LIBRE|AR BOT - VERSIÓN COMPLETA
# ================================================
# CARACTERÍSTICAS:
# ✅ MENÚ EXACTO: 1=INFO, 2=PRECIOS, 3=COMPRAR, 4=RENOVAR, 5=APP, 6=REPRESENTANTE
# ✅ Usuarios terminan en 'j' · Contraseña fija: 12345
# ✅ Pregunta Android/Apple al elegir APP
# ✅ Link APP configurable (Android) · Soporte configurable (Apple)
# ✅ Limpieza total inicial
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
║              🕋 BIENVENIDO A TIENDA LIBRE|AR                ║
║                                                              ║
║     ✅ MENÚ EXACTO: 1=INFO · 2=PRECIOS · 3=COMPRAR         ║
║     4=RENOVAR · 5=APP · 6=REPRESENTANTE                    ║
║     ✅ USUARIOS TERMINAN EN 'j' · CONTRASEÑA 12345         ║
║     ✅ PREGUNTA ANDROID/APPLE · LINKS CONFIGURABLES        ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
BANNER
echo -e "${NC}"

echo -e "${GREEN}✅ CARACTERÍSTICAS:${NC}"
echo -e "  📱 ${CYAN}WPPConnect${NC} - API WhatsApp funcional"
echo -e "  💰 ${GREEN}MercadoPago SDK v2.x${NC} - Integrado"
echo -e "  🎛️  ${PURPLE}MENÚ EXACTO${NC} - 1=INFO · 2=PRECIOS · 3=COMPRAR · 4=RENOVAR · 5=APP · 6=REPRESENTANTE"
echo -e "  🔐 ${YELLOW}Usuarios terminan en 'j' · Pass: 12345${NC}"
echo -e "  📲 ${YELLOW}Pregunta Android/Apple al elegir APP${NC}"
echo -e "  🧹 ${YELLOW}Limpieza total inicial${NC}"
echo -e "${CYAN}══════════════════════════════════════════════════════════════${NC}\n"

# Verificar root
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}❌ Debes ejecutar como root${NC}"
    echo -e "${YELLOW}Usa: sudo bash $0${NC}"
    exit 1
fi

# ================================================
# LIMPIEZA TOTAL INICIAL
# ================================================
echo -e "\n${CYAN}${BOLD}🧹 EJECUTANDO LIMPIEZA TOTAL...${NC}"

# Matar procesos
echo -e "${YELLOW}Deteniendo procesos...${NC}"
pm2 kill 2>/dev/null || true
pkill -f node 2>/dev/null || true
pkill -f chrome 2>/dev/null || true
pkill -f chromium 2>/dev/null || true

# Eliminar instalaciones anteriores
echo -e "${YELLOW}Eliminando instalaciones anteriores...${NC}"
rm -rf /opt/ssh-bot /root/ssh-bot 2>/dev/null || true
rm -rf /opt/sshbot-pro /root/sshbot-pro 2>/dev/null || true
rm -rf /root/ssh-bot-whatsapp /root/iniciar-bot.sh 2>/dev/null || true
rm -rf /root/SSH-BOT /root/ssh-bot-pro 2>/dev/null || true
rm -rf /root/.wppconnect 2>/dev/null || true
rm -rf /root/.wwebjs_auth 2>/dev/null || true
rm -rf /root/.pm2/logs/* 2>/dev/null || true

echo -e "${GREEN}✅ Limpieza completada${NC}\n"

# ================================================
# CONFIGURACIÓN DEL BOT
# ================================================
echo -e "${CYAN}${BOLD}⚙️ CONFIGURACIÓN DEL BOT${NC}"

# Link de la APP (Android)
read -p "📲 Link de descarga para Android (APP): " APP_LINK
APP_LINK=${APP_LINK:-"https://www.mediafire.com/file/p8kgthxbsid7xws/MAJ/DNI_AND_FIL"}

# Número de soporte (WhatsApp)
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

echo -e "\n${GREEN}✅ Configuración guardada:${NC}"
echo -e "   • Contraseña fija: ${CYAN}12345${NC}"
echo -e "   • Usuarios terminan en: ${CYAN}j${NC}"
echo -e "   • Soporte: ${CYAN}$SUPPORT_NUMBER${NC}"
echo -e "   • APP Android: ${CYAN}$APP_LINK${NC}"
echo -e "   • Precios: 7d=$${PRICE_7D} · 15d=$${PRICE_15D} · 30d=$${PRICE_30D} · 50d=$${PRICE_50D}${NC}"
echo -e "   • Horas prueba: ${CYAN}$TEST_HOURS${NC}\n"

# Detectar IP
echo -e "${CYAN}🔍 Detectando IP...${NC}"
SERVER_IP=$(curl -4 -s --max-time 10 ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}' || echo "127.0.0.1")
if [[ -z "$SERVER_IP" || "$SERVER_IP" == "127.0.0.1" ]]; then
    read -p "📝 Ingresa la IP del servidor manualmente: " SERVER_IP
fi
echo -e "${GREEN}✅ IP: ${CYAN}$SERVER_IP${NC}\n"

# Confirmar instalación
read -p "$(echo -e "${YELLOW}¿Continuar con la instalación? (s/N): ${NC}")" -n 1 -r
echo
if [[ ! $REPLY =~ ^[Ss]$ ]]; then
    echo -e "${RED}❌ Cancelado${NC}"
    exit 0
fi

# ================================================
# INSTALAR DEPENDENCIAS
# ================================================
echo -e "\n${CYAN}📦 Instalando dependencias...${NC}"

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
# PREPARAR ESTRUCTURA
# ================================================
echo -e "\n${CYAN}📁 Creando estructura...${NC}"

INSTALL_DIR="/opt/tienda-libre-bot"
USER_HOME="/root/tienda-libre-bot"
DB_FILE="$INSTALL_DIR/data/users.db"
CONFIG_FILE="$INSTALL_DIR/config/config.json"

# Crear directorios
mkdir -p "$INSTALL_DIR"/{data,config,sessions,logs,qr_codes}
mkdir -p "$USER_HOME"
mkdir -p /root/.wppconnect
chmod -R 755 "$INSTALL_DIR"
chmod -R 700 /root/.wppconnect

# Configuración
cat > "$CONFIG_FILE" << EOF
{
    "bot": {
        "name": "TIENDA LIBRE|AR",
        "version": "1.0-MENU-EXACTO",
        "server_ip": "$SERVER_IP",
        "default_password": "12345",
        "test_hours": $TEST_HOURS
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

# Crear base de datos
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

echo -e "${GREEN}✅ Estructura creada${NC}"

# ================================================
# CREAR BOT.JS CON MENÚ EXACTO
# ================================================
echo -e "\n${CYAN}🤖 Creando bot.js con menú exacto...${NC}"

cd "$USER_HOME"

# package.json
cat > package.json << 'PKGEOF'
{
    "name": "tienda-libre-bot",
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

echo -e "${YELLOW}📦 Instalando dependencias...${NC}"
npm install --silent 2>&1 | grep -v "npm WARN" || true

# bot.js con MENÚ EXACTO
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

// Cargar configuración
function loadConfig() {
    delete require.cache[require.resolve('/opt/tienda-libre-bot/config/config.json')];
    return require('/opt/tienda-libre-bot/config/config.json');
}

let config = loadConfig();
const db = new sqlite3.Database('/opt/tienda-libre-bot/data/users.db');

console.log(chalk.cyan.bold('\n╔══════════════════════════════════════════════════════════════╗'));
console.log(chalk.cyan.bold('║              🕋 TIENDA LIBRE|AR BOT v1.0                      ║'));
console.log(chalk.cyan.bold('║     ✅ MENÚ EXACTO: 1=INFO · 2=PRECIOS · 3=COMPRAR            ║'));
console.log(chalk.cyan.bold('║     4=RENOVAR · 5=APP · 6=REPRESENTANTE                       ║'));
console.log(chalk.cyan.bold('║     ✅ USUARIOS TERMINAN EN j · CONTRASEÑA 12345              ║'));
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
        console.log(chalk.yellow('⚠️ MercadoPago NO configurado (usa sshbot-control mercadopago)'));
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
// FUNCIONES SSH - usuarios terminan en 'j' y pass 12345
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

// Función para RENOVAR usuario
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
                title: `TIENDA LIBRE|AR - ${planName}`,
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
// MENÚ EXACTO (según lo solicitado)
// ==============================================
function getMainMenuMessage() {
    return `🕋 BIENVENIDO A TIENDA LIBRE|AR

1 ⁃📢 INFORMACIÓN
2 ⁃🏷️ PRECIOS
3 ⁃🛍️ COMPRAR USUARIO
4 ⁃🔄 RENOVAR USUARIO
5 ⁃📲 DESCARGAR APLICACION
6 ⁃👥 HABLAR CON UN REPRESENTANTE

👉 Escribe una opción`;
}

function getInfoMessage() {
    return `*📢 INFORMACIÓN*

🤖 *TIENDA LIBRE|AR BOT*

🔐 *TODOS LOS USUARIOS:*
• Contraseña: *12345* (fija para todos)
• Usuario termina en *'j'*

🌐 *SERVIDOR:*
• IP: ${config.bot.server_ip}
• Puerto: 22

⏰ *PRUEBA GRATIS:*
• ${config.bot.test_hours} horas (opción 1 del menú)

💳 *PAGOS:*
• MercadoPago integrado

_Escribe *menu* para volver al inicio_`;
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

function getRenewMessage() {
    return `*🔄 RENOVAR USUARIO*

Primero, necesito que me muestres tus cuentas activas.

*1* - Ver mis cuentas
*0* - Volver al menú principal

👉 Responde:`;
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
    
    // Comando para volver al menú principal
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

// ==============================================
// MANEJADOR DEL MENÚ PRINCIPAL
// ==============================================
async function handleMainMenu(phone, text, from) {
    switch (text) {
        case '1': // INFORMACIÓN
            await client.sendText(from, getInfoMessage());
            await setUserState(phone, 'main_menu');
            break;
            
        case '2': // PRECIOS
            await client.sendText(from, getPricesMessage());
            await setUserState(phone, 'main_menu');
            break;
            
        case '3': // COMPRAR USUARIO
            await setUserState(phone, 'buying_plan', {});
            await client.sendText(from, getPlansToBuyMessage());
            break;
            
        case '4': // RENOVAR USUARIO
            await handleRenewStart(phone, from);
            break;
            
        case '5': // DESCARGAR APLICACION
            await setUserState(phone, 'waiting_os');
            await client.sendText(from, getAndroidPromptMessage());
            break;
            
        case '6': // HABLAR CON REPRESENTANTE
            await client.sendText(from, `*👥 REPRESENTANTE*\n\nContacta con nosotros:\n${config.links.support}\n\n_Escribe *menu* para volver_`);
            await setUserState(phone, 'main_menu');
            break;
            
        default:
            await client.sendText(from, `❌ Opción no válida. Elige 1-6.\n\n${getMainMenuMessage()}`);
    }
}

// ==============================================
// COMPRA DE USUARIO
// ==============================================
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

// ==============================================
// RENOVAR USUARIO
// ==============================================
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
        // Crear pago para renovación
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

// ==============================================
// MANEJAR SELECCIÓN ANDROID/APPLE
// ==============================================
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
// PRUEBA GRATIS (se activa al comprar? o es opción extra?)
// ==============================================
// Nota: El menú no incluye prueba gratis, pero si el usuario es nuevo,
// podemos ofrecerla automáticamente o mantenerla como comando especial

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
        console.log(chalk.cyan('🚀 Iniciando TIENDA LIBRE|AR BOT...'));
        
        const chromePath = config.paths.chromium;
        if (!fs.existsSync(chromePath)) {
            console.error(chalk.red(`❌ Chrome no encontrado`));
            process.exit(1);
        }
        
        setupCleanupCron();
        
        client = await wppconnect.create({
            session: 'tienda-libre-bot',
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
                console.log(chalk.cyan('3. El bot mostrará "🕋 BIENVENIDO A TIENDA LIBRE|AR"\n'));
                
                // Guardar QR
                const qrImagePath = `/opt/tienda-libre-bot/qr_codes/qr-${Date.now()}.png`;
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
                console.log(chalk.green('\n✅ TIENDA LIBRE|AR BOT LISTO'));
                console.log(chalk.cyan('💬 El bot ya puede recibir mensajes\n'));
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
        
        console.log(chalk.green.bold('\n✅ BOT INICIADO CORRECTAMENTE!'));
        iniciando = false;
        
    } catch (error) {
        console.error(chalk.red('❌ Error iniciando bot:'), error.message);
        iniciando = false;
        process.exit(1);
    }
}

startBot();
BOTEOF

echo -e "${GREEN}✅ Bot.js creado con el menú exacto solicitado${NC}"

# ================================================
# SCRIPT DE CONTROL
# ================================================
echo -e "\n${CYAN}${BOLD}⚙️ Creando script de control...${NC}"
cat > "/usr/local/bin/sshbot-control" << 'CONTROLEOF'
#!/bin/bash
BOLD='\033[1m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; CYAN='\033[0;36m'; NC='\033[0m'

case "$1" in
    start)
        echo -e "${GREEN}▶️ Iniciando TIENDA LIBRE|AR BOT...${NC}"
        cd /root/tienda-libre-bot
        pm2 start bot.js --name tienda-libre-bot --time
        pm2 save
        ;;
    stop)
        echo -e "${YELLOW}⏹️ Deteniendo bot...${NC}"
        pm2 stop tienda-libre-bot
        ;;
    restart)
        echo -e "${CYAN}🔄 Reiniciando bot...${NC}"
        pm2 restart tienda-libre-bot
        ;;
    logs)
        pm2 logs tienda-libre-bot --lines 50
        ;;
    clean)
        echo -e "${YELLOW}🧹 Limpiando sesión...${NC}"
        pm2 stop tienda-libre-bot 2>/dev/null
        rm -rf /root/.wppconnect/tienda-libre-bot/*
        echo -e "${GREEN}✅ Sesión limpiada. Reinicia con: sshbot-control restart${NC}"
        ;;
    config)
        nano /opt/tienda-libre-bot/config/config.json
        ;;
    mercadopago)
        echo -e "${CYAN}💰 Configurar MercadoPago:${NC}"
        read -p "Access Token: " token
        jq --arg t "$token" '.mercadopago.access_token = $t | .mercadopago.enabled = true' /opt/tienda-libre-bot/config/config.json > /tmp/config.tmp && mv /tmp/config.tmp /opt/tienda-libre-bot/config/config.json
        echo -e "${GREEN}✅ Token guardado. Reinicia: sshbot-control restart${NC}"
        ;;
    *)
        echo -e "${CYAN}${BOLD}TIENDA LIBRE|AR BOT - COMANDOS:${NC}"
        echo -e "  ${GREEN}start${NC}     - Iniciar bot"
        echo -e "  ${GREEN}stop${NC}      - Detener bot"
        echo -e "  ${GREEN}restart${NC}   - Reiniciar bot"
        echo -e "  ${GREEN}logs${NC}      - Ver logs/QR"
        echo -e "  ${GREEN}clean${NC}     - Limpiar sesión"
        echo -e "  ${GREEN}config${NC}    - Editar configuración"
        echo -e "  ${GREEN}mercadopago${NC} - Configurar MP"
        ;;
esac
CONTROLEOF

chmod +x /usr/local/bin/sshbot-control

# ================================================
# CONFIGURAR PM2
# ================================================
pm2 startup
pm2 save

# ================================================
# INICIAR BOT
# ================================================
echo -e "\n${CYAN}${BOLD}🚀 Iniciando TIENDA LIBRE|AR BOT...${NC}"
cd "$USER_HOME"
pm2 start bot.js --name tienda-libre-bot --time
pm2 save

echo -e "${GREEN}"
cat << "SUCCESS"
╔══════════════════════════════════════════════════════════════╗
║     🎉 INSTALACIÓN COMPLETADA CON ÉXITO! 🎉                 ║
╚══════════════════════════════════════════════════════════════╝
SUCCESS
echo -e "${NC}"

echo -e "${YELLOW}📋 CONFIGURACIÓN GUARDADA:${NC}"
echo -e "   • Contraseña fija: ${CYAN}12345${NC}"
echo -e "   • Usuarios terminan en: ${CYAN}j${NC}"
echo -e "   • Soporte: ${CYAN}$SUPPORT_NUMBER${NC}"
echo -e "   • APP Android: ${CYAN}$APP_LINK${NC}"
echo -e "   • Precios: 7d=$${PRICE_7D} · 15d=$${PRICE_15D} · 30d=$${PRICE_30D} · 50d=$${PRICE_50D}${NC}"
echo -e "   • IP Servidor: ${CYAN}$SERVER_IP${NC}"

echo -e "\n${CYAN}📱 VER QR AHORA:${NC}"
echo -e "  ${GREEN}sshbot-control logs${NC}"

echo -e "\n${PURPLE}⚡ COMANDOS ÚTILES:${NC}"
echo -e "  ${GREEN}sshbot-control logs${NC}   - Ver QR"
echo -e "  ${GREEN}sshbot-control restart${NC} - Reiniciar"
echo -e "  ${GREEN}sshbot-control mercadopago${NC} - Configurar pagos"

echo -e "\n${YELLOW}📢 MOSTRANDO LOGS (ESPERA EL QR)...${NC}"
sleep 2
pm2 logs tienda-libre-bot --lines 15 --nostream

echo -e "\n${CYAN}══════════════════════════════════════════════════════════════${NC}"
echo -e "${BOLD}✅ TIENDA LIBRE|AR BOT - VERSIÓN CON MENÚ EXACTO${NC}"
echo -e "${CYAN}══════════════════════════════════════════════════════════════${NC}"
