#!/bin/bash
# ================================================
# SERVERTUC™ BOT v10.0 - CONFIGURACIÓN POR MENÚ SSH
# INSTALADOR COMPLETO - VERSIÓN CORREGIDA
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
║            SERVERTUC™ BOT v10.0 - MENÚ SSH                  ║
║   🌐 CONFIGURACIÓN TOTAL DESDE LA VPS CON COMANDO sshbot    ║
║   🎫 AGREGA REVENDEDORES, SERVIDORES Y MÁS DESPUÉS          ║
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

# Confirmar instalación (única pregunta)
echo -e "\n${YELLOW}⚠️  ESTE INSTALADOR:${NC}"
echo -e "   • Instalará Node.js 18.x y dependencias"
echo -e "   • Creará el bot con sistema multi-servidor"
echo -e "   • Instalará el comando ${GREEN}sshbot${NC} para configuración"
echo -e "   • NO configurará nada automáticamente"
echo -e "   • Podrás agregar servidores y revendedores después con ${GREEN}sshbot${NC}"
echo -e "\n${RED}⚠️  Se eliminarán instalaciones anteriores${NC}"

read -p "$(echo -e "${YELLOW}¿Continuar con la instalación? (s/N): ${NC}")" -n 1 -r
echo
if [[ ! $REPLY =~ ^[Ss]$ ]]; then
    echo -e "${RED}❌ Instalación cancelada${NC}"
    exit 0
fi

# ================================================
# INSTALACIÓN DE DEPENDENCIAS
# ================================================
echo -e "\n${CYAN}${BOLD}📦 INSTALANDO DEPENDENCIAS...${NC}"

apt-get update -y
apt-get upgrade -y

# Instalar Node.js
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt-get install -y nodejs gcc g++ make

# Instalar Chrome/Chromium
apt-get install -y wget gnupg
wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | apt-key add -
echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list
apt-get update -y
apt-get install -y google-chrome-stable

# Instalar utilidades
apt-get install -y \
    git \
    curl \
    wget \
    sqlite3 \
    jq \
    build-essential \
    python3 \
    python3-pip \
    ffmpeg \
    unzip \
    cron \
    ufw \
    sshpass \
    openssh-client \
    net-tools \
    nano

# Instalar PM2
npm install -g pm2

# Configurar firewall
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 3000/tcp
ufw --force enable

# ================================================
# CREAR ESTRUCTURA DEL BOT
# ================================================
echo -e "\n${CYAN}${BOLD}📁 CREANDO ESTRUCTURA DEL BOT...${NC}"

INSTALL_DIR="/opt/ssh-bot"
DB_FILE="$INSTALL_DIR/data/users.db"
CONFIG_FILE="$INSTALL_DIR/config/config.json"

# Limpiar instalaciones anteriores
pm2 delete ssh-bot 2>/dev/null || true
rm -rf "$INSTALL_DIR"
mkdir -p "$INSTALL_DIR"/{data,config,qr_codes,logs,sessions,scripts,backups}
mkdir -p /root/.wppconnect

# ================================================
# CREAR CONFIGURACIÓN BASE
# ================================================
cat > "$CONFIG_FILE" << EOF
{
    "bot": {
        "name": "SERVERTUC™ BOT",
        "version": "10.0-MENU-SSH",
        "server_ip": "$(curl -s ifconfig.me)",
        "default_password": "12345"
    },
    "servers": {},
    "resellers": {},
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
    "links": {
        "tutorial": "https://youtube.com/@serviertuc",
        "support": "https://wa.me/123456789",
        "app_download": "https://www.mediafire.com/ejemplo"
    },
    "paths": {
        "database": "$DB_FILE",
        "chromium": "/usr/bin/google-chrome",
        "qr_codes": "$INSTALL_DIR/qr_codes",
        "sessions": "/root/.wppconnect",
        "scripts": "$INSTALL_DIR/scripts"
    }
}
EOF

# ================================================
# CREAR BASE DE DATOS
# ================================================
echo -e "${YELLOW}🗄️ Creando base de datos...${NC}"

sqlite3 "$DB_FILE" << 'SQL'
-- Tabla de usuarios
CREATE TABLE users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    username TEXT UNIQUE,
    password TEXT DEFAULT '12345',
    phone TEXT,
    server_id INTEGER,
    server_ip TEXT,
    created_by_reseller TEXT,
    reseller_code TEXT,
    tipo TEXT DEFAULT 'user',
    expires_at DATETIME,
    max_connections INTEGER DEFAULT 1,
    status INTEGER DEFAULT 1,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Tabla de pruebas diarias
CREATE TABLE daily_tests (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    phone TEXT,
    date DATE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(phone, date)
);

-- Tabla de pagos
CREATE TABLE payments (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    payment_id TEXT UNIQUE,
    phone TEXT,
    username TEXT,
    plan TEXT,
    days INTEGER,
    connections INTEGER DEFAULT 1,
    amount REAL,
    reseller_code TEXT,
    reseller_phone TEXT,
    final_amount REAL,
    server_id INTEGER,
    status TEXT DEFAULT 'pending',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    approved_at DATETIME
);

-- Tabla de revendedores autorizados
CREATE TABLE authorized_resellers (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    phone TEXT UNIQUE NOT NULL,
    code TEXT UNIQUE NOT NULL,
    discount_percent INTEGER DEFAULT 50,
    is_active INTEGER DEFAULT 1,
    total_sales INTEGER DEFAULT 0,
    total_discount_given REAL DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    notes TEXT
);

-- Tabla de servidores
CREATE TABLE servers (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    ip TEXT NOT NULL,
    port INTEGER DEFAULT 22,
    user TEXT DEFAULT 'root',
    auth_type TEXT DEFAULT 'password',
    auth_data TEXT,
    is_active INTEGER DEFAULT 1,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Tabla de usuarios creados por revendedores
CREATE TABLE reseller_creations (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    reseller_phone TEXT,
    username TEXT,
    server_id INTEGER,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Índices
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_phone ON users(phone);
CREATE INDEX idx_payments_reseller ON payments(reseller_phone);
CREATE INDEX idx_authorized_phone ON authorized_resellers(phone);
CREATE INDEX idx_authorized_code ON authorized_resellers(code);
CREATE INDEX idx_servers_ip ON servers(ip);
SQL

# ================================================
# CREAR SCRIPT PARA CREAR USUARIOS EN SERVIDORES REMOTOS
# ================================================
cat > "$INSTALL_DIR/scripts/create_user.sh" << 'EOF'
#!/bin/bash
# Script para crear usuario SSH en servidor remoto

USERNAME=$1
PASSWORD=$2
DAYS=$3
SERVER_ID=$4

DB_FILE="/opt/ssh-bot/data/users.db"

# Obtener datos del servidor desde la base de datos
SERVER_INFO=$(sqlite3 $DB_FILE "SELECT ip, port, user, auth_type, auth_data FROM servers WHERE id=$SERVER_ID AND is_active=1;")
if [[ -z "$SERVER_INFO" ]]; then
    echo "ERROR: Servidor no encontrado"
    exit 1
fi

# Parsear datos del servidor
SERVER_IP=$(echo $SERVER_INFO | cut -d'|' -f1)
SERVER_PORT=$(echo $SERVER_INFO | cut -d'|' -f2)
SERVER_USER=$(echo $SERVER_INFO | cut -d'|' -f3)
AUTH_TYPE=$(echo $SERVER_INFO | cut -d'|' -f4)
AUTH_DATA=$(echo $SERVER_INFO | cut -d'|' -f5)

# Calcular fecha de expiración
if [[ "$DAYS" == "test" ]]; then
    EXPIRE_DATE=$(date -d "+2 hours" +%Y-%m-%d)
else
    EXPIRE_DATE=$(date -d "+$DAYS days" +%Y-%m-%d)
fi

# Comando para crear usuario
COMMAND="
useradd -m -s /bin/bash $USERNAME 2>/dev/null;
echo '$USERNAME:$PASSWORD' | chpasswd 2>/dev/null;
chage -E $EXPIRE_DATE $USERNAME 2>/dev/null;
mkdir -p /home/$USERNAME/.ssh 2>/dev/null;
chown $USERNAME:$USERNAME /home/$USERNAME/.ssh 2>/dev/null;
chmod 700 /home/$USERNAME/.ssh 2>/dev/null;
echo 'OK'
"

# Ejecutar comando remoto según tipo de autenticación
if [[ "$AUTH_TYPE" == "key" && -f "$AUTH_DATA" ]]; then
    RESULT=$(ssh -i "$AUTH_DATA" -p $SERVER_PORT -o StrictHostKeyChecking=no -o ConnectTimeout=10 $SERVER_USER@$SERVER_IP "$COMMAND" 2>/dev/null)
else
    RESULT=$(sshpass -p "$AUTH_DATA" ssh -p $SERVER_PORT -o StrictHostKeyChecking=no -o ConnectTimeout=10 $SERVER_USER@$SERVER_IP "$COMMAND" 2>/dev/null)
fi

if [[ "$RESULT" == "OK" ]]; then
    echo "Usuario $USERNAME creado en $SERVER_IP"
    exit 0
else
    echo "ERROR: No se pudo crear el usuario"
    exit 1
fi
EOF

chmod +x "$INSTALL_DIR/scripts/create_user.sh"

# ================================================
# CREAR ARCHIVO PRINCIPAL DEL BOT
# ================================================
cat > "$INSTALL_DIR/index.js" << 'EOF'
// ================================================
// SERVERTUC™ BOT v10.0 - CONFIGURABLE POR MENÚ SSH
// ================================================

const { Client, LocalAuth } = require('whatsapp-web.js');
const qrcode = require('qrcode-terminal');
const express = require('express');
const fs = require('fs');
const path = require('path');
const sqlite3 = require('sqlite3').verbose();
const { exec } = require('child_process');
const util = require('util');
const execPromise = util.promisify(exec);

// Configuración
const config = JSON.parse(fs.readFileSync('/opt/ssh-bot/config/config.json', 'utf8'));
const db = new sqlite3.Database(config.paths.database);

// Estados de conversación
const userStates = new Map();

// Cache de servidores activos
let serversCache = [];
let resellersCache = new Map();

// Actualizar caches cada 5 minutos
function updateCaches() {
    db.all("SELECT * FROM servers WHERE is_active = 1", [], (err, rows) => {
        if (!err) serversCache = rows;
    });
    
    db.all("SELECT phone, code FROM authorized_resellers WHERE is_active = 1", [], (err, rows) => {
        if (!err) {
            resellersCache.clear();
            rows.forEach(r => resellersCache.set(r.phone, r.code));
        }
    });
}

// Actualizar cada 5 minutos
setInterval(updateCaches, 300000);
updateCaches();

// ================================================
// FUNCIONES PRINCIPALES
// ================================================

/**
 * Verifica si un número es revendedor autorizado
 */
function isAuthorizedReseller(phone) {
    return resellersCache.has(phone);
}

/**
 * Verifica código de revendedor
 */
function validateResellerCode(code) {
    return new Promise((resolve) => {
        db.get("SELECT phone FROM authorized_resellers WHERE code = ? AND is_active = 1", [code], (err, row) => {
            if (row) {
                resolve({ valid: true, resellerPhone: row.phone });
            } else {
                resolve({ valid: false, resellerPhone: null });
            }
        });
    });
}

/**
 * Obtiene lista de servidores
 */
function getServersList() {
    if (serversCache.length === 0) {
        return "❌ No hay servidores configurados. Contacta al administrador.";
    }
    
    let list = "🌐 SERVIDORES DISPONIBLES:\n\n";
    serversCache.forEach((server, index) => {
        list += `${index + 1}) ${server.name}\n   📡 ${server.ip}:${server.port}\n\n`;
    });
    return list;
}

/**
 * Crea usuario SSH
 */
async function createSSHUser(username, password, days, serverId, resellerPhone, resellerCode) {
    return new Promise(async (resolve, reject) => {
        try {
            const server = serversCache[serverId - 1];
            if (!server) {
                reject('Servidor no encontrado');
                return;
            }

            // Ejecutar script de creación
            const scriptPath = config.paths.scripts + '/create_user.sh';
            const cmd = `bash ${scriptPath} ${username} ${password} ${days} ${server.id}`;
            
            const { stdout, stderr } = await execPromise(cmd);
            
            // Calcular expiración
            const expiresAt = new Date();
            if (days === 'test') {
                expiresAt.setHours(expiresAt.getHours() + 2);
            } else {
                expiresAt.setDate(expiresAt.getDate() + parseInt(days));
            }
            
            // Guardar en base de datos
            db.run(`
                INSERT INTO users (username, password, phone, server_id, server_ip, created_by_reseller, reseller_code, tipo, expires_at)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
            `, [
                username, password, resellerPhone, server.id, server.ip,
                resellerPhone, resellerCode, days === 'test' ? 'test' : 'user',
                expiresAt.toISOString()
            ]);
            
            // Registrar creación
            db.run(`
                INSERT INTO reseller_creations (reseller_phone, username, server_id)
                VALUES (?, ?, ?)
            `, [resellerPhone, username, server.id]);
            
            // Actualizar contador del revendedor
            db.run(`
                UPDATE authorized_resellers 
                SET total_sales = total_sales + 1 
                WHERE phone = ?
            `, [resellerPhone]);
            
            resolve({
                username,
                password,
                server: server.name,
                ip: server.ip,
                port: server.port,
                expires: expiresAt.toLocaleString()
            });
        } catch (error) {
            reject(error.message);
        }
    });
}

// ================================================
// CLIENTE DE WHATSAPP
// ================================================
const client = new Client({
    authStrategy: new LocalAuth({
        dataPath: config.paths.sessions
    }),
    puppeteer: {
        executablePath: config.paths.chromium,
        args: ['--no-sandbox', '--disable-setuid-sandbox']
    }
});

client.on('qr', (qr) => {
    console.log('\n📱 ESCANEA EL QR CON WHATSAPP:\n');
    qrcode.generate(qr, { small: true });
    console.log('\n');
});

client.on('ready', () => {
    console.log('\n✅ BOT CONECTADO!');
    console.log(`📱 Revendedores: ${resellersCache.size}`);
    console.log(`🌐 Servidores: ${serversCache.length}`);
    console.log('\n📝 Para administrar: sshbot\n');
});

client.on('message', async (message) => {
    const msg = message.body.trim();
    const phone = message.from.split('@')[0];
    
    // Verificar si es revendedor
    const isReseller = isAuthorizedReseller(phone);
    
    if (isReseller) {
        await handleResellerMessage(phone, msg, message);
    } else {
        await handleClientMessage(phone, msg, message);
    }
});

// ================================================
// MANEJADOR PARA CLIENTES
// ================================================
async function handleClientMessage(phone, msg, message) {
    const lowerMsg = msg.toLowerCase();
    const state = userStates.get(phone);
    
    // Comandos básicos
    if (lowerMsg === '1') {
        if (serversCache.length === 0) {
            await message.reply('❌ No hay servidores disponibles. Contacta a soporte.');
            return;
        }
        await message.reply('🎁 PRUEBA GRATIS\n\nResponde con tu CÓDIGO DE REVENDEDOR para obtener 2 horas de prueba.');
        userStates.set(phone, { step: 'awaiting_code_test' });
    }
    else if (lowerMsg === '2') {
        await message.reply(
            '📋 PLANES DISPONIBLES\n\n' +
            '1) 7 días - 1 conexión\n' +
            '2) 15 días - 1 conexión\n' +
            '3) 30 días - 1 conexión\n' +
            '4) 7 días - 2 conexiones\n' +
            '5) 15 días - 2 conexiones\n' +
            '6) 30 días - 2 conexiones\n' +
            '7) 50 días - 1 conexión\n\n' +
            '💰 Para comprar, contacta a un revendedor y pide su código.'
        );
    }
    else if (lowerMsg === '3') {
        await message.reply('📱 MIS CUENTAS\n\nPara ver tus cuentas, contacta a tu revendedor.');
    }
    else if (lowerMsg === '4') {
        await message.reply('💰 ESTADO DE PAGO\n\nPara consultar pagos, contacta a tu revendedor.');
    }
    else if (lowerMsg === '5') {
        await message.reply(`📲 DESCARGAR APP\n\n${config.links.app_download}`);
    }
    else if (lowerMsg === '6') {
        await message.reply(`🆘 SOPORTE\n\n${config.links.support}`);
    }
    else if (state?.step === 'awaiting_code_test') {
        const codeValidation = await validateResellerCode(msg);
        if (codeValidation.valid) {
            userStates.set(phone, { 
                step: 'awaiting_server_test', 
                reseller: codeValidation.resellerPhone,
                code: msg
            });
            await message.reply('✅ CÓDIGO VÁLIDO\n\n' + getServersList() + '\nElige el NÚMERO del servidor:');
        } else {
            await message.reply('❌ CÓDIGO INVÁLIDO\n\nEl código ingresado no es válido.');
            userStates.delete(phone);
        }
    }
    else if (state?.step === 'awaiting_server_test') {
        const serverId = parseInt(msg);
        if (serverId >= 1 && serverId <= serversCache.length) {
            const username = `test${phone.slice(-4)}j`;
            const password = '12345';
            
            await message.reply('⏳ CREANDO CUENTA DE PRUEBA...\n\nPor favor espera...');
            
            try {
                const result = await createSSHUser(
                    username, password, 'test', serverId,
                    state.reseller, state.code
                );
                
                await message.reply(
                    `✅ CUENTA DE PRUEBA CREADA\n\n` +
                    `👤 Usuario: ${result.username}\n` +
                    `🔑 Contraseña: ${result.password}\n` +
                    `🌐 Servidor: ${result.server}\n` +
                    `📡 IP: ${result.ip}\n` +
                    `🔌 Puerto: ${result.port}\n` +
                    `⏱️ Expira: ${result.expires}\n\n` +
                    `💡 Cambia tu contraseña al ingresar.`
                );
            } catch (error) {
                await message.reply('❌ ERROR\n\nNo se pudo crear la cuenta. Contacta a soporte.');
            }
            
            userStates.delete(phone);
        } else {
            await message.reply('❌ Opción inválida. Elige un número del 1 al ' + serversCache.length);
        }
    }
    else {
        await message.reply(
            '🤖 BOT SSH - SERVIERTUC\n\n' +
            'Comandos disponibles:\n' +
            '1) Prueba gratis (requiere código)\n' +
            '2) Ver planes\n' +
            '3) Mis cuentas\n' +
            '4) Estado de pago\n' +
            '5) Descargar APP\n' +
            '6) Soporte\n\n' +
            'Responde el NÚMERO de la opción que deseas.'
        );
    }
}

// ================================================
// MANEJADOR PARA REVENDEDORES
// ================================================
async function handleResellerMessage(phone, msg, message) {
    const state = userStates.get(phone);
    
    // Comandos especiales
    if (msg === '!ayuda') {
        await message.reply(
            '🎫 COMANDOS PARA REVENDEDORES\n\n' +
            '• !clientes - Ver mis clientes\n' +
            '• !ventas - Ver estadísticas\n' +
            '• !codigo - Ver mi código\n' +
            '• 1-7 - Iniciar venta de plan\n' +
            '• 0 - Cancelar operación'
        );
        return;
    }
    
    if (msg === '!codigo') {
        db.get("SELECT code FROM authorized_resellers WHERE phone = ?", [phone], (err, row) => {
            if (row) {
                message.reply(`🎫 TU CÓDIGO: ${row.code}\n\nComparte este código con tus clientes.`);
            }
        });
        return;
    }
    
    if (msg === '!clientes') {
        db.all(`
            SELECT username, server_ip, expires_at 
            FROM users 
            WHERE created_by_reseller = ? 
            ORDER BY created_at DESC LIMIT 10
        `, [phone], (err, rows) => {
            if (rows && rows.length > 0) {
                let response = '📋 TUS ÚLTIMOS CLIENTES:\n\n';
                rows.forEach((r, i) => {
                    response += `${i+1}. ${r.username}\n   📡 ${r.server_ip}\n   ⏱️ Exp: ${r.expires_at.split('T')[0]}\n\n`;
                });
                message.reply(response);
            } else {
                message.reply('📭 No tienes clientes aún.');
            }
        });
        return;
    }
    
    if (msg === '!ventas') {
        db.get(`
            SELECT 
                COUNT(*) as total,
                SUM(CASE WHEN tipo='test' THEN 1 ELSE 0 END) as tests,
                SUM(CASE WHEN tipo='user' THEN 1 ELSE 0 END) as users
            FROM users 
            WHERE created_by_reseller = ?
        `, [phone], (err, row) => {
            if (row) {
                message.reply(
                    `📊 TUS ESTADÍSTICAS\n\n` +
                    `📈 Total: ${row.total || 0}\n` +
                    `🎁 Pruebas: ${row.tests || 0}\n` +
                    `💰 Ventas: ${row.users || 0}`
                );
            }
        });
        return;
    }
    
    // Iniciar venta (opciones 1-7)
    if (['1','2','3','4','5','6','7'].includes(msg)) {
        if (serversCache.length === 0) {
            await message.reply('❌ No hay servidores configurados. Contacta al administrador.');
            return;
        }
        
        const plans = {
            '1': { days: 7, conn: 1, price: config.prices.price_7d_1conn },
            '2': { days: 15, conn: 1, price: config.prices.price_15d_1conn },
            '3': { days: 30, conn: 1, price: config.prices.price_30d_1conn },
            '4': { days: 7, conn: 2, price: config.prices.price_7d_2conn },
            '5': { days: 15, conn: 2, price: config.prices.price_15d_2conn },
            '6': { days: 30, conn: 2, price: config.prices.price_30d_2conn },
            '7': { days: 50, conn: 1, price: config.prices.price_50d_1conn }
        };
        
        const plan = plans[msg];
        const discountPrice = plan.price * 0.5;
        
        userStates.set(phone, {
            step: 'awaiting_client_phone',
            plan: plan,
            finalPrice: discountPrice
        });
        
        await message.reply(
            `🛒 NUEVA VENTA\n\n` +
            `📦 Plan: ${plan.days} días (${plan.conn} conexión)\n` +
            `💰 Precio: $${discountPrice}\n\n` +
            `📱 Ingresa el NÚMERO DE WHATSAPP del cliente:`
        );
        return;
    }
    
    // Manejar flujo de venta
    if (state) {
        switch (state.step) {
            case 'awaiting_client_phone':
                userStates.set(phone, {
                    ...state,
                    step: 'awaiting_server',
                    clientPhone: msg
                });
                await message.reply(
                    '✅ Número registrado.\n\n' +
                    getServersList() +
                    '\nElige el NÚMERO del servidor:'
                );
                break;
                
            case 'awaiting_server':
                const serverId = parseInt(msg);
                if (serverId >= 1 && serverId <= serversCache.length) {
                    userStates.set(phone, {
                        ...state,
                        step: 'confirm',
                        serverId: serverId
                    });
                    
                    const server = serversCache[serverId - 1];
                    await message.reply(
                        `📡 SERVIDOR: ${server.name}\n\n` +
                        `📋 RESUMEN:\n` +
                        `• Plan: ${state.plan.days} días\n` +
                        `• Precio: $${state.finalPrice}\n\n` +
                        `Responde CONFIRMAR para crear el usuario\n` +
                        `o CANCELAR para abortar.`
                    );
                } else {
                    await message.reply('❌ Servidor inválido.');
                }
                break;
                
            case 'confirm':
                if (msg.toLowerCase() === 'confirmar') {
                    await message.reply('⏳ CREANDO USUARIO...');
                    
                    const username = `user${Date.now().toString().slice(-6)}j`;
                    const password = Math.random().toString(36).slice(-8);
                    
                    try {
                        const result = await createSSHUser(
                            username, password, state.plan.days, state.serverId,
                            phone, 'RESELLER'
                        );
                        
                        db.run(`
                            INSERT INTO payments (phone, username, plan, days, amount, reseller_phone, final_amount, server_id, status)
                            VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'approved')
                        `, [
                            state.clientPhone, username, `${state.plan.days}d`,
                            state.plan.days, state.plan.price,
                            phone, state.finalPrice, state.serverId
                        ]);
                        
                        await message.reply(
                            `✅ USUARIO CREADO\n\n` +
                            `👤 Usuario: ${result.username}\n` +
                            `🔑 Contraseña: ${result.password}\n` +
                            `🌐 Servidor: ${result.server}\n` +
                            `📡 IP: ${result.ip}\n` +
                            `🔌 Puerto: ${result.port}\n` +
                            `⏱️ Expira: ${result.expires}`
                        );
                        
                    } catch (error) {
                        await message.reply('❌ ERROR\n\nNo se pudo crear el usuario.');
                    }
                    
                    userStates.delete(phone);
                } else if (msg.toLowerCase() === 'cancelar') {
                    await message.reply('❌ Operación cancelada.');
                    userStates.delete(phone);
                }
                break;
        }
        return;
    }
    
    // Menú principal revendedor
    await message.reply(
        '🎫 MENÚ REVENDEDOR\n\n' +
        '1) 7 días (1 conexión)\n' +
        '2) 15 días (1 conexión)\n' +
        '3) 30 días (1 conexión)\n' +
        '4) 7 días (2 conexiones)\n' +
        '5) 15 días (2 conexiones)\n' +
        '6) 30 días (2 conexiones)\n' +
        '7) 50 días (1 conexión)\n\n' +
        '📌 Comandos:\n' +
        '• !clientes - Ver mis clientes\n' +
        '• !ventas - Mis estadísticas\n' +
        '• !codigo - Mi código\n' +
        '• !ayuda - Ayuda\n\n' +
        'Responde el NÚMERO del plan.'
    );
}

// Iniciar bot
client.initialize();

// Health check
const app = express();
app.get('/health', (req, res) => res.send('OK'));
app.listen(3000);
EOF

# ================================================
# CREAR PACKAGE.JSON
# ================================================
cat > "$INSTALL_DIR/package.json" << EOF
{
  "name": "ssh-bot",
  "version": "10.0.0",
  "main": "index.js",
  "dependencies": {
    "whatsapp-web.js": "^1.23.0",
    "qrcode-terminal": "^0.12.0",
    "express": "^4.18.2",
    "sqlite3": "^5.1.6"
  }
}
EOF

# Instalar dependencias
cd "$INSTALL_DIR"
npm install

# ================================================
# CREAR MENÚ SSH (COMANDO sshbot) - VERSIÓN CORREGIDA
# ================================================
cat > /usr/local/bin/sshbot << 'EOF'
#!/bin/bash
# ================================================
# MENÚ DE ADMINISTRACIÓN SSH BOT - VERSIÓN CORREGIDA
# ================================================

DB_FILE="/opt/ssh-bot/data/users.db"
CONFIG_FILE="/opt/ssh-bot/config/config.json"
INSTALL_DIR="/opt/ssh-bot"

# Verificar root
if [[ $EUID -ne 0 ]]; then
    echo "❌ Debes ejecutar como root"
    exit 1
fi

mostrar_menu() {
    clear
    echo "================================================"
    echo "     SERVERTUC™ BOT - MENÚ DE ADMINISTRACIÓN    "
    echo "================================================"
    echo ""
    echo " 1) Gestionar Revendedores"
    echo " 2) Gestionar Servidores SSH"
    echo " 3) Ver Estadísticas"
    echo " 4) Ver Logs del Bot"
    echo " 5) Reiniciar Bot"
    echo " 6) Ver QR de Conexión"
    echo " 7) Configurar Precios"
    echo " 8) Hacer Backup"
    echo " 9) Restaurar Backup"
    echo " 0) Salir"
    echo ""
    echo "================================================"
}

gestionar_revendedores() {
    while true; do
        clear
        echo "================================================"
        echo "           GESTIÓN DE REVENDEDORES              "
        echo "================================================"
        echo ""
        echo " 1) Listar revendedores"
        echo " 2) Agregar revendedor"
        echo " 3) Eliminar revendedor"
        echo " 4) Generar nuevo código"
        echo " 5) Ver detalles de revendedor"
        echo " 0) Volver al menú principal"
        echo ""
        echo "================================================"
        echo ""
        read -p "Selecciona una opción: " opt
        
        case $opt in
            1)
                echo ""
                echo "REVENDEDORES REGISTRADOS:"
                echo "------------------------"
                sqlite3 "$DB_FILE" "SELECT id, phone, code, total_sales, CASE WHEN is_active = 1 THEN 'ACTIVO' ELSE 'INACTIVO' END FROM authorized_resellers ORDER BY total_sales DESC;"
                echo ""
                read -p "Presiona Enter para continuar..."
                ;;
            2)
                echo ""
                echo "NUEVO REVENDEDOR"
                echo "---------------"
                read -p "Número WhatsApp (ej: 5493813414485): " tel
                # Generar código aleatorio
                code=$(tr -dc 'A-Z0-9' < /dev/urandom | fold -w 6 | head -n 1)
                sqlite3 "$DB_FILE" "INSERT INTO authorized_resellers (phone, code) VALUES ('$tel', '$code');"
                echo "✅ Revendedor agregado con código: $code"
                pm2 restart ssh-bot > /dev/null 2>&1
                echo ""
                read -p "Presiona Enter para continuar..."
                ;;
            3)
                echo ""
                echo "ELIMINAR REVENDEDOR"
                echo "------------------"
                read -p "ID o número a eliminar: " id
                sqlite3 "$DB_FILE" "UPDATE authorized_resellers SET is_active=0 WHERE phone='$id' OR id='$id';"
                echo "✅ Revendedor desactivado"
                pm2 restart ssh-bot > /dev/null 2>&1
                echo ""
                read -p "Presiona Enter para continuar..."
                ;;
            4)
                echo ""
                echo "GENERAR NUEVO CÓDIGO"
                echo "--------------------"
                read -p "Número del revendedor: " tel
                newcode=$(tr -dc 'A-Z0-9' < /dev/urandom | fold -w 6 | head -n 1)
                sqlite3 "$DB_FILE" "UPDATE authorized_resellers SET code='$newcode' WHERE phone='$tel';"
                echo "✅ Nuevo código: $newcode"
                pm2 restart ssh-bot > /dev/null 2>&1
                echo ""
                read -p "Presiona Enter para continuar..."
                ;;
            5)
                echo ""
                read -p "Número del revendedor: " tel
                echo ""
                echo "DETALLES DEL REVENDEDOR"
                echo "-----------------------"
                sqlite3 "$DB_FILE" "SELECT phone, code, total_sales, created_at FROM authorized_resellers WHERE phone='$tel';"
                echo ""
                echo "ÚLTIMAS VENTAS:"
                echo "--------------"
                sqlite3 "$DB_FILE" "SELECT username, server_ip, created_at FROM users WHERE created_by_reseller='$tel' ORDER BY created_at DESC LIMIT 5;"
                echo ""
                read -p "Presiona Enter para continuar..."
                ;;
            0)
                return
                ;;
            *)
                echo "Opción no válida"
                sleep 2
                ;;
        esac
    done
}

gestionar_servidores() {
    while true; do
        clear
        echo "================================================"
        echo "           GESTIÓN DE SERVIDORES SSH           "
        echo "================================================"
        echo ""
        echo " 1) Listar servidores"
        echo " 2) Agregar servidor"
        echo " 3) Eliminar servidor"
        echo " 4) Probar conexión"
        echo " 0) Volver al menú principal"
        echo ""
        echo "================================================"
        echo ""
        read -p "Selecciona una opción: " opt
        
        case $opt in
            1)
                echo ""
                echo "SERVIDORES CONFIGURADOS:"
                echo "-----------------------"
                sqlite3 "$DB_FILE" "SELECT id, name, ip, port, user, CASE WHEN is_active = 1 THEN 'ACTIVO' ELSE 'INACTIVO' END FROM servers ORDER BY id;"
                echo ""
                read -p "Presiona Enter para continuar..."
                ;;
            2)
                echo ""
                echo "NUEVO SERVIDOR SSH"
                echo "------------------"
                read -p "Nombre del servidor: " name
                read -p "IP del servidor: " ip
                read -p "Puerto SSH [22]: " port
                port=${port:-22}
                read -p "Usuario [root]: " user
                user=${user:-root}
                read -p "Contraseña: " pass
                
                sqlite3 "$DB_FILE" "INSERT INTO servers (name, ip, port, user, auth_type, auth_data) VALUES ('$name', '$ip', $port, '$user', 'password', '$pass');"
                echo "✅ Servidor agregado"
                pm2 restart ssh-bot > /dev/null 2>&1
                echo ""
                read -p "Presiona Enter para continuar..."
                ;;
            3)
                echo ""
                echo "ELIMINAR SERVIDOR"
                echo "----------------"
                read -p "ID del servidor: " id
                sqlite3 "$DB_FILE" "UPDATE servers SET is_active=0 WHERE id=$id;"
                echo "✅ Servidor desactivado"
                pm2 restart ssh-bot > /dev/null 2>&1
                echo ""
                read -p "Presiona Enter para continuar..."
                ;;
            4)
                echo ""
                read -p "ID del servidor a probar: " id
                echo ""
                echo "PROBANDO CONEXIÓN..."
                echo "-------------------"
                server_info=$(sqlite3 "$DB_FILE" "SELECT ip, port, user, auth_data FROM servers WHERE id=$id AND is_active=1;")
                if [ -z "$server_info" ]; then
                    echo "❌ Servidor no encontrado o inactivo"
                else
                    IFS='|' read -r ip port user pass <<< "$server_info"
                    
                    sshpass -p "$pass" ssh -p $port -o ConnectTimeout=5 -o StrictHostKeyChecking=no $user@$ip "echo '✅ Conexión exitosa'" 2>/dev/null
                    if [ $? -eq 0 ]; then
                        echo "✅ Servidor accesible"
                    else
                        echo "❌ No se pudo conectar al servidor"
                    fi
                fi
                echo ""
                read -p "Presiona Enter para continuar..."
                ;;
            0)
                return
                ;;
            *)
                echo "Opción no válida"
                sleep 2
                ;;
        esac
    done
}

ver_estadisticas() {
    clear
    echo "================================================"
    echo "           ESTADÍSTICAS GENERALES              "
    echo "================================================"
    echo ""
    
    total_rev=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM authorized_resellers WHERE is_active=1;")
    total_serv=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM servers WHERE is_active=1;")
    total_users=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM users;")
    total_tests=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM users WHERE tipo='test';")
    total_paid=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM users WHERE tipo='user';")
    
    echo "📱 Revendedores activos: $total_rev"
    echo "🌐 Servidores activos: $total_serv"
    echo "👥 Total usuarios creados: $total_users"
    echo "🎁 Pruebas gratis: $total_tests"
    echo "💰 Usuarios pagos: $total_paid"
    
    echo ""
    echo "ÚLTIMOS USUARIOS CREADOS:"
    echo "-------------------------"
    sqlite3 "$DB_FILE" "SELECT username, server_ip, created_at FROM users ORDER BY created_at DESC LIMIT 5;"
    
    echo ""
    read -p "Presiona Enter para continuar..."
}

# Menú principal
while true; do
    mostrar_menu
    echo ""
    read -p "Selecciona una opción: " opcion
    
    case $opcion in
        1) gestionar_revendedores ;;
        2) gestionar_servidores ;;
        3) ver_estadisticas ;;
        4) 
            clear
            echo "================================================"
            echo "               LOGS DEL BOT                    "
            echo "================================================"
            echo ""
            pm2 logs ssh-bot --lines 30 --nostream
            echo ""
            read -p "Presiona Enter para continuar..."
            ;;
        5)
            echo ""
            echo "Reiniciando bot..."
            pm2 restart ssh-bot
            echo "✅ Bot reiniciado"
            sleep 2
            ;;
        6)
            clear
            echo "================================================"
            echo "           QR DE CONEXIÓN WHATSAPP             "
            echo "================================================"
            echo ""
            echo "Buscando QR en los logs..."
            echo ""
            pm2 logs ssh-bot --lines 50 --nostream | grep -A 15 "QR" || echo "No se encontró QR. Espera a que el bot genere uno."
            echo ""
            read -p "Presiona Enter para continuar..."
            ;;
        7)
            nano "$CONFIG_FILE"
            echo ""
            echo "Reiniciando bot para aplicar cambios..."
            pm2 restart ssh-bot
            echo "✅ Bot reiniciado"
            sleep 2
            ;;
        8)
            echo ""
            echo "CREANDO BACKUP..."
            echo "----------------"
            mkdir -p /opt/ssh-bot/backups
            backup_file="/opt/ssh-bot/backups/backup_$(date +%Y%m%d_%H%M%S).tar.gz"
            tar -czf "$backup_file" -C /opt/ssh-bot data config 2>/dev/null
            echo "✅ Backup creado: $backup_file"
            echo ""
            read -p "Presiona Enter para continuar..."
            ;;
        9)
            echo ""
            echo "BACKUPS DISPONIBLES:"
            echo "-------------------"
            ls -lh /opt/ssh-bot/backups/ | grep tar.gz
            echo ""
            read -p "Nombre del archivo de backup a restaurar: " backup
            if [ -f "/opt/ssh-bot/backups/$backup" ]; then
                echo "Restaurando backup..."
                tar -xzf "/opt/ssh-bot/backups/$backup" -C /opt/ssh-bot 2>/dev/null
                echo "✅ Backup restaurado"
                echo "Reiniciando bot..."
                pm2 restart ssh-bot
                echo "✅ Bot reiniciado"
            else
                echo "❌ Archivo no encontrado"
            fi
            echo ""
            read -p "Presiona Enter para continuar..."
            ;;
        0)
            clear
            echo "================================================"
            echo "              ¡HASTA LUEGO!                    "
            echo "================================================"
            echo ""
            exit 0
            ;;
        *)
            echo "❌ Opción no válida"
            sleep 2
            ;;
    esac
done
EOF

chmod +x /usr/local/bin/sshbot

# ================================================
# INICIAR BOT
# ================================================
cd "$INSTALL_DIR"
pm2 start index.js --name ssh-bot
pm2 save
pm2 startup

# ================================================
# MENSAJE FINAL
# ================================================
clear
echo "================================================"
echo "         ✅ INSTALACIÓN COMPLETADA              "
echo "================================================"
echo ""
echo "  📱 COMANDO PRINCIPAL:"
echo "  sshbot"
echo ""
echo "  🔧 PRÓXIMOS PASOS:"
echo "  1. Ejecuta 'sshbot' para configurar"
echo "  2. Agrega servidores SSH (opción 2)"
echo "  3. Agrega revendedores (opción 1)"
echo "  4. Escanea el QR (opción 6)"
echo ""
echo "  📁 RUTAS IMPORTANTES:"
echo "  • Bot: /opt/ssh-bot/"
echo "  • Logs: pm2 logs ssh-bot"
echo ""
echo "================================================"

# Mostrar QR si está disponible
echo ""
echo "📱 ESPERANDO QR... (puede tomar unos segundos)"
sleep 5
pm2 logs ssh-bot --lines 20 --nostream | grep -A 10 "QR" || echo "Ejecuta 'sshbot' y opción 6 para ver el QR"
echo ""
echo "================================================"

exit 0
