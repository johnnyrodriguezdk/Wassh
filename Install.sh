#!/bin/bash
# ================================================
# SERVERTUC™ BOT v10.0 - MULTI-SERVIDOR + REVENDEDORES
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
║            SERVERTUC™ BOT v10.0 - MULTI-SERVIDOR            ║
║   🌐 SOPORTE PARA 2 VPS DISTINTAS                           ║
║   🎫 CADA REVENDEDOR CON SU CÓDIGO ÚNICO                    ║
║   🔐 SOLO RESPUESTA A NÚMEROS AUTORIZADOS                   ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
BANNER
echo -e "${NC}"

# Verificar root
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}${BOLD}❌ ERROR: Debes ejecutar como root${NC}"
    exit 1
fi

# ================================================
# CONFIGURACIÓN DE SERVIDORES
# ================================================
echo -e "\n${CYAN}${BOLD}🌐 CONFIGURACIÓN DE SERVIDORES SSH${NC}"

declare -A SERVIDORES
NUM_SERVIDORES=0

while true; do
    echo -e "\n${YELLOW}Configurar servidor $((NUM_SERVIDORES + 1)) (máx 2)${NC}"
    echo -e "${CYAN}¿Quieres agregar un servidor? (s/N):${NC} "
    read -n 1 -r AGREGAR
    echo
    
    if [[ ! $AGREGAR =~ ^[Ss]$ ]] || [[ $NUM_SERVIDORES -ge 2 ]]; then
        break
    fi
    
    NUM_SERVIDORES=$((NUM_SERVIDORES + 1))
    
    echo -e "${GREEN}📡 Servidor #$NUM_SERVIDORES${NC}"
    read -p "IP del servidor: " SERVIDOR_IP
    read -p "Puerto SSH (default 22): " SERVIDOR_PORT
    SERVIDOR_PORT=${SERVIDOR_PORT:-22}
    read -p "Usuario SSH (default root): " SERVIDOR_USER
    SERVIDOR_USER=${SERVIDOR_USER:-root}
    read -p "Contraseña o ruta de clave SSH: " SERVIDOR_PASS
    
    SERVIDORES[$NUM_SERVIDORES,ip]=$SERVIDOR_IP
    SERVIDORES[$NUM_SERVIDORES,port]=$SERVIDOR_PORT
    SERVIDORES[$NUM_SERVIDORES,user]=$SERVIDOR_USER
    SERVIDORES[$NUM_SERVIDORES,pass]=$SERVIDOR_PASS
    SERVIDORES[$NUM_SERVIDORES,name]="Servidor $NUM_SERVIDORES ($SERVIDOR_IP)"
done

if [[ $NUM_SERVIDORES -eq 0 ]]; then
    echo -e "${RED}❌ Debes configurar al menos 1 servidor${NC}"
    exit 1
fi

# ================================================
# CONFIGURACIÓN DE REVENDEDORES
# ================================================
echo -e "\n${CYAN}${BOLD}🎫 CONFIGURACIÓN DE REVENDEDORES${NC}"

echo -e "${YELLOW}¿Cuántos revendedores quieres crear?${NC} "
read -p "Cantidad: " CANT_REVENDEDORES

# Crear arrays para almacenar datos de revendedores
declare -A REVENDEDORES_NUMEROS
declare -A REVENDEDORES_CODIGOS

for ((i=1; i<=CANT_REVENDEDORES; i++)); do
    echo -e "\n${GREEN}📱 Revendedor #$i${NC}"
    
    # Número de teléfono
    while true; do
        read -p "Número de WhatsApp (ej: 5493813414485): " TELEFONO
        if [[ -n "$TELEFONO" ]]; then
            REVENDEDORES_NUMEROS[$i]=$TELEFONO
            break
        fi
    done
    
    # Código único para este revendedor
    CODIGO_GENERADO=$(tr -dc 'A-Z0-9' < /dev/urandom | fold -w 8 | head -n 1)
    echo -e "${CYAN}Código generado: $CODIGO_GENERADO${NC}"
    read -p "¿Usar este código? (Enter para aceptar, o escribe otro): " CODIGO_CUSTOM
    REVENDEDORES_CODIGOS[$i]=${CODIGO_CUSTOM:-$CODIGO_GENERADO}
done

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
    git curl wget sqlite3 jq build-essential \
    python3 python3-pip ffmpeg unzip cron ufw \
    sshpass openssh-client  # Para conexión SSH a otros servidores

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
mkdir -p "$INSTALL_DIR"/{data,config,qr_codes,logs,sessions,scripts}
mkdir -p /root/.wppconnect

# ================================================
# CREAR CONFIGURACIÓN
# ================================================
cat > "$CONFIG_FILE" << EOF
{
    "bot": {
        "name": "SERVERTUC™ BOT",
        "version": "10.0-MULTI-SERVER",
        "server_ip": "$(curl -s ifconfig.me)",
        "default_password": "12345"
    },
    "servers": {
EOF

# Agregar servidores al JSON
for ((i=1; i<=NUM_SERVIDORES; i++)); do
    COMMA=$([ $i -lt $NUM_SERVIDORES ] && echo "," || echo "")
    cat >> "$CONFIG_FILE" << EOF
        "server_$i": {
            "name": "${SERVIDORES[$i,name]}",
            "ip": "${SERVIDORES[$i,ip]}",
            "port": ${SERVIDORES[$i,port]},
            "user": "${SERVIDORES[$i,user]}"
        }$COMMA
EOF
done

cat >> "$CONFIG_FILE" << EOF
    },
    "resellers": {
EOF

# Agregar revendedores al JSON
for ((i=1; i<=CANT_REVENDEDORES; i++)); do
    COMMA=$([ $i -lt $CANT_REVENDEDORES ] && echo "," || echo "")
    cat >> "$CONFIG_FILE" << EOF
        "${REVENDEDORES_NUMEROS[$i]}": {
            "code": "${REVENDEDORES_CODIGOS[$i]}",
            "discount": 50,
            "active": true,
            "created_at": "$(date +%Y-%m-%d)"
        }$COMMA
EOF
done

cat >> "$CONFIG_FILE" << EOF
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
SQL

# Insertar revendedores en la BD
for ((i=1; i<=CANT_REVENDEDORES; i++)); do
    sqlite3 "$DB_FILE" "INSERT INTO authorized_resellers (phone, code, discount_percent, is_active) VALUES ('${REVENDEDORES_NUMEROS[$i]}', '${REVENDEDORES_CODIGOS[$i]}', 50, 1);"
done

# ================================================
# CREAR SCRIPT PARA CREAR USUARIOS EN SERVIDORES REMOTOS
# ================================================
cat > "$INSTALL_DIR/scripts/create_user.sh" << 'EOF'
#!/bin/bash

# Script para crear usuario SSH en servidor remoto
USERNAME=$1
PASSWORD=$2
DAYS=$3
SERVER_IP=$4
SERVER_PORT=$5
SERVER_USER=$6
SERVER_PASS=$7

# Calcular fecha de expiración
if [[ "$DAYS" == "test" ]]; then
    # 2 horas para prueba
    EXPIRE_DATE=$(date -d "+2 hours" +%Y-%m-%d)
else
    EXPIRE_DATE=$(date -d "+$DAYS days" +%Y-%m-%d)
fi

# Comando para crear usuario en el servidor remoto
COMMAND="
useradd -m -s /bin/bash $USERNAME;
echo '$USERNAME:$PASSWORD' | chpasswd;
chage -E $EXPIRE_DATE $USERNAME;
mkdir -p /home/$USERNAME/.ssh;
chown $USERNAME:$USERNAME /home/$USERNAME/.ssh;
chmod 700 /home/$USERNAME/.ssh;
"

# Ejecutar comando remoto
if [[ -f "$SERVER_PASS" ]]; then
    # Usar clave SSH
    ssh -i "$SERVER_PASS" -p $SERVER_PORT $SERVER_USER@$SERVER_IP "$COMMAND"
else
    # Usar contraseña
    sshpass -p "$SERVER_PASS" ssh -p $SERVER_PORT $SERVER_USER@$SERVER_IP "$COMMAND"
fi

echo "Usuario $USERNAME creado en $SERVER_IP (expira: $EXPIRE_DATE)"
EOF

chmod +x "$INSTALL_DIR/scripts/create_user.sh"

# ================================================
# CREAR ARCHIVO PRINCIPAL DEL BOT
# ================================================
cat > "$INSTALL_DIR/index.js" << 'EOF'
// ================================================
// SERVERTUC™ BOT v10.0 - MULTI-SERVIDOR + REVENDEDORES
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

// ================================================
// FUNCIONES DE REVENDEDORES
// ================================================

/**
 * Verifica si un número es revendedor autorizado
 */
function isAuthorizedReseller(phone) {
    return new Promise((resolve) => {
        db.get("SELECT * FROM authorized_resellers WHERE phone = ? AND is_active = 1", [phone], (err, row) => {
            resolve(!!row);
        });
    });
}

/**
 * Verifica código de revendedor y obtiene el número del revendedor
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
 * Muestra servidores disponibles
 */
function getServersList() {
    let list = "🌐 *SERVIDORES DISPONIBLES:*\n\n";
    Object.keys(config.servers).forEach((key, index) => {
        const server = config.servers[key];
        list += `${index + 1}) ${server.name}\n`;
    });
    return list;
}

/**
 * Crea usuario SSH
 */
async function createSSHUser(username, password, days, serverId, resellerPhone, resellerCode) {
    return new Promise(async (resolve, reject) => {
        try {
            const server = config.servers[`server_${serverId}`];
            if (!server) {
                reject('Servidor no encontrado');
                return;
            }

            // Generar comando
            const scriptPath = config.paths.scripts + '/create_user.sh';
            const cmd = `bash ${scriptPath} ${username} ${password} ${days} ${server.ip} ${server.port} ${server.user} ${server.pass}`;
            
            const { stdout, stderr } = await execPromise(cmd);
            
            // Guardar en base de datos
            const expiresAt = new Date();
            if (days === 'test') {
                expiresAt.setHours(expiresAt.getHours() + 2);
            } else {
                expiresAt.setDate(expiresAt.getDate() + parseInt(days));
            }
            
            db.run(`
                INSERT INTO users (username, password, phone, server_id, server_ip, created_by_reseller, reseller_code, tipo, expires_at, max_connections)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            `, [
                username, password, resellerPhone, serverId, server.ip,
                resellerPhone, resellerCode, 'user', expiresAt.toISOString(), 1
            ]);
            
            // Registrar creación
            db.run(`
                INSERT INTO reseller_creations (reseller_phone, username, server_id)
                VALUES (?, ?, ?)
            `, [resellerPhone, username, serverId]);
            
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
    console.log('📱 ESCANEA EL QR:');
    qrcode.generate(qr, { small: true });
});

client.on('ready', () => {
    console.log('✅ BOT CONECTADO!');
    console.log('🎫 Revendedores configurados:', Object.keys(config.resellers).length);
    console.log('🌐 Servidores disponibles:', Object.keys(config.servers).length);
});

client.on('message', async (message) => {
    const msg = message.body.trim();
    const phone = message.from.split('@')[0];
    
    console.log(`📨 Mensaje de ${phone}: ${msg}`);
    
    // Verificar si el mensaje es de un cliente (no revendedor)
    const isReseller = await isAuthorizedReseller(phone);
    
    if (isReseller) {
        // Si es revendedor, manejar su flujo especial
        await handleResellerMessage(phone, msg, message);
    } else {
        // Si es cliente, solo responder a comandos básicos
        await handleClientMessage(phone, msg, message);
    }
});

// ================================================
// MANEJADOR PARA CLIENTES (COMPRADORES)
// ================================================
async function handleClientMessage(phone, msg, message) {
    const lowerMsg = msg.toLowerCase();
    
    // Comandos básicos para clientes
    if (lowerMsg === '1') {
        await message.reply('🎁 *PRUEBA GRATIS*\n\nPara obtener una prueba, necesitas un código de revendedor.\nResponde con tu *CÓDIGO* si tienes uno.');
        userStates.set(phone, 'awaiting_code_test');
    }
    else if (lowerMsg === '2') {
        await message.reply('📋 *PLANES DISPONIBLES*\n\n1️⃣ 7 días - 1 conexión\n2️⃣ 15 días - 1 conexión\n3️⃣ 30 días - 1 conexión\n4️⃣ 7 días - 2 conexiones\n5️⃣ 15 días - 2 conexiones\n6️⃣ 30 días - 2 conexiones\n7️⃣ 50 días - 1 conexión\n\n💰 *PRECIOS*\nContacta a un revendedor para precios y códigos.');
    }
    else if (lowerMsg === '3') {
        await message.reply('📱 *MIS CUENTAS*\n\nPara ver tus cuentas, contacta a tu revendedor.');
    }
    else if (lowerMsg === '4') {
        await message.reply('💰 *ESTADO DE PAGO*\n\nPara consultar pagos, contacta a tu revendedor.');
    }
    else if (lowerMsg === '5') {
        await message.reply(`📲 *DESCARGAR APP*\n\n${config.links?.app_download || 'https://example.com/app'}`);
    }
    else if (lowerMsg === '6') {
        await message.reply(`🆘 *SOPORTE*\n\n${config.links?.support || 'https://wa.me/123456789'}`);
    }
    else {
        // Verificar si está en estado de espera de código
        const state = userStates.get(phone);
        
        if (state === 'awaiting_code_test') {
            // Verificar código para prueba gratis
            const codeValidation = await validateResellerCode(msg);
            if (codeValidation.valid) {
                userStates.set(phone, { state: 'awaiting_server_test', reseller: codeValidation.resellerPhone });
                await message.reply('✅ *CÓDIGO VÁLIDO*\n\nElige el servidor:\n' + getServersList());
            } else {
                await message.reply('❌ *CÓDIGO INVÁLIDO*\n\nEl código ingresado no es válido.');
                userStates.delete(phone);
            }
        }
        else if (state?.state === 'awaiting_server_test') {
            // Crear usuario de prueba
            const serverId = parseInt(msg);
            if (serverId >= 1 && serverId <= Object.keys(config.servers).length) {
                const username = `test${phone.slice(-4)}j`;
                const password = '12345';
                
                await message.reply('⏳ *CREANDO CUENTA DE PRUEBA...*\n\nPor favor espera unos segundos.');
                
                try {
                    const result = await createSSHUser(
                        username, password, 'test', serverId,
                        state.reseller, 'TEST'
                    );
                    
                    await message.reply(
                        `✅ *CUENTA DE PRUEBA CREADA*\n\n` +
                        `👤 *Usuario:* ${result.username}\n` +
                        `🔑 *Contraseña:* ${result.password}\n` +
                        `🌐 *Servidor:* ${result.server}\n` +
                        `📡 *IP:* ${result.ip}\n` +
                        `🔌 *Puerto:* ${result.port}\n` +
                        `⏱️ *Expira:* ${result.expires}\n\n` +
                        `💡 *Recomendación:* Cambia tu contraseña al ingresar.`
                    );
                } catch (error) {
                    await message.reply('❌ *ERROR*\n\nNo se pudo crear la cuenta. Contacta a soporte.');
                }
                
                userStates.delete(phone);
            } else {
                await message.reply('❌ Opción inválida. Elige un número de servidor válido.');
            }
        }
        else {
            await message.reply(
                '🤖 *BOT SSH*\n\n' +
                'Comandos disponibles:\n' +
                '1️⃣ Prueba gratis (requiere código)\n' +
                '2️⃣ Ver planes\n' +
                '3️⃣ Mis cuentas\n' +
                '4️⃣ Estado de pago\n' +
                '5️⃣ Descargar APP\n' +
                '6️⃣ Soporte\n\n' +
                'Responde el *NÚMERO* de la opción que deseas.'
            );
        }
    }
}

// ================================================
// MANEJADOR PARA REVENDEDORES
// ================================================
async function handleResellerMessage(phone, msg, message) {
    const lowerMsg = msg.toLowerCase();
    const state = userStates.get(phone);
    
    // Comandos especiales para revendedores
    if (msg === '!ayuda') {
        await message.reply(
            '🎫 *COMANDOS PARA REVENDEDORES*\n\n' +
            '• *!clientes* - Ver mis clientes\n' +
            '• *!ventas* - Ver estadísticas\n' +
            '• *!codigo* - Ver mi código\n' +
            '• *!crear* - Crear usuario (seguir flujo)\n' +
            '• *1-7* - Iniciar venta de plan\n' +
            '• *0* - Cancelar operación actual'
        );
        return;
    }
    
    if (msg === '!codigo') {
        db.get("SELECT code FROM authorized_resellers WHERE phone = ?", [phone], (err, row) => {
            if (row) {
                message.reply(`🎫 *TU CÓDIGO DE REVENDEDOR:*\n\n\`${row.code}\`\n\nComparte este código con tus clientes.`);
            }
        });
        return;
    }
    
    if (msg === '!ventas') {
        db.get(`
            SELECT 
                COUNT(*) as total_ventas,
                COUNT(CASE WHEN tipo='test' THEN 1 END) as pruebas,
                COUNT(CASE WHEN tipo='user' THEN 1 END) as pagos
            FROM users 
            WHERE created_by_reseller = ?
        `, [phone], (err, row) => {
            if (row) {
                message.reply(
                    `📊 *TUS ESTADÍSTICAS*\n\n` +
                    `📈 Total ventas: ${row.total_ventas || 0}\n` +
                    `🎁 Pruebas gratis: ${row.pruebas || 0}\n` +
                    `💰 Ventas pagas: ${row.pagos || 0}`
                );
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
                let response = '📋 *TUS ÚLTIMOS CLIENTES:*\n\n';
                rows.forEach((r, i) => {
                    response += `${i+1}. *${r.username}*\n   📡 ${r.server_ip}\n   ⏱️ Exp: ${r.expires_at.split('T')[0]}\n\n`;
                });
                message.reply(response);
            } else {
                message.reply('📭 No tienes clientes aún.');
            }
        });
        return;
    }
    
    // Iniciar proceso de venta (opciones 1-7)
    if (['1','2','3','4','5','6','7'].includes(msg)) {
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
        const discountPrice = plan.price * 0.5; // 50% descuento
        
        userStates.set(phone, {
            step: 'awaiting_client_phone',
            plan: plan,
            originalPrice: plan.price,
            finalPrice: discountPrice
        });
        
        await message.reply(
            `🛒 *NUEVA VENTA*\n\n` +
            `📦 Plan: ${plan.days} días (${plan.conn} conexión)\n` +
            `💰 Precio original: $${plan.price}\n` +
            `🏷️ Tu precio (50% off): $${discountPrice}\n\n` +
            `📱 Ingresa el *NÚMERO DE WHATSAPP* del cliente:`
        );
        return;
    }
    
    // Manejar estados del flujo de venta
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
                    '\nElige el *NÚMERO* del servidor:'
                );
                break;
                
            case 'awaiting_server':
                const serverId = parseInt(msg);
                if (serverId >= 1 && serverId <= Object.keys(config.servers).length) {
                    userStates.set(phone, {
                        ...state,
                        step: 'confirm',
                        serverId: serverId
                    });
                    
                    const server = config.servers[`server_${serverId}`];
                    await message.reply(
                        `📡 *SERVIDOR SELECCIONADO:* ${server.name}\n\n` +
                        `📋 *RESUMEN:*\n` +
                        `• Plan: ${state.plan.days} días\n` +
                        `• Conexiones: ${state.plan.conn}\n` +
                        `• Precio final: $${state.finalPrice}\n` +
                        `• Servidor: ${server.name}\n\n` +
                        `Responde *CONFIRMAR* para crear el usuario\n` +
                        `o *CANCELAR* para abortar.`
                    );
                } else {
                    await message.reply('❌ Servidor inválido. Elige un número válido.');
                }
                break;
                
            case 'confirm':
                if (msg.toLowerCase() === 'confirmar') {
                    await message.reply('⏳ *CREANDO USUARIO...*\n\nEsto puede tomar unos segundos.');
                    
                    // Generar usuario y contraseña
                    const username = `user${Date.now().toString().slice(-6)}j`;
                    const password = Math.random().toString(36).slice(-8);
                    
                    try {
                        const result = await createSSHUser(
                            username, password, state.plan.days, state.serverId,
                            phone, state.resellerCode
                        );
                        
                        // Registrar pago
                        db.run(`
                            INSERT INTO payments (phone, username, plan, days, connections, amount, reseller_code, reseller_phone, final_amount, server_id, status)
                            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'approved')
                        `, [
                            state.clientPhone, username, `${state.plan.days}d`,
                            state.plan.days, state.plan.conn, state.originalPrice,
                            'RESELLER', phone, state.finalPrice, state.serverId
                        ]);
                        
                        await message.reply(
                            `✅ *USUARIO CREADO EXITOSAMENTE*\n\n` +
                            `👤 *Usuario:* ${result.username}\n` +
                            `🔑 *Contraseña:* ${result.password}\n` +
                            `🌐 *Servidor:* ${result.server}\n` +
                            `📡 *IP:* ${result.ip}\n` +
                            `🔌 *Puerto:* ${result.port}\n` +
                            `⏱️ *Expira:* ${result.expires}\n\n` +
                            `📱 *Cliente:* ${state.clientPhone}\n\n` +
                            `💡 *Comparte estos datos con el cliente.*`
                        );
                        
                        // También enviar al cliente si es necesario
                        // await client.sendMessage(`${state.clientPhone}@c.us`, `...`);
                        
                    } catch (error) {
                        await message.reply('❌ *ERROR*\n\nNo se pudo crear el usuario. Contacta al administrador.');
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
    
    // Si no hay estado, mostrar menú de revendedor
    await message.reply(
        '🎫 *MENÚ REVENDEDOR*\n\n' +
        '1️⃣ 7 días (1 conexión)\n' +
        '2️⃣ 15 días (1 conexión)\n' +
        '3️⃣ 30 días (1 conexión)\n' +
        '4️⃣ 7 días (2 conexiones)\n' +
        '5️⃣ 15 días (2 conexiones)\n' +
        '6️⃣ 30 días (2 conexiones)\n' +
        '7️⃣ 50 días (1 conexión)\n\n' +
        '📌 *Comandos:*\n' +
        '• !clientes - Ver mis clientes\n' +
        '• !ventas - Mis estadísticas\n' +
        '• !codigo - Mi código\n' +
        '• !ayuda - Ayuda\n\n' +
        'Responde el *NÚMERO* del plan para vender.'
    );
}

// ================================================
// INICIAR BOT
// ================================================
client.initialize();

// Servidor web para health check
const app = express();
app.get('/health', (req, res) => res.send('OK'));
app.listen(3000, () => console.log('🌐 Health check en puerto 3000'));
EOF

# ================================================
# CREAR PACKAGE.JSON E INSTALAR DEPENDENCIAS
# ================================================
cat > "$INSTALL_DIR/package.json" << EOF
{
  "name": "ssh-bot-multi-server",
  "version": "10.0.0",
  "description": "Bot SSH Multi-servidor con revendedores",
  "main": "index.js",
  "dependencies": {
    "whatsapp-web.js": "^1.23.0",
    "qrcode-terminal": "^0.12.0",
    "express": "^4.18.2",
    "sqlite3": "^5.1.6",
    "node-cron": "^3.0.3"
  }
}
EOF

# Instalar dependencias Node
cd "$INSTALL_DIR"
npm install

# ================================================
# INICIAR BOT CON PM2
# ================================================
pm2 start index.js --name ssh-bot
pm2 save
pm2 startup

# ================================================
# CREAR MENÚ DE ADMINISTRACIÓN
# ================================================
cat > /usr/local/bin/menu-revendedores << 'EOF'
#!/bin/bash
DB_FILE="/opt/ssh-bot/data/users.db"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

while true; do
    clear
    echo -e "${CYAN}╔════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║    GESTIÓN DE REVENDEDORES            ║${NC}"
    echo -e "${CYAN}╠════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}║${NC}  ${GREEN}1)${NC} Listar revendedores                  ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  ${GREEN}2)${NC} Agregar revendedor                    ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  ${GREEN}3)${NC} Eliminar revendedor                   ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  ${GREEN}4)${NC} Ver estadísticas                      ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  ${GREEN}5)${NC} Ver códigos                            ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  ${GREEN}6)${NC} Generar nuevo código                   ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  ${GREEN}0)${NC} Salir                                  ${CYAN}║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════╝${NC}"
    
    read -p "Opción: " opt
    
    case $opt in
        1)
            echo -e "\n${YELLOW}REVENDEDORES REGISTRADOS:${NC}"
            sqlite3 "$DB_FILE" "SELECT id, phone, code, total_sales FROM authorized_resellers WHERE is_active=1;"
            read -p "Enter para continuar..."
            ;;
        2)
            read -p "Número WhatsApp: " tel
            read -p "Código único: " code
            sqlite3 "$DB_FILE" "INSERT INTO authorized_resellers (phone, code) VALUES ('$tel', '$code');"
            echo -e "${GREEN}Agregado!${NC}"
            sleep 2
            ;;
        3)
            read -p "ID o número a eliminar: " id
            sqlite3 "$DB_FILE" "UPDATE authorized_resellers SET is_active=0 WHERE phone='$id' OR id='$id';"
            echo -e "${RED}Desactivado${NC}"
            sleep 2
            ;;
        4)
            sqlite3 "$DB_FILE" "
            SELECT 
                phone,
                code,
                total_sales,
                total_discount_given
            FROM authorized_resellers 
            WHERE is_active=1
            ORDER BY total_sales DESC;"
            read -p "Enter para continuar..."
            ;;
        5)
            sqlite3 "$DB_FILE" "SELECT phone, code FROM authorized_resellers WHERE is_active=1;"
            read -p "Enter para continuar..."
            ;;
        6)
            read -p "Número del revendedor: " tel
            newcode=$(tr -dc 'A-Z0-9' < /dev/urandom | fold -w 8 | head -n 1)
            sqlite3 "$DB_FILE" "UPDATE authorized_resellers SET code='$newcode' WHERE phone='$tel';"
            echo -e "${GREEN}Nuevo código: $newcode${NC}"
            sleep 3
            ;;
        0)
            exit 0
            ;;
    esac
done
EOF

chmod +x /usr/local/bin/menu-revendedores

# ================================================
# MOSTRAR RESUMEN FINAL
# ================================================
clear
echo -e "${GREEN}${BOLD}"
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                                                              ║"
echo "║         ✅ INSTALACIÓN COMPLETADA EXITOSAMENTE              ║"
echo "║                                                              ║"
echo "╠══════════════════════════════════════════════════════════════╣"
echo "║                                                              ║"
echo "║  🌐 SERVIDORES CONFIGURADOS:                                 ║"
for ((i=1; i<=NUM_SERVIDORES; i++)); do
    echo "║     $i) ${SERVIDORES[$i,ip]} (${SERVIDORES[$i,user]})"
done
echo "║                                                              ║"
echo "║  🎫 REVENDEDORES CREADOS:                                    ║"
for ((i=1; i<=CANT_REVENDEDORES; i++)); do
    echo "║     • ${REVENDEDORES_NUMEROS[$i]} -> Código: ${REVENDEDORES_CODIGOS[$i]}"
done
echo "║                                                              ║"
echo "║  📱 COMANDOS ÚTILES:                                         ║"
echo "║     • Ver bot: pm2 logs ssh-bot                              ║"
echo "║     • Menú revendedores: menu-revendedores                   ║"
echo "║     • Reiniciar bot: pm2 restart ssh-bot                     ║"
echo "║                                                              ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Guardar códigos en un archivo
echo "CÓDIGOS DE REVENDEDORES" > /root/codigos_revendedores.txt
echo "======================" >> /root/codigos_revendedores.txt
for ((i=1; i<=CANT_REVENDEDORES; i++)); do
    echo "${REVENDEDORES_NUMEROS[$i]} : ${REVENDEDORES_CODIGOS[$i]}" >> /root/codigos_revendedores.txt
done

echo -e "\n${YELLOW}📁 Códigos guardados en: /root/codigos_revendedores.txt${NC}"
echo -e "\n${CYAN}🎫 COPIAS DE SEGURIDAD DE CÓDIGOS:${NC}"
cat /root/codigos_revendedores.txt

echo -e "\n${GREEN}✅ INSTALACIÓN FINALIZADA${NC}"
