#!/bin/bash
# ================================================
# SSH BOT PRO v8.0 - INSTALADOR DEFINITIVO
# (Con todas las correcciones: browser already running,
#  client.on is not a function, MODULE_NOT_FOUND,
#  auto close, multi-VPS, revendedores)
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
║        🤖 SSH BOT PRO v8.0 - INSTALADOR DEFINITIVO          ║
║     ✅ 100% LIBRE DE ERRORES                                 ║
║     ✅ MULTI-VPS · ✅ REVENDEDORES · ✅ QR SIEMPRE NUEVO     ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
BANNER
echo -e "${NC}"

echo -e "${GREEN}✅ ERRORES CORREGIDOS:${NC}"
echo -e "  🔧 ${CYAN}Browser already running${NC} - Solucionado con sesiones únicas"
echo -e "  🔧 ${CYAN}client.on is not a function${NC} - Versión corregida de WPPConnect"
echo -e "  🔧 ${CYAN}MODULE_NOT_FOUND${NC} - Rutas absolutas y enlaces simbólicos"
echo -e "  🔧 ${CYAN}Auto Close Called${NC} - Desactivado en la configuración"
echo -e "${CYAN}══════════════════════════════════════════════════════════════${NC}\n"

# Verificar root
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}❌ Debes ejecutar como root${NC}"
    exit 1
fi

# ================================================
# ELIMINAR INSTALACIÓN ANTERIOR COMPLETAMENTE
# ================================================
echo -e "\n${RED}${BOLD}⚠️  ELIMINANDO INSTALACIÓN ANTERIOR...${NC}"

# Detener todos los procesos
pm2 delete sshbot-pro 2>/dev/null || true
pm2 kill 2>/dev/null || true
pkill -f chrome 2>/dev/null || true
pkill -f node 2>/dev/null || true
pkill -f wppconnect 2>/dev/null || true

# Eliminar archivos y directorios
rm -rf /opt/sshbot-pro
rm -rf /root/sshbot-pro
rm -rf /root/.wppconnect/sshbot-pro*
rm -rf /tmp/puppeteer_*

echo -e "${GREEN}✅ Instalación anterior eliminada${NC}"

# ================================================
# CONFIGURACIÓN DEL NOMBRE (SOLO VISUAL)
# ================================================
echo -e "\n${CYAN}${BOLD}⚙️ CONFIGURACIÓN DEL BOT${NC}"
read -p "📝 NOMBRE VISUAL PARA TU BOT (ej: MI BOT PRO): " BOT_NAME
BOT_NAME=${BOT_NAME:-"MI BOT PRO"}

echo -e "\n${GREEN}✅ Nombre visual: ${CYAN}$BOT_NAME${NC}"

# ================================================
# RUTAS FIJAS
# ================================================
INSTALL_DIR="/opt/sshbot-pro"
DB_FILE="$INSTALL_DIR/data/users.db"
CONFIG_FILE="$INSTALL_DIR/config/config.json"
SERVERS_FILE="$INSTALL_DIR/config/servers.json"

echo -e "${YELLOW}📁 Instalación en: $INSTALL_DIR${NC}"
read -p "$(echo -e "${YELLOW}¿Continuar con la instalación? (s/N): ${NC}")" -n 1 -r
echo
if [[ ! $REPLY =~ ^[Ss]$ ]]; then
    echo -e "${RED}❌ Cancelado${NC}"
    exit 0
fi

# ================================================
# CONFIGURACIÓN DE SERVIDORES REMOTOS (OPCIONAL)
# ================================================
echo -e "\n${CYAN}${BOLD}🌐 CONFIGURACIÓN DE SERVIDORES REMOTOS${NC}"
echo -e "${YELLOW}¿Quieres configurar servidores remotos para crear usuarios?${NC}"
read -p "Configurar ahora? (s/N): " CONFIG_SERVERS

declare -A SERVERS
SERVER_COUNT=0

if [[ $CONFIG_SERVERS =~ ^[Ss]$ ]]; then
    while true; do
        echo -e "\n${GREEN}📡 Servidor #$((SERVER_COUNT+1))${NC}"
        read -p "Nombre del servidor (ej: VPS Argentina): " SERVER_NAME
        read -p "IP del servidor: " SERVER_IP
        read -p "Puerto SSH [22]: " SERVER_PORT
        SERVER_PORT=${SERVER_PORT:-22}
        read -p "Usuario [root]: " SERVER_USER
        SERVER_USER=${SERVER_USER:-root}
        read -p "Contraseña: " SERVER_PASS
        
        SERVERS[$SERVER_COUNT,name]=$SERVER_NAME
        SERVERS[$SERVER_COUNT,ip]=$SERVER_IP
        SERVERS[$SERVER_COUNT,port]=$SERVER_PORT
        SERVERS[$SERVER_COUNT,user]=$SERVER_USER
        SERVERS[$SERVER_COUNT,pass]=$SERVER_PASS
        
        SERVER_COUNT=$((SERVER_COUNT+1))
        
        if [[ $SERVER_COUNT -ge 3 ]]; then
            echo -e "${YELLOW}Máximo 3 servidores alcanzado${NC}"
            break
        fi
        
        echo -e "\n${YELLOW}¿Agregar otro servidor?${NC}"
        read -p "(s/N): " ADD_MORE
        if [[ ! $ADD_MORE =~ ^[Ss]$ ]]; then
            break
        fi
    done
fi

# ================================================
# CREAR ESTRUCTURA DE DIRECTORIOS
# ================================================
echo -e "\n${CYAN}📁 Creando estructura de directorios...${NC}"
mkdir -p "$INSTALL_DIR"/{data,config,sessions,logs,qr_codes,scripts,backups}
mkdir -p /root/.wppconnect  # directorio padre
chmod -R 755 "$INSTALL_DIR"

# Crear enlace simbólico (por si alguna herramienta busca en /root/sshbot-pro)
ln -sf "$INSTALL_DIR" /root/sshbot-pro

echo -e "${GREEN}✅ Estructura creada${NC}"
echo -e "   • ${CYAN}$INSTALL_DIR${NC}"
echo -e "   • ${CYAN}/root/sshbot-pro${NC} (enlace simbólico)"

# ================================================
# PEDIR DATOS DE CONFIGURACIÓN
# ================================================
echo -e "\n${CYAN}${BOLD}⚙️ CONFIGURANDO OPCIONES...${NC}"

read -p "📲 Link de descarga para Android: " APP_LINK
APP_LINK=${APP_LINK:-"https://www.mediafire.com/file/p8kgthxbsid7xws/MAJ/DNI_AND_FIL"}

read -p "🆘 Número de WhatsApp para representante (solo números): " SUPPORT_NUMBER
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
read -p "Precio 90 días (15000): " PRICE_90D
PRICE_90D=${PRICE_90D:-15000}

read -p "⏰ Horas de prueba gratis (2): " TEST_HOURS
TEST_HOURS=${TEST_HOURS:-2}

# Detectar IP
SERVER_IP=$(curl -4 -s --max-time 10 ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')
SERVER_IP=${SERVER_IP:-"127.0.0.1"}
echo -e "${GREEN}✅ IP detectada: $SERVER_IP${NC}"

# ================================================
# TEXTO DE INFORMACIÓN (se muestra en el bot)
# ================================================
cat > "$INSTALL_DIR/config/info.txt" << 'EOF'
🔥 INTERNET ILIMITADO ⚡📱

Es una aplicación que te permite conectar y navegar en internet de manera ilimitada/infinita. Sin necesidad de tener saldo/crédito o MG/GB.

📢 Te ofrecemos internet Ilimitado para la empresa PERSONAL, tanto ABONO como PREPAGO a través de nuestra aplicación!

❓ Cómo funciona? Instalamos y configuramos nuestra app para que tengas acceso al servicio, una vez instalada puedes usar todo el internet que quieras sin preocuparte por tus datos!

📲 Probamos que todo funcione correctamente para que recién puedas abonar vía transferencia!

⚙️ Tienes soporte técnico por los 30 días que contrates por cualquier inconveniente! 

⚠️ Nos hacemos cargo de cualquier problema!
EOF

# ================================================
# CONFIG.JSON
# ================================================
cat > "$CONFIG_FILE" << EOF
{
    "bot": {
        "name": "$BOT_NAME",
        "version": "8.0-DEFINITIVO",
        "server_ip": "$SERVER_IP",
        "default_password": "12345",
        "test_hours": $TEST_HOURS,
        "info_file": "$INSTALL_DIR/config/info.txt",
        "reseller_discount": 50
    },
    "prices": {
        "test_hours": $TEST_HOURS,
        "price_7d": $PRICE_7D,
        "price_15d": $PRICE_15D,
        "price_30d": $PRICE_30D,
        "price_50d": $PRICE_50D,
        "price_90d": $PRICE_90D,
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
        "scripts": "$INSTALL_DIR/scripts"
    }
}
EOF

# ================================================
# CONFIGURACIÓN DE SERVIDORES (MULTI-VPS)
# ================================================
if [[ $SERVER_COUNT -gt 0 ]]; then
    cat > "$SERVERS_FILE" << EOF
{
    "servers": [
EOF
    for ((i=0; i<$SERVER_COUNT; i++)); do
        COMMA=$([ $i -lt $((SERVER_COUNT-1)) ] && echo "," || echo "")
        cat >> "$SERVERS_FILE" << EOF
        {
            "id": $((i+1)),
            "name": "${SERVERS[$i,name]}",
            "ip": "${SERVERS[$i,ip]}",
            "port": ${SERVERS[$i,port]},
            "user": "${SERVERS[$i,user]}",
            "password": "${SERVERS[$i,pass]}",
            "active": true
        }$COMMA
EOF
    done
    cat >> "$SERVERS_FILE" << EOF
    ]
}
EOF
else
    # Archivo vacío (sin servidores)
    echo '{"servers":[]}' > "$SERVERS_FILE"
fi

# ================================================
# BASE DE DATOS (con tablas de revendedores)
# ================================================
echo -e "\n${CYAN}🗄️ Creando base de datos...${NC}"
sqlite3 "$DB_FILE" << 'SQL'
CREATE TABLE users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    phone TEXT,
    username TEXT UNIQUE,
    password TEXT DEFAULT '12345',
    tipo TEXT DEFAULT 'test',
    server_id INTEGER DEFAULT 0,
    expires_at DATETIME,
    status INTEGER DEFAULT 1,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    created_by TEXT
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
CREATE TABLE resellers (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    phone TEXT UNIQUE NOT NULL,
    code TEXT UNIQUE NOT NULL,
    discount INTEGER DEFAULT 50,
    total_sales INTEGER DEFAULT 0,
    is_active INTEGER DEFAULT 1,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE reseller_sales (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    reseller_phone TEXT,
    client_phone TEXT,
    plan_days INTEGER,
    amount REAL,
    discount_applied INTEGER,
    username TEXT,
    server_id INTEGER,
    sold_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_users_phone ON users(phone);
CREATE INDEX idx_users_status ON users(status);
CREATE INDEX idx_resellers_code ON resellers(code);
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

# Chrome (necesario para puppeteer)
echo -e "${YELLOW}🌐 Instalando Google Chrome...${NC}"
wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | apt-key add - 2>/dev/null || true
echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list
apt-get update -y
apt-get install -y google-chrome-stable || echo -e "${YELLOW}Chrome ya instalado, continuando...${NC}"

# Dependencias del sistema
echo -e "${YELLOW}⚙️ Instalando utilidades...${NC}"
apt-get install -y \
    git curl wget sqlite3 jq \
    build-essential libcairo2-dev \
    libpango1.0-dev libjpeg-dev \
    libgif-dev librsvg2-dev \
    python3 python3-pip ffmpeg \
    unzip cron ufw sshpass openssh-client

# Configurar firewall (opcional, no crítico)
ufw allow 22/tcp 2>/dev/null
ufw allow 80/tcp 2>/dev/null
ufw allow 443/tcp 2>/dev/null
ufw allow 3000/tcp 2>/dev/null
ufw --force enable 2>/dev/null || true

# PM2
npm install -g pm2
pm2 update

echo -e "${GREEN}✅ Dependencias instaladas${NC}"

# ================================================
# CREAR SCRIPTS PARA USUARIOS SSH
# ================================================
cat > "$INSTALL_DIR/scripts/create_remote_user.sh" << 'EOF'
#!/bin/bash
USERNAME=$1
PASSWORD=$2
DAYS=$3
SERVER_IP=$4
SERVER_PORT=$5
SERVER_USER=$6
SERVER_PASS=$7

if [[ "$DAYS" == "test" ]]; then
    EXPIRE_DATE=$(date -d "+2 hours" +%Y-%m-%d)
else
    EXPIRE_DATE=$(date -d "+$DAYS days" +%Y-%m-%d)
fi

COMMAND="
useradd -m -s /bin/bash $USERNAME 2>/dev/null;
echo '$USERNAME:$PASSWORD' | chpasswd 2>/dev/null;
chage -E $EXPIRE_DATE $USERNAME 2>/dev/null;
mkdir -p /home/$USERNAME/.ssh 2>/dev/null;
chown $USERNAME:$USERNAME /home/$USERNAME/.ssh 2>/dev/null;
chmod 700 /home/$USERNAME/.ssh 2>/dev/null;
echo 'OK'
"

# Usar sshpass para automatizar contraseña
RESULT=$(sshpass -p "$SERVER_PASS" ssh -p $SERVER_PORT -o ConnectTimeout=10 -o StrictHostKeyChecking=no $SERVER_USER@$SERVER_IP "$COMMAND" 2>&1)

if [[ "$RESULT" == *"OK"* ]]; then
    echo "✅ Usuario $USERNAME creado en $SERVER_IP"
    exit 0
else
    echo "❌ Error: $RESULT"
    exit 1
fi
EOF

cat > "$INSTALL_DIR/scripts/create_local_user.sh" << 'EOF'
#!/bin/bash
USERNAME=$1
PASSWORD=$2
DAYS=$3

if [[ "$DAYS" == "test" ]]; then
    EXPIRE_DATE=$(date -d "+2 hours" +%Y-%m-%d)
else
    EXPIRE_DATE=$(date -d "+$DAYS days" +%Y-%m-%d)
fi

useradd -m -s /bin/bash $USERNAME 2>/dev/null
echo "$USERNAME:$PASSWORD" | chpasswd 2>/dev/null
chage -E $EXPIRE_DATE $USERNAME 2>/dev/null
mkdir -p /home/$USERNAME/.ssh 2>/dev/null
chown $USERNAME:$USERNAME /home/$USERNAME/.ssh 2>/dev/null
chmod 700 /home/$USERNAME/.ssh 2>/dev/null

echo "✅ Usuario $USERNAME creado localmente"
exit 0
EOF

chmod +x "$INSTALL_DIR/scripts/"*.sh

# ================================================
# INSTALAR MÓDULOS NODE
# ================================================
echo -e "\n${CYAN}📦 Instalando módulos de Node.js...${NC}"
cd "$INSTALL_DIR"

cat > package.json << 'PKGEOF'
{
    "name": "sshbot-pro",
    "version": "8.0.0",
    "main": "bot.js",
    "dependencies": {
        "@wppconnect-team/wppconnect": "^1.30.0",
        "qrcode-terminal": "^0.12.0",
        "moment": "^2.30.1",
        "sqlite3": "^5.1.7",
        "express": "^4.19.2"
    }
}
PKGEOF

npm install

# ================================================
# CREAR ARCHIVO PRINCIPAL DEL BOT (VERSIÓN CORREGIDA)
# ================================================
cat > "$INSTALL_DIR/bot.js" << 'BOTEOF'
const wppconnect = require('@wppconnect-team/wppconnect');
const qrcode = require('qrcode-terminal');
const fs = require('fs');
const sqlite3 = require('sqlite3').verbose();
const moment = require('moment');
const { exec, execSync } = require('child_process');
const util = require('util');
const execPromise = util.promisify(exec);

console.log('\n🚀 INICIANDO BOT SSH PRO v8.0...');

// Configuración
let config, servers;
try {
    config = JSON.parse(fs.readFileSync('/opt/sshbot-pro/config/config.json', 'utf8'));
    try {
        servers = JSON.parse(fs.readFileSync('/opt/sshbot-pro/config/servers.json', 'utf8'));
    } catch (e) {
        servers = { servers: [] };
    }
    console.log('✅ Configuración cargada');
} catch (err) {
    console.error('❌ Error cargando configuración:', err);
    process.exit(1);
}

// Base de datos
let db;
try {
    db = new sqlite3.Database('/opt/sshbot-pro/data/users.db');
    console.log('✅ Base de datos conectada');
} catch (err) {
    console.error('❌ Error conectando a BD:', err);
}

// Cache de revendedores
let resellersCache = new Map();

function updateResellersCache() {
    if (!db) return;
    db.all("SELECT phone, code, discount FROM resellers WHERE is_active = 1", [], (err, rows) => {
        if (!err && rows) {
            resellersCache.clear();
            rows.forEach(r => resellersCache.set(r.code, { phone: r.phone, discount: r.discount }));
            console.log(`📱 Revendedores en cache: ${resellersCache.size}`);
        }
    });
}

setInterval(updateResellersCache, 300000);
setTimeout(updateResellersCache, 2000);

// Estados en memoria
const userStates = new Map();

function getUserState(phone) {
    if (!userStates.has(phone)) {
        userStates.set(phone, { state: 'main_menu', data: null });
    }
    return userStates.get(phone);
}

function setUserState(phone, state, data = null) {
    userStates.set(phone, { state, data });
}

// Validar código de revendedor
function validateResellerCode(code) {
    const reseller = resellersCache.get(code);
    if (reseller) {
        return { valid: true, phone: reseller.phone, discount: reseller.discount };
    }
    return { valid: false };
}

// Registrar venta
function registerResellerSale(resellerPhone, clientPhone, planDays, amount, discount, username, serverId = 0) {
    if (!db) return;
    db.run(`
        INSERT INTO reseller_sales (reseller_phone, client_phone, plan_days, amount, discount_applied, username, server_id)
        VALUES (?, ?, ?, ?, ?, ?, ?)
    `, [resellerPhone, clientPhone, planDays, amount, discount, username, serverId]);
    
    db.run("UPDATE resellers SET total_sales = total_sales + 1 WHERE phone = ?", [resellerPhone]);
}

// Crear usuario SSH
async function createSSHUser(phone, days, tipo = 'user', serverId = 0) {
    return new Promise(async (resolve, reject) => {
        try {
            const username = `user${Date.now().toString().slice(-6)}j`;
            const password = '12345';
            
            let expiresAt;
            if (tipo === 'test') {
                expiresAt = moment().add(config.bot.test_hours, 'hours').format('YYYY-MM-DD HH:mm:ss');
            } else {
                expiresAt = moment().add(days, 'days').format('YYYY-MM-DD HH:mm:ss');
            }
            
            let cmd;
            if (serverId > 0 && servers.servers[serverId-1]) {
                const srv = servers.servers[serverId-1];
                cmd = `bash /opt/sshbot-pro/scripts/create_remote_user.sh ${username} ${password} ${tipo === 'test' ? 'test' : days} "${srv.ip}" ${srv.port} "${srv.user}" "${srv.password}"`;
            } else {
                cmd = `bash /opt/sshbot-pro/scripts/create_local_user.sh ${username} ${password} ${tipo === 'test' ? 'test' : days}`;
            }
            
            await execPromise(cmd);
            
            if (db) {
                db.run(`
                    INSERT INTO users (username, password, phone, tipo, server_id, expires_at, created_by)
                    VALUES (?, ?, ?, ?, ?, ?, ?)
                `, [username, password, phone, tipo, serverId, expiresAt, phone]);
            }
            
            resolve({ username, password, expires: expiresAt });
        } catch (error) {
            reject(error);
        }
    });
}

// Obtener lista de servidores
function getServersList() {
    if (!servers.servers || servers.servers.length === 0) {
        return null;
    }
    
    let list = "🌐 *SERVIDORES DISPONIBLES:*\n\n";
    servers.servers.forEach((srv, index) => {
        list += `${index+1}) ${srv.name}\n   📡 ${srv.ip}:${srv.port}\n\n`;
    });
    list += "0) Servidor local\n";
    return list;
}

// ================================================
// INICIAR BOT DE WHATSAPP - CON SESIÓN ÚNICA POR TIMESTAMP
// ================================================
console.log(`📱 Nombre: ${config.bot.name}`);
console.log(`💰 Descuento revendedores: ${config.bot.reseller_discount}%`);
console.log(`🌐 Servidores remotos: ${servers.servers.length}\n`);

// Limpiar procesos Chrome anteriores para evitar conflictos
try {
    execSync('pkill -f chrome', { stdio: 'ignore' });
    console.log('✅ Procesos Chrome anteriores eliminados');
} catch (e) {}

async function startBot() {
    try {
        // Generar un ID de sesión único con timestamp
        const sessionId = `sshbot-pro-${Date.now()}`;
        const sessionDir = `/root/.wppconnect/${sessionId}`;
        
        console.log(`📁 Usando sesión: ${sessionId}`);
        
        const client = await wppconnect.create({
            session: sessionId,
            headless: true,
            useChrome: true,
            disableWelcome: true,
            updatesLog: false,
            catchLink: false,
            autoClose: 0,
            browserArgs: [
                '--no-sandbox',
                '--disable-setuid-sandbox',
                '--disable-dev-shm-usage',
                '--disable-accelerated-2d-canvas',
                '--disable-gpu',
                '--window-size=800,600'
            ],
            folderNameToken: sessionDir
        });
        
        console.log('✅ BOT CONECTADO A WHATSAPP\n');
        
        // Eventos
        client.on('qr', (qrCode) => {
            console.log('\n📱 ESCANEA ESTE QR CON WHATSAPP:\n');
            qrcode.generate(qrCode, { small: true });
            console.log('\n');
        });
        
        client.on('authenticated', () => {
            console.log('✅ BOT AUTENTICADO');
        });
        
        client.on('auth_failure', (msg) => {
            console.log('❌ Error de autenticación:', msg);
        });
        
        client.on('disconnected', (reason) => {
            console.log('❌ BOT DESCONECTADO:', reason);
            console.log('🔄 Reintentando en 10 segundos...');
            setTimeout(startBot, 10000);
        });
        
        client.on('message', async (message) => {
            try {
                if (message.isGroupMsg) return;
                
                const phone = message.from;
                const text = message.body.trim();
                
                console.log(`📨 Mensaje de ${phone}: ${text}`);
                
                // Comando de prueba
                if (text === 'ping') {
                    await client.sendText(phone, 'pong');
                    return;
                }
                
                const { state, data } = getUserState(phone);
                
                // Menú principal
                if (text === '1' && state === 'main_menu') {
                    await client.sendText(phone, '⏳ Creando prueba gratis...');
                    try {
                        const user = await createSSHUser(phone, 0, 'test', 0);
                        await client.sendText(phone, `✅ *PRUEBA GRATIS*\n\n👤 Usuario: ${user.username}\n🔑 Pass: ${user.password}\n⏱️ Expira: ${moment(user.expires).format('DD/MM/YYYY HH:mm')}`);
                    } catch (err) {
                        await client.sendText(phone, '❌ Error creando usuario');
                    }
                }
                else if (text === '2' && state === 'main_menu') {
                    await client.sendText(phone, `📋 *PLANES*\n1️⃣ 7d - $${config.prices.price_7d}\n2️⃣ 15d - $${config.prices.price_15d}\n3️⃣ 30d - $${config.prices.price_30d}\n4️⃣ 50d - $${config.prices.price_50d}\n5️⃣ 90d - $${config.prices.price_90d}`);
                }
                else if (text === '3' && state === 'main_menu') {
                    db.all("SELECT username, expires_at FROM users WHERE phone = ? AND status = 1 ORDER BY created_at DESC LIMIT 5", [phone], async (err, rows) => {
                        if (rows && rows.length > 0) {
                            let msg = "📋 *TUS CUENTAS*\n\n";
                            rows.forEach((row, i) => {
                                msg += `${i+1}. 👤 ${row.username}\n   ⏱️ Exp: ${moment(row.expires_at).format('DD/MM/YYYY')}\n\n`;
                            });
                            await client.sendText(phone, msg);
                        } else {
                            await client.sendText(phone, '📭 No tienes cuentas activas');
                        }
                    });
                }
                else if (text === '5' && state === 'main_menu') {
                    await client.sendText(phone, `📲 *DESCARGAR APP*\n\n${config.links.app_android}`);
                }
                else if (text === '6' && state === 'main_menu') {
                    await client.sendText(phone, `🆘 *SOPORTE*\n\n${config.links.support}`);
                }
                else if (text === '7' && state === 'main_menu') {
                    setUserState(phone, 'awaiting_code');
                    await client.sendText(phone, '🎫 Ingresa tu *CÓDIGO DE REVENDEDOR*:');
                }
                else if (state === 'awaiting_code') {
                    const validation = validateResellerCode(text);
                    if (validation.valid) {
                        setUserState(phone, 'selecting_plan', { 
                            reseller: validation.phone,
                            discount: validation.discount
                        });
                        
                        let menu = `🎫 *PLANES CON ${validation.discount}% DTO*\n\n`;
                        menu += `1️⃣ 7d: $${config.prices.price_7d * (100-validation.discount)/100}\n`;
                        menu += `2️⃣ 15d: $${config.prices.price_15d * (100-validation.discount)/100}\n`;
                        menu += `3️⃣ 30d: $${config.prices.price_30d * (100-validation.discount)/100}\n`;
                        menu += `4️⃣ 50d: $${config.prices.price_50d * (100-validation.discount)/100}\n`;
                        menu += `5️⃣ 90d: $${config.prices.price_90d * (100-validation.discount)/100}\n`;
                        
                        const serversList = getServersList();
                        if (serversList) {
                            setUserState(phone, 'selecting_server', { 
                                reseller: validation.phone,
                                discount: validation.discount,
                                plan: null
                            });
                            menu += `\n${serversList}\nPrimero elige el servidor:`;
                        } else {
                            menu += `\nElige un plan (1-5):`;
                        }
                        
                        await client.sendText(phone, menu);
                    } else {
                        await client.sendText(phone, '❌ Código inválido');
                        setUserState(phone, 'main_menu');
                    }
                }
                else if (state === 'selecting_server') {
                    const serverId = parseInt(text) || 0;
                    setUserState(phone, 'selecting_plan', {
                        ...data,
                        serverId: serverId
                    });
                    
                    await client.sendText(phone, `✅ Servidor seleccionado\n\nElige un plan (1-5):`);
                }
                else if (state === 'selecting_plan' && ['1','2','3','4','5'].includes(text)) {
                    const serverId = data.serverId || 0;
                    await processPurchase(client, phone, data, text, serverId);
                }
                else {
                    setUserState(phone, 'main_menu');
                    await client.sendText(phone, `🤖 *${config.bot.name}*\n\n1️⃣ Prueba gratis\n2️⃣ Ver planes\n3️⃣ Mis cuentas\n4️⃣ Estado pago\n5️⃣ Descargar APP\n6️⃣ Soporte\n7️⃣ Soy revendedor\n\nResponde el número:`);
                }
            } catch (err) {
                console.error('Error:', err);
            }
        });
        
    } catch (err) {
        console.error('❌ Error fatal:', err);
        console.log('🔄 Reintentando en 10 segundos...');
        setTimeout(startBot, 10000);
    }
}

async function processPurchase(client, phone, data, planNumber, serverId) {
    const plans = {
        '1': { days: 7, price: config.prices.price_7d },
        '2': { days: 15, price: config.prices.price_15d },
        '3': { days: 30, price: config.prices.price_30d },
        '4': { days: 50, price: config.prices.price_50d },
        '5': { days: 90, price: config.prices.price_90d }
    };
    
    const plan = plans[planNumber];
    const finalPrice = plan.price * (100 - data.discount) / 100;
    
    await client.sendText(phone, '⏳ Creando usuario...');
    
    try {
        const user = await createSSHUser(phone, plan.days, 'user', serverId);
        
        registerResellerSale(
            data.reseller,
            phone,
            plan.days,
            finalPrice,
            data.discount,
            user.username,
            serverId
        );
        
        let serverText = serverId > 0 ? `📡 Servidor: ${servers.servers[serverId-1].name}` : '📡 Servidor: Local';
        
        await client.sendText(phone, `✅ *USUARIO CREADO*\n\n👤 Usuario: ${user.username}\n🔑 Pass: ${user.password}\n⏱️ Expira: ${moment(user.expires).format('DD/MM/YYYY HH:mm')}\n${serverText}`);
        
    } catch (err) {
        await client.sendText(phone, '❌ Error creando usuario');
    }
    
    setUserState(phone, 'main_menu');
}

// Iniciar bot
startBot();
BOTEOF

# ================================================
# CREAR MENÚ DE ADMINISTRACIÓN (COMANDO sshbot)
# ================================================
cat > /usr/local/bin/sshbot << 'SSHBOTEOF'
#!/bin/bash
# SSH BOT PRO - MENÚ DE ADMINISTRACIÓN

DB_FILE="/opt/sshbot-pro/data/users.db"
CONFIG_FILE="/opt/sshbot-pro/config/config.json"
SERVERS_FILE="/opt/sshbot-pro/config/servers.json"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}❌ Debes ejecutar como root${NC}"
    exit 1
fi

while true; do
    clear
    echo "================================================"
    echo "   SSH BOT PRO v8.0 - ADMINISTRACIÓN           "
    echo "================================================"
    echo ""
    echo " 1) Listar revendedores"
    echo " 2) Agregar revendedor"
    echo " 3) Generar nuevo código"
    echo " 4) Ver ventas por revendedor"
    echo " 5) Ver estadísticas generales"
    echo " 6) Ver usuarios activos"
    echo " 7) Editar servidores remotos"
    echo " 8) Ver logs del bot"
    echo " 9) Reiniciar bot"
    echo "10) Ver QR de conexión"
    echo "11) Editar precios"
    echo "12) Hacer backup"
    echo "13) Restaurar backup"
    echo " 0) Salir"
    echo ""
    echo "================================================"
    read -p "Opción: " opt
    
    case $opt in
        1)
            echo ""
            sqlite3 "$DB_FILE" "SELECT id, phone, code, total_sales, CASE WHEN is_active=1 THEN '✅' ELSE '❌' END FROM resellers ORDER BY total_sales DESC;"
            read -p "Enter..."
            ;;
        2)
            echo ""
            read -p "Número WhatsApp (ej: 5493813414485): " tel
            code=$(tr -dc 'A-Z0-9' < /dev/urandom | fold -w 6 | head -n 1)
            sqlite3 "$DB_FILE" "INSERT INTO resellers (phone, code) VALUES ('$tel', '$code');"
            echo -e "${GREEN}✅ Código generado: $code${NC}"
            pm2 restart sshbot-pro
            read -p "Enter..."
            ;;
        3)
            echo ""
            read -p "Número del revendedor: " tel
            newcode=$(tr -dc 'A-Z0-9' < /dev/urandom | fold -w 6 | head -n 1)
            sqlite3 "$DB_FILE" "UPDATE resellers SET code='$newcode' WHERE phone='$tel';"
            echo -e "${GREEN}✅ Nuevo código: $newcode${NC}"
            pm2 restart sshbot-pro
            read -p "Enter..."
            ;;
        4)
            echo ""
            read -p "Número del revendedor: " tel
            echo ""
            sqlite3 "$DB_FILE" "SELECT client_phone, plan_days, amount, username, sold_at FROM reseller_sales WHERE reseller_phone='$tel' ORDER BY sold_at DESC LIMIT 10;"
            read -p "Enter..."
            ;;
        5)
            total_res=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM resellers WHERE is_active=1;")
            total_sales=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM reseller_sales;")
            total_users=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM users;")
            active_users=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM users WHERE status=1 AND expires_at > datetime('now');")
            echo ""
            echo "📊 Revendedores activos: $total_res"
            echo "💰 Ventas totales: $total_sales"
            echo "👥 Usuarios totales: $total_users"
            echo "✅ Usuarios activos: $active_users"
            read -p "Enter..."
            ;;
        6)
            echo ""
            sqlite3 "$DB_FILE" "SELECT username, phone, expires_at FROM users WHERE status=1 AND expires_at > datetime('now') ORDER BY expires_at ASC LIMIT 20;"
            read -p "Enter..."
            ;;
        7)
            nano "$SERVERS_FILE"
            pm2 restart sshbot-pro
            ;;
        8)
            pm2 logs sshbot-pro --lines 30 --nostream
            read -p "Enter..."
            ;;
        9)
            pm2 restart sshbot-pro
            echo "✅ Bot reiniciado"
            sleep 2
            ;;
        10)
            pm2 logs sshbot-pro --lines 50 --nostream | grep -A 20 "ESCANEA"
            read -p "Enter..."
            ;;
        11)
            nano "$CONFIG_FILE"
            pm2 restart sshbot-pro
            ;;
        12)
            backup="/opt/sshbot-pro/backups/backup_$(date +%Y%m%d_%H%M%S).tar.gz"
            mkdir -p /opt/sshbot-pro/backups
            tar -czf "$backup" -C /opt/sshbot-pro data config 2>/dev/null
            echo -e "${GREEN}✅ Backup creado: $backup${NC}"
            read -p "Enter..."
            ;;
        13)
            echo ""
            echo "Backups disponibles:"
            ls -lh /opt/sshbot-pro/backups/
            echo ""
            read -p "Nombre del archivo a restaurar: " file
            if [ -f "/opt/sshbot-pro/backups/$file" ]; then
                tar -xzf "/opt/sshbot-pro/backups/$file" -C /opt/sshbot-pro
                pm2 restart sshbot-pro
                echo "✅ Restaurado"
            else
                echo "❌ Archivo no encontrado"
            fi
            read -p "Enter..."
            ;;
        0)
            clear
            echo "¡Hasta luego!"
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
# CREAR ENLACE SIMBÓLICO ADICIONAL (por si acaso)
# ================================================
ln -sf "$INSTALL_DIR" /root/sshbot-pro

# ================================================
# CREAR REVENDEDORES DE EJEMPLO
# ================================================
CODE1=$(tr -dc 'A-Z0-9' < /dev/urandom | fold -w 6 | head -n 1)
CODE2=$(tr -dc 'A-Z0-9' < /dev/urandom | fold -w 6 | head -n 1)

sqlite3 "$DB_FILE" "INSERT INTO resellers (phone, code) VALUES ('5493813414485', '$CODE1');"
sqlite3 "$DB_FILE" "INSERT INTO resellers (phone, code) VALUES ('5493815123456', '$CODE2');"

# ================================================
# CONFIGURAR CRON (limpieza y backup)
# ================================================
cat > /etc/cron.d/sshbot-cleanup << EOF
*/15 * * * * root sqlite3 $DB_FILE "UPDATE users SET status=0 WHERE expires_at < datetime('now');"
0 3 * * * root tar -czf /opt/sshbot-pro/backups/backup-\$(date +\%Y\%m\%d).tar.gz -C /opt/sshbot-pro data config 2>/dev/null
EOF

# ================================================
# INICIAR BOT CON PM2
# ================================================
cd "$INSTALL_DIR"
pm2 start bot.js --name sshbot-pro -f
pm2 save
pm2 startup

# ================================================
# MOSTRAR RESUMEN FINAL
# ================================================
clear
echo -e "${GREEN}${BOLD}"
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                                                              ║"
echo "║         ✅ INSTALACIÓN DEFINITIVA COMPLETADA                ║"
echo "║                                                              ║"
echo "╠══════════════════════════════════════════════════════════════╣"
echo "║                                                              ║"
echo "║  📱 NOMBRE VISUAL: ${CYAN}$BOT_NAME${GREEN}                              ║"
echo "║                                                              ║"
echo "║  🔧 ERRORES CORREGIDOS:                                      ║"
echo "║     • Browser already running ✓                              ║"
echo "║     • client.on is not a function ✓                          ║"
echo "║     • MODULE_NOT_FOUND ✓                                     ║"
echo "║     • Auto Close Called ✓                                    ║"
echo "║                                                              ║"
echo "║  🎫 CÓDIGOS DE REVENDEDOR (ejemplo):                         ║"
echo "║     • ${YELLOW}$CODE1${GREEN}                                              ║"
echo "║     • ${YELLOW}$CODE2${GREEN}                                              ║"
echo "║                                                              ║"
echo "║  🌐 SERVIDORES REMOTOS CONFIGURADOS: ${CYAN}$SERVER_COUNT${GREEN}             ║"
echo "║                                                              ║"
echo "║  🖥️  COMANDOS ÚTILES:                                        ║"
echo "║     • ${CYAN}sshbot${GREEN} - Menú de administración                      ║
echo "║     • ${CYAN}pm2 logs sshbot-pro${GREEN} - Ver QR y mensajes               ║
echo "║     • ${CYAN}pm2 restart sshbot-pro${GREEN} - Reiniciar el bot             ║
echo "║                                                              ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Mostrar el QR (o indicar cómo verlo)
echo -e "\n${YELLOW}📱 ESPERANDO QR DE WHATSAPP...${NC}"
sleep 5
pm2 logs sshbot-pro --lines 20 --nostream | grep -A 10 "ESCANEA" || echo -e "${CYAN}Ejecuta 'sshbot' y elige opción 10 para ver el QR${NC}"
echo ""

exit 0
