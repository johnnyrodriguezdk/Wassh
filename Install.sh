#!/bin/bash
# ================================================
# SSH BOT PRO - MODIFICADO (LIMPIEZA + MENÚ PERSONALIZABLE)
# Basado en: https://github.com/martincho247/ssh-bot
# Mejoras:
#   ✅ Limpieza total inicial (como solicitaste)
#   ✅ Menú principal editable (1=Prueba, 2=Planes, 3=Cuentas, 4=Pagos, 5=APP, 6=Soporte)
#   ✅ Nombre del bot configurable durante instalación
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
║     ███████╗███████╗██║  ██║    ██████╗  ██████╗ ████████╗  ║
║     ██╔════╝██╔════╝██║  ██║    ██╔══██╗██╔═══██╗╚══██╔══╝  ║
║     ███████╗███████╗███████║    ██████╔╝██║   ██║   ██║     ║
║     ╚════██║╚════██║██╔══██║    ██╔══██╗██║   ██║   ██║     ║
║     ███████║███████╗██║  ██║    ██████╔╝╚██████╔╝   ██║     ║
║     ╚══════╝╚══════╝╚═╝  ╚═╝    ╚═════╝  ╚═════╝    ╚═╝     ║
╠══════════════════════════════════════════════════════════════╣
║                                                              ║
║        🤖 SSH BOT PRO - VERSIÓN MEJORADA                    ║
║        ✅ CON LIMPIEZA TOTAL INICIAL                         ║
║        ✅ MENÚ PERSONALIZABLE (6 OPCIONES)                   ║
║        ✅ NOMBRE DEL BOT CONFIGURABLE                        ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
BANNER
echo -e "${NC}"

echo -e "${GREEN}✅ CARACTERÍSTICAS PRINCIPALES:${NC}"
echo -e "  📱 ${CYAN}WPPConnect${NC} - API WhatsApp que funciona"
echo -e "  💰 ${GREEN}MercadoPago SDK v2.x${NC} - Integrado completo"
echo -e "  🎛️  ${PURPLE}Menú personalizado${NC} - 1=Prueba, 2=Planes, 3=Cuentas, 4=Pagos, 5=APP, 6=Soporte"
echo -e "  🧹 ${YELLOW}Limpieza total inicial${NC} - Elimina instalaciones anteriores"
echo -e "${CYAN}══════════════════════════════════════════════════════════════${NC}\n"

# Verificar root
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}❌ Debes ejecutar como root${NC}"
    echo -e "${YELLOW}Usa: sudo bash $0${NC}"
    exit 1
fi

# ================================================
# LIMPIEZA TOTAL INICIAL (Como solicitaste)
# ================================================
echo -e "\n${CYAN}${BOLD}🧹 EJECUTANDO LIMPIEZA TOTAL...${NC}"

# Matar procesos
echo -e "${YELLOW}Deteniendo procesos...${NC}"
pm2 kill 2>/dev/null || true
pkill -f node 2>/dev/null || true
pkill -f chrome 2>/dev/null || true
pkill -f chromium 2>/dev/null || true

# Eliminar directorios de instalaciones anteriores
echo -e "${YELLOW}Eliminando instalaciones anteriores...${NC}"
rm -rf /opt/ssh-bot /root/ssh-bot 2>/dev/null || true
rm -rf /opt/sshbot-pro /root/sshbot-pro 2>/dev/null || true
rm -rf /root/ssh-bot-whatsapp /root/iniciar-bot.sh 2>/dev/null || true
rm -rf /root/SSH-BOT /root/ssh-bot-pro 2>/dev/null || true

# Eliminar sesiones de WhatsApp
echo -e "${YELLOW}Limpiando sesiones de WhatsApp...${NC}"
rm -rf /root/.wppconnect 2>/dev/null || true
rm -rf /root/.wwebjs_auth 2>/dev/null || true
rm -rf /root/.wwebjs_cache 2>/dev/null || true
rm -rf /root/.pm2/logs/* 2>/dev/null || true

echo -e "${GREEN}✅ Limpieza completada${NC}\n"

# ================================================
# CONFIGURACIÓN DEL BOT (NUEVO - Personalizable)
# ================================================
echo -e "${CYAN}${BOLD}⚙️ CONFIGURACIÓN DEL BOT${NC}"

# Nombre del bot
read -p "📝 Nombre para tu bot (ej: MI BOT PRO): " BOT_NAME
BOT_NAME=${BOT_NAME:-"SSH Bot Pro"}

# Contraseña por defecto
read -p "🔐 Contraseña por defecto para usuarios (Enter para '12345'): " DEFAULT_PASS
DEFAULT_PASS=${DEFAULT_PASS:-"12345"}

# Horas de prueba
read -p "⏰ Horas de prueba gratis (Enter para 2): " TEST_HOURS
TEST_HOURS=${TEST_HOURS:-2}

echo -e "\n${GREEN}✅ Configuración guardada${NC}\n"

# Detectar IP
echo -e "${CYAN}🔍 Detectando IP...${NC}"
SERVER_IP=$(curl -4 -s --max-time 10 ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}' || echo "127.0.0.1")
if [[ -z "$SERVER_IP" || "$SERVER_IP" == "127.0.0.1" ]]; then
    read -p "📝 Ingresa la IP del servidor manualmente: " SERVER_IP
fi
echo -e "${GREEN}✅ IP: ${CYAN}$SERVER_IP${NC}\n"

# Confirmar instalación
echo -e "${YELLOW}⚠️  SE INSTALARÁ CON:${NC}"
echo -e "   • Nombre del bot: ${GREEN}$BOT_NAME${NC}"
echo -e "   • Contraseña: ${GREEN}$DEFAULT_PASS${NC}"
echo -e "   • Horas de prueba: ${GREEN}$TEST_HOURS${NC}"
echo -e "   • IP del servidor: ${GREEN}$SERVER_IP${NC}"

read -p "$(echo -e "${YELLOW}¿Continuar instalación? (s/N): ${NC}")" -n 1 -r
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

# Chrome/Chromium
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

INSTALL_DIR="/opt/sshbot-pro"
USER_HOME="/root/sshbot-pro"
DB_FILE="$INSTALL_DIR/data/users.db"
CONFIG_FILE="$INSTALL_DIR/config/config.json"

# Crear directorios
mkdir -p "$INSTALL_DIR"/{data,config,sessions,logs,qr_codes}
mkdir -p "$USER_HOME"
mkdir -p /root/.wppconnect
chmod -R 755 "$INSTALL_DIR"
chmod -R 700 /root/.wppconnect

# Configuración con valores personalizados
cat > "$CONFIG_FILE" << EOF
{
    "bot": {
        "name": "$BOT_NAME",
        "version": "2.1-MENU-PERSONALIZADO",
        "server_ip": "$SERVER_IP",
        "default_password": "$DEFAULT_PASS",
        "test_hours": $TEST_HOURS
    },
    "prices": {
        "test_hours": $TEST_HOURS,
        "price_7d": 3000.00,
        "price_15d": 4000.00,
        "price_30d": 7000.00,
        "price_50d": 9700.00,
        "currency": "ARS"
    },
    "mercadopago": {
        "access_token": "",
        "enabled": false,
        "public_key": ""
    },
    "links": {
        "app_download": "https://www.mediafire.com/file/p8kgthxbsid7xws/MAJ/DNI_AND_FIL",
        "support": "https://wa.me/543435071016"
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
# CREAR BOT.JS CON MENÚ PERSONALIZADO
# ================================================
echo -e "\n${CYAN}🤖 Creando bot.js con menú personalizado...${NC}"

cd "$USER_HOME"

# package.json
cat > package.json << 'PKGEOF'
{
    "name": "sshbot-pro",
    "version": "2.1.0",
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

# bot.js con menú personalizado
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
    delete require.cache[require.resolve('/opt/sshbot-pro/config/config.json')];
    return require('/opt/sshbot-pro/config/config.json');
}

let config = loadConfig();
const db = new sqlite3.Database('/opt/sshbot-pro/data/users.db');

console.log(chalk.cyan.bold('\n╔══════════════════════════════════════════════════════════════╗'));
console.log(chalk.cyan.bold(`║           ${config.bot.name.padEnd(42)}║`));
console.log(chalk.cyan.bold('║              MENÚ PERSONALIZADO (6 OPCIONES)                ║'));
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
    return `user${timestamp}${random}`;
}

async function createSSHUser(username, password, days = 0, maxConnections = 1) {
    try {
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
// MENSAJES (MENÚ PERSONALIZADO)
// ==============================================
function getMainMenuMessage() {
    return `*🤖 ${config.bot.name}*

*MENÚ PRINCIPAL:*
🔹 *1* - Prueba gratis (${config.bot.test_hours} horas)
🔹 *2* - Ver planes y precios
🔹 *3* - Mis cuentas SSH
🔹 *4* - Estado de pago
🔹 *5* - Descargar APP
🔹 *6* - Soporte

*Elige una opción (1-6):*`;
}

function getPlansMenuMessage() {
    return `*📋 PLANES DISPONIBLES:*

🔸 *1* - 7 días → $${config.prices.price_7d} ARS
🔸 *2* - 15 días → $${config.prices.price_15d} ARS
🔸 *3* - 30 días → $${config.prices.price_30d} ARS
🔸 *4* - 50 días → $${config.prices.price_50d} ARS

*Elige el plan (1-4):*
_O escribe 0 para volver_`;
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
    if (planNumber >= 1 && planNumber <= 4) {
        const plan = getPlanDetails(planNumber);
        if (plan) {
            await setUserState(phone, 'buying_plan', { planNumber, ...plan });
            const msg = `*🛒 CONFIRMAR COMPRA:*\n\n*Plan:* ${plan.name}\n*Precio:* $${plan.price} ARS\n\n¿Continuar?\n\n🔘 *1* - Sí\n🔘 *2* - No\n🔘 *0* - Menú principal`;
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
        const payment = await createMercadoPagoPayment(phone, planData.name, planData.days, planData.price);
        if (payment.success) {
            await client.sendText(from, `*✅ PAGO GENERADO:*\n\n*Enlace:* ${payment.paymentUrl}\n\n_Tras aprobar, recibirás credenciales._\n\nEscribe *menu* para volver.`);
            await setUserState(phone, 'waiting_payment', { paymentId: payment.paymentId, planData });
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
        const password = config.bot.default_password;
        const result = await createSSHUser(username, password, 0);
        if (result.success) {
            db.run(`INSERT INTO users (phone, username, password, tipo, expires_at) VALUES (?, ?, ?, 'test', ?)`, [phone, username, password, result.expires]);
            db.run('INSERT INTO daily_tests (phone, date) VALUES (?, ?)', [phone, today]);
            await client.sendText(from, `*✅ PRUEBA ACTIVADA:*\n\n*Usuario:* ${username}\n*Contraseña:* ${password}\n*Servidor:* ${config.bot.server_ip}\n*Expira:* ${config.bot.test_hours} horas\n\n*APP:* ${config.links.app_download}\n\nEscribe *menu* para más opciones.`);
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
        console.log(chalk.cyan(`🚀 Iniciando ${config.bot.name}...`));
        
        const chromePath = config.paths.chromium;
        if (!fs.existsSync(chromePath)) {
            console.error(chalk.red(`❌ Chrome no encontrado`));
            process.exit(1);
        }
        
        setupCleanupCron();
        
        client = await wppconnect.create({
            session: 'sshbot-pro',
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
            }
        });
        
        console.log(chalk.green('✅ WhatsApp conectado exitosamente!'));
        
        client.onStateChange((state) => {
            const states = {
                'CONNECTED': chalk.green('✅ Conectado'),
                'PAIRING': chalk.cyan('📱 Emparejando...'),
                'UNPAIRED': chalk.yellow('📱 Esperando QR...'),
                'DISCONNECTED': chalk.red('❌ Desconectado')
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

echo -e "${GREEN}✅ Bot.js creado con menú personalizado${NC}"

# ================================================
# SCRIPT DE CONTROL
# ================================================
echo -e "\n${CYAN}${BOLD}⚙️ Creando script de control...${NC}"
cat > "/usr/local/bin/sshbot-control" << 'CONTROLEOF'
#!/bin/bash
BOLD='\033[1m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; CYAN='\033[0;36m'; NC='\033[0m'

case "$1" in
    start)
        echo -e "${GREEN}▶️ Iniciando bot...${NC}"
        cd /root/sshbot-pro
        pm2 start bot.js --name sshbot-pro --time
        pm2 save
        ;;
    stop)
        echo -e "${YELLOW}⏹️ Deteniendo...${NC}"
        pm2 stop sshbot-pro
        ;;
    restart)
        echo -e "${CYAN}🔄 Reiniciando...${NC}"
        pm2 restart sshbot-pro
        ;;
    logs)
        pm2 logs sshbot-pro --lines 50
        ;;
    clean)
        echo -e "${YELLOW}🧹 Limpieza rápida...${NC}"
        pm2 stop sshbot-pro 2>/dev/null
        rm -rf /root/.wppconnect/sshbot-pro/*
        echo -e "${GREEN}✅ Sesión limpiada. Reinicia con: sshbot-control restart${NC}"
        ;;
    config)
        nano /opt/sshbot-pro/config/config.json
        ;;
    mercadopago)
        echo -e "${CYAN}💰 Configurar MercadoPago:${NC}"
        read -p "Access Token: " token
        jq --arg t "$token" '.mercadopago.access_token = $t | .mercadopago.enabled = true' /opt/sshbot-pro/config/config.json > /tmp/config.tmp && mv /tmp/config.tmp /opt/sshbot-pro/config/config.json
        echo -e "${GREEN}✅ Token guardado. Reinicia: sshbot-control restart${NC}"
        ;;
    *)
        echo -e "${CYAN}${BOLD}COMANDOS DISPONIBLES:${NC}"
        echo -e "  ${GREEN}start${NC}     - Iniciar bot"
        echo -e "  ${GREEN}stop${NC}      - Detener bot"
        echo -e "  ${GREEN}restart${NC}   - Reiniciar bot"
        echo -e "  ${GREEN}logs${NC}      - Ver logs"
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
echo -e "\n${CYAN}${BOLD}🚀 Iniciando bot...${NC}"
cd "$USER_HOME"
pm2 start bot.js --name sshbot-pro --time
pm2 save

echo -e "${GREEN}"
cat << "SUCCESS"
╔══════════════════════════════════════════════════════════════╗
║     🎉 INSTALACIÓN COMPLETADA CON ÉXITO! 🎉                 ║
╚══════════════════════════════════════════════════════════════╝
SUCCESS
echo -e "${NC}"

echo -e "${YELLOW}📋 CONFIGURACIÓN:${NC}"
echo -e "  📝 Nombre del bot: ${GREEN}$BOT_NAME${NC}"
echo -e "  🔐 Contraseña: ${GREEN}$DEFAULT_PASS${NC}"
echo -e "  ⏰ Prueba gratis: ${GREEN}$TEST_HOURS horas${NC}"
echo -e "  🌐 IP Servidor: ${GREEN}$SERVER_IP${NC}"

echo -e "\n${CYAN}📱 VER QR AHORA:${NC}"
echo -e "  ${GREEN}sshbot-control logs${NC}"

echo -e "\n${PURPLE}⚡ COMANDOS ÚTILES:${NC}"
echo -e "  ${GREEN}sshbot-control logs${NC}   - Ver QR"
echo -e "  ${GREEN}sshbot-control restart${NC} - Reiniciar"
echo -e "  ${GREEN}sshbot-control mercadopago${NC} - Configurar pagos"

echo -e "\n${YELLOW}📢 MOSTRANDO LOGS (ESPERA EL QR)...${NC}"
sleep 2
pm2 logs sshbot-pro --lines 15 --nostream
