#!/bin/bash
# ================================================
# SERVERTUC™ BOT v9.1 - WPPCONNECT + SISTEMA DE ESTADOS
# CORREGIDO: Error de navegador ya corriendo
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
║    ███████╗███████╗██████╗ ██╗   ██╗██████╗ ████████╗██╗   ██╗║
║    ██╔════╝██╔════╝██╔══██╗██║   ██║██╔══██╗╚══██╔══╝██║   ██║║
║    ███████╗█████╗  ██████╔╝██║   ██║██████╔╝   ██║   ██║   ██║║
║    ╚════██║██╔══╝  ██╔══██╗██║   ██║██╔══██╗   ██║   ██║   ██║║
║    ███████║███████╗██║  ██║╚██████╔╝██║  ██║   ██║   ╚██████╔╝║
║    ╚══════╝╚══════╝╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═╝   ╚═╝    ╚═════╝ ║
╠══════════════════════════════════════════════════════════════╣
║                                                              ║
║                 SERVERTUC™ BOT v9.1 - FIX                    ║
║         ✅ ERROR DE NAVEGADOR CORREGIDO                      ║
║         ✅ SESIONES WPPCONNECT OPTIMIZADAS                   ║
║         ✅ MENÚS ORIGINALES + WPPCONNECT                     ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
BANNER
echo -e "${NC}"

# Verificar root
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}${BOLD}❌ ERROR: Debes ejecutar como root${NC}"
    echo -e "${YELLOW}Usa: sudo bash $0${NC}"
    exit 1
fi

# Detectar IP
echo -e "${CYAN}${BOLD}🔍 DETECTANDO IP DEL SERVIDOR...${NC}"
SERVER_IP=$(curl -4 -s --max-time 10 ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}' || echo "127.0.0.1")
if [[ -z "$SERVER_IP" || "$SERVER_IP" == "127.0.0.1" ]]; then
    echo -e "${RED}❌ No se pudo obtener IP pública${NC}"
    read -p "📝 Ingresa la IP del servidor manualmente: " SERVER_IP
fi
echo -e "${GREEN}✅ IP detectada: ${CYAN}$SERVER_IP${NC}\n"

# Confirmar instalación
echo -e "${YELLOW}⚠️  ESTE INSTALADOR CORREGIDO HARÁ:${NC}"
echo -e "   • Limpieza TOTAL de procesos de Chrome/Chromium"
echo -e "   • Instalación Node.js 18.x + Chrome"
echo -e "   • Bot con menús originales (6 opciones)"
echo -e "   • API WPPConnect optimizada (SIN error de navegador)"
echo -e "   • Sistema de estados del primer bot"
echo -e "   • Contraseña fija: 12345"
echo -e "   • Usuarios terminan en 'j'"
echo -e "\n${RED}⚠️  Se eliminarán TODAS las instalaciones anteriores${NC}"

read -p "$(echo -e "${YELLOW}¿Continuar con la instalación? (s/N): ${NC}")" -n 1 -r
echo
if [[ ! $REPLY =~ ^[Ss]$ ]]; then
    echo -e "${RED}❌ Instalación cancelada${NC}"
    exit 0
fi

# ================================================
# 1. LIMPIEZA PROFUNDA (NUEVO - para evitar el error)
# ================================================
echo -e "\n${CYAN}${BOLD}🧹 LIMPIEZA PROFUNDA DEL SISTEMA...${NC}"

# Matar todos los procesos de Chrome/Chromium
echo -e "${YELLOW}Deteniendo procesos de Chrome/Chromium...${NC}"
pkill -f chrome || true
pkill -f chromium || true
pkill -f "chrome-headless" || true
pkill -f "chromium-headless" || true
pkill -f "google-chrome" || true

# Eliminar PM2 processes
pm2 delete ssh-bot 2>/dev/null || true
pm2 delete servertuc-bot 2>/dev/null || true
pm2 kill 2>/dev/null || true

# Eliminar directorios de sesión
echo -e "${YELLOW}Eliminando directorios de sesión...${NC}"
rm -rf /root/.wppconnect 2>/dev/null || true
rm -rf /root/.config/puppeteer 2>/dev/null || true
rm -rf /root/ssh-bot/tokens 2>/dev/null || true
rm -rf /root/ssh-bot/sessions 2>/dev/null || true
rm -rf /opt/ssh-bot 2>/dev/null || true
rm -rf /root/ssh-bot 2>/dev/null || true

# Limpiar caché de npm
npm cache clean --force 2>/dev/null || true

echo -e "${GREEN}✅ Limpieza completada${NC}"

# ================================================
# 2. INSTALAR DEPENDENCIAS
# ================================================
echo -e "\n${CYAN}${BOLD}📦 INSTALANDO DEPENDENCIAS...${NC}"

# Actualizar sistema
apt-get update -y
apt-get upgrade -y

# Node.js 18.x
echo -e "${YELLOW}📦 Instalando Node.js 18.x...${NC}"
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt-get install -y nodejs gcc g++ make

# Google Chrome
echo -e "${YELLOW}🌐 Instalando Google Chrome...${NC}"
wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | apt-key add -
echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list
apt-get update -y
apt-get install -y google-chrome-stable

# Dependencias del sistema
echo -e "${YELLOW}⚙️ Instalando utilidades...${NC}"
apt-get install -y \
    git curl wget sqlite3 jq \
    build-essential libcairo2-dev libpango1.0-dev \
    libjpeg-dev libgif-dev librsvg2-dev \
    python3 python3-pip ffmpeg unzip \
    cron ufw

# PM2
npm install -g pm2
pm2 update

# Firewall
ufw allow 22/tcp && ufw allow 80/tcp && ufw allow 443/tcp
ufw allow 8001/tcp && ufw allow 3000/tcp
ufw --force enable

echo -e "${GREEN}✅ Dependencias instaladas${NC}"

# ================================================
# 3. PREPARAR ESTRUCTURA
# ================================================
echo -e "\n${CYAN}${BOLD}📁 CREANDO ESTRUCTURA...${NC}"

INSTALL_DIR="/opt/ssh-bot"
USER_HOME="/root/ssh-bot"
DB_FILE="$INSTALL_DIR/data/users.db"
CONFIG_FILE="$INSTALL_DIR/config/config.json"

# Crear directorios (estructura CORREGIDA - sin tokens/)
mkdir -p "$INSTALL_DIR"/{data,config,qr_codes,logs}
mkdir -p "$USER_HOME"
mkdir -p /root/.wppconnect/servertuc-bot
chmod -R 755 "$INSTALL_DIR"
chmod -R 700 /root/.wppconnect

# Crear configuración
cat > "$CONFIG_FILE" << EOF
{
    "bot": {
        "name": "SERVERTUC™ BOT",
        "version": "9.1-FIX-NAVEGADOR",
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
        "sessions": "/root/.wppconnect/servertuc-bot"
    }
}
EOF

# Crear base de datos
sqlite3 "$DB_FILE" << 'SQL'
CREATE TABLE users (id INTEGER PRIMARY KEY AUTOINCREMENT, phone TEXT, username TEXT UNIQUE, password TEXT DEFAULT '12345', tipo TEXT DEFAULT 'test', expires_at DATETIME, max_connections INTEGER DEFAULT 1, status INTEGER DEFAULT 1, created_at DATETIME DEFAULT CURRENT_TIMESTAMP);
CREATE TABLE daily_tests (id INTEGER PRIMARY KEY AUTOINCREMENT, phone TEXT, date DATE, created_at DATETIME DEFAULT CURRENT_TIMESTAMP, UNIQUE(phone, date));
CREATE TABLE payments (id INTEGER PRIMARY KEY AUTOINCREMENT, payment_id TEXT UNIQUE, phone TEXT, plan TEXT, days INTEGER, connections INTEGER DEFAULT 1, amount REAL, status TEXT DEFAULT 'pending', payment_url TEXT, qr_code TEXT, preference_id TEXT, created_at DATETIME DEFAULT CURRENT_TIMESTAMP, approved_at DATETIME);
CREATE TABLE logs (id INTEGER PRIMARY KEY AUTOINCREMENT, type TEXT, message TEXT, data TEXT, created_at DATETIME DEFAULT CURRENT_TIMESTAMP);
CREATE TABLE user_state (phone TEXT PRIMARY KEY, state TEXT DEFAULT 'main_menu', data TEXT, updated_at DATETIME DEFAULT CURRENT_TIMESTAMP);
CREATE INDEX idx_users_phone ON users(phone); CREATE INDEX idx_users_status ON users(status); CREATE INDEX idx_payments_status ON payments(status); CREATE INDEX idx_payments_preference ON payments(preference_id);
SQL

echo -e "${GREEN}✅ Estructura creada${NC}"

# ================================================
# 4. CREAR BOT.JS (VERSIÓN CORREGIDA)
# ================================================
echo -e "\n${CYAN}${BOLD}🤖 CREANDO BOT.JS CORREGIDO...${NC}"
cd "$USER_HOME"

# package.json
cat > package.json << 'PKGEOF'
{
    "name": "servertuc-bot",
    "version": "9.1.0",
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

# bot.js CORREGIDO - con manejo de errores y sin reintento infinito
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
console.log(chalk.cyan.bold('║           SERVERTUC™ BOT v9.1 - VERSIÓN CORREGIDA            ║'));
console.log(chalk.cyan.bold('║          ✅ ERROR DE NAVEGADOR SOLUCIONADO                   ║'));
console.log(chalk.cyan.bold('╚══════════════════════════════════════════════════════════════╝\n'));

// ==============================================
// CARGA DE CONFIGURACIÓN
// ==============================================
function loadConfig() {
    try {
        delete require.cache[require.resolve('/opt/ssh-bot/config/config.json')];
        return require('/opt/ssh-bot/config/config.json');
    } catch (error) {
        console.error(chalk.red('❌ Error cargando configuración:'), error.message);
        process.exit(1);
    }
}
let config = loadConfig();
const db = new sqlite3.Database('/opt/ssh-bot/data/users.db');

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

async function createSSHUser(username, password = '12345', days = 0, maxConnections = 1) {
    try {
        const expiryDate = days > 0 ? moment().add(days, 'days').format('YYYY-MM-DD HH:mm:ss') : moment().add(config.prices.test_hours, 'hours').format('YYYY-MM-DD HH:mm:ss');
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
// FUNCIONES MP
// ==============================================
async function createMercadoPagoPayment(phone, planName, days, amount, connections = 1) {
    if (!mpEnabled) return { success: false, error: 'MercadoPago no configurado' };
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
            external_reference: paymentId,
            auto_return: 'approved'
        };
        const preference = await mpPreference.create({ body: preferenceData });
        const qrPath = path.join(config.paths.qr_codes, `${paymentId}.png`);
        await QRCode.toFile(qrPath, preference.init_point);
        db.run(`INSERT INTO payments (payment_id, phone, plan, days, connections, amount, status, payment_url, qr_code, preference_id) VALUES (?, ?, ?, ?, ?, ?, 'pending', ?, ?, ?)`, [paymentId, phone, planName, days, connections, amount, preference.init_point, qrPath, preference.id]);
        return { success: true, paymentId, paymentUrl: preference.init_point, qrCode: qrPath };
    } catch (error) {
        console.error('Error creando pago MP:', error);
        return { success: false, error: error.message };
    }
}

// ==============================================
// MENSAJES
// ==============================================
function getMainMenuMessage() {
    return `*🤖 SERVERTUC™ BOT v9.1*

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

*1 CONEXIÓN:*
🔸 *1* - 7 días → $${config.prices.price_7d_1conn} ARS
🔸 *2* - 15 días → $${config.prices.price_15d_1conn} ARS
🔸 *3* - 30 días → $${config.prices.price_30d_1conn} ARS
🔸 *7* - 50 días → $${config.prices.price_50d_1conn} ARS

*2 CONEXIONES:*
🔸 *4* - 7 días → $${config.prices.price_7d_2conn} ARS
🔸 *5* - 15 días → $${config.prices.price_15d_2conn} ARS
🔸 *6* - 30 días → $${config.prices.price_30d_2conn} ARS

*Elige el plan (1-7):*
_O escribe 0 para volver_`;
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
            await client.sendText(from, `❌ Opción no válida. Elige 1-6.\n\n${getMainMenuMessage()}`);
    }
}

async function handlePlansMenu(phone, text, from) {
    const planNumber = parseInt(text);
    if (planNumber >= 1 && planNumber <= 7) {
        const plan = getPlanDetails(planNumber);
        if (plan) {
            await setUserState(phone, 'buying_plan', { planNumber, ...plan });
            const amount = config.prices[plan.price];
            const msg = `*🛒 CONFIRMAR COMPRA:*\n\n*Plan:* ${plan.name}\n*Precio:* $${amount} ARS\n\n¿Continuar?\n\n🔘 *1* - Sí\n🔘 *2* - No\n🔘 *0* - Menú principal`;
            await client.sendText(from, msg);
        }
    } else if (text === '0') {
        await setUserState(phone, 'main_menu');
        await client.sendText(from, getMainMenuMessage());
    } else {
        await client.sendText(from, `❌ Plan no válido\n\n${getPlansMenuMessage()}`);
    }
}

async function handleBuyingPlan(phone, text, from, planData) {
    if (text === '1') {
        const amount = config.prices[planData.price];
        const payment = await createMercadoPagoPayment(phone, planData.name, planData.days, amount, planData.connections);
        if (payment.success) {
            await client.sendText(from, `*✅ PAGO GENERADO:*\n\n*Enlace:* ${payment.paymentUrl}\n\n_Tras aprobar, recibirás credenciales._\n\nEscribe *menu* para volver.`);
            await setUserState(phone, 'waiting_payment', { paymentId: payment.paymentId });
        } else {
            await client.sendText(from, `❌ Error: ${payment.error}\n\nEscribe *menu*`);
            await setUserState(phone, 'main_menu');
        }
    } else if (text === '2') {
        await setUserState(phone, 'plans_menu');
        await client.sendText(from, getPlansMenuMessage());
    } else if (text === '0') {
        await setUserState(phone, 'main_menu');
        await client.sendText(from, getMainMenuMessage());
    }
}

async function handleFreeTest(phone, from) {
    const today = moment().format('YYYY-MM-DD');
    db.get('SELECT id FROM daily_tests WHERE phone = ? AND date = ?', [phone, today], async (err, row) => {
        if (row) {
            await client.sendText(from, `❌ Ya usaste la prueba hoy.\nCompra un plan con *menu* → *2*.`);
            await setUserState(phone, 'main_menu');
            return;
        }
        const username = generateSSHUsername(phone);
        const result = await createSSHUser(username, '12345', 0, 1);
        if (result.success) {
            db.run(`INSERT INTO users (phone, username, password, tipo, expires_at) VALUES (?, ?, ?, 'test', ?)`, [phone, username, '12345', result.expires]);
            db.run('INSERT INTO daily_tests (phone, date) VALUES (?, ?)', [phone, today]);
            await client.sendText(from, `*✅ PRUEBA ACTIVADA:*\n\n*Usuario:* ${username}\n*Contraseña:* 12345\n*Servidor:* ${config.bot.server_ip}\n*Expira:* ${config.prices.test_hours} horas\n\n*APP:* ${config.links.app_download}\n\nEscribe *menu* para más opciones.`);
            await setUserState(phone, 'main_menu');
        } else {
            await client.sendText(from, `❌ Error al crear cuenta.\nContacta a soporte: ${config.links.support}`);
            await setUserState(phone, 'main_menu');
        }
    });
}

async function showMyAccounts(phone, from) {
    db.all(`SELECT username, password, tipo, expires_at, status FROM users WHERE phone = ? ORDER BY created_at DESC`, [phone], async (err, rows) => {
        if (err || !rows || rows.length === 0) {
            await client.sendText(from, `*📂 MIS CUENTAS:*\n\nNo tienes cuentas activas.\n\nPrueba gratis: *menu* → *1*`);
            return;
        }
        let msg = `*📂 MIS CUENTAS:*\n\n`;
        rows.forEach((acc, i) => {
            const expires = moment(acc.expires_at).format('DD/MM/YYYY HH:mm');
            msg += `*Cuenta ${i+1}:*\n👤 ${acc.username}\n🔐 ${acc.password}\n📡 ${acc.tipo}\n⏰ ${expires}\n✅ ${acc.status ? 'Activa':'Inactiva'}\n\n`;
        });
        await client.sendText(from, msg);
        await setUserState(phone, 'main_menu');
    });
}

async function showPaymentStatus(phone, from) {
    db.all(`SELECT payment_id, plan, amount, status, created_at FROM payments WHERE phone = ? ORDER BY created_at DESC LIMIT 5`, [phone], async (err, rows) => {
        if (err || !rows || rows.length === 0) {
            await client.sendText(from, `*💳 ESTADO DE PAGOS:*\n\nNo tienes pagos registrados.`);
            return;
        }
        let msg = `*💳 ÚLTIMOS PAGOS:*\n\n`;
        rows.forEach((pay, i) => {
            const created = moment(pay.created_at).format('DD/MM HH:mm');
            const emoji = pay.status === 'approved' ? '✅' : (pay.status === 'pending' ? '⏳' : '❌');
            msg += `*Pago ${i+1}:* ${emoji} ${pay.status}\n📋 ${pay.plan}\n💰 $${pay.amount}\n📅 ${created}\n🔑 ${pay.payment_id}\n\n`;
        });
        await client.sendText(from, msg);
        await setUserState(phone, 'main_menu');
    });
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
                await execPromise(`pkill -u ${user.username}; userdel ${user.username} 2>/dev/null || true`);
                db.run(`UPDATE users SET status = 0 WHERE username = ?`, [user.username]);
                console.log(chalk.gray(`  ➤ Usuario ${user.username} eliminado`));
            }
        });
        db.run(`DELETE FROM user_state WHERE updated_at < datetime('now', '-1 day')`);
    });
}

// ==============================================
// INICIO DEL BOT (VERSIÓN CORREGIDA - SIN REINTENTOS INFINITOS)
// ==============================================
let client = null;
let iniciando = false;

async function startBot() {
    if (iniciando) {
        console.log(chalk.yellow('⚠️ Ya hay una instancia iniciándose...'));
        return;
    }
    iniciando = true;
    
    try {
        console.log(chalk.cyan('🚀 Iniciando SERVERTUC™ BOT v9.1...'));
        
        // Verificar que Chrome existe
        const chromePath = config.paths.chromium;
        if (!fs.existsSync(chromePath)) {
            console.error(chalk.red(`❌ Chrome no encontrado en: ${chromePath}`));
            process.exit(1);
        }
        
        // Asegurar que el directorio de sesión existe y está vacío
        const sessionDir = config.paths.sessions;
        if (fs.existsSync(sessionDir)) {
            // No eliminar, solo asegurar permisos
            fs.chmodSync(sessionDir, 0o700);
        } else {
            fs.mkdirSync(sessionDir, { recursive: true, mode: 0o700 });
        }
        
        // Configurar cron
        setupCleanupCron();
        
        // Iniciar WPPConnect
        client = await wppconnect.create({
            session: 'servertuc-bot',
            folderNameToken: sessionDir,  // Usar el directorio correcto
            puppeteerOptions: {
                executablePath: chromePath,
                headless: 'new',
                args: [
                    '--no-sandbox',
                    '--disable-setuid-sandbox',
                    '--disable-dev-shm-usage',
                    '--disable-accelerated-2d-canvas',
                    '--no-first-run',
                    '--no-zygote',
                    '--disable-gpu',
                    '--disable-web-security',
                    '--disable-features=IsolateOrigins,site-per-process',
                    '--window-size=1024,768'
                ]
            },
            disableWelcome: true,
            updatesLog: false,
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
                console.log(chalk.yellow('══════════════════════════════════════════════════'));
                
                // Guardar QR como imagen
                const qrImagePath = `/opt/ssh-bot/qr_codes/qr-${Date.now()}.png`;
                QRCode.toFile(qrImagePath, base64Qr, { width: 300 }, (err) => {
                    if (!err) console.log(chalk.green(`✅ QR guardado en: ${qrImagePath}`));
                });
            },
            createPathFileToken: false
        });
        
        console.log(chalk.green('✅ WhatsApp conectado exitosamente!'));
        
        client.onAuthenticated(() => {
            console.log(chalk.green('✅ Autenticación completada!'));
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
        
        client.onStateChange((state) => {
            const states = {
                'CONNECTED': chalk.green('✅ Conectado'),
                'PAIRING': chalk.cyan('📱 Emparejando...'),
                'UNPAIRED': chalk.yellow('📱 Esperando QR...')
            };
            console.log(chalk.blue(`🔁 Estado: ${states[state] || state}`));
        });
        
        console.log(chalk.green.bold('\n✅ BOT INICIADO CORRECTAMENTE!'));
        console.log(chalk.cyan('📱 Busca el QR arriba y escanéalo.'));
        console.log(chalk.cyan('💬 Luego envía "menu" al bot.\n'));
        
        iniciando = false;
        
    } catch (error) {
        console.error(chalk.red('❌ Error iniciando bot:'), error.message);
        console.error(chalk.red('Detalles:'), error.stack);
        
        // Limpiar posible proceso zombie
        try {
            await execPromise('pkill -f chrome');
            await execPromise('pkill -f chromium');
        } catch (e) {}
        
        console.log(chalk.yellow('\n⚠️  El bot no pudo iniciar.'));
        console.log(chalk.yellow('Posibles soluciones:'));
        console.log(chalk.yellow('1. Ejecuta: sudo sshbot-control restart'));
        console.log(chalk.yellow('2. Si persiste: sudo rm -rf /root/.wppconnect/servertuc-bot'));
        console.log(chalk.yellow('3. Luego: sudo sshbot-control start\n'));
        
        iniciando = false;
        process.exit(1);
    }
}

// Iniciar (solo una vez)
startBot();
BOTEOF

echo -e "${GREEN}✅ Bot.js corregido creado${NC}"

# ================================================
# 5. SCRIPT DE CONTROL
# ================================================
echo -e "\n${CYAN}${BOLD}⚙️ CREANDO SCRIPT DE CONTROL...${NC}"
cat > "/usr/local/bin/sshbot-control" << 'CONTROLEOF'
#!/bin/bash
BOLD='\033[1m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; CYAN='\033[0;36m'; NC='\033[0m'

case "$1" in
    start)
        echo -e "${GREEN}▶️ Iniciando bot...${NC}"
        cd /root/ssh-bot
        pm2 start bot.js --name ssh-bot --time
        pm2 save
        ;;
    stop)
        echo -e "${YELLOW}⏹️ Deteniendo...${NC}"
        pm2 stop ssh-bot
        pkill -f chrome 2>/dev/null || true
        ;;
    restart)
        echo -e "${CYAN}🔄 Reiniciando...${NC}"
        pm2 stop ssh-bot
        pkill -f chrome 2>/dev/null || true
        sleep 2
        cd /root/ssh-bot
        pm2 start bot.js --name ssh-bot --time
        pm2 save
        ;;
    status)
        pm2 status ssh-bot
        ;;
    logs)
        pm2 logs ssh-bot --lines 50
        ;;
    qr)
        echo -e "${CYAN}📱 Mostrando QR...${NC}"
        pm2 restart ssh-bot
        sleep 3
        pm2 logs ssh-bot --lines 10
        ;;
    clean)
        echo -e "${YELLOW}🧹 Limpiando sesión...${NC}"
        pm2 stop ssh-bot
        pkill -f chrome
        pkill -f chromium
        rm -rf /root/.wppconnect/servertuc-bot/*
        echo -e "${GREEN}✅ Sesión limpiada. Reinicia con: sshbot-control restart${NC}"
        ;;
    config)
        nano /opt/ssh-bot/config/config.json
        ;;
    mercadopago)
        echo -e "${CYAN}💰 Configurar MercadoPago:${NC}"
        read -p "Ingresa tu Access Token: " mp_token
        if [[ -n "$mp_token" ]]; then
            jq --arg t "$mp_token" '.mercadopago.access_token = $t | .mercadopago.enabled = true' /opt/ssh-bot/config/config.json > /tmp/config.tmp && mv /tmp/config.tmp /opt/ssh-bot/config/config.json
            echo -e "${GREEN}✅ Token guardado.${NC}"
            echo -e "${YELLOW}Reinicia el bot: sshbot-control restart${NC}"
        else
            echo -e "${RED}❌ Token no válido${NC}"
        fi
        ;;
    users)
        echo -e "${CYAN}👥 Usuarios recientes:${NC}"
        sqlite3 /opt/ssh-bot/data/users.db "SELECT username, phone, tipo, expires_at, status FROM users ORDER BY created_at DESC LIMIT 10;" -column
        ;;
    payments)
        echo -e "${CYAN}💳 Últimos pagos:${NC}"
        sqlite3 /opt/ssh-bot/data/users.db "SELECT payment_id, phone, plan, amount, status, created_at FROM payments ORDER BY created_at DESC LIMIT 10;" -column
        ;;
    backup)
        mkdir -p /root/backups
        backup_file="/root/backups/sshbot-$(date +%Y%m%d-%H%M%S).tar.gz"
        tar -czf "$backup_file" /opt/ssh-bot/data /opt/ssh-bot/config 2>/dev/null
        echo -e "${GREEN}✅ Backup: $backup_file${NC}"
        ;;
    fix)
        echo -e "${YELLOW}🔧 Aplicando fix de navegador...${NC}"
        pm2 stop ssh-bot
        pkill -f chrome
        pkill -f chromium
        rm -rf /root/.wppconnect/servertuc-bot
        mkdir -p /root/.wppconnect/servertuc-bot
        chmod 700 /root/.wppconnect/servertuc-bot
        echo -e "${GREEN}✅ Fix aplicado. Reinicia con: sshbot-control restart${NC}"
        ;;
    *)
        echo -e "${CYAN}${BOLD}SERVERTUC™ BOT CONTROL v9.1${NC}"
        echo -e "${GREEN}Uso:${NC} sshbot-control [comando]"
        echo -e ""
        echo -e "${YELLOW}Comandos:${NC}"
        echo -e "  ${GREEN}start${NC}      - Iniciar bot"
        echo -e "  ${GREEN}stop${NC}       - Detener bot"
        echo -e "  ${GREEN}restart${NC}    - Reiniciar bot"
        echo -e "  ${GREEN}status${NC}     - Ver estado"
        echo -e "  ${GREEN}logs${NC}       - Ver logs"
        echo -e "  ${GREEN}qr${NC}         - Mostrar QR"
        echo -e "  ${GREEN}clean${NC}      - Limpiar sesión"
        echo -e "  ${GREEN}fix${NC}        - Fix de navegador"
        echo -e "  ${GREEN}config${NC}     - Editar configuración"
        echo -e "  ${GREEN}mercadopago${NC} - Configurar MP"
        echo -e "  ${GREEN}users${NC}      - Listar usuarios"
        echo -e "  ${GREEN}payments${NC}   - Ver pagos"
        echo -e "  ${GREEN}backup${NC}     - Crear backup"
        ;;
esac
CONTROLEOF

chmod +x /usr/local/bin/sshbot-control

# ================================================
# 6. CONFIGURAR CRON
# ================================================
echo -e "\n${CYAN}${BOLD}⏰ CONFIGURANDO CRON...${NC}"
(crontab -l 2>/dev/null | grep -v "cleanup"; echo "*/15 * * * * /usr/bin/find /opt/ssh-bot/data -name \"*.db\" -exec /usr/bin/sqlite3 {} \"DELETE FROM users WHERE expires_at < datetime('now') AND status = 1; UPDATE users SET status = 0 WHERE expires_at < datetime('now');\" \;") | crontab -
pm2 startup
pm2 save

# ================================================
# 7. INICIAR Y MOSTRAR RESULTADO
# ================================================
echo -e "\n${CYAN}${BOLD}🚀 INICIANDO BOT...${NC}"
cd "$USER_HOME"
pm2 start bot.js --name ssh-bot --time
pm2 save

echo -e "${GREEN}"
cat << "SUCCESS"
╔══════════════════════════════════════════════════════════════╗
║      🎉 INSTALACIÓN COMPLETADA - ERROR CORREGIDO! 🎉        ║
╚══════════════════════════════════════════════════════════════╝
SUCCESS
echo -e "${NC}"

echo -e "${YELLOW}📋 RESUMEN:${NC}"
echo -e "  ✅ ${GREEN}Menús originales (6 opciones)${NC}"
echo -e "  ✅ ${GREEN}Planes: 7 opciones (incluye 50 días)${NC}"
echo -e "  ✅ ${GREEN}Sistema de estados activado${NC}"
echo -e "  ✅ ${GREEN}API WPPConnect (corregida)${NC}"
echo -e "  ✅ ${GREEN}Contraseña fija: 12345${NC}"
echo -e "  ✅ ${GREEN}Usuarios terminan en 'j'${NC}"

echo -e "\n${CYAN}📱 VER QR:${NC}"
echo -e "  ${GREEN}sudo sshbot-control logs${NC}"

echo -e "\n${PURPLE}⚡ COMANDOS ÚTILES:${NC}"
echo -e "  ${GREEN}sshbot-control restart${NC} - Reiniciar"
echo -e "  ${GREEN}sshbot-control fix${NC}      - Si el error persiste"
echo -e "  ${GREEN}sshbot-control clean${NC}    - Limpiar sesión"
echo -e "  ${GREEN}sshbot-control mercadopago${NC} - Configurar MP"

echo -e "\n${YELLOW}📢 Mostrando logs (espera el QR)...${NC}"
sleep 2
pm2 logs ssh-bot --lines 10 --nostream

echo -e "\n${CYAN}══════════════════════════════════════════════════════════════${NC}"
echo -e "${BOLD}✅ ERROR DE NAVEGADOR CORREGIDO - v9.1${NC}"
echo -e "${CYAN}══════════════════════════════════════════════════════════════${NC}"
