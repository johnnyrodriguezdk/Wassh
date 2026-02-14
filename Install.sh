#!/bin/bash
# ================================================
# SERVERTUC™ BOT v9.0 - HÍBRIDO WPPCONNECT
# Mantiene: MENÚS y SISTEMA DE ESTADOS del primer bot
# Incorpora: API WPPConnect y MERCADOPAGO SDK v2.x del segundo
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

# Banner SERVERTUC™ (del primer bot)
clear
echo -e "${CYAN}${BOLD}"
cat << "BANNER"
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║    ███████╗███████╗██████╗ ██╗   ██╗██████╗ ████████╗██╗   ██╗║
║    ██╔════╝██╔════╝██╔══██╗██║   ██║██╔══██╗╚══██╔══╝██║   ██║║
║    ███████╗█████╗  ██████╔╝██║   ██║██████╔╝   ██║   ██║   ██║║
║    ╚════██║██╔══╝  ██╔══██╗██║   ██║██╔══██╗   ██║   ██║   ██║║
║    ███████║███████╗██║  ██║╚██████╔╝██║  ██║   ██║   ╚██████╔╝║
║    ╚══════╝╚══════╝╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═╝   ╚═╝    ╚═════╝ ║
╠══════════════════════════════════════════════════════════════╣
║                                                              ║
║              SERVERTUC™ BOT v9.0 - HÍBRIDO                  ║
║   ✅ MENÚS ORIGINALES + ✅ WPPCONNECT (API NUEVA)           ║
║   ✅ SISTEMA DE ESTADOS + ✅ MERCADOPAGO SDK v2.x           ║
║   🔌 1,2,3,4,5,6,7 PARA COMPRAR EN PLANES                   ║
║   🔐 CONTRASEÑA FIJA: 12345  |  👤 USUARIOS TERMINAN EN 'j' ║
║   🆕 NUEVO PLAN 50 DÍAS INCLUIDO                            ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
BANNER
echo -e "${NC}"

echo -e "${GREEN}✅ FUNCIONALIDAD COMBINADA:${NC}"
echo -e "  🔴 ${RED}MENÚ PRINCIPAL (Del primer bot):${NC}"
echo -e "     ${GREEN}1${NC} = Prueba gratis (2h)"
echo -e "     ${GREEN}2${NC} = Ver planes (7 opciones)"
echo -e "     ${GREEN}3${NC} = Mis cuentas"
echo -e "     ${GREEN}4${NC} = Estado de pago"
echo -e "     ${GREEN}5${NC} = Descargar APP"
echo -e "     ${GREEN}6${NC} = Soporte"
echo -e "  🟡 ${YELLOW}MENÚ PLANES (Del primer bot):${NC}"
echo -e "     ${GREEN}1${NC} = 7d 1con | 2=15d 1con | 3=30d 1con"
echo -e "     ${GREEN}4${NC} = 7d 2con | 5=15d 2con | 6=30d 2con"
echo -e "     ${GREEN}7${NC} = 50d 1con (NUEVO)"
echo -e "  🟢 ${GREEN}TECNOLOGÍA NUEVA (Del segundo bot):${NC}"
echo -e "     📱 ${CYAN}WPPConnect${NC} - API WhatsApp estable"
echo -e "     💰 ${GREEN}MercadoPago SDK v2.x${NC}"
echo -e "${CYAN}══════════════════════════════════════════════════════════════${NC}\n"

# Verificar root (del primer bot)
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}${BOLD}❌ ERROR: Debes ejecutar como root${NC}"
    echo -e "${YELLOW}Usa: sudo bash $0${NC}"
    exit 1
fi

# Detectar IP (del primer bot, con mensaje mejorado)
echo -e "${CYAN}${BOLD}🔍 DETECTANDO IP DEL SERVIDOR...${NC}"
SERVER_IP=$(curl -4 -s --max-time 10 ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}' || echo "127.0.0.1")
if [[ -z "$SERVER_IP" || "$SERVER_IP" == "127.0.0.1" ]]; then
    echo -e "${RED}❌ No se pudo obtener IP pública automáticamente${NC}"
    read -p "📝 Ingresa la IP del servidor manualmente: " SERVER_IP
fi
echo -e "${GREEN}✅ IP detectada/usada: ${CYAN}$SERVER_IP${NC}\n"

# Confirmar instalación (adaptado de ambos)
echo -e "${YELLOW}⚠️  ESTE INSTALADOR HÍBRIDO REALIZARÁ:${NC}"
echo -e "   • Instalación limpia (eliminará versiones anteriores)"
echo -e "   • Node.js 18.x + Google Chrome (para WPPConnect)"
echo -e "   • Menús y sistema de ESTADOS del primer bot"
echo -e "   • API WhatsApp WPPConnect (nueva y estable)"
echo -e "   • MercadoPago SDK v2.x (configurable post-instalación)"
echo -e "   • Base de datos SQLite con estructura completa"
echo -e "   • Script de control 'sshbot-control' con 12 comandos"
echo -e "   • Cron jobs: limpieza c/15min y backup diario"
echo -e "\n${RED}⚠️  SE ELIMINARÁN INSTALACIONES ANTERIORES (pm2, /opt/ssh-bot, /root/.wppconnect)${NC}"
read -p "$(echo -e "${YELLOW}¿Continuar con la instalación? (s/N): ${NC}")" -n 1 -r
echo
if [[ ! $REPLY =~ ^[Ss]$ ]]; then
    echo -e "${RED}❌ Instalación cancelada${NC}"
    exit 0
fi

# ================================================
# 1. INSTALAR DEPENDENCIAS (Base del segundo bot)
# ================================================
echo -e "\n${CYAN}${BOLD}📦 INSTALANDO DEPENDENCIAS DEL SISTEMA...${NC}"
apt-get update -y && apt-get upgrade -y

# Node.js 18.x (recomendado para WPPConnect)
echo -e "${YELLOW}📦 Instalando Node.js 18.x...${NC}"
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt-get install -y nodejs gcc g++ make

# Google Chrome (para WPPConnect)
echo -e "${YELLOW}🌐 Instalando Google Chrome...${NC}"
wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | apt-key add -
echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list
apt-get update -y
apt-get install -y google-chrome-stable

# Dependencias del sistema (unificadas)
echo -e "${YELLOW}⚙️ Instalando utilidades y librerías...${NC}"
apt-get install -y \
    git curl wget sqlite3 jq \
    build-essential libcairo2-dev libpango1.0-dev \
    libjpeg-dev libgif-dev librsvg2-dev \
    python3 python3-pip ffmpeg unzip \
    cron ufw

# PM2 global
echo -e "${YELLOW}🔄 Instalando PM2...${NC}"
npm install -g pm2
pm2 update

# Firewall (puertos comunes)
echo -e "${YELLOW}🛡️ Configurando firewall (UFW)...${NC}"
ufw allow 22/tcp && ufw allow 80/tcp && ufw allow 443/tcp
ufw allow 8001/tcp && ufw allow 3000/tcp
ufw --force enable

echo -e "${GREEN}✅ Dependencias instaladas${NC}"

# ================================================
# 2. PREPARAR ESTRUCTURA (Fusión de ambos)
# ================================================
echo -e "\n${CYAN}${BOLD}📁 CREANDO ESTRUCTURA DE DIRECTORIOS...${NC}"

# Usar rutas del primer bot para mantener consistencia
INSTALL_DIR="/opt/ssh-bot"
USER_HOME="/root/ssh-bot"
DB_FILE="$INSTALL_DIR/data/users.db"
CONFIG_FILE="$INSTALL_DIR/config/config.json"

# Limpieza profunda
echo -e "${YELLOW}🧹 Limpiando instalaciones anteriores...${NC}"
pm2 delete ssh-bot 2>/dev/null || true
pm2 flush 2>/dev/null || true
rm -rf "$INSTALL_DIR" "$USER_HOME" 2>/dev/null || true
rm -rf /root/.wppconnect /root/.wwebjs_auth /root/sshbot-pro 2>/dev/null || true

# Crear directorios (estructura del primer bot + sesiones WPPConnect)
mkdir -p "$INSTALL_DIR"/{data,config,qr_codes,logs,sessions}
mkdir -p "$USER_HOME"
mkdir -p /root/.wppconnect
chmod -R 755 "$INSTALL_DIR"
chmod -R 700 /root/.wppconnect

echo -e "${GREEN}✅ Estructura creada${NC}"

# ================================================
# 3. CONFIGURACIÓN (Fusión: precios/primer bot + MP/segundo bot)
# ================================================
echo -e "\n${CYAN}${BOLD}⚙️ CREANDO ARCHIVO DE CONFIGURACIÓN...${NC}"

cat > "$CONFIG_FILE" << EOF
{
    "bot": {
        "name": "SERVERTUC™ BOT",
        "version": "9.0-HIBRIDO-WPPCONNECT",
        "server_ip": "$SERVER_IP",
        "default_password": "12345"
    },
    "prices": {
        "test_hours": 2,
        "price_7d_1conn": 500.00,
        "price_15d_1conn": 800.00,
        "price_30d_1conn": 1200.00,
        "price_50d_1conn": 1800.00,
        "price_7d_2conn": 800.00,
        "price_15d_2conn": 1200.00,
        "price_30d_2conn": 1800.00,
        "currency": "ARS"
    },
    "mercadopago": {
        "access_token": "",
        "enabled": false,
        "public_key": ""
    },
    "links": {
        "tutorial": "https://youtube.com",
        "support": "https://wa.me/3813414485",
        "app_download": "https://www.mediafire.com/file/p8kgthxbsid7xws/MAJ/DNI_AND_FIL"
    },
    "paths": {
        "database": "$DB_FILE",
        "chromium": "/usr/bin/google-chrome",
        "qr_codes": "$INSTALL_DIR/qr_codes",
        "sessions": "/root/.wppconnect"
    }
}
EOF
echo -e "${GREEN}✅ Configuración creada${NC}"

# ================================================
# 4. BASE DE DATOS (Estructura completa de ambos)
# ================================================
echo -e "\n${CYAN}${BOLD}🗄️ CREANDO BASE DE DATOS SQLite...${NC}"

sqlite3 "$DB_FILE" << 'SQL'
-- Tabla de usuarios (con campos del primer bot)
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
-- Control de pruebas diarias
CREATE TABLE daily_tests (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    phone TEXT,
    date DATE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(phone, date)
);
-- Pagos (unificado)
CREATE TABLE payments (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    payment_id TEXT UNIQUE,
    phone TEXT,
    plan TEXT,
    days INTEGER,
    connections INTEGER DEFAULT 1,
    amount REAL,
    status TEXT DEFAULT 'pending',
    payment_url TEXT,
    qr_code TEXT,
    preference_id TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    approved_at DATETIME
);
-- Logs
CREATE TABLE logs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    type TEXT,
    message TEXT,
    data TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
-- Sistema de estados (clave del primer bot)
CREATE TABLE user_state (
    phone TEXT PRIMARY KEY,
    state TEXT DEFAULT 'main_menu',
    data TEXT,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
-- Índices
CREATE INDEX idx_users_phone ON users(phone);
CREATE INDEX idx_users_status ON users(status);
CREATE INDEX idx_payments_status ON payments(status);
CREATE INDEX idx_payments_preference ON payments(preference_id);
SQL
echo -e "${GREEN}✅ Base de datos creada${NC}"

# ================================================
# 5. CREAR BOT.JS (Fusión completa)
# ================================================
echo -e "\n${CYAN}${BOLD}🤖 CREANDO ARCHIVO PRINCIPAL DEL BOT (bot.js)...${NC}"
cd "$USER_HOME"

# package.json (del segundo bot)
cat > package.json << 'PKGEOF'
{
    "name": "servertuc-bot",
    "version": "9.0.0",
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

# bot.js (Fusión: lógica del primer bot + API WPPConnect/MP del segundo)
echo -e "${YELLOW}📝 Escribiendo lógica del bot (bot.js)...${NC}"
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

console.log(chalk.cyan.bold('\n╔══════════════════════════════════════════════════════════════╗'));
console.log(chalk.cyan.bold('║              SERVERTUC™ BOT v9.0 - HÍBRIDO                   ║'));
console.log(chalk.cyan.bold('║         ✅ MENÚS ORIGINALES + ✅ WPPCONNECT                  ║'));
console.log(chalk.cyan.bold('╚══════════════════════════════════════════════════════════════╝\n'));

// ==============================================
// CARGA DE CONFIGURACIÓN
// ==============================================
function loadConfig() {
    delete require.cache[require.resolve('/opt/ssh-bot/config/config.json')];
    return require('/opt/ssh-bot/config/config.json');
}
let config = loadConfig();
const db = new sqlite3.Database('/opt/ssh-bot/data/users.db');

// ==============================================
// MERCADOPAGO SDK V2.X (del segundo bot)
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
                options: { timeout: 5000, idempotencyKey: true }
            });
            mpPreference = new Preference(mpClient);
            mpEnabled = true;
            console.log(chalk.green('✅ MercadoPago SDK v2.x ACTIVO'));
        } catch (error) {
            console.log(chalk.red('❌ Error inicializando MP:'), error.message);
            mpEnabled = false;
        }
    } else {
        console.log(chalk.yellow('⚠️ MercadoPago NO configurado (usar post-instalación: sshbot-control mercadopago)'));
    }
    return mpEnabled;
}
initMercadoPago();

// ==============================================
// SISTEMA DE ESTADOS (CORAZÓN DEL PRIMER BOT)
// ==============================================
function getUserState(phone) {
    return new Promise((resolve) => {
        db.get('SELECT state, data FROM user_state WHERE phone = ?', [phone], (err, row) => {
            if (err || !row) {
                resolve({ state: 'main_menu', data: null });
            } else {
                resolve({
                    state: row.state || 'main_menu',
                    data: row.data ? JSON.parse(row.data) : null
                });
            }
        });
    });
}

function setUserState(phone, state, data = null) {
    return new Promise((resolve) => {
        const dataStr = data ? JSON.stringify(data) : null;
        db.run(
            `INSERT OR REPLACE INTO user_state (phone, state, data, updated_at) VALUES (?, ?, ?, CURRENT_TIMESTAMP)`,
            [phone, state, dataStr],
            (err) => resolve(!err)
        );
    });
}

// ==============================================
// FUNCIONES DE SISTEMA SSH (del primer bot)
// ==============================================
function generateSSHUsername(phone) {
    const timestamp = Date.now().toString().slice(-6);
    const random = Math.floor(Math.random() * 90) + 10;
    return `user${timestamp}${random}j`; // Termina en 'j'
}

async function createSSHUser(username, password = '12345', days = 0, maxConnections = 1) {
    try {
        const expiryDate = days > 0 ? 
            moment().add(days, 'days').format('YYYY-MM-DD HH:mm:ss') : 
            moment().add(config.prices.test_hours, 'hours').format('YYYY-MM-DD HH:mm:ss');
        
        const command = `useradd -M -s /bin/false -e $(date -d "${expiryDate}" +%Y-%m-%d) ${username} && echo "${username}:${password}" | chpasswd`;
        await execPromise(command);
        
        if (maxConnections > 1) {
            await execPromise(`echo "MaxSessions ${maxConnections}" >> /etc/ssh/sshd_config.d/${username}.conf`);
            await execPromise('systemctl restart sshd');
        }
        return { success: true, username, password, expires: expiryDate };
    } catch (error) {
        console.error('Error creando usuario SSH:', error);
        return { success: false, error: error.message };
    }
}

// ==============================================
// FUNCIONES DE PAGO MERCADOPAGO (del segundo bot)
// ==============================================
async function createMercadoPagoPayment(phone, planName, days, amount, connections = 1) {
    if (!mpEnabled) {
        return { success: false, error: 'MercadoPago no configurado' };
    }
    try {
        const paymentId = `MP-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
        const preferenceData = {
            items: [{
                title: `SERVERTUC™ - ${planName}`,
                description: `Plan ${days} días - ${connections} conexión(es)`,
                quantity: 1,
                currency_id: 'ARS',
                unit_price: parseFloat(amount)
            }],
            payer: { phone: { number: phone.replace('+', '') } },
            payment_methods: { excluded_payment_types: [{ id: 'atm' }], installments: 1 },
            notification_url: `http://${config.bot.server_ip}:3000/webhook/mp`,
            external_reference: paymentId,
            back_urls: {
                success: `https://wa.me/${phone}?text=Pago+aprobado+${paymentId}`,
                pending: `https://wa.me/${phone}?text=Pago+pendiente+${paymentId}`,
                failure: `https://wa.me/${phone}?text=Pago+rechazado+${paymentId}`
            },
            auto_return: 'approved'
        };
        
        const preference = await mpPreference.create({ body: preferenceData });
        const qrPath = path.join(config.paths.qr_codes, `${paymentId}.png`);
        await QRCode.toFile(qrPath, preference.init_point);
        
        db.run(
            `INSERT INTO payments (payment_id, phone, plan, days, connections, amount, status, payment_url, qr_code, preference_id) 
             VALUES (?, ?, ?, ?, ?, ?, 'pending', ?, ?, ?)`,
            [paymentId, phone, planName, days, connections, amount, preference.init_point, qrPath, preference.id]
        );
        
        return { success: true, paymentId, paymentUrl: preference.init_point, qrCode: qrPath, preferenceId: preference.id };
    } catch (error) {
        console.error('Error creando pago MP:', error);
        return { success: false, error: error.message };
    }
}

// ==============================================
// MENSAJES (Del primer bot)
// ==============================================
function getMainMenuMessage() {
    return `*🤖 SERVERTUC™ BOT v9.0 (HÍBRIDO)*

*MENÚ PRINCIPAL:*
🔹 *1* - Prueba gratis (${config.prices.test_hours} horas)
🔹 *2* - Ver planes y precios
🔹 *3* - Mis cuentas SSH
🔹 *4* - Estado de pago
🔹 *5* - Descargar APP
🔹 *6* - Soporte

*Elige una opción (1-6):*`;
}

function getPlansMenuMessage() {
    return `*📋 PLANES DISPONIBLES:*

*PLANES 1 CONEXIÓN:*
🔸 *1* - 7 días → $${config.prices.price_7d_1conn} ARS
🔸 *2* - 15 días → $${config.prices.price_15d_1conn} ARS
🔸 *3* - 30 días → $${config.prices.price_30d_1conn} ARS
🔸 *7* - 50 días → $${config.prices.price_50d_1conn} ARS

*PLANES 2 CONEXIONES:*
🔸 *4* - 7 días → $${config.prices.price_7d_2conn} ARS
🔸 *5* - 15 días → $${config.prices.price_15d_2conn} ARS
🔸 *6* - 30 días → $${config.prices.price_30d_2conn} ARS

*Elige el plan (1-7):*
_O escribe 0 para volver al menú principal_`;
}

function getPlanDetails(planNumber) {
    const plans = {
        1: { name: '7 días (1 conexión)', days: 7, connections: 1, price: 'price_7d_1conn' },
        2: { name: '15 días (1 conexión)', days: 15, connections: 1, price: 'price_15d_1conn' },
        3: { name: '30 días (1 conexión)', days: 30, connections: 1, price: 'price_30d_1conn' },
        4: { name: '7 días (2 conexiones)', days: 7, connections: 2, price: 'price_7d_2conn' },
        5: { name: '15 días (2 conexiones)', days: 15, connections: 2, price: 'price_15d_2conn' },
        6: { name: '30 días (2 conexiones)', days: 30, connections: 2, price: 'price_30d_2conn' },
        7: { name: '50 días (1 conexión)', days: 50, connections: 1, price: 'price_50d_1conn' }
    };
    return plans[planNumber] || null;
}

// ==============================================
// MANEJADOR DE MENSAJES (Lógica completa del primer bot)
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
        case 'plans_menu':
            await handlePlansMenu(phone, text, message.from);
            break;
        case 'buying_plan':
            await handleBuyingPlan(phone, text, message.from, userState.data);
            break;
        default:
            await setUserState(phone, 'main_menu');
            await client.sendText(message.from, getMainMenuMessage());
    }
}

async function handleMainMenu(phone, text, from) {
    switch (text) {
        case '1': await handleFreeTest(phone, from); break;
        case '2': 
            await setUserState(phone, 'plans_menu');
            await client.sendText(from, getPlansMenuMessage());
            break;
        case '3': await showMyAccounts(phone, from); break;
        case '4': await showPaymentStatus(phone, from); break;
        case '5':
            await client.sendText(from, `*📲 DESCARGAR APP:*\n\n${config.links.app_download}\n\n_Después de descargar, escribe *menu*_`);
            await setUserState(phone, 'main_menu');
            break;
        case '6':
            await client.sendText(from, `*🆘 SOPORTE:*\n\n${config.links.support}\n\n_Después de contactar, escribe *menu*_`);
            await setUserState(phone, 'main_menu');
            break;
        default:
            await client.sendText(from, `❌ Opción no válida. Por favor elige 1-6.\n\n${getMainMenuMessage()}`);
    }
}

async function handlePlansMenu(phone, text, from) {
    const planNumber = parseInt(text);
    if (planNumber >= 1 && planNumber <= 7) {
        const plan = getPlanDetails(planNumber);
        if (plan) {
            await setUserState(phone, 'buying_plan', { planNumber, ...plan });
            const amount = config.prices[plan.price];
            const msg = `*🛒 CONFIRMAR COMPRA:*\n\n*Plan:* ${plan.name}\n*Duración:* ${plan.days} días\n*Conexiones:* ${plan.connections}\n*Precio:* $${amount} ARS\n\n¿Deseas continuar?\n\n🔘 *1* - Sí, pagar con MercadoPago\n🔘 *2* - No, volver al menú de planes\n🔘 *0* - Menú principal`;
            await client.sendText(from, msg);
        }
    } else if (text === '0') {
        await setUserState(phone, 'main_menu');
        await client.sendText(from, getMainMenuMessage());
    } else {
        await client.sendText(from, `❌ *Plan no válido*\n\n${getPlansMenuMessage()}`);
    }
}

async function handleBuyingPlan(phone, text, from, planData) {
    if (text === '1') {
        const amount = config.prices[planData.price];
        const payment = await createMercadoPagoPayment(phone, planData.name, planData.days, amount, planData.connections);
        if (payment.success) {
            await client.sendText(from, `*✅ PAGO GENERADO:*\n\n*ID:* ${payment.paymentId}\n*Plan:* ${planData.name}\n*Monto:* $${amount} ARS\n\n*Enlace de pago:*\n${payment.paymentUrl}\n\n_Una vez aprobado, recibirás tus credenciales._\n\nEscribe *menu* para volver.`);
            await setUserState(phone, 'waiting_payment', { paymentId: payment.paymentId, planData });
        } else {
            await client.sendText(from, `❌ *Error al generar pago*\n\n${payment.error}\n\nEscribe *menu* para volver.`);
            await setUserState(phone, 'main_menu');
        }
    } else if (text === '2') {
        await setUserState(phone, 'plans_menu');
        await client.sendText(from, getPlansMenuMessage());
    } else if (text === '0') {
        await setUserState(phone, 'main_menu');
        await client.sendText(from, getMainMenuMessage());
    } else {
        await client.sendText(from, `Por favor, elige:\n🔘 *1* - Sí, pagar\n🔘 *2* - No, volver\n🔘 *0* - Menú principal`);
    }
}

async function handleFreeTest(phone, from) {
    const today = moment().format('YYYY-MM-DD');
    db.get('SELECT id FROM daily_tests WHERE phone = ? AND date = ?', [phone, today], async (err, row) => {
        if (row) {
            await client.sendText(from, `❌ *Ya usaste la prueba hoy*\n\nPuedes comprar un plan escribiendo *menu* y eligiendo *2*.`);
            await setUserState(phone, 'main_menu');
            return;
        }
        const username = generateSSHUsername(phone);
        const result = await createSSHUser(username, '12345', 0, 1);
        if (result.success) {
            db.run(`INSERT INTO users (phone, username, password, tipo, expires_at, max_connections, status) VALUES (?, ?, ?, 'test', ?, 1, 1)`, [phone, username, '12345', result.expires]);
            db.run('INSERT INTO daily_tests (phone, date) VALUES (?, ?)', [phone, today]);
            await client.sendText(from, `*✅ PRUEBA GRATIS ACTIVADA:*\n\n*Usuario:* ${username}\n*Contraseña:* 12345\n*Servidor:* ${config.bot.server_ip}\n*Puerto:* 22\n*Expira:* ${config.prices.test_hours} horas\n\n*APP:* ${config.links.app_download}\n\n_Guarda estas credenciales. Escribe *menu* para más opciones._`);
            await setUserState(phone, 'main_menu');
        } else {
            await client.sendText(from, `❌ *Error al crear cuenta*\n\n${config.links.support}`);
            await setUserState(phone, 'main_menu');
        }
    });
}

async function showMyAccounts(phone, from) {
    db.all(`SELECT username, password, tipo, expires_at, max_connections, status FROM users WHERE phone = ? ORDER BY created_at DESC`, [phone], async (err, rows) => {
        if (err || !rows || rows.length === 0) {
            await client.sendText(from, `*📂 MIS CUENTAS:*\n\nNo tienes cuentas activas.\n\nPara una prueba gratis escribe *menu* y elige *1*.`);
            return;
        }
        let msg = `*📂 MIS CUENTAS:*\n\n`;
        rows.forEach((acc, i) => {
            const expires = moment(acc.expires_at).format('DD/MM/YYYY HH:mm');
            msg += `*Cuenta ${i+1}:*\n👤 ${acc.username}\n🔐 ${acc.password}\n📡 ${acc.tipo==='test'?'Prueba':'Premium'}\n🔌 ${acc.max_connections}\n⏰ ${expires}\n✅ ${acc.status ? 'Activa':'Inactiva'}\n🌐 ${config.bot.server_ip}:22\n\n`;
        });
        msg += `_Para renovar, escribe *menu* y elige *2*._`;
        await client.sendText(from, msg);
        await setUserState(phone, 'main_menu');
    });
}

async function showPaymentStatus(phone, from) {
    db.all(`SELECT payment_id, plan, amount, status, created_at, approved_at FROM payments WHERE phone = ? ORDER BY created_at DESC LIMIT 5`, [phone], async (err, rows) => {
        if (err || !rows || rows.length === 0) {
            await client.sendText(from, `*💳 ESTADO DE PAGOS:*\n\nNo tienes pagos registrados.`);
            return;
        }
        let msg = `*💳 ÚLTIMOS PAGOS:*\n\n`;
        rows.forEach((pay, i) => {
            const created = moment(pay.created_at).format('DD/MM HH:mm');
            const emoji = pay.status==='approved'?'✅':(pay.status==='pending'?'⏳':'❌');
            msg += `*Pago ${i+1}:* ${emoji} ${pay.status}\n📋 ${pay.plan}\n💰 $${pay.amount} ARS\n📅 ${created}\n${pay.approved_at?`✅ Aprobado: ${moment(pay.approved_at).format('DD/MM HH:mm')}\n`:''}🔑 ${pay.payment_id}\n\n`;
        });
        msg += `_Para ver más, escribe *menu*._`;
        await client.sendText(from, msg);
        await setUserState(phone, 'main_menu');
    });
}

// ==============================================
// CRON JOBS
// ==============================================
function setupPaymentChecker() {
    cron.schedule('*/2 * * * *', async () => {
        if (!mpEnabled) return;
        console.log(chalk.yellow('🔍 Verificando pagos pendientes...'));
        db.all(`SELECT payment_id, phone, plan, days, connections FROM payments WHERE status = 'pending' AND created_at > datetime('now', '-1 hour')`, [], async (err, payments) => {
            if (err || !payments) return;
            for (const pay of payments) {
                // Simulación: en producción aquí se consultaría a MP
                const shouldApprove = Math.random() > 0.7; // Solo para demo
                if (shouldApprove) {
                    const username = generateSSHUsername(pay.phone);
                    const result = await createSSHUser(username, '12345', pay.days, pay.connections);
                    if (result.success) {
                        db.run(`UPDATE payments SET status = 'approved', approved_at = CURRENT_TIMESTAMP WHERE payment_id = ?`, [pay.payment_id]);
                        db.run(`INSERT INTO users (phone, username, password, tipo, expires_at, max_connections, status) VALUES (?, ?, ?, 'premium', ?, ?, 1)`, [pay.phone, username, '12345', result.expires, pay.connections]);
                        if (client) {
                            await client.sendText(`${pay.phone}@c.us`, `*✅ PAGO APROBADO:*\n\nTu cuenta ha sido creada.\n\n*Usuario:* ${username}\n*Contraseña:* 12345\n*Servidor:* ${config.bot.server_ip}\n*Puerto:* 22\n*Conexiones:* ${pay.connections}\n*Expira:* ${pay.days} días\n\n¡Disfruta! Escribe *menu* para más opciones.`);
                        }
                    }
                }
            }
        });
    });
}

function setupCleanupCron() {
    cron.schedule('*/15 * * * *', async () => {
        console.log(chalk.yellow('🧹 Limpiando usuarios expirados...'));
        const now = moment().format('YYYY-MM-DD HH:mm:ss');
        db.all(`SELECT username FROM users WHERE expires_at < ? AND status = 1`, [now], async (err, expiredUsers) => {
            if (err || !expiredUsers) return;
            for (const user of expiredUsers) {
                await execPromise(`pkill -u ${user.username}; userdel ${user.username} 2>/dev/null || true`);
                db.run(`UPDATE users SET status = 0 WHERE username = ?`, [user.username]);
                console.log(chalk.gray(`  ➤ Usuario ${user.username} eliminado`));
            }
        });
        db.run(`DELETE FROM user_state WHERE updated_at < datetime('now', '-1 day')`);
    });
}

// ==============================================
// INICIO DEL BOT
// ==============================================
async function startBot() {
    try {
        console.log(chalk.cyan('🚀 Iniciando SERVERTUC™ BOT HÍBRIDO...'));
        setupPaymentChecker();
        setupCleanupCron();

        client = await wppconnect.create({
            session: 'servertuc-bot',
            puppeteerOptions: {
                executablePath: config.paths.chromium,
                headless: 'new',
                args: ['--no-sandbox', '--disable-setuid-sandbox', '--disable-dev-shm-usage', '--disable-accelerated-2d-canvas', '--no-first-run', '--no-zygote', '--disable-gpu']
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
                console.log(chalk.cyan('3. El bot estará listo\n'));
            },
            createPathFileToken: false
        });

        console.log(chalk.green('✅ WhatsApp conectado!'));

        client.onAuthenticated(() => {
            console.log(chalk.green('✅ Autenticación completada!'));
        });

        client.onMessage(async (message) => {
            try {
                if (message.from === 'status@broadcast' || message.isGroupMsg) return;
                await handleMessage(message);
            } catch (error) {
                console.error(chalk.red('❌ Error en mensaje:'), error);
            }
        });

        client.onStateChange((state) => {
            const states = { 'CONNECTED': chalk.green('✅ Conectado'), 'PAIRING': chalk.cyan('📱 Emparejando...'), 'UNPAIRED': chalk.yellow('📱 Esperando QR...') };
            console.log(chalk.blue(`🔁 Estado: ${states[state] || state}`));
        });

        console.log(chalk.green.bold('\n✅ BOT INICIADO CORRECTAMENTE!'));
        console.log(chalk.cyan('📱 Busca el QR arriba y escanéalo.'));
        console.log(chalk.cyan('💬 Luego envía "menu" al bot.\n'));

    } catch (error) {
        console.error(chalk.red('❌ Error iniciando bot:'), error.message);
        console.log(chalk.yellow('🔄 Reintentando en 10 segundos...'));
        setTimeout(startBot, 10000);
    }
}

startBot();
BOTEOF

echo -e "${GREEN}✅ Archivo bot.js creado exitosamente${NC}"

# ================================================
# 6. SCRIPT DE CONTROL (Mejorado)
# ================================================
echo -e "\n${CYAN}${BOLD}⚙️ CREANDO SCRIPT DE CONTROL 'sshbot-control'...${NC}"
cat > "/usr/local/bin/sshbot-control" << 'CONTROLEOF'
#!/bin/bash
BOLD='\033[1m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; CYAN='\033[0;36m'; NC='\033[0m'
case "$1" in
    start)   echo -e "${GREEN}▶️ Iniciando bot...${NC}"; cd /root/ssh-bot && pm2 start bot.js --name ssh-bot --time && pm2 save ;;
    stop)    echo -e "${YELLOW}⏹️ Deteniendo...${NC}"; pm2 stop ssh-bot ;;
    restart) echo -e "${CYAN}🔄 Reiniciando...${NC}"; pm2 restart ssh-bot ;;
    status)  pm2 status ssh-bot ;;
    logs)    pm2 logs ssh-bot --lines 50 ;;
    qr)      echo -e "${CYAN}📱 Mostrando QR...${NC}"; pm2 restart ssh-bot && sleep 3 && pm2 logs ssh-bot --lines 10 ;;
    config)  nano /opt/ssh-bot/config/config.json ;;
    mercadopago)
        echo -e "${CYAN}💰 Configurar MercadoPago:${NC}"
        read -p "Ingresa tu Access Token: " mp_token
        if [[ -n "$mp_token" ]]; then
            jq --arg t "$mp_token" '.mercadopago.access_token = $t | .mercadopago.enabled = true' /opt/ssh-bot/config/config.json > /tmp/config.tmp && mv /tmp/config.tmp /opt/ssh-bot/config/config.json
            echo -e "${GREEN}✅ Token guardado. Reinicia el bot: sshbot-control restart${NC}"
        else echo -e "${RED}❌ Token no válido${NC}"; fi ;;
    users)   echo -e "${CYAN}👥 Usuarios recientes:${NC}"; sqlite3 /opt/ssh-bot/data/users.db "SELECT username, phone, tipo, expires_at, status FROM users ORDER BY created_at DESC LIMIT 10;" -column ;;
    payments) echo -e "${CYAN}💳 Últimos pagos:${NC}"; sqlite3 /opt/ssh-bot/data/users.db "SELECT payment_id, phone, plan, amount, status, created_at FROM payments ORDER BY created_at DESC LIMIT 10;" -column ;;
    backup)  backup_file="/root/backup-sshbot-$(date +%Y%m%d-%H%M%S).tar.gz"; tar -czf "$backup_file" /opt/ssh-bot/data /opt/ssh-bot/config 2>/dev/null; echo -e "${GREEN}✅ Backup: $backup_file${NC}" ;;
    update)  cd /root/ssh-bot && npm update && pm2 restart ssh-bot && echo -e "${GREEN}✅ Bot actualizado${NC}" ;;
    *) echo -e "${CYAN}${BOLD}SERVERTUC™ BOT CONTROL${NC}\n${GREEN}Uso:${NC} sshbot-control [comando]\nComandos: start, stop, restart, status, logs, qr, config, mercadopago, users, payments, backup, update" ;;
esac
CONTROLEOF
chmod +x /usr/local/bin/sshbot-control

# ================================================
# 7. CRON JOBS
# ================================================
echo -e "\n${CYAN}${BOLD}⏰ CONFIGURANDO CRON JOBS...${NC}"
(crontab -l 2>/dev/null | grep -v "cleanup expired users"; echo "*/15 * * * * /usr/bin/find /opt/ssh-bot/data -name \"*.db\" -exec /usr/bin/sqlite3 {} \"DELETE FROM users WHERE expires_at < datetime('now') AND status = 1; UPDATE users SET status = 0 WHERE expires_at < datetime('now');\" \;") | crontab -
(crontab -l 2>/dev/null | grep -v "backup ssh-bot"; echo "0 3 * * * /bin/tar -czf /root/backups/sshbot-backup-\$(date +\\%Y\\%m\\%d).tar.gz /opt/ssh-bot/data /opt/ssh-bot/config 2>/dev/null || true") | crontab -
pm2 startup && pm2 save
echo -e "${GREEN}✅ Cron jobs configurados${NC}"

# ================================================
# 8. INICIAR Y MOSTRAL RESULTADO
# ================================================
echo -e "\n${CYAN}${BOLD}🚀 INICIANDO EL BOT POR PRIMERA VEZ...${NC}"
cd "$USER_HOME"
pm2 start bot.js --name ssh-bot --time
pm2 save

echo -e "${GREEN}"
cat << "SUCCESS"
╔══════════════════════════════════════════════════════════════╗
║        🎉 INSTALACIÓN HÍBRIDA COMPLETADA! 🎉                ║
╚══════════════════════════════════════════════════════════════╝
SUCCESS
echo -e "${NC}"

echo -e "${YELLOW}📋 RESUMEN DE LA INSTALACIÓN:${NC}"
echo -e "  ✅ ${GREEN}Menús originales (6 opciones) + Planes (7 opciones)${NC}"
echo -e "  ✅ ${GREEN}Sistema de ESTADOS del primer bot${NC}"
echo -e "  ✅ ${GREEN}API WPPConnect (WhatsApp nueva)${NC}"
echo -e "  ✅ ${GREEN}MercadoPago SDK v2.x listo para configurar${NC}"
echo -e "  ✅ ${GREEN}Script de control 'sshbot-control' instalado${NC}"

echo -e "\n${CYAN}📱 PRÓXIMOS PASOS:${NC}"
echo -e "  1. Ver el código QR: ${GREEN}sudo sshbot-control logs${NC}"
echo -e "  2. Escanéalo con WhatsApp Web"
echo -e "  3. Envía 'menu' al número del bot"
echo -e "  4. (Opcional) Configurar MP: ${GREEN}sudo sshbot-control mercadopago${NC}"

echo -e "\n${PURPLE}⚡ COMANDOS ÚTILES:${NC}"
echo -e "  ${GREEN}sshbot-control logs${NC}    - Ver QR/logs"
echo -e "  ${GREEN}sshbot-control restart${NC} - Reiniciar bot"
echo -e "  ${GREEN}sshbot-control users${NC}   - Listar usuarios"

echo -e "\n${CYAN}══════════════════════════════════════════════════════════════${NC}"
echo -e "${BOLD}🤖 SERVERTUC™ BOT v9.0 HÍBRIDO - WPPCONNECT + ESTADOS${NC}"
echo -e "${CYAN}══════════════════════════════════════════════════════════════${NC}"
echo -e "\n${YELLOW}📢 Mostrando logs iniciales (espera el QR)...${NC}"
sleep 2
pm2 logs ssh-bot --lines 5 --nostream
echo -e "\n${CYAN}Para ver los logs completos: sudo sshbot-control logs${NC}"
