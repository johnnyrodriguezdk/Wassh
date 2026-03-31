#!/bin/bash
# ================================================
# SSH BOT PRO REVENDEDORES - CON HWID
# MODIFICADO: Creación de usuarios con NOMBRE + HWID
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

clear
echo -e "${CYAN}${BOLD}"
cat << "BANNER"
╔══════════════════════════════════════════════════════════════════╗
║                                                              ║
║     ███████╗███████╗██╗  ██╗    ██████╗  ██████╗ ████████╗  ║
║     ██╔════╝██╔════╝██║  ██║    ██╔══██╗██╔═══██╗╚══██╔══╝  ║
║     ███████╗███████╗███████║    ██████╔╝██║   ██║   ██║     ║
║     ╚════██║╚════██║██╔══██║    ██╔══██╗██║   ██║   ██║     ║
║     ███████║███████║██║  ██║    ██████╔╝╚██████╔╝   ██║     ║
║     ╚══════╝╚══════╝╚═╝  ╚═╝    ╚═════╝  ╚═════╝    ╚═╝     ║
║                                                              ║
║          🤖 SSH BOT PRO - SISTEMA DE REVENDEDORES          ║
║               🔐 CADA REVENDEDOR CON SU CLAVE              ║
║               💰 PANEL ADMINISTRADOR COMPLETO              ║
║               📊 CONTROL DE COMISIONES Y VENTAS            ║
║               🎛️  REVENDEDORES CREAN USUARIOS SSH + HWID    ║
║                                                              ║
╚══════════════════════════════════════════════════════════════════╝
BANNER
echo -e "${NC}"

echo -e "${GREEN}✅ CARACTERÍSTICAS DEL SISTEMA DE REVENDEDORES:${NC}"
echo -e "  🔐 ${CYAN}Cada revendedor${NC} - Contraseña única personalizada"
echo -e "  💰 ${GREEN}Comisiones${NC} - Control de ventas por revendedor"
echo -e "  📊 ${YELLOW}Estadísticas${NC} - Ventas y usuarios por revendedor"
echo -e "  🎛️  ${PURPLE}Panel Admin${NC} - Crear y gestionar revendedores"
echo -e "  👥 ${BLUE}Panel Revendedor${NC} - Crear usuarios con NOMBRE + HWID"
echo -e "  🔑 ${CYAN}Contraseña fija${NC} - mgvpn247 para todos los usuarios"
echo -e "  🆔 ${CYAN}HWID${NC} - Formato AR-E2Q2 (obligatorio para cada cliente)"
echo -e "${CYAN}══════════════════════════════════════════════════════════════════${NC}\n"

# Verificar root
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}❌ Debes ejecutar como root${NC}"
    echo -e "${YELLOW}Usa: sudo bash $0${NC}"
    exit 1
fi

# Detectar IP
echo -e "${CYAN}🔍 Detectando IP...${NC}"
SERVER_IP=$(curl -4 -s --max-time 10 ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}' || echo "127.0.0.1")
if [[ -z "$SERVER_IP" || "$SERVER_IP" == "127.0.0.1" ]]; then
    read -p "📝 Ingresa la IP del servidor: " SERVER_IP
fi

echo -e "${GREEN}✅ IP: ${CYAN}$SERVER_IP${NC}\n"

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
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt-get install -y nodejs gcc g++ make

# Chrome/Chromium
wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | apt-key add -
echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list
apt-get update -y
apt-get install -y google-chrome-stable

# Dependencias del sistema
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
APK_PATH="/root/mgvpn.apk"

# Limpiar anterior
pm2 delete sshbot-pro 2>/dev/null || true
rm -rf "$INSTALL_DIR" "$USER_HOME" 2>/dev/null || true
rm -rf /root/.wppconnect 2>/dev/null || true

# Crear directorios
mkdir -p "$INSTALL_DIR"/{data,config,sessions,logs,qr_codes}
mkdir -p "$USER_HOME"
mkdir -p /root/.wppconnect
chmod -R 755 "$INSTALL_DIR"
chmod -R 700 /root/.wppconnect

cat > "$CONFIG_FILE" << EOF
{
    "bot": {
        "name": "SSH Bot Pro Revendedores con HWID",
        "version": "3.0-HWID",
        "server_ip": "$SERVER_IP",
        "default_password": "mgvpn247"
    },
    "prices": {
        "test_hours": 2,
        "price_7d": 3000.00,
        "price_15d": 4000.00,
        "price_30d": 7000.00,
        "price_50d": 10000.00,
        "currency": "ARS"
    },
    "commission": {
        "type": "percentage",
        "value": 20
    },
    "mercadopago": {
        "access_token": "",
        "enabled": false,
        "public_key": ""
    },
    "paths": {
        "database": "$DB_FILE",
        "qr_codes": "$INSTALL_DIR/qr_codes",
        "sessions": "/root/.wppconnect",
        "apk_file": "$APK_PATH"
    }
}
EOF

# Crear base de datos COMPLETA con columna hwid en users
sqlite3 "$DB_FILE" << 'SQL'
CREATE TABLE users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    phone TEXT,
    username TEXT UNIQUE,
    hwid TEXT UNIQUE,
    password TEXT DEFAULT 'mgvpn247',
    tipo TEXT DEFAULT 'test',
    expires_at DATETIME,
    status INTEGER DEFAULT 1,
    created_by TEXT,
    reseller_id INTEGER,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE resellers (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    username TEXT UNIQUE,
    password TEXT,
    name TEXT,
    phone TEXT,
    commission_type TEXT DEFAULT 'percentage',
    commission_value REAL DEFAULT 20,
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
    reseller_id INTEGER,
    commission REAL,
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
CREATE INDEX idx_users_reseller ON users(reseller_id);
CREATE INDEX idx_payments_status ON payments(status);
CREATE INDEX idx_payments_reseller ON payments(reseller_id);
SQL

echo -e "${GREEN}✅ Estructura creada con sistema de revendedores y HWID${NC}"

# Crear usuario admin por defecto
ADMIN_PASS="admin123"
sqlite3 "$DB_FILE" << SQL
INSERT OR REPLACE INTO resellers (username, password, name, phone, commission_type, commission_value, status) 
VALUES ('admin', '$ADMIN_PASS', 'Administrador', '0000000000', 'percentage', 0, 1);
SQL

echo -e "${GREEN}✅ Admin creado: usuario 'admin', contraseña '$ADMIN_PASS'${NC}"

# ================================================
# CREAR BOT COMPLETO CON REVENDEDORES Y HWID
# ================================================
echo -e "\n${CYAN}🤖 Creando bot con sistema de revendedores y HWID...${NC}"

cd "$USER_HOME"

# package.json
cat > package.json << 'PKGEOF'
{
    "name": "sshbot-pro",
    "version": "3.0.0",
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

# Crear bot.js con HWID
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

console.log(chalk.cyan.bold('\n╔══════════════════════════════════════════════════════════════════╗'));
console.log(chalk.cyan.bold('║      🤖 SSH BOT PRO - SISTEMA DE REVENDEDORES CON HWID     ║'));
console.log(chalk.cyan.bold('║              🔐 CADA REVENDEDOR CON SU CLAVE                ║'));
console.log(chalk.cyan.bold('║                    📊 CONTROL DE VENTAS + HWID              ║'));
console.log(chalk.cyan.bold('╚══════════════════════════════════════════════════════════════════╝\n'));

function loadConfig() {
    delete require.cache[require.resolve('/opt/sshbot-pro/config/config.json')];
    return require('/opt/sshbot-pro/config/config.json');
}

let config = loadConfig();
const db = new sqlite3.Database('/opt/sshbot-pro/data/users.db');

// Variables globales
let client = null;

// Función para validar HWID (formato AR-E2Q2)
function isValidHWID(hwid) {
    return /^[A-Z]{2}-[A-Z0-9]{4}$/.test(hwid);
}

// Función para crear usuario SSH (ahora con username personalizado y HWID)
async function createSSHUser(phone, username, hwid, days, resellerId = null) {
    const password = config.bot.default_password || 'mgvpn247';
    
    // Verificar si el username ya existe
    const userExists = await new Promise((resolve) => {
        db.get('SELECT id FROM users WHERE username = ?', [username], (err, row) => {
            resolve(!err && row);
        });
    });
    if (userExists) {
        return { success: false, error: 'El nombre de usuario ya existe' };
    }
    
    // Verificar si el HWID ya está registrado
    const hwidExists = await new Promise((resolve) => {
        db.get('SELECT id FROM users WHERE hwid = ?', [hwid], (err, row) => {
            resolve(!err && row);
        });
    });
    if (hwidExists) {
        return { success: false, error: 'El HWID ya está registrado' };
    }
    
    if (days === 0) {
        const expireFull = moment().add(config.prices.test_hours, 'hours').format('YYYY-MM-DD HH:mm:ss');
        
        try {
            await execPromise(`useradd -m -s /bin/bash ${username} && echo "${username}:${password}" | chpasswd`);
            
            db.run(`INSERT INTO users (phone, username, hwid, password, tipo, expires_at, created_by, reseller_id) VALUES (?, ?, ?, ?, 'test', ?, ?, ?)`,
                [phone, username, hwid, password, expireFull, 'test', resellerId]);
            
            return { success: true, username, password, hwid, expires: expireFull };
        } catch (error) {
            console.error(chalk.red('❌ Error:'), error.message);
            return { success: false, error: error.message };
        }
    } else {
        const expireFull = moment().add(days, 'days').format('YYYY-MM-DD 23:59:59');
        
        try {
            await execPromise(`useradd -M -s /bin/false -e ${moment().add(days, 'days').format('YYYY-MM-DD')} ${username} && echo "${username}:${password}" | chpasswd`);
            
            db.run(`INSERT INTO users (phone, username, hwid, password, tipo, expires_at, created_by, reseller_id) VALUES (?, ?, ?, ?, 'premium', ?, ?, ?)`,
                [phone, username, hwid, password, expireFull, 'premium', resellerId]);
            
            return { success: true, username, password, hwid, expires: expireFull };
        } catch (error) {
            console.error(chalk.red('❌ Error:'), error.message);
            return { success: false, error: error.message };
        }
    }
}

function canCreateTest(phone) {
    return new Promise((resolve) => {
        const today = moment().format('YYYY-MM-DD');
        db.get('SELECT COUNT(*) as count FROM daily_tests WHERE phone = ? AND date = ?', [phone, today],
            (err, row) => resolve(!err && row && row.count === 0));
    });
}

function registerTest(phone) {
    db.run('INSERT OR IGNORE INTO daily_tests (phone, date) VALUES (?, ?)', [phone, moment().format('YYYY-MM-DD')]);
}

async function sendAppFile(to) {
    const apkPath = '/root/mgvpn.apk';
    
    if (!fs.existsSync(apkPath)) {
        console.log(chalk.yellow(`⚠️ Archivo APK no encontrado`));
        return false;
    }
    
    try {
        await client.sendFile(
            to,
            apkPath,
            'mgvpn.apk',
            '📲 *APP MGVPN*\n\nDescarga nuestra aplicación oficial.\n\n*Credenciales por defecto:*\nUsuario: (el que te proporcionamos)\nContraseña: mgvpn247\nHWID: (el que te asignaron)'
        );
        return true;
    } catch (error) {
        console.error(chalk.red(`❌ Error enviando APK: ${error.message}`));
        return false;
    }
}

function authenticateReseller(username, password) {
    return new Promise((resolve) => {
        db.get('SELECT id, username, name, commission_type, commission_value, status FROM resellers WHERE username = ? AND password = ? AND status = 1',
            [username, password], (err, row) => {
                resolve(err ? null : row);
            });
    });
}

async function getUserState(phone) {
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
            (err) => {
                if (err) console.error(chalk.red('❌ Error estado:'), err.message);
                resolve();
            }
        );
    });
}

function clearUserState(phone) {
    db.run('DELETE FROM user_state WHERE phone = ?', [phone]);
}

async function getResellerStats(resellerId) {
    return new Promise((resolve) => {
        db.get(`
            SELECT 
                COUNT(DISTINCT u.id) as total_users,
                COUNT(CASE WHEN u.status = 1 THEN 1 END) as active_users,
                COUNT(CASE WHEN u.tipo = 'test' THEN 1 END) as test_users,
                COUNT(CASE WHEN u.tipo = 'premium' THEN 1 END) as premium_users,
                COUNT(p.id) as total_sales,
                COALESCE(SUM(p.amount), 0) as total_income,
                COALESCE(SUM(p.commission), 0) as total_commission
            FROM users u
            LEFT JOIN payments p ON u.reseller_id = p.reseller_id AND p.status = 'approved'
            WHERE u.reseller_id = ?
        `, [resellerId], (err, row) => {
            resolve(row || { total_users: 0, active_users: 0, test_users: 0, premium_users: 0, total_sales: 0, total_income: 0, total_commission: 0 });
        });
    });
}

async function getResellerUsers(resellerId, limit = 20) {
    return new Promise((resolve) => {
        db.all(`
            SELECT username, hwid, phone, tipo, expires_at, status, created_at 
            FROM users 
            WHERE reseller_id = ? 
            ORDER BY created_at DESC 
            LIMIT ?
        `, [resellerId, limit], (err, rows) => {
            resolve(rows || []);
        });
    });
}

async function createResellerUser(username, password, name, phone, commissionType = 'percentage', commissionValue = 20) {
    return new Promise((resolve) => {
        db.run(`
            INSERT INTO resellers (username, password, name, phone, commission_type, commission_value, status)
            VALUES (?, ?, ?, ?, ?, ?, 1)
        `, [username, password, name, phone, commissionType, commissionValue], function(err) {
            if (err) {
                resolve({ success: false, error: err.message });
            } else {
                resolve({ success: true, id: this.lastID });
            }
        });
    });
}

async function getAllResellers() {
    return new Promise((resolve) => {
        db.all(`
            SELECT r.id, r.username, r.name, r.phone, r.commission_type, r.commission_value, r.status, r.created_at,
                   COUNT(u.id) as total_users,
                   COUNT(CASE WHEN u.status = 1 THEN 1 END) as active_users
            FROM resellers r
            LEFT JOIN users u ON r.id = u.reseller_id
            WHERE r.username != 'admin'
            GROUP BY r.id
            ORDER BY r.created_at DESC
        `, [], (err, rows) => {
            resolve(rows || []);
        });
    });
}

async function getAdminStats() {
    return new Promise((resolve) => {
        db.get(`
            SELECT 
                COUNT(DISTINCT u.id) as total_users,
                COUNT(CASE WHEN u.status = 1 THEN 1 END) as active_users,
                COUNT(DISTINCT r.id) as total_resellers,
                COUNT(CASE WHEN r.status = 1 THEN 1 END) as active_resellers,
                COUNT(p.id) as total_sales,
                COALESCE(SUM(p.amount), 0) as total_income
            FROM users u
            LEFT JOIN resellers r ON 1=1
            LEFT JOIN payments p ON p.status = 'approved'
        `, [], (err, row) => {
            resolve(row || { total_users: 0, active_users: 0, total_resellers: 0, active_resellers: 0, total_sales: 0, total_income: 0 });
        });
    });
}

// Inicializar WPPConnect
async function initializeBot() {
    try {
        console.log(chalk.yellow('🚀 Inicializando WPPConnect...'));
        
        client = await wppconnect.create({
            session: 'sshbot-pro-session',
            headless: true,
            devtools: false,
            useChrome: true,
            debug: false,
            logQR: true,
            browserWS: '',
            browserArgs: [
                '--no-sandbox',
                '--disable-setuid-sandbox',
                '--disable-dev-shm-usage',
                '--disable-accelerated-2d-canvas',
                '--no-first-run',
                '--no-zygote',
                '--disable-gpu',
                '--disable-background-timer-throttling',
                '--disable-backgrounding-occluded-windows',
                '--disable-renderer-backgrounding',
                '--disable-features=site-per-process',
                '--window-size=1920,1080'
            ],
            puppeteerOptions: {
                executablePath: '/usr/bin/google-chrome',
                headless: 'new',
                args: [
                    '--no-sandbox',
                    '--disable-setuid-sandbox',
                    '--disable-dev-shm-usage'
                ]
            },
            disableWelcome: true,
            updatesLog: false,
            autoClose: 0,
            tokenStore: 'file',
            folderNameToken: '/root/.wppconnect'
        });
        
        console.log(chalk.green('✅ WPPConnect conectado!'));
        
        client.onStateChange((state) => {
            console.log(chalk.cyan(`📱 Estado: ${state}`));
            
            if (state === 'DISCONNECTED') {
                console.log(chalk.yellow('⚠️ Desconectado, reconectando...'));
                setTimeout(initializeBot, 10000);
            }
        });
        
        // Manejar mensajes
        client.onMessage(async (message) => {
            try {
                const text = message.body.trim();
                const from = message.from;
                
                console.log(chalk.cyan(`📩 [${from}]: ${text.substring(0, 30)}`));
                
                const userState = await getUserState(from);
                
                // Verificar si es un revendedor autenticado
                if (userState.state === 'reseller_authenticated') {
                    const reseller = userState.data;
                    
                    // MENÚ REVENDEDOR
                    if (text.toLowerCase() === 'menu' || text === '0') {
                        await client.sendText(from, `👤 *PANEL REVENDEDOR - ${reseller.name}*

Elija una opción:

1️⃣ - CREAR USUARIO SSH (con NOMBRE + HWID)
2️⃣ - VER MIS USUARIOS
3️⃣ - MIS ESTADÍSTICAS
4️⃣ - DESCARGAR APLICACIÓN

0️⃣ - SALIR`);
                        return;
                    }
                    
                    // Opción 1: Crear usuario SSH (ahora con nombre y HWID)
                    if (text === '1') {
                        await setUserState(from, 'reseller_asking_username', reseller);
                        await client.sendText(from, `📝 *CREAR USUARIO SSH*

*Paso 1/4:* Ingresa el NOMBRE DE USUARIO deseado (ej: juanperez, cliente01):

*0* - Cancelar`);
                        return;
                    }
                    
                    // Opción 2: Ver usuarios creados
                    if (text === '2') {
                        const users = await getResellerUsers(reseller.id);
                        
                        if (users.length === 0) {
                            await client.sendText(from, `📭 *NO HAY USUARIOS CREADOS*

Aún no has creado ningún usuario.
Usa la opción 1 para crear.`);
                        } else {
                            let userList = `👥 *MIS USUARIOS (${users.length})*\n\n`;
                            for (const u of users) {
                                const status = u.status === 1 ? '✅ Activo' : '❌ Inactivo';
                                const expireDate = moment(u.expires_at).format('DD/MM/YYYY');
                                userList += `👤 *${u.username}*\n🆔 HWID: ${u.hwid}\n📱 ${u.phone || 'sin teléfono'}\n📅 Expira: ${expireDate}\n${status}\n\n`;
                            }
                            await client.sendText(from, userList);
                        }
                        return;
                    }
                    
                    // Opción 3: Estadísticas
                    if (text === '3') {
                        const stats = await getResellerStats(reseller.id);
                        
                        const message = `📊 *MIS ESTADÍSTICAS*

👤 *${reseller.name}*

─────────────────
📀 *USUARIOS CREADOS*
Total: ${stats.total_users}
Activos: ${stats.active_users}
Tests: ${stats.test_users}
Premium: ${stats.premium_users}

─────────────────
💰 *VENTAS*
Total ventas: ${stats.total_sales}
Ingresos: $${stats.total_income}
Comisiones: $${stats.total_commission}
─────────────────

💡 *Comisión configurada:* ${reseller.commission_value}%`;
                        
                        await client.sendText(from, message);
                        return;
                    }
                    
                    // Opción 4: Descargar app
                    if (text === '4') {
                        await client.sendText(from, '📲 Enviando aplicación...');
                        await sendAppFile(from);
                        return;
                    }
                    
                    // Proceso de creación de usuario (4 pasos)
                    if (userState.state === 'reseller_asking_username') {
                        const reseller = userState.data;
                        
                        if (text === '0') {
                            await setUserState(from, 'reseller_authenticated', reseller);
                            await client.sendText(from, '❌ Operación cancelada. Envía *MENU* para volver.');
                            return;
                        }
                        
                        // Validar nombre de usuario (solo letras minúsculas, números, guión bajo)
                        const usernameRegex = /^[a-z0-9_]+$/;
                        if (!usernameRegex.test(text)) {
                            await client.sendText(from, '❌ *Nombre inválido*\nSolo letras minúsculas, números y guión bajo. Sin espacios.\n\nIntenta de nuevo:');
                            return;
                        }
                        
                        // Verificar si ya existe
                        const userExists = await new Promise((resolve) => {
                            db.get('SELECT id FROM users WHERE username = ?', [text], (err, row) => resolve(!err && row));
                        });
                        if (userExists) {
                            await client.sendText(from, '❌ *El nombre de usuario ya existe*\nElige otro nombre:');
                            return;
                        }
                        
                        // Guardar username y pasar al siguiente paso
                        await setUserState(from, 'reseller_asking_hwid', { ...reseller, desiredUsername: text });
                        await client.sendText(from, `✅ *Nombre de usuario:* ${text}\n\n*Paso 2/4:* Ingresa el HWID del cliente (formato AR-E2Q2, dos letras mayúsculas, guión, cuatro caracteres alfanuméricos):

*0* - Cancelar`);
                        return;
                    }
                    
                    if (userState.state === 'reseller_asking_hwid') {
                        const data = userState.data;
                        const reseller = data;
                        const desiredUsername = data.desiredUsername;
                        
                        if (text === '0') {
                            await setUserState(from, 'reseller_authenticated', reseller);
                            await client.sendText(from, '❌ Operación cancelada. Envía *MENU* para volver.');
                            return;
                        }
                        
                        if (!isValidHWID(text)) {
                            await client.sendText(from, '❌ *Formato HWID inválido*\nDebe ser como: AR-E2Q2 (dos letras mayúsculas, guión, cuatro caracteres alfanuméricos).\n\nIntenta de nuevo:');
                            return;
                        }
                        
                        // Verificar HWID único
                        const hwidExists = await new Promise((resolve) => {
                            db.get('SELECT id FROM users WHERE hwid = ?', [text], (err, row) => resolve(!err && row));
                        });
                        if (hwidExists) {
                            await client.sendText(from, '❌ *El HWID ya está registrado*\nUsa otro HWID:');
                            return;
                        }
                        
                        // Guardar HWID y pasar a pedir teléfono
                        await setUserState(from, 'reseller_asking_phone', { ...reseller, desiredUsername, desiredHwid: text });
                        await client.sendText(from, `✅ *HWID:* ${text}\n\n*Paso 3/4:* Ingresa el teléfono del usuario (ej: 5491122334455):

*0* - Cancelar`);
                        return;
                    }
                    
                    if (userState.state === 'reseller_asking_phone') {
                        const data = userState.data;
                        const reseller = data;
                        const desiredUsername = data.desiredUsername;
                        const desiredHwid = data.desiredHwid;
                        
                        if (text === '0') {
                            await setUserState(from, 'reseller_authenticated', reseller);
                            await client.sendText(from, '❌ Operación cancelada. Envía *MENU* para volver.');
                            return;
                        }
                        
                        // Guardar teléfono y pasar a selección de plan
                        await setUserState(from, 'reseller_selecting_plan', { ...reseller, desiredUsername, desiredHwid, userPhone: text });
                        
                        await client.sendText(from, `📞 *Teléfono:* ${text}\n\n*Paso 4/4 - SELECCIONAR PLAN*

🌐 PLANES SSH PREMIUM

1️⃣ - 7 DIAS - $${config.prices.price_7d}
2️⃣ - 15 DIAS - $${config.prices.price_15d}
3️⃣ - 30 DIAS - $${config.prices.price_30d}
4️⃣ - 50 DIAS - $${config.prices.price_50d}
5️⃣ - PRUEBA (${config.prices.test_hours} horas GRATIS)

0️⃣ - CANCELAR`);
                        return;
                    }
                    
                    if (userState.state === 'reseller_selecting_plan') {
                        const data = userState.data;
                        const reseller = data;
                        const desiredUsername = data.desiredUsername;
                        const desiredHwid = data.desiredHwid;
                        const userPhone = data.userPhone;
                        
                        if (text === '0') {
                            await setUserState(from, 'reseller_authenticated', reseller);
                            await client.sendText(from, '❌ Operación cancelada. Envía *MENU* para volver.');
                            return;
                        }
                        
                        const planMap = {
                            '1': { days: 7, price: config.prices.price_7d, type: 'premium' },
                            '2': { days: 15, price: config.prices.price_15d, type: 'premium' },
                            '3': { days: 30, price: config.prices.price_30d, type: 'premium' },
                            '4': { days: 50, price: config.prices.price_50d, type: 'premium' },
                            '5': { days: 0, price: 0, type: 'test' }
                        };
                        
                        const plan = planMap[text];
                        
                        if (!plan) {
                            await client.sendText(from, '❌ Opción inválida. Elige 1-5');
                            return;
                        }
                        
                        await client.sendText(from, '⏳ Creando usuario...');
                        
                        const result = await createSSHUser(userPhone, desiredUsername, desiredHwid, plan.days, reseller.id);
                        
                        if (result.success) {
                            let message = `✅ *USUARIO CREADO CON ÉXITO*

👤 Usuario: ${result.username}
🆔 HWID: ${result.hwid}
🔑 Contraseña: ${result.password}
📱 Teléfono: ${userPhone}`;
                            
                            if (plan.type === 'test') {
                                message += `\n⏰ Expira en: ${config.prices.test_hours} horas`;
                                message += `\n🎁 PRUEBA GRATUITA`;
                            } else {
                                const expireDate = moment(result.expires).format('DD/MM/YYYY HH:mm');
                                message += `\n📅 Expira: ${expireDate}`;
                                message += `\n💰 Plan: ${plan.days} días - $${plan.price} ARS`;
                                message += `\n💸 *Comisión generada: $${(plan.price * (reseller.commission_value / 100)).toFixed(2)} ARS*`;
                                
                                // Registrar pago
                                const paymentId = `RESELLER-${reseller.id}-${Date.now()}`;
                                const commission = plan.price * (reseller.commission_value / 100);
                                
                                db.run(`
                                    INSERT INTO payments (payment_id, phone, plan, days, amount, status, reseller_id, commission, approved_at)
                                    VALUES (?, ?, ?, ?, ?, 'approved', ?, ?, CURRENT_TIMESTAMP)
                                `, [paymentId, userPhone, `${plan.days}d`, plan.days, plan.price, reseller.id, commission]);
                            }
                            
                            await client.sendText(from, message);
                            
                            // Enviar mensaje al usuario
                            if (client) {
                                let userMessage = `🎉 *CUENTA SSH ACTIVADA*

👤 Usuario: ${result.username}
🆔 HWID: ${result.hwid}
🔑 Contraseña: ${result.password}

📲 Descarga la app: Envía *MENU* al bot

🔌 *1 dispositivo máximo*`;
                                
                                if (plan.type === 'test') {
                                    userMessage += `\n⏰ *PRUEBA DE ${config.prices.test_hours} HORAS*`;
                                } else {
                                    userMessage += `\n📅 *VÁLIDO HASTA: ${moment(result.expires).format('DD/MM/YYYY')}*`;
                                }
                                
                                await client.sendText(userPhone, userMessage);
                            }
                            
                            console.log(chalk.green(`✅ Revendedor ${reseller.username} creó usuario ${result.username} con HWID ${result.hwid}`));
                        } else {
                            await client.sendText(from, `❌ Error: ${result.error}`);
                        }
                        
                        await setUserState(from, 'reseller_authenticated', reseller);
                        return;
                    }
                    
                    // Salir
                    if (text.toLowerCase() === 'salir') {
                        await clearUserState(from);
                        await client.sendText(from, `👋 *SESIÓN CERRADA*

Para iniciar sesión nuevamente, envía:

*LOGIN usuario contraseña*
Ejemplo: LOGIN revendedor123 pass123`);
                        return;
                    }
                    
                    return;
                }
                
                // MENÚ PRINCIPAL - Autenticación de revendedores
                if (text.toLowerCase() === 'menu' || text.toLowerCase() === 'hola' || text.toLowerCase() === 'start') {
                    await setUserState(from, 'main_menu');
                    await client.sendText(from, `🤖 *SSH BOT PRO - SISTEMA DE REVENDEDORES*

Para revendedores:

*LOGIN usuario contraseña*

Para clientes:
Envía *HELP* para información`);
                    return;
                }
                
                // Autenticación de revendedores
                if (text.toUpperCase().startsWith('LOGIN ')) {
                    const parts = text.split(' ');
                    if (parts.length >= 3) {
                        const username = parts[1];
                        const password = parts[2];
                        
                        const reseller = await authenticateReseller(username, password);
                        
                        if (reseller) {
                            await setUserState(from, 'reseller_authenticated', reseller);
                            await client.sendText(from, `✅ *AUTENTICACIÓN EXITOSA*

👤 Bienvenido ${reseller.name}

Envía *MENU* para ver las opciones`);
                        } else {
                            await client.sendText(from, `❌ *AUTENTICACIÓN FALLIDA*

Usuario o contraseña incorrectos.

Para clientes:
Envía *HELP* para información

Para revendedores:
*LOGIN usuario contraseña*`);
                        }
                    } else {
                        await client.sendText(from, `❌ *FORMATO INCORRECTO*

Usa: *LOGIN usuario contraseña*
Ejemplo: LOGIN revendedor123 pass123`);
                    }
                    return;
                }
                
                // Menú para clientes
                if (text.toLowerCase() === 'help') {
                    await client.sendText(from, `🤖 *SSH BOT PRO*

Para obtener una cuenta SSH, contacta a un revendedor autorizado.

Si eres revendedor:
*LOGIN usuario contraseña*

Para descargar la app:
Envía *APK*`);
                    return;
                }
                
                if (text.toLowerCase() === 'apk') {
                    await sendAppFile(from);
                    return;
                }
                
            } catch (error) {
                console.error(chalk.red('❌ Error procesando mensaje:'), error.message);
            }
        });
        
        // Limpieza cada 15 minutos
        cron.schedule('*/15 * * * *', async () => {
            const now = moment().format('YYYY-MM-DD HH:mm:ss');
            console.log(chalk.yellow(`🧹 Limpiando usuarios expirados...`));
            
            db.all('SELECT username FROM users WHERE expires_at < ? AND status = 1', [now], async (err, rows) => {
                if (err || !rows || rows.length === 0) return;
                
                for (const r of rows) {
                    try {
                        await execPromise(`pkill -u ${r.username} 2>/dev/null || true`);
                        await execPromise(`userdel -f ${r.username} 2>/dev/null || true`);
                        db.run('UPDATE users SET status = 0 WHERE username = ?', [r.username]);
                        console.log(chalk.green(`🗑️ Eliminado: ${r.username}`));
                    } catch (e) {
                        console.error(chalk.red(`Error eliminando ${r.username}:`), e.message);
                    }
                }
            });
        });
        
        // Limpiar estados antiguos
        cron.schedule('0 * * * *', () => {
            db.run(`DELETE FROM user_state WHERE updated_at < datetime('now', '-1 hour')`);
        });
        
    } catch (error) {
        console.error(chalk.red('❌ Error inicializando WPPConnect:'), error.message);
        console.log(chalk.yellow('🔄 Reintentando en 10 segundos...'));
        setTimeout(initializeBot, 10000);
    }
}

initializeBot();

process.on('SIGINT', async () => {
    console.log(chalk.yellow('\n🛑 Cerrando bot...'));
    if (client) {
        await client.close();
    }
    process.exit();
});
BOTEOF

echo -e "${GREEN}✅ Bot creado con sistema de revendedores y HWID${NC}"

# ================================================
# CREAR PANEL ADMINISTRADOR DE REVENDEDORES (MODIFICADO CON HWID)
# ================================================
echo -e "\n${CYAN}🎛️  Creando panel administrador de revendedores...${NC}"

cat > /usr/local/bin/reseller-admin << 'ADMINEOF'
#!/bin/bash
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'; CYAN='\033[0;36m'; BLUE='\033[0;34m'; PURPLE='\033[0;35m'; NC='\033[0m'

DB="/opt/sshbot-pro/data/users.db"
CONFIG="/opt/sshbot-pro/config/config.json"

get_val() { jq -r "$1" "$CONFIG" 2>/dev/null; }

show_header() {
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║         🎛️  PANEL ADMIN - SISTEMA DE REVENDEDORES CON HWID       ║${NC}"
    echo -e "${CYAN}║              🔐 GESTIÓN COMPLETA DE REVENDEDORES                  ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════╝${NC}\n"
}

create_reseller() {
    clear
    echo -e "${CYAN}👤 CREAR NUEVO REVENDEDOR${NC}\n"
    
    read -p "Nombre del revendedor: " NAME
    read -p "Usuario (login): " USERNAME
    read -p "Contraseña: " PASSWORD
    read -p "Teléfono (ej: 5491122334455): " PHONE
    
    echo -e "\n${YELLOW}Tipo de comisión:${NC}"
    echo -e "  1. Porcentaje (%)"
    echo -e "  2. Monto fijo (ARS)"
    read -p "Selecciona (1/2): " COMM_TYPE
    
    if [[ "$COMM_TYPE" == "1" ]]; then
        COM_TYPE="percentage"
        read -p "Porcentaje de comisión (ej: 20): " COM_VALUE
    else
        COM_TYPE="fixed"
        read -p "Monto fijo por venta (ej: 500): " COM_VALUE
    fi
    
    echo -e "\n${YELLOW}Creando revendedor...${NC}"
    
    sqlite3 "$DB" "INSERT INTO resellers (username, password, name, phone, commission_type, commission_value, status) 
                   VALUES ('$USERNAME', '$PASSWORD', '$NAME', '$PHONE', '$COM_TYPE', $COM_VALUE, 1)" 2>/dev/null
    
    if [[ $? -eq 0 ]]; then
        echo -e "\n${GREEN}✅ REVENDEDOR CREADO${NC}"
        echo -e "  👤 Nombre: $NAME"
        echo -e "  🔑 Usuario: $USERNAME"
        echo -e "  🔐 Contraseña: $PASSWORD"
        echo -e "  📱 Teléfono: $PHONE"
        echo -e "  💰 Comisión: $COM_VALUE ${COM_TYPE == 'percentage' ? '%' : 'ARS'}"
    else
        echo -e "\n${RED}❌ Error: Usuario ya existe${NC}"
    fi
    
    read -p "Presiona Enter..."
}

list_resellers() {
    clear
    echo -e "${CYAN}👥 LISTA DE REVENDEDORES${NC}\n"
    
    echo -e "${YELLOW}──────────────────────────────────────────────────────────────────${NC}"
    printf "${CYAN}%-20s %-15s %-15s %-15s %-10s${NC}\n" "NOMBRE" "USUARIO" "TELÉFONO" "COMISIÓN" "ESTADO"
    echo -e "${YELLOW}──────────────────────────────────────────────────────────────────${NC}"
    
    sqlite3 "$DB" "SELECT name, username, phone, commission_type, commission_value, status FROM resellers WHERE username != 'admin'" | while IFS='|' read name username phone com_type com_val status; do
        if [[ "$com_type" == "percentage" ]]; then
            COM="${com_val}%"
        else
            COM="$${com_val}"
        fi
        
        if [[ "$status" == "1" ]]; then
            STATUS="${GREEN}ACTIVO${NC}"
        else
            STATUS="${RED}INACTIVO${NC}"
        fi
        
        printf "%-20s %-15s %-15s %-15s ${STATUS}\n" "$name" "$username" "$phone" "$COM"
    done
    
    echo -e "${YELLOW}──────────────────────────────────────────────────────────────────${NC}"
    
    TOTAL=$(sqlite3 "$DB" "SELECT COUNT(*) FROM resellers WHERE username != 'admin'")
    echo -e "\n${GREEN}Total: $TOTAL revendedores${NC}"
    read -p "Presiona Enter..."
}

view_reseller_stats() {
    clear
    echo -e "${CYAN}📊 ESTADÍSTICAS DE REVENDEDOR${NC}\n"
    
    read -p "ID del revendedor (o nombre de usuario): " INPUT
    
    # Buscar revendedor
    RESELLER=$(sqlite3 "$DB" "SELECT id, name, username, commission_type, commission_value FROM resellers WHERE id = '$INPUT' OR username = '$INPUT' AND username != 'admin'")
    
    if [[ -z "$RESELLER" ]]; then
        echo -e "${RED}❌ Revendedor no encontrado${NC}"
        read -p "Presiona Enter..."
        return
    fi
    
    IFS='|' read RESELLER_ID RESELLER_NAME RESELLER_USER COM_TYPE COM_VAL <<< "$RESELLER"
    
    # Obtener estadísticas
    STATS=$(sqlite3 "$DB" "SELECT 
        COUNT(DISTINCT u.id) as total_users,
        COUNT(CASE WHEN u.status = 1 THEN 1 END) as active_users,
        COUNT(CASE WHEN u.tipo = 'test' THEN 1 END) as test_users,
        COUNT(CASE WHEN u.tipo = 'premium' THEN 1 END) as premium_users,
        COUNT(p.id) as total_sales,
        COALESCE(SUM(p.amount), 0) as total_income,
        COALESCE(SUM(p.commission), 0) as total_commission
        FROM users u
        LEFT JOIN payments p ON u.reseller_id = p.reseller_id AND p.status = 'approved'
        WHERE u.reseller_id = $RESELLER_ID")
    
    IFS='|' read TOTAL_USERS ACTIVE_USERS TEST_USERS PREMIUM_USERS TOTAL_SALES TOTAL_INCOME TOTAL_COMMISSION <<< "$STATS"
    
    echo -e "\n${CYAN}──────────────────────────────────────────────────────────────────${NC}"
    echo -e "${GREEN}📊 ESTADÍSTICAS DE ${RESELLER_NAME}${NC}"
    echo -e "${CYAN}──────────────────────────────────────────────────────────────────${NC}\n"
    
    echo -e "${YELLOW}👤 DATOS DEL REVENDEDOR:${NC}"
    echo -e "  ID: $RESELLER_ID"
    echo -e "  Nombre: $RESELLER_NAME"
    echo -e "  Usuario: $RESELLER_USER"
    echo -e "  Comisión: ${COM_VAL}${COM_TYPE == 'percentage' ? '%' : ' ARS'}"
    
    echo -e "\n${YELLOW}📀 USUARIOS CREADOS:${NC}"
    echo -e "  Total: $TOTAL_USERS"
    echo -e "  Activos: $ACTIVE_USERS"
    echo -e "  Pruebas: $TEST_USERS"
    echo -e "  Premium: $PREMIUM_USERS"
    
    echo -e "\n${YELLOW}💰 VENTAS:${NC}"
    echo -e "  Total ventas: $TOTAL_SALES"
    echo -e "  Ingresos: $${TOTAL_INCOME}"
    echo -e "  Comisiones: $${TOTAL_COMMISSION}"
    
    echo -e "\n${YELLOW}📋 ÚLTIMOS USUARIOS CREADOS:${NC}"
    sqlite3 "$DB" "SELECT username, hwid, phone, tipo, created_at FROM users WHERE reseller_id = $RESELLER_ID ORDER BY created_at DESC LIMIT 10" | while IFS='|' read user hwid phone tipo created; do
        echo -e "  👤 $user (HWID: $hwid) - $phone - $tipo - $(echo $created | cut -d' ' -f1)"
    done
    
    echo -e "\n${CYAN}──────────────────────────────────────────────────────────────────${NC}"
    read -p "Presiona Enter..."
}

toggle_reseller() {
    clear
    echo -e "${CYAN}🔧 ACTIVAR/DESACTIVAR REVENDEDOR${NC}\n"
    
    read -p "ID del revendedor: " RESELLER_ID
    
    CURRENT=$(sqlite3 "$DB" "SELECT status, name FROM resellers WHERE id = $RESELLER_ID AND username != 'admin'")
    
    if [[ -z "$CURRENT" ]]; then
        echo -e "${RED}❌ Revendedor no encontrado${NC}"
        read -p "Presiona Enter..."
        return
    fi
    
    IFS='|' read STATUS NAME <<< "$CURRENT"
    
    if [[ "$STATUS" == "1" ]]; then
        echo -e "${YELLOW}⚠️ ¿Desactivar revendedor $NAME?${NC}"
        read -p "(s/N): " CONFIRM
        if [[ "$CONFIRM" == "s" ]]; then
            sqlite3 "$DB" "UPDATE resellers SET status = 0 WHERE id = $RESELLER_ID"
            echo -e "${GREEN}✅ Revendedor desactivado${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️ ¿Activar revendedor $NAME?${NC}"
        read -p "(s/N): " CONFIRM
        if [[ "$CONFIRM" == "s" ]]; then
            sqlite3 "$DB" "UPDATE resellers SET status = 1 WHERE id = $RESELLER_ID"
            echo -e "${GREEN}✅ Revendedor activado${NC}"
        fi
    fi
    
    read -p "Presiona Enter..."
}

edit_commission() {
    clear
    echo -e "${CYAN}💰 EDITAR COMISIÓN${NC}\n"
    
    read -p "ID del revendedor: " RESELLER_ID
    
    CURRENT=$(sqlite3 "$DB" "SELECT name, commission_type, commission_value FROM resellers WHERE id = $RESELLER_ID AND username != 'admin'")
    
    if [[ -z "$CURRENT" ]]; then
        echo -e "${RED}❌ Revendedor no encontrado${NC}"
        read -p "Presiona Enter..."
        return
    fi
    
    IFS='|' read NAME COM_TYPE COM_VAL <<< "$CURRENT"
    
    echo -e "\n${YELLOW}Revendedor: $NAME${NC}"
    echo -e "Comisión actual: ${COM_VAL}${COM_TYPE == 'percentage' ? '%' : ' ARS'}\n"
    
    echo -e "Nuevo tipo de comisión:"
    echo -e "  1. Porcentaje (%)"
    echo -e "  2. Monto fijo (ARS)"
    echo -e "  0. Mantener actual"
    read -p "Selecciona: " NEW_TYPE
    
    if [[ "$NEW_TYPE" == "1" ]]; then
        read -p "Nuevo porcentaje: " NEW_VALUE
        sqlite3 "$DB" "UPDATE resellers SET commission_type = 'percentage', commission_value = $NEW_VALUE WHERE id = $RESELLER_ID"
        echo -e "${GREEN}✅ Comisión actualizada a ${NEW_VALUE}%${NC}"
    elif [[ "$NEW_TYPE" == "2" ]]; then
        read -p "Nuevo monto fijo: " NEW_VALUE
        sqlite3 "$DB" "UPDATE resellers SET commission_type = 'fixed', commission_value = $NEW_VALUE WHERE id = $RESELLER_ID"
        echo -e "${GREEN}✅ Comisión actualizada a \$${NEW_VALUE} ARS${NC}"
    else
        echo -e "${YELLOW}Comisión sin cambios${NC}"
    fi
    
    read -p "Presiona Enter..."
}

global_stats() {
    clear
    echo -e "${CYAN}📊 ESTADÍSTICAS GLOBALES${NC}\n"
    
    # Usuarios
    TOTAL_USERS=$(sqlite3 "$DB" "SELECT COUNT(*) FROM users WHERE username != ''")
    ACTIVE_USERS=$(sqlite3 "$DB" "SELECT COUNT(*) FROM users WHERE status = 1")
    TEST_TODAY=$(sqlite3 "$DB" "SELECT COUNT(*) FROM daily_tests WHERE date = date('now')")
    
    # Revendedores
    TOTAL_RESELLERS=$(sqlite3 "$DB" "SELECT COUNT(*) FROM resellers WHERE username != 'admin'")
    ACTIVE_RESELLERS=$(sqlite3 "$DB" "SELECT COUNT(*) FROM resellers WHERE status = 1 AND username != 'admin'")
    
    # Ventas
    TOTAL_SALES=$(sqlite3 "$DB" "SELECT COUNT(*) FROM payments WHERE status = 'approved'")
    TOTAL_INCOME=$(sqlite3 "$DB" "SELECT printf('%.2f', SUM(amount)) FROM payments WHERE status = 'approved'")
    TODAY_SALES=$(sqlite3 "$DB" "SELECT COUNT(*) FROM payments WHERE status = 'approved' AND date(approved_at) = date('now')")
    TODAY_INCOME=$(sqlite3 "$DB" "SELECT printf('%.2f', SUM(amount)) FROM payments WHERE status = 'approved' AND date(approved_at) = date('now')")
    
    # Comisiones
    TOTAL_COMMISSIONS=$(sqlite3 "$DB" "SELECT printf('%.2f', SUM(commission)) FROM payments WHERE status = 'approved'")
    
    echo -e "${CYAN}──────────────────────────────────────────────────────────────────${NC}"
    echo -e "${GREEN}📊 ESTADÍSTICAS DEL SISTEMA${NC}"
    echo -e "${CYAN}──────────────────────────────────────────────────────────────────${NC}\n"
    
    echo -e "${YELLOW}👥 USUARIOS:${NC}"
    echo -e "  Total usuarios creados: $TOTAL_USERS"
    echo -e "  Usuarios activos: $ACTIVE_USERS"
    echo -e "  Pruebas hoy: $TEST_TODAY"
    
    echo -e "\n${YELLOW}🤝 REVENDEDORES:${NC}"
    echo -e "  Total revendedores: $TOTAL_RESELLERS"
    echo -e "  Revendedores activos: $ACTIVE_RESELLERS"
    
    echo -e "\n${YELLOW}💰 VENTAS:${NC}"
    echo -e "  Total ventas: $TOTAL_SALES"
    echo -e "  Ingresos totales: \$${TOTAL_INCOME}"
    echo -e "  Comisiones totales: \$${TOTAL_COMMISSIONS}"
    echo -e "  Ventas hoy: $TODAY_SALES"
    echo -e "  Ingresos hoy: \$${TODAY_INCOME}"
    
    echo -e "\n${YELLOW}🏆 TOP REVENDEDORES (por ventas):${NC}"
    sqlite3 "$DB" "SELECT r.name, COUNT(p.id) as sales, printf('%.2f', SUM(p.amount)) as total
                   FROM resellers r
                   LEFT JOIN payments p ON r.id = p.reseller_id AND p.status = 'approved'
                   WHERE r.username != 'admin'
                   GROUP BY r.id
                   ORDER BY total DESC
                   LIMIT 5" | while IFS='|' read name sales total; do
        echo -e "  🏆 $name - $sales ventas - \$${total}"
    done
    
    echo -e "\n${CYAN}──────────────────────────────────────────────────────────────────${NC}"
    read -p "Presiona Enter..."
}

while true; do
    show_header
    
    TOTAL_RESELLERS=$(sqlite3 "$DB" "SELECT COUNT(*) FROM resellers WHERE username != 'admin'" 2>/dev/null || echo "0")
    TOTAL_USERS=$(sqlite3 "$DB" "SELECT COUNT(*) FROM users" 2>/dev/null || echo "0")
    TODAY_SALES=$(sqlite3 "$DB" "SELECT COUNT(*) FROM payments WHERE status='approved' AND date(approved_at)=date('now')" 2>/dev/null || echo "0")
    
    echo -e "${YELLOW}📊 RESUMEN:${NC}"
    echo -e "  Revendedores: ${CYAN}$TOTAL_RESELLERS${NC}"
    echo -e "  Usuarios totales: ${CYAN}$TOTAL_USERS${NC}"
    echo -e "  Ventas hoy: ${GREEN}$TODAY_SALES${NC}"
    echo -e ""
    
    echo -e "${BLUE}──────────────────────────────────────────────────────────────────${NC}"
    echo -e "${CYAN}[1]${NC} 👤 Crear nuevo revendedor"
    echo -e "${CYAN}[2]${NC} 👥 Listar revendedores"
    echo -e "${CYAN}[3]${NC} 📊 Ver estadísticas de revendedor"
    echo -e "${CYAN}[4]${NC} 🔧 Activar/Desactivar revendedor"
    echo -e "${CYAN}[5]${NC} 💰 Editar comisión"
    echo -e "${CYAN}[6]${NC} 📀 Estadísticas globales"
    echo -e "${CYAN}[7]${NC} 💳 Ver pagos pendientes"
    echo -e "${CYAN}[8]${NC} ⚙️ Configuración general"
    echo -e "${CYAN}[0]${NC} 🚪 Salir"
    echo -e "${BLUE}──────────────────────────────────────────────────────────────────${NC}"
    echo -e ""
    
    read -p "👉 Selecciona: " OPTION
    
    case $OPTION in
        1) create_reseller ;;
        2) list_resellers ;;
        3) view_reseller_stats ;;
        4) toggle_reseller ;;
        5) edit_commission ;;
        6) global_stats ;;
        7)
            clear
            echo -e "${CYAN}💳 PAGOS PENDIENTES${NC}\n"
            sqlite3 -column -header "$DB" "SELECT payment_id, phone, plan, amount, created_at FROM payments WHERE status='pending' LIMIT 20"
            read -p "Presiona Enter..."
            ;;
        8)
            clear
            echo -e "${CYAN}⚙️ CONFIGURACIÓN${NC}\n"
            echo -e "${YELLOW}Precios actuales:${NC}"
            echo -e "  7 días: $ ${get_val '.prices.price_7d'}"
            echo -e "  15 días: $ ${get_val '.prices.price_15d'}"
            echo -e "  30 días: $ ${get_val '.prices.price_30d'}"
            echo -e "  50 días: $ ${get_val '.prices.price_50d'}"
            echo -e "  Prueba: ${get_val '.prices.test_hours'} horas"
            echo -e ""
            read -p "Presiona Enter..."
            ;;
        0)
            echo -e "\n${GREEN}👋 Hasta pronto${NC}\n"
            exit 0
            ;;
        *)
            echo -e "\n${RED}❌ Opción inválida${NC}"
            sleep 1
            ;;
    esac
done
ADMINEOF

chmod +x /usr/local/bin/reseller-admin

# Crear panel rápido para revendedores (desde SSH) - MODIFICADO CON HWID
cat > /usr/local/bin/reseller << 'RESELLEREOF'
#!/bin/bash
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'; CYAN='\033[0;36m'; NC='\033[0m'

DB="/opt/sshbot-pro/data/users.db"

echo -e "${CYAN}══════════════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}         🎛️  PANEL DE REVENDEDOR SSH BOT PRO CON HWID            ${NC}"
echo -e "${CYAN}══════════════════════════════════════════════════════════════════${NC}\n"

read -p "Usuario: " USERNAME
read -s -p "Contraseña: " PASSWORD
echo ""

RESELLER=$(sqlite3 "$DB" "SELECT id, name, commission_type, commission_value FROM resellers WHERE username = '$USERNAME' AND password = '$PASSWORD' AND status = 1")

if [[ -z "$RESELLER" ]]; then
    echo -e "\n${RED}❌ Credenciales incorrectas o revendedor inactivo${NC}"
    exit 1
fi

IFS='|' read RESELLER_ID NAME COM_TYPE COM_VAL <<< "$RESELLER"

echo -e "\n${GREEN}✅ Bienvenido $NAME${NC}\n"

while true; do
    clear
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}         🎛️  PANEL DE REVENDEDOR - $NAME                         ${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════${NC}\n"
    
    # Estadísticas rápidas
    STATS=$(sqlite3 "$DB" "SELECT COUNT(*) FROM users WHERE reseller_id = $RESELLER_ID")
    ACTIVE=$(sqlite3 "$DB" "SELECT COUNT(*) FROM users WHERE reseller_id = $RESELLER_ID AND status = 1")
    
    echo -e "${YELLOW}📊 TUS ESTADÍSTICAS:${NC}"
    echo -e "  Usuarios creados: ${CYAN}$STATS${NC}"
    echo -e "  Usuarios activos: ${GREEN}$ACTIVE${NC}"
    echo -e "  Comisión: ${COM_VAL}${COM_TYPE == 'percentage' ? '%' : ' ARS'}"
    echo -e ""
    
    echo -e "${BLUE}──────────────────────────────────────────────────────────────────${NC}"
    echo -e "${CYAN}[1]${NC} 👤 Crear usuario SSH (con NOMBRE + HWID)"
    echo -e "${CYAN}[2]${NC} 👥 Ver mis usuarios"
    echo -e "${CYAN}[3]${NC} 📊 Ver estadísticas detalladas"
    echo -e "${CYAN}[4]${NC} 💰 Ver mis comisiones"
    echo -e "${CYAN}[0]${NC} 🚪 Salir"
    echo -e "${BLUE}──────────────────────────────────────────────────────────────────${NC}"
    echo -e ""
    
    read -p "👉 Selecciona: " OPT
    
    case $OPT in
        1)
            clear
            echo -e "${CYAN}👤 CREAR USUARIO SSH CON NOMBRE Y HWID${NC}\n"
            
            read -p "Nombre de usuario (ej: juanperez): " CUSTOM_USER
            if [[ ! "$CUSTOM_USER" =~ ^[a-z0-9_]+$ ]]; then
                echo -e "${RED}❌ Nombre inválido. Solo minúsculas, números y guión bajo.${NC}"
                read -p "Presiona Enter..."
                continue
            fi
            
            # Verificar si ya existe
            EXISTS=$(sqlite3 "$DB" "SELECT id FROM users WHERE username = '$CUSTOM_USER'")
            if [[ -n "$EXISTS" ]]; then
                echo -e "${RED}❌ El nombre de usuario ya existe${NC}"
                read -p "Presiona Enter..."
                continue
            fi
            
            read -p "HWID (formato AR-E2Q2): " HWID
            if [[ ! "$HWID" =~ ^[A-Z]{2}-[A-Z0-9]{4}$ ]]; then
                echo -e "${RED}❌ Formato HWID inválido. Ejemplo: AR-E2Q2${NC}"
                read -p "Presiona Enter..."
                continue
            fi
            
            # Verificar HWID único
            EXISTS_HWID=$(sqlite3 "$DB" "SELECT id FROM users WHERE hwid = '$HWID'")
            if [[ -n "$EXISTS_HWID" ]]; then
                echo -e "${RED}❌ El HWID ya está registrado${NC}"
                read -p "Presiona Enter..."
                continue
            fi
            
            read -p "Teléfono del usuario (ej: 5491122334455): " PHONE
            
            echo -e "\n${YELLOW}Planes disponibles:${NC}"
            echo -e "  1. 7 días"
            echo -e "  2. 15 días"
            echo -e "  3. 30 días"
            echo -e "  4. 50 días"
            echo -e "  5. Prueba (2 horas gratis)"
            read -p "Selecciona plan (1-5): " PLAN
            
            case $PLAN in
                1) DAYS=7; TYPE="premium";;
                2) DAYS=15; TYPE="premium";;
                3) DAYS=30; TYPE="premium";;
                4) DAYS=50; TYPE="premium";;
                5) DAYS=0; TYPE="test";;
                *) echo -e "${RED}❌ Opción inválida${NC}"; sleep 2; continue;;
            esac
            
            echo -e "\n${YELLOW}Creando usuario...${NC}"
            
            PASSWORD="mgvpn247"
            if [[ "$DAYS" == "0" ]]; then
                EXPIRE=$(date -d "+2 hours" +"%Y-%m-%d %H:%M:%S")
                useradd -m -s /bin/bash "$CUSTOM_USER" && echo "$CUSTOM_USER:$PASSWORD" | chpasswd
            else
                EXPIRE=$(date -d "+$DAYS days" +"%Y-%m-%d 23:59:59")
                useradd -M -s /bin/false -e "$(date -d "+$DAYS days" +%Y-%m-%d)" "$CUSTOM_USER" && echo "$CUSTOM_USER:$PASSWORD" | chpasswd
            fi
            
            if [[ $? -eq 0 ]]; then
                sqlite3 "$DB" "INSERT INTO users (phone, username, hwid, password, tipo, expires_at, status, created_by, reseller_id) 
                               VALUES ('$PHONE', '$CUSTOM_USER', '$HWID', '$PASSWORD', '$TYPE', '$EXPIRE', 1, '$NAME', $RESELLER_ID)"
                
                echo -e "\n${GREEN}✅ USUARIO CREADO CON ÉXITO${NC}"
                echo -e "  👤 Usuario: $CUSTOM_USER"
                echo -e "  🆔 HWID: $HWID"
                echo -e "  🔑 Contraseña: $PASSWORD"
                echo -e "  📱 Teléfono: $PHONE"
                echo -e "  ⏰ Expira: $EXPIRE"
                echo -e "  📦 Tipo: $TYPE"
            else
                echo -e "\n${RED}❌ Error al crear usuario${NC}"
            fi
            read -p "Presiona Enter..."
            ;;
        2)
            clear
            echo -e "${CYAN}👥 MIS USUARIOS${NC}\n"
            sqlite3 -column -header "$DB" "SELECT username, hwid, phone, tipo, expires_at, status FROM users WHERE reseller_id = $RESELLER_ID ORDER BY created_at DESC LIMIT 30"
            read -p "Presiona Enter..."
            ;;
        3)
            clear
            echo -e "${CYAN}📊 ESTADÍSTICAS DETALLADAS${NC}\n"
            
            TOTAL=$(sqlite3 "$DB" "SELECT COUNT(*) FROM users WHERE reseller_id = $RESELLER_ID")
            ACTIVE=$(sqlite3 "$DB" "SELECT COUNT(*) FROM users WHERE reseller_id = $RESELLER_ID AND status = 1")
            TESTS=$(sqlite3 "$DB" "SELECT COUNT(*) FROM users WHERE reseller_id = $RESELLER_ID AND tipo = 'test'")
            PREMIUM=$(sqlite3 "$DB" "SELECT COUNT(*) FROM users WHERE reseller_id = $RESELLER_ID AND tipo = 'premium'")
            SALES=$(sqlite3 "$DB" "SELECT COUNT(*) FROM payments WHERE reseller_id = $RESELLER_ID AND status = 'approved'")
            INCOME=$(sqlite3 "$DB" "SELECT printf('%.2f', SUM(amount)) FROM payments WHERE reseller_id = $RESELLER_ID AND status = 'approved'")
            COMMISSIONS=$(sqlite3 "$DB" "SELECT printf('%.2f', SUM(commission)) FROM payments WHERE reseller_id = $RESELLER_ID AND status = 'approved'")
            
            echo -e "${YELLOW}📀 USUARIOS:${NC}"
            echo -e "  Total creados: $TOTAL"
            echo -e "  Activos: $ACTIVE"
            echo -e "  Pruebas: $TESTS"
            echo -e "  Premium: $PREMIUM"
            
            echo -e "\n${YELLOW}💰 VENTAS:${NC}"
            echo -e "  Ventas realizadas: $SALES"
            echo -e "  Ingresos generados: \$${INCOME:-0}"
            echo -e "  Tus comisiones: \$${COMMISSIONS:-0}"
            
            read -p "Presiona Enter..."
            ;;
        4)
            clear
            echo -e "${CYAN}💰 MIS COMISIONES${NC}\n"
            
            echo -e "${YELLOW}Configuración de comisión:${NC}"
            echo -e "  Tipo: ${COM_TYPE}"
            echo -e "  Valor: ${COM_VAL}${COM_TYPE == 'percentage' ? '%' : ' ARS'}"
            echo -e ""
            
            echo -e "${YELLOW}Últimas comisiones generadas:${NC}"
            sqlite3 -column -header "$DB" "SELECT plan, amount, commission, approved_at FROM payments WHERE reseller_id = $RESELLER_ID AND status = 'approved' ORDER BY approved_at DESC LIMIT 10"
            
            TOTAL_COMM=$(sqlite3 "$DB" "SELECT printf('%.2f', SUM(commission)) FROM payments WHERE reseller_id = $RESELLER_ID AND status = 'approved'")
            echo -e "\n${GREEN}Total comisiones acumuladas: \$${TOTAL_COMM:-0}${NC}"
            
            read -p "Presiona Enter..."
            ;;
        0)
            echo -e "\n${GREEN}👋 Hasta pronto${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}❌ Opción inválida${NC}"
            sleep 1
            ;;
    esac
done
RESELLEREOF

chmod +x /usr/local/bin/reseller

echo -e "${GREEN}✅ Paneles creados con soporte HWID${NC}"

# ================================================
# INICIAR BOT
# ================================================
echo -e "\n${CYAN}🚀 Iniciando bot...${NC}"

cd "$USER_HOME"
pm2 start bot.js --name sshbot-pro
pm2 save
pm2 startup systemd -u root --hp /root > /dev/null 2>&1

sleep 3

# ================================================
# MENSAJE FINAL
# ================================================
clear
echo -e "${GREEN}${BOLD}"
cat << "FINAL"
╔══════════════════════════════════════════════════════════════════╗
║                                                              ║
║          🎉 INSTALACIÓN COMPLETADA - REVENDEDORES + HWID 🎉   ║
║                                                              ║
║       🤖 SSH BOT PRO - SISTEMA DE REVENDEDORES CON HWID      ║
║       🔐 CADA REVENDEDOR CON SU CONTRASEÑA ÚNICA            ║
║       💰 CONTROL DE COMISIONES Y VENTAS                     ║
║       📊 ESTADÍSTICAS POR REVENDEDOR                        ║
║       🎛️  PANEL ADMINISTRADOR COMPLETO                      ║
║       👥 REVENDEDORES CREAN USUARIOS CON NOMBRE + HWID      ║
║       🆔 LOS CLIENTES AUTENTICAN CON USUARIO + HWID         ║
║                                                              ║
╚══════════════════════════════════════════════════════════════════╝
FINAL
echo -e "${NC}"

echo -e "${CYAN}══════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ Sistema completo instalado con HWID${NC}"
echo -e "${GREEN}✅ Sistema de revendedores activo${NC}"
echo -e "${GREEN}✅ Cada revendedor tiene su propia contraseña${NC}"
echo -e "${GREEN}✅ Control de comisiones integrado${NC}"
echo -e "${GREEN}✅ Creación de usuarios con NOMBRE + HWID${NC}"
echo -e "${CYAN}══════════════════════════════════════════════════════════════════${NC}\n"

echo -e "${YELLOW}📋 COMANDOS PRINCIPALES:${NC}\n"
echo -e "  ${GREEN}reseller-admin${NC}   - Panel administrador de revendedores"
echo -e "  ${GREEN}reseller${NC}         - Panel de revendedor (desde SSH)"
echo -e "  ${GREEN}pm2 logs sshbot-pro${NC} - Ver logs del bot"
echo -e "  ${GREEN}pm2 restart sshbot-pro${NC} - Reiniciar bot"
echo -e "\n"

echo -e "${YELLOW}🚀 PRIMEROS PASOS:${NC}\n"
echo -e "  1. Ver logs: ${GREEN}pm2 logs sshbot-pro${NC}"
echo -e "  2. Escanear QR cuando aparezca"
echo -e "  3. Panel admin: ${GREEN}reseller-admin${NC}"
echo -e "  4. Credenciales admin: usuario 'admin', contraseña 'admin123'"
echo -e "  5. Crear revendedores desde el panel admin"
echo -e "  6. Dar credenciales a los revendedores"
echo -e "  7. Los revendedores se autentican en WhatsApp con: LOGIN usuario pass"
echo -e "  8. Al crear usuario, se pedirá: NOMBRE, HWID, teléfono y plan"
echo -e "\n"

echo -e "${YELLOW}📱 PARA REVENDEDORES (WhatsApp):${NC}\n"
echo -e "  Enviar al bot: ${GREEN}LOGIN usuario contraseña${NC}"
echo -e "  Ejemplo: LOGIN juan123 pass123"
echo -e "  Luego enviar MENU para ver opciones"
echo -e "\n"

echo -e "${YELLOW}💰 CONFIGURAR COMISIONES:${NC}\n"
echo -e "  En panel admin: Opción 5 - Editar comisión"
echo -e "  Tipo: percentage (ej: 20%) o fixed (ej: 500 ARS)"
echo -e "  Las comisiones se calculan automáticamente"
echo -e "\n"

echo -e "${YELLOW}🔐 CREDENCIALES ADMIN:${NC}\n"
echo -e "  Usuario: ${GREEN}admin${NC}"
echo -e "  Contraseña: ${GREEN}admin123${NC}"
echo -e "  Cambia la contraseña del admin por seguridad"
echo -e "\n"

echo -e "${GREEN}${BOLD}¡Sistema de revendedores con HWID listo! Escanea el QR y empieza a gestionar tus revendedores 🚀${NC}\n"

# Ver logs automáticamente
read -p "$(echo -e "${YELLOW}¿Ver logs ahora? (s/N): ${NC}")" -n 1 -r
echo
if [[ $REPLY =~ ^[Ss]$ ]]; then
    echo -e "\n${CYAN}Mostrando logs...${NC}"
    echo -e "${YELLOW}📱 Espera que aparezca el QR para escanear...${NC}\n"
    sleep 2
    pm2 logs sshbot-pro
else
    echo -e "\n${YELLOW}💡 Para iniciar panel admin: ${GREEN}reseller-admin${NC}"
    echo -e "${YELLOW}💡 Para logs: ${GREEN}pm2 logs sshbot-pro${NC}\n"
fi

exit 0
