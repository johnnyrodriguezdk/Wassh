#!/bin/bash
# ================================================
# SSH BOT PRO v5.0 - CON REVENDEDORES Y DESCUENTO
# BASADO EN: https://github.com/johnnyrodriguezdk/ssh-bot-2
# ================================================
# CARACTERÍSTICAS ORIGINALES + NUEVAS:
# ✅ MERCADOPAGO SDK v2.x
# ✅ MENÚ PROPIO (2 opciones de compra)
# ✅ BOT SILENCIOSO
# ✅ USUARIOS TERMINAN EN 'j' · CONTRASEÑA 12345
# ✅ PANEL VPS COMPLETO (13 opciones)
# ✅ ESTADÍSTICAS DETALLADAS
# ✅ BACKUP AUTOMÁTICO
# ================================================
# 🎫 NUEVO: SISTEMA DE REVENDEDORES
# ✅ OPCIÓN 7 EN WHATSAPP PARA REVENDEDORES
# ✅ CÓDIGO ÚNICO POR REVENDEDOR (6 CARACTERES)
# ✅ 50% DE DESCUENTO AUTOMÁTICO
# ✅ MENÚ ESPECIAL EN VPS (COMANDO: sshbot)
# ================================================
# NOTA: El nombre del bot es SOLO VISUAL
# Las rutas son FIJAS: /opt/sshbot-pro y /root/sshbot-pro
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
║          🤖 SSH BOT PRO v5.0 - CON REVENDEDORES             ║
║     ✅ MP INTEGRADO · ✅ PANEL VPS (13 OPCIONES)            ║
║     ✅ NUEVO: REVENDEDORES CON 50% DTO · ✅ COMANDO sshbot  ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
BANNER
echo -e "${NC}"

echo -e "${GREEN}✅ CARACTERÍSTICAS COMPLETAS:${NC}"
echo -e "  💰 ${CYAN}MercadoPago SDK v2.x${NC} - Pagos automáticos"
echo -e "  🎛️  ${PURPLE}Panel VPS${NC} - 13 opciones de administración"
echo -e "  🔐 ${YELLOW}Usuarios:${NC} Terminan en 'j' · Contraseña 12345"
echo -e "  📊 ${BLUE}Estadísticas${NC} - Ventas, usuarios, ingresos"
echo -e "  💾 ${GREEN}Backup automático${NC} - Diario a las 3 AM"
echo -e "  🎫 ${PURPLE}NUEVO:${NC} Revendedores con 50% descuento"
echo -e "  🖥️  ${CYAN}NUEVO:${NC} Comando 'sshbot' para administrar"
echo -e "${CYAN}══════════════════════════════════════════════════════════════${NC}\n"

# Verificar root
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}❌ Debes ejecutar como root${NC}"
    exit 1
fi

# ================================================
# CONFIGURACIÓN DEL NOMBRE (SOLO VISUAL)
# ================================================
echo -e "\n${CYAN}${BOLD}⚙️ CONFIGURACIÓN DEL BOT (SOLO VISUAL)${NC}"
echo -e "${YELLOW}⚠️  El nombre que ingreses SOLO se verá en los mensajes${NC}"
echo -e "${YELLOW}⚠️  Las rutas de instalación son FIJAS: /opt/sshbot-pro${NC}\n"

read -p "📝 NOMBRE VISUAL PARA TU BOT (ej: MI BOT PRO): " BOT_NAME
BOT_NAME=${BOT_NAME:-"MI BOT PRO"}

echo -e "\n${GREEN}✅ Nombre visual: ${CYAN}$BOT_NAME${NC}"
echo -e "${GREEN}✅ Rutas fijas: ${CYAN}/opt/sshbot-pro${NC} y ${CYAN}/root/sshbot-pro${NC}\n"

# ================================================
# RUTAS FIJAS (NO DEPENDEN DEL NOMBRE)
# ================================================
INSTALL_DIR="/opt/sshbot-pro"
USER_HOME="/root/sshbot-pro"
DB_FILE="$INSTALL_DIR/data/users.db"
CONFIG_FILE="$INSTALL_DIR/config/config.json"
INFO_FILE="$INSTALL_DIR/config/info.txt"

echo -e "${YELLOW}📁 Instalación en: $INSTALL_DIR${NC}"
read -p "$(echo -e "${YELLOW}¿Continuar? (s/N): ${NC}")" -n 1 -r
echo
if [[ ! $REPLY =~ ^[Ss]$ ]]; then
    echo -e "${RED}❌ Cancelado${NC}"
    exit 0
fi

# ================================================
# LIMPIEZA TOTAL
# ================================================
echo -e "\n${CYAN}${BOLD}🧹 LIMPIEZA TOTAL...${NC}"
pm2 delete sshbot-pro 2>/dev/null || true
pm2 kill 2>/dev/null || true
pkill -f chrome 2>/dev/null || true
pkill -f node 2>/dev/null || true
rm -rf "$INSTALL_DIR" "$USER_HOME" /root/.wppconnect/sshbot-pro 2>/dev/null || true
echo -e "${GREEN}✅ Limpieza completada${NC}"

# ================================================
# CREAR ESTRUCTURA (RUTAS FIJAS)
# ================================================
echo -e "\n${CYAN}📁 Creando estructura en rutas fijas...${NC}"
mkdir -p "$INSTALL_DIR"/{data,config,sessions,logs,qr_codes,scripts,backups}
mkdir -p "$USER_HOME"
mkdir -p /root/.wppconnect/sshbot-pro
chmod -R 755 "$INSTALL_DIR"
chmod -R 700 /root/.wppconnect/sshbot-pro

# Crear enlace simbólico para compatibilidad
ln -sf "$INSTALL_DIR" "$USER_HOME"

echo -e "${GREEN}✅ Estructura creada${NC}"
echo -e "   • ${CYAN}$INSTALL_DIR${NC} (directorio principal)"
echo -e "   • ${CYAN}$USER_HOME${NC} (enlace simbólico)"
echo -e "   • ${CYAN}/root/.wppconnect/sshbot-pro${NC} (sesiones)"

# ================================================
# PEDIR DATOS DE CONFIGURACIÓN
# ================================================
echo -e "\n${CYAN}${BOLD}⚙️ CONFIGURANDO OPCIONES...${NC}"

read -p "📲 Link de descarga para Android: " APP_LINK
APP_LINK=${APP_LINK:-"https://www.mediafire.com/file/p8kgthxbsid7xws/MAJ/DNI_AND_FIL"}

read -p "🆘 Número de WhatsApp para representante: " SUPPORT_NUMBER
SUPPORT_NUMBER=${SUPPORT_NUMBER:-"543435071016"}

echo -e "\n${YELLOW}💰 CONFIGURACIÓN DE PRECIOS (ARS):${NC}"
read -p "Precio 7 días (3000): " PRICE_7D
PRICE_7D=${PRICE_7D:-3000}
read -p "Precio 15 días (4000): " PRICE_15D
PRICE_15D=${PRICE_15D:-4000}
read -p "Precio 30 días (7000): " PRICE_30D
PRICE_30D=${PRICE_30D:-7000}
read -p "Precio 50 días (9700): " PRICE_50D
PRICE_50D=${PRICE_50D:-9700}

read -p "⏰ Horas de prueba gratis (2): " TEST_HOURS
TEST_HOURS=${TEST_HOURS:-2}

# Detectar IP
SERVER_IP=$(curl -4 -s --max-time 10 ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')
SERVER_IP=${SERVER_IP:-"127.0.0.1"}
echo -e "${GREEN}✅ IP detectada: $SERVER_IP${NC}"

# ================================================
# TEXTO DE INFORMACIÓN
# ================================================
cat > "$INFO_FILE" << 'EOF'
🔥 INTERNET ILIMITADO ⚡📱

Es una aplicación que te permite conectar y navegar en internet de manera ilimitada/infinita. Sin necesidad de tener saldo/crédito o MG/GB.

📢 Te ofrecemos internet Ilimitado para la empresa PERSONAL, tanto ABONO como PREPAGO a través de nuestra aplicación!

❓ Cómo funciona? Instalamos y configuramos nuestra app para que tengas acceso al servicio, una vez instalada puedes usar todo el internet que quieras sin preocuparte por tus datos!

📲 Probamos que todo funcione correctamente para que recién puedas abonar vía transferencia!

⚙️ Tienes soporte técnico por los 30 días que contrates por cualquier inconveniente! 

⚠️ Nos hacemos cargo de cualquier problema!
EOF

# ================================================
# CONFIG.JSON (CON NOMBRE SOLO VISUAL)
# ================================================
cat > "$CONFIG_FILE" << EOF
{
    "bot": {
        "name": "$BOT_NAME",
        "version": "5.0-REVENDEDORES",
        "server_ip": "$SERVER_IP",
        "default_password": "12345",
        "test_hours": $TEST_HOURS,
        "info_file": "$INFO_FILE",
        "reseller_discount": 50
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
        "sessions": "/root/.wppconnect/sshbot-pro"
    }
}
EOF

# ================================================
# BASE DE DATOS (CON TABLAS DE REVENDEDORES)
# ================================================
echo -e "\n${CYAN}🗄️ Creando base de datos...${NC}"
sqlite3 "$DB_FILE" << 'SQL'
-- Tablas originales
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
    connections INTEGER DEFAULT 1,
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

-- NUEVA TABLA: Revendedores
CREATE TABLE resellers (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    phone TEXT UNIQUE NOT NULL,
    code TEXT UNIQUE NOT NULL,
    discount INTEGER DEFAULT 50,
    total_sales INTEGER DEFAULT 0,
    is_active INTEGER DEFAULT 1,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- NUEVA TABLA: Ventas de revendedores
CREATE TABLE reseller_sales (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    reseller_phone TEXT,
    client_phone TEXT,
    plan_days INTEGER,
    amount REAL,
    discount_applied INTEGER,
    username TEXT,
    sold_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Índices
CREATE INDEX idx_users_phone ON users(phone);
CREATE INDEX idx_users_status ON users(status);
CREATE INDEX idx_payments_status ON payments(status);
CREATE INDEX idx_payments_preference ON payments(preference_id);
CREATE INDEX idx_resellers_code ON resellers(code);
CREATE INDEX idx_reseller_sales_reseller ON reseller_sales(reseller_phone);
SQL
echo -e "${GREEN}✅ Base de datos creada${NC}"

# ================================================
# INSTALAR DEPENDENCIAS DEL SISTEMA
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
    unzip cron ufw sshpass openssh-client

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
# CREAR SCRIPT PARA CREAR USUARIOS SSH
# ================================================
cat > "$INSTALL_DIR/scripts/create_user.sh" << 'EOF'
#!/bin/bash
# Script para crear usuario SSH localmente

USERNAME=$1
PASSWORD=$2
DAYS=$3

# Calcular fecha de expiración
if [[ "$DAYS" == "test" ]]; then
    EXPIRE_DATE=$(date -d "+2 hours" +%Y-%m-%d)
else
    EXPIRE_DATE=$(date -d "+$DAYS days" +%Y-%m-%d)
fi

# Crear usuario local
useradd -m -s /bin/bash $USERNAME 2>/dev/null
echo "$USERNAME:$PASSWORD" | chpasswd 2>/dev/null
chage -E $EXPIRE_DATE $USERNAME 2>/dev/null
mkdir -p /home/$USERNAME/.ssh 2>/dev/null
chown $USERNAME:$USERNAME /home/$USERNAME/.ssh 2>/dev/null
chmod 700 /home/$USERNAME/.ssh 2>/dev/null

echo "Usuario $USERNAME creado (expira: $EXPIRE_DATE)"
exit 0
EOF

chmod +x "$INSTALL_DIR/scripts/create_user.sh"

# ================================================
# INSTALAR MÓDULOS NODE
# ================================================
echo -e "\n${CYAN}📦 Instalando módulos de Node.js...${NC}"
cd "$INSTALL_DIR"

cat > package.json << 'PKGEOF'
{
    "name": "sshbot-pro",
    "version": "5.0.0",
    "main": "bot.js",
    "dependencies": {
        "@wppconnect-team/wppconnect": "^1.24.0",
        "qrcode-terminal": "^0.12.0",
        "qrcode": "^1.5.3",
        "moment": "^2.30.1",
        "sqlite3": "^5.1.6",
        "express": "^4.18.2",
        "mercadopago": "^2.0.0"
    }
}
PKGEOF

npm install

# ================================================
# CREAR ARCHIVO PRINCIPAL DEL BOT (bot.js)
# ================================================
cat > "$INSTALL_DIR/bot.js" << 'BOTEOF'
const wppconnect = require('@wppconnect-team/wppconnect');
const qrcode = require('qrcode-terminal');
const fs = require('fs');
const sqlite3 = require('sqlite3').verbose();
const moment = require('moment');
const { exec } = require('child_process');
const util = require('util');
const execPromise = util.promisify(exec);

// Configuración
const config = JSON.parse(fs.readFileSync('/opt/sshbot-pro/config/config.json', 'utf8'));
const db = new sqlite3.Database(config.paths.database);

// Cache de revendedores
let resellersCache = new Map();

// Actualizar cache de revendedores
function updateResellersCache() {
    db.all("SELECT phone, code, discount FROM resellers WHERE is_active = 1", [], (err, rows) => {
        if (!err) {
            resellersCache.clear();
            rows.forEach(r => resellersCache.set(r.code, { phone: r.phone, discount: r.discount }));
            console.log(`📱 Revendedores en cache: ${resellersCache.size}`);
        }
    });
}

setInterval(updateResellersCache, 300000);
updateResellersCache();

// ================================================
// FUNCIONES DE REVENDEDORES
// ================================================

function validateResellerCode(code) {
    const reseller = resellersCache.get(code);
    if (reseller) {
        return { valid: true, phone: reseller.phone, discount: reseller.discount };
    }
    return { valid: false };
}

function registerResellerSale(resellerPhone, clientPhone, planDays, amount, discount, username) {
    db.run(`
        INSERT INTO reseller_sales (reseller_phone, client_phone, plan_days, amount, discount_applied, username)
        VALUES (?, ?, ?, ?, ?, ?)
    `, [resellerPhone, clientPhone, planDays, amount, discount, username]);
    
    db.run("UPDATE resellers SET total_sales = total_sales + 1 WHERE phone = ?", [resellerPhone]);
}

// ================================================
// FUNCIONES DE USUARIOS SSH
// ================================================

async function createSSHUser(phone, days, tipo = 'user') {
    return new Promise(async (resolve, reject) => {
        try {
            const username = `user${Date.now().toString().slice(-6)}j`;
            const password = '12345';
            
            const expiresAt = moment().add(days === 'test' ? 2 : days * 24, 'hours').format('YYYY-MM-DD HH:mm:ss');
            
            // Ejecutar script de creación
            const cmd = `bash /opt/sshbot-pro/scripts/create_user.sh ${username} ${password} ${days === 'test' ? 'test' : days}`;
            await execPromise(cmd);
            
            db.run(`
                INSERT INTO users (username, password, phone, tipo, expires_at)
                VALUES (?, ?, ?, ?, ?)
            `, [username, password, phone, tipo, expiresAt]);
            
            resolve({ username, password, expires: expiresAt });
        } catch (error) {
            reject(error);
        }
    });
}

// ================================================
// FUNCIONES DE ESTADO
// ================================================

function getUserState(phone) {
    return new Promise((resolve) => {
        db.get("SELECT state, data FROM user_state WHERE phone = ?", [phone], (err, row) => {
            if (row) {
                resolve({ state: row.state, data: row.data ? JSON.parse(row.data) : null });
            } else {
                resolve({ state: 'main_menu', data: null });
            }
        });
    });
}

function setUserState(phone, state, data = null) {
    db.run(`
        INSERT INTO user_state (phone, state, data, updated_at)
        VALUES (?, ?, ?, CURRENT_TIMESTAMP)
        ON CONFLICT(phone) DO UPDATE SET
            state = excluded.state,
            data = excluded.data,
            updated_at = CURRENT_TIMESTAMP
    `, [phone, state, data ? JSON.stringify(data) : null]);
}

// ================================================
// INICIAR BOT
// ================================================
wppconnect.create({
    session: 'sshbot-pro',
    headless: true,
    useChrome: true,
    browserArgs: ['--no-sandbox', '--disable-setuid-sandbox'],
    folderNameToken: config.paths.sessions
}).then(client => start(client)).catch(err => console.log(err));

function start(client) {
    console.log('\n✅ BOT SSH PRO v5.0 INICIADO');
    console.log(`📱 Nombre visual: ${config.bot.name}`);
    console.log(`💰 Descuento revendedores: ${config.bot.reseller_discount}%`);
    console.log(`📁 Rutas fijas: /opt/sshbot-pro y /root/sshbot-pro\n`);
    
    client.on('qr', (qr) => {
        console.log('📱 ESCANEA EL QR:\n');
        qrcode.generate(qr, { small: true });
        console.log('\n');
    });
    
    client.onMessage(async (message) => {
        if (message.isGroupMsg) return;
        
        const phone = message.from;
        const text = message.body.trim();
        
        console.log(`📨 Mensaje de ${phone}: ${text}`);
        
        const { state, data } = await getUserState(phone);
        
        // ================================================
        // MENÚ PRINCIPAL (CON NUEVA OPCIÓN 7)
        // ================================================
        if (text === '1' && state === 'main_menu') {
            await handleTest(client, phone);
        }
        else if (text === '2' && state === 'main_menu') {
            await showPlans(client, phone);
        }
        else if (text === '3' && state === 'main_menu') {
            await myAccounts(client, phone);
        }
        else if (text === '4' && state === 'main_menu') {
            await paymentStatus(client, phone);
        }
        else if (text === '5' && state === 'main_menu') {
            await downloadApp(client, phone);
        }
        else if (text === '6' && state === 'main_menu') {
            await support(client, phone);
        }
        // ================================================
        // NUEVA OPCIÓN 7: REVENDEDORES
        // ================================================
        else if (text === '7' && state === 'main_menu') {
            setUserState(phone, 'awaiting_reseller_code');
            await client.sendText(phone, `🎫 *MODO REVENDEDOR*\n\nIngresa tu *CÓDIGO DE REVENDEDOR* para acceder a los planes con ${config.bot.reseller_discount}% de descuento:`);
        }
        // ================================================
        // FLUJO DE REVENDEDOR
        // ================================================
        else if (state === 'awaiting_reseller_code') {
            const validation = validateResellerCode(text);
            if (validation.valid) {
                setUserState(phone, 'reseller_menu', { 
                    resellerPhone: validation.phone,
                    discount: validation.discount
                });
                await showResellerPlans(client, phone, validation.discount);
            } else {
                await client.sendText(phone, '❌ *CÓDIGO INVÁLIDO*\n\nEl código ingresado no es válido. Intenta de nuevo o envía 0 para volver al menú principal.');
            }
        }
        else if (state === 'reseller_menu') {
            if (text === '0') {
                setUserState(phone, 'main_menu');
                await showMainMenu(client, phone);
            }
            else if (['1','2','3','4'].includes(text)) {
                setUserState(phone, 'reseller_confirm', {
                    ...data,
                    selectedPlan: text
                });
                await confirmResellerPlan(client, phone, text, data.discount);
            }
            else {
                await client.sendText(phone, '❌ Opción no válida. Elige un número del 1 al 4 o 0 para volver.');
            }
        }
        else if (state === 'reseller_confirm') {
            if (text.toLowerCase() === 'si') {
                await processResellerPurchase(client, phone, data);
            }
            else if (text.toLowerCase() === 'no') {
                setUserState(phone, 'reseller_menu', {
                    resellerPhone: data.resellerPhone,
                    discount: data.discount
                });
                await showResellerPlans(client, phone, data.discount);
            }
            else {
                await client.sendText(phone, '❌ Responde *SI* para confirmar o *NO* para cancelar.');
            }
        }
        // ================================================
        // VOLVER AL MENÚ PRINCIPAL
        // ================================================
        else if (text === '0') {
            setUserState(phone, 'main_menu');
            await showMainMenu(client, phone);
        }
        else {
            setUserState(phone, 'main_menu');
            await showMainMenu(client, phone);
        }
    });
}

// ================================================
// FUNCIONES DEL MENÚ
// ================================================

async function showMainMenu(client, phone) {
    const menu = `╭━━━ *${config.bot.name}* ━━━╮
┃
┃ 1️⃣ *PRUEBA GRATIS*
┃ 2️⃣ *VER PLANES*
┃ 3️⃣ *MIS CUENTAS*
┃ 4️⃣ *ESTADO DE PAGO*
┃ 5️⃣ *DESCARGAR APP*
┃ 6️⃣ *SOPORTE*
┃ 7️⃣ *🎫 SOY REVENDEDOR*
┃
╰━━━━━━━━━━━━━━━━╯
    
Responde el *NÚMERO* de la opción que deseas.`;
    
    await client.sendText(phone, menu);
}

async function showResellerPlans(client, phone, discount) {
    const menu = `╭━━━ *PLANES CON ${discount}% DCTO* ━━━╮
┃
┃ 1️⃣ *7 DÍAS* 
┃    💰 Normal: $${config.prices.price_7d}
┃    🏷️  Tu precio: $${config.prices.price_7d * (100-discount)/100}
┃
┃ 2️⃣ *15 DÍAS*
┃    💰 Normal: $${config.prices.price_15d}
┃    🏷️  Tu precio: $${config.prices.price_15d * (100-discount)/100}
┃
┃ 3️⃣ *30 DÍAS*
┃    💰 Normal: $${config.prices.price_30d}
┃    🏷️  Tu precio: $${config.prices.price_30d * (100-discount)/100}
┃
┃ 4️⃣ *50 DÍAS*
┃    💰 Normal: $${config.prices.price_50d}
┃    🏷️  Tu precio: $${config.prices.price_50d * (100-discount)/100}
┃
┃ 0️⃣ *VOLVER AL MENÚ PRINCIPAL*
┃
╰━━━━━━━━━━━━━━━━╯
    
Elige el *NÚMERO* del plan que deseas comprar:`;
    
    await client.sendText(phone, menu);
}

async function confirmResellerPlan(client, phone, planNumber, discount) {
    const plans = {
        '1': { days: 7, price: config.prices.price_7d, name: '7 días' },
        '2': { days: 15, price: config.prices.price_15d, name: '15 días' },
        '3': { days: 30, price: config.prices.price_30d, name: '30 días' },
        '4': { days: 50, price: config.prices.price_50d, name: '50 días' }
    };
    
    const plan = plans[planNumber];
    const finalPrice = plan.price * (100 - discount) / 100;
    
    const msg = `╭━━━ *CONFIRMAR COMPRA* ━━━╮
┃
┃ 📦 *Plan:* ${plan.name}
┃ 💰 *Precio original:* $${plan.price}
┃ 🎫 *Descuento:* ${discount}%
┃ 🏷️  *Precio final:* $${finalPrice}
┃
┃ ¿Confirmar la compra?
┃
┃ *SI* - Confirmar
┃ *NO* - Cancelar
┃
╰━━━━━━━━━━━━━━━━╯`;
    
    await client.sendText(phone, msg);
}

async function processResellerPurchase(client, phone, data) {
    const plans = {
        '1': { days: 7, price: config.prices.price_7d },
        '2': { days: 15, price: config.prices.price_15d },
        '3': { days: 30, price: config.prices.price_30d },
        '4': { days: 50, price: config.prices.price_50d }
    };
    
    const plan = plans[data.selectedPlan];
    const finalPrice = plan.price * (100 - data.discount) / 100;
    
    try {
        await client.sendText(phone, '⏳ *CREANDO TU CUENTA...*\n\nPor favor espera unos segundos.');
        
        const user = await createSSHUser(phone, plan.days, 'user');
        
        // Registrar venta del revendedor
        registerResellerSale(
            data.resellerPhone,
            phone,
            plan.days,
            finalPrice,
            data.discount,
            user.username
        );
        
        const msg = `✅ *¡CUENTA CREADA CON ÉXITO!*

╭━━━ *DATOS DE ACCESO* ━━━╮
┃
┃ 👤 *Usuario:* \`${user.username}\`
┃ 🔑 *Contraseña:* \`${user.password}\`
┃ 🌐 *Servidor:* ${config.bot.server_ip}
┃ ⏱️ *Expira:* ${moment(user.expires).format('DD/MM/YYYY HH:mm')}
┃
┃ 💰 *Total pagado:* $${finalPrice}
┃
╰━━━━━━━━━━━━━━━━╯

📲 *DESCARGAR APP:* 
${config.links.app_android}`;
        
        await client.sendText(phone, msg);
        setUserState(phone, 'main_menu');
        
    } catch (error) {
        await client.sendText(phone, '❌ *ERROR*\n\nNo se pudo crear la cuenta. Contacta a soporte.');
        setUserState(phone, 'main_menu');
    }
}

// ================================================
// FUNCIONES ORIGINALES
// ================================================

async function handleTest(client, phone) {
    const today = moment().format('YYYY-MM-DD');
    
    db.get("SELECT * FROM daily_tests WHERE phone = ? AND date = ?", [phone, today], async (err, row) => {
        if (row) {
            await client.sendText(phone, '❌ Ya usaste tu prueba gratis hoy. Vuelve mañana o adquiere un plan.');
        } else {
            try {
                const user = await createSSHUser(phone, 'test', 'test');
                db.run("INSERT INTO daily_tests (phone, date) VALUES (?, ?)", [phone, today]);
                
                await client.sendText(phone, `✅ *PRUEBA GRATIS ACTIVADA*

👤 Usuario: \`${user.username}\`
🔑 Contraseña: \`${user.password}\`
⏱️ Duración: ${config.bot.test_hours} horas

📲 APP: ${config.links.app_android}`);
            } catch (err) {
                await client.sendText(phone, '❌ Error al crear la prueba.');
            }
        }
    });
}

async function showPlans(client, phone) {
    const msg = `╭━━━ *PLANES DISPONIBLES* ━━━╮
┃
┃ 1️⃣ *7 DÍAS* - $${config.prices.price_7d}
┃ 2️⃣ *15 DÍAS* - $${config.prices.price_15d}
┃ 3️⃣ *30 DÍAS* - $${config.prices.price_30d}
┃ 4️⃣ *50 DÍAS* - $${config.prices.price_50d}
┃
╰━━━━━━━━━━━━━━━━╯

💰 *MEDIOS DE PAGO:* MercadoPago / Transferencia
💬 Contacta a soporte para comprar: ${config.links.support}`;
    
    await client.sendText(phone, msg);
}

async function myAccounts(client, phone) {
    db.all("SELECT username, expires_at FROM users WHERE phone = ? AND status = 1 ORDER BY created_at DESC LIMIT 5", [phone], async (err, rows) => {
        if (rows && rows.length > 0) {
            let msg = "📋 *TUS CUENTAS ACTIVAS*\n\n";
            rows.forEach((row, i) => {
                msg += `${i+1}. 👤 ${row.username}\n   ⏱️ Exp: ${moment(row.expires_at).format('DD/MM/YYYY')}\n\n`;
            });
            await client.sendText(phone, msg);
        } else {
            await client.sendText(phone, '📭 No tienes cuentas activas.');
        }
    });
}

async function paymentStatus(client, phone) {
    await client.sendText(phone, '💰 *ESTADO DE PAGOS*\n\nPróximamente disponible con MercadoPago.');
}

async function downloadApp(client, phone) {
    await client.sendText(phone, `📲 *DESCARGAR APP*

Link directo:
${config.links.app_android}

⚠️ *INSTRUCCIONES:*
1. Descarga e instala la app
2. Abre la app y acepta permisos
3. Ingresa con tu usuario y contraseña
4. Conecta y disfruta internet ilimitado`);
}

async function support(client, phone) {
    await client.sendText(phone, `🆘 *SOPORTE TÉCNICO*

Si tienes problemas, contacta a nuestro representante:
${config.links.support}

⏰ Horario de atención: 24/7`);
}
BOTEOF

# ================================================
# CREAR MENÚ DE ADMINISTRACIÓN EN VPS (sshbot)
# ================================================
cat > /usr/local/bin/sshbot << 'SSHBOTEOF'
#!/bin/bash
# ================================================
# MENÚ DE ADMINISTRACIÓN SSH BOT PRO v5.0
# ================================================

DB_FILE="/opt/sshbot-pro/data/users.db"
CONFIG_FILE="/opt/sshbot-pro/config/config.json"
INSTALL_DIR="/opt/sshbot-pro"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}❌ Debes ejecutar como root${NC}"
    exit 1
fi

mostrar_menu() {
    clear
    echo "================================================"
    echo "   SSH BOT PRO v5.0 - ADMINISTRACIÓN           "
    echo "================================================"
    echo ""
    echo " 1) Gestionar Revendedores"
    echo " 2) Listar Revendedores"
    echo " 3) Agregar Revendedor"
    echo " 4) Generar Código para Revendedor"
    echo " 5) Ver Ventas por Revendedor"
    echo " 6) Ver Estadísticas Generales"
    echo " 7) Ver Usuarios Activos"
    echo " 8) Ver Logs del Bot"
    echo " 9) Reiniciar Bot"
    echo "10) Ver QR de Conexión"
    echo "11) Configurar Precios"
    echo "12) Hacer Backup"
    echo "13) Restaurar Backup"
    echo " 0) Salir"
    echo ""
    echo "================================================"
}

listar_revendedores() {
    echo ""
    echo "📱 REVENDEDORES REGISTRADOS:"
    echo "----------------------------"
    echo ""
    sqlite3 "$DB_FILE" "SELECT id, phone, code, total_sales, CASE WHEN is_active=1 THEN 'ACTIVO' ELSE 'INACTIVO' END FROM resellers ORDER BY total_sales DESC;"
    echo ""
    read -p "Presiona Enter para continuar..."
}

agregar_revendedor() {
    echo ""
    echo "➕ NUEVO REVENDEDOR"
    echo "------------------"
    read -p "Número de WhatsApp (ej: 5493813414485): " phone
    # Generar código aleatorio de 6 caracteres
    code=$(tr -dc 'A-Z0-9' < /dev/urandom | fold -w 6 | head -n 1)
    
    sqlite3 "$DB_FILE" "INSERT INTO resellers (phone, code) VALUES ('$phone', '$code');"
    echo -e "${GREEN}✅ Revendedor agregado con código: $code${NC}"
    echo ""
    echo "Reiniciando bot para aplicar cambios..."
    pm2 restart sshbot-pro > /dev/null 2>&1
    echo ""
    read -p "Presiona Enter para continuar..."
}

generar_codigo() {
    echo ""
    read -p "Número del revendedor: " phone
    newcode=$(tr -dc 'A-Z0-9' < /dev/urandom | fold -w 6 | head -n 1)
    sqlite3 "$DB_FILE" "UPDATE resellers SET code='$newcode' WHERE phone='$phone';"
    echo -e "${GREEN}✅ Nuevo código: $newcode${NC}"
    echo ""
    echo "Reiniciando bot para aplicar cambios..."
    pm2 restart sshbot-pro > /dev/null 2>&1
    echo ""
    read -p "Presiona Enter para continuar..."
}

ver_ventas() {
    echo ""
    read -p "Número del revendedor: " phone
    echo ""
    echo "📊 VENTAS DEL REVENDEDOR $phone"
    echo "-------------------------------"
    echo ""
    sqlite3 "$DB_FILE" "SELECT client_phone, plan_days, amount, username, sold_at FROM reseller_sales WHERE reseller_phone='$phone' ORDER BY sold_at DESC LIMIT 10;"
    echo ""
    read -p "Presiona Enter para continuar..."
}

ver_estadisticas() {
    total_resellers=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM resellers WHERE is_active=1;")
    total_sales=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM reseller_sales;")
    total_users=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM users;")
    active_users=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM users WHERE status=1 AND expires_at > datetime('now');")
    total_tests=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM users WHERE tipo='test';")
    
    echo ""
    echo "📊 ESTADÍSTICAS GENERALES"
    echo "-------------------------"
    echo ""
    echo "📱 Revendedores activos: $total_resellers"
    echo "💰 Ventas totales: $total_sales"
    echo "👥 Usuarios totales: $total_users"
    echo "✅ Usuarios activos: $active_users"
    echo "🎁 Pruebas gratis: $total_tests"
    echo ""
    read -p "Presiona Enter para continuar..."
}

ver_usuarios() {
    echo ""
    echo "👥 USUARIOS ACTIVOS"
    echo "-------------------"
    echo ""
    sqlite3 "$DB_FILE" "SELECT username, phone, expires_at FROM users WHERE status=1 AND expires_at > datetime('now') ORDER BY expires_at ASC LIMIT 20;"
    echo ""
    read -p "Presiona Enter para continuar..."
}

ver_logs() {
    clear
    echo "📋 LOGS DEL BOT (últimas 30 líneas)"
    echo "------------------------------------"
    echo ""
    pm2 logs sshbot-pro --lines 30 --nostream
    echo ""
    read -p "Presiona Enter para continuar..."
}

reiniciar_bot() {
    echo ""
    echo "Reiniciando bot..."
    pm2 restart sshbot-pro
    echo -e "${GREEN}✅ Bot reiniciado${NC}"
    sleep 2
}

ver_qr() {
    clear
    echo "📱 QR DE CONEXIÓN WHATSAPP"
    echo "--------------------------"
    echo ""
    echo "Buscando QR en los logs..."
    echo ""
    pm2 logs sshbot-pro --lines 50 --nostream | grep -A 15 "QR" || echo "No se encontró QR. Espera a que el bot genere uno."
    echo ""
    read -p "Presiona Enter para continuar..."
}

configurar_precios() {
    nano "$CONFIG_FILE"
    echo ""
    echo "Reiniciando bot para aplicar cambios..."
    pm2 restart sshbot-pro
    echo -e "${GREEN}✅ Bot reiniciado${NC}"
    sleep 2
}

hacer_backup() {
    echo ""
    echo "📦 CREANDO BACKUP..."
    echo "-------------------"
    mkdir -p /opt/sshbot-pro/backups
    backup_file="/opt/sshbot-pro/backups/backup_$(date +%Y%m%d_%H%M%S).tar.gz"
    tar -czf "$backup_file" -C /opt/sshbot-pro data config 2>/dev/null
    echo -e "${GREEN}✅ Backup creado: $backup_file${NC}"
    echo ""
    read -p "Presiona Enter para continuar..."
}

restaurar_backup() {
    echo ""
    echo "📂 BACKUPS DISPONIBLES:"
    echo "-----------------------"
    ls -lh /opt/sshbot-pro/backups/ | grep tar.gz
    echo ""
    read -p "Nombre del archivo de backup a restaurar: " backup
    if [ -f "/opt/sshbot-pro/backups/$backup" ]; then
        echo "Restaurando backup..."
        tar -xzf "/opt/sshbot-pro/backups/$backup" -C /opt/sshbot-pro 2>/dev/null
        echo -e "${GREEN}✅ Backup restaurado${NC}"
        echo "Reiniciando bot..."
        pm2 restart sshbot-pro
        echo -e "${GREEN}✅ Bot reiniciado${NC}"
    else
        echo -e "${RED}❌ Archivo no encontrado${NC}"
    fi
    echo ""
    read -p "Presiona Enter para continuar..."
}

# Menú principal
while true; do
    mostrar_menu
    read -p "Selecciona una opción: " opcion
    
    case $opcion in
        1|2) listar_revendedores ;;
        3) agregar_revendedor ;;
        4) generar_codigo ;;
        5) ver_ventas ;;
        6) ver_estadisticas ;;
        7) ver_usuarios ;;
        8) ver_logs ;;
        9) reiniciar_bot ;;
        10) ver_qr ;;
        11) configurar_precios ;;
        12) hacer_backup ;;
        13) restaurar_backup ;;
        0) 
            clear
            echo "================================================"
            echo "              ¡HASTA LUEGO!                    "
            echo "================================================"
            exit 0
            ;;
        *)
            echo "❌ Opción no válida"
            sleep 2
            ;;
    esac
done
SSHBOTEOF

chmod +x /usr/local/bin/sshbot

# ================================================
# CONFIGURAR CRON Y PM2
# ================================================
echo -e "\n${CYAN}${BOLD}⚙️ CONFIGURANDO SERVICIOS...${NC}"

# Script de limpieza
cat > "$INSTALL_DIR/scripts/cleanup.sh" << 'EOF'
#!/bin/bash
DB_FILE="/opt/sshbot-pro/data/users.db"
sqlite3 "$DB_FILE" "UPDATE users SET status=0 WHERE expires_at < datetime('now');"
find /root/.wppconnect -type f -mtime +7 -delete 2>/dev/null
echo "$(date): Limpieza completada" >> /opt/sshbot-pro/logs/cleanup.log
EOF

chmod +x "$INSTALL_DIR/scripts/cleanup.sh"

# Cron jobs
echo "*/15 * * * * root /opt/sshbot-pro/scripts/cleanup.sh" > /etc/cron.d/sshbot-cleanup
echo "0 3 * * * root tar -czf /opt/sshbot-pro/backups/backup-\$(date +\%Y\%m\%d).tar.gz -C /opt/sshbot-pro data config 2>/dev/null" >> /etc/cron.d/sshbot-cleanup

# Iniciar con PM2
cd "$INSTALL_DIR"
pm2 start bot.js --name sshbot-pro
pm2 save
pm2 startup

# ================================================
# CREAR REVENDEDORES DE EJEMPLO
# ================================================
echo -e "\n${YELLOW}🎫 Creando revendedores de ejemplo...${NC}"
CODE1=$(tr -dc 'A-Z0-9' < /dev/urandom | fold -w 6 | head -n 1)
CODE2=$(tr -dc 'A-Z0-9' < /dev/urandom | fold -w 6 | head -n 1)

sqlite3 "$DB_FILE" "INSERT INTO resellers (phone, code) VALUES ('5493813414485', '$CODE1');"
sqlite3 "$DB_FILE" "INSERT INTO resellers (phone, code) VALUES ('5493815123456', '$CODE2');"

# ================================================
# MOSTRAR INFORMACIÓN FINAL
# ================================================
clear
echo -e "${GREEN}${BOLD}"
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                                                              ║"
echo "║         ✅ INSTALACIÓN COMPLETADA EXITOSAMENTE              ║"
echo "║                                                              ║"
echo "╠══════════════════════════════════════════════════════════════╣"
echo "║                                                              ║"
echo "║  📱 NOMBRE VISUAL:                                          ║"
echo "║     ${CYAN}$BOT_NAME${GREEN}                                          ║"
echo "║                                                              ║"
echo "║  📁 RUTAS FIJAS (NO CAMBIAN):                                ║"
echo "║     • Principal: ${CYAN}/opt/sshbot-pro${GREEN}                        ║"
echo "║     • Usuario:   ${CYAN}/root/sshbot-pro${GREEN} (enlace simbólico)   ║"
echo "║     • Sesiones:  ${CYAN}/root/.wppconnect/sshbot-pro${GREEN}           ║"
echo "║                                                              ║"
echo "║  🎫 REVENDEDORES DE EJEMPLO:                                 ║"
echo "║     • Revendedor 1 - Código: ${YELLOW}$CODE1${GREEN}                   ║"
echo "║     • Revendedor 2 - Código: ${YELLOW}$CODE2${GREEN}                   ║"
echo "║                                                              ║"
echo "║  🖥️  COMANDO DE ADMINISTRACIÓN:                               ║"
echo "║     ${CYAN}sshbot${GREEN}                                                ║"
echo "║                                                              ║"
echo "║  📱 NUEVA OPCIÓN EN WHATSAPP:                                ║"
echo "║     • Opción ${YELLOW}7${GREEN} - SOY REVENDEDOR                         ║"
echo "║     • Ingresa el código para 50% descuento                  ║"
echo "║                                                              ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Mostrar QR
echo -e "\n${YELLOW}📱 ESPERANDO QR DE WHATSAPP...${NC}"
sleep 5
pm2 logs sshbot-pro --lines 20 --nostream | grep -A 10 "QR" || echo -e "${CYAN}Ejecuta 'sshbot' y opción 10 para ver el QR${NC}"
echo ""

exit 0
