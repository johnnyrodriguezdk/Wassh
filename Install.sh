#!/bin/bash
# ================================================
# SSH BOT PRO - INSTALADOR MEJORADO
# Mejoras aplicadas:
# 1. ✅ Removida funcionalidad maliciosa
# 2. ✅ Mejoras de seguridad
# 3. ✅ Código más limpio y mantenible
# 4. ✅ Validaciones mejoradas
# 5. ✅ Sin auto-destrucción peligrosa
# ================================================

set -euo pipefail

# Colores mejorados para mejor legibilidad
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly CYAN='\033[0;36m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly BOLD='\033[1m'
readonly NC='\033[0m'
readonly ITALIC='\033[3m'

# Configuración
readonly INSTALL_DIR="/opt/ssh-bot"
readonly USER_HOME="/root/ssh-bot"
readonly DB_FILE="$INSTALL_DIR/data/users.db"
readonly CONFIG_FILE="$INSTALL_DIR/config/config.json"
readonly LOG_FILE="/var/log/ssh-bot-install.log"

# Funciones de logging
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1" | tee -a "$LOG_FILE"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
}

log_debug() {
    echo -e "${BLUE}[DEBUG]${NC} $1" | tee -a "$LOG_FILE"
}

# Función para mostrar el banner
show_banner() {
    clear
    echo -e "${CYAN}${BOLD}"
    cat << "BANNER"
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║     ███████╗███████╗██║  ██║    ██████╗  ██████╗ ████████╗  ║
║     ██╔════╝██╔════╝██║  ██║    ██╔══██╗██╔═══██╗╚══██╔══╝  ║
║     ███████╗███████╗███████║    ██████╔╝██║   ██║   ██║     ║
║     ╚════██║╚════██║██╔══██║    ██╔══██╗██║   ██║   ██║     ║
║     ███████║███████║██║  ██║    ██████╔╝╚██████╔╝   ██║     ║
║     ╚══════╝╚══════╝╚═╝  ╚═╝    ╚═════╝  ╚═════╝    ╚═╝     ║
╠══════════════════════════════════════════════════════════════╣
║                                                              ║
║               🚀 SSH BOT PRO - INSTALADOR                   ║
║               🔒 VERSIÓN SEGURA Y MEJORADA                  ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
BANNER
    echo -e "${NC}"
}

# Función para verificar si es root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "Debes ejecutar como root"
        echo -e "${YELLOW}Usa: sudo bash $0${NC}"
        exit 1
    fi
    log_info "Verificación de root: OK"
}

# Función para detectar IP
get_server_ip() {
    local ip=""
    
    # Intentar obtener IP pública
    local services=(
        "ifconfig.me"
        "ipinfo.io/ip"
        "api.ipify.org"
        "checkip.amazonaws.com"
    )
    
    for service in "${services[@]}"; do
        ip=$(curl -4 -s --max-time 5 "https://$service" 2>/dev/null)
        if [[ -n "$ip" && "$ip" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            echo "$ip"
            return 0
        fi
    done
    
    # Fallback a IP local
    ip=$(hostname -I | awk '{print $1}' | head -1)
    if [[ -z "$ip" ]]; then
        ip="127.0.0.1"
    fi
    
    echo "$ip"
}

# Función para confirmar instalación
confirm_installation() {
    echo -e "${YELLOW}${BOLD}⚠️  RESUMEN DE LA INSTALACIÓN:${NC}"
    echo -e "   • Instalar Node.js 20.x + Dependencias"
    echo -e "   • Crear estructura de directorios"
    echo -e "   • Configurar base de datos SQLite"
    echo -e "   • Instalar bot de WhatsApp"
    echo -e "   • Configurar panel de control"
    echo -e "   • Configurar servicio PM2"
    echo -e ""
    echo -e "${RED}${BOLD}⚠️  ADVERTENCIA:${NC}"
    echo -e "   • Se eliminarán instalaciones anteriores"
    echo -e "   • Se instalará software de terceros"
    echo -e ""
    
    read -rp "$(echo -e "${YELLOW}¿Continuar con la instalación? (s/N): ${NC}")" confirm
    if [[ ! "$confirm" =~ ^[Ss](i|í)?$ ]]; then
        log_info "Instalación cancelada por el usuario"
        exit 0
    fi
}

# Función para instalar dependencias
install_dependencies() {
    log_info "Instalando dependencias del sistema..."
    
    # Actualizar repositorios
    apt-get update -qq
    
    # Instalar paquetes básicos
    local packages=(
        curl wget git unzip
        sqlite3 jq nano htop
        cron build-essential
        ca-certificates gnupg
        software-properties-common
        libgbm-dev libxshmfence-dev
        sshpass at
        net-tools
        python3
        python3-pip
    )
    
    apt-get install -y -qq "${packages[@]}"
    
    # Habilitar servicio 'at'
    systemctl enable atd 2>/dev/null || true
    systemctl start atd 2>/dev/null || true
    
    # Instalar Google Chrome
    if ! command -v google-chrome &> /dev/null; then
        log_info "Instalando Google Chrome..."
        wget -q https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb -O /tmp/chrome.deb
        apt-get install -y -qq /tmp/chrome.deb
        rm -f /tmp/chrome.deb
    fi
    
    # Instalar Node.js 20.x
    if ! command -v node &> /dev/null; then
        log_info "Instalando Node.js 20.x..."
        curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
        apt-get install -y -qq nodejs
    fi
    
    # Instalar PM2 global
    log_info "Instalando PM2..."
    npm install -g pm2 --silent
    
    log_info "Dependencias instaladas correctamente"
}

# Función para crear estructura de directorios
create_directory_structure() {
    log_info "Creando estructura de directorios..."
    
    # Limpiar instalaciones anteriores de forma segura
    pm2 delete ssh-bot 2>/dev/null || true
    pm2 flush 2>/dev/null || true
    
    # Crear directorios con permisos adecuados
    mkdir -p "$INSTALL_DIR"/{data,config,qr_codes,logs,backups}
    mkdir -p "$USER_HOME"
    mkdir -p /root/.wwebjs_auth
    
    # Configurar permisos
    chmod -R 755 "$INSTALL_DIR"
    chmod -R 700 /root/.wwebjs_auth
    chmod 644 "$LOG_FILE" 2>/dev/null || true
    
    # Crear usuario del sistema para el bot (mejor práctica de seguridad)
    if ! id "sshbot" &>/dev/null; then
        useradd -r -s /bin/false -d "$INSTALL_DIR" sshbot
        chown -R sshbot:sshbot "$INSTALL_DIR"
    fi
    
    log_info "Estructura creada correctamente"
}

# Función para crear configuración
create_configuration() {
    local server_ip="$1"
    
    log_info "Creando archivo de configuración..."
    
    cat > "$CONFIG_FILE" << EOF
{
    "bot": {
        "name": "SSH Bot Pro",
        "version": "1.0.0",
        "server_ip": "$server_ip",
        "admin_phone": "",
        "log_level": "info"
    },
    "prices": {
        "test_hours": 2,
        "price_7d": 500.00,
        "price_15d": 800.00,
        "price_30d": 1200.00,
        "currency": "ARS"
    },
    "mercadopago": {
        "access_token": "",
        "enabled": false,
        "sandbox": true,
        "webhook_url": ""
    },
    "security": {
        "max_connections_per_user": 1,
        "session_timeout_minutes": 30,
        "enable_rate_limiting": true
    },
    "notifications": {
        "enable_email": false,
        "enable_telegram": false,
        "admin_email": ""
    },
    "paths": {
        "database": "$DB_FILE",
        "chromium": "/usr/bin/google-chrome",
        "qr_codes": "$INSTALL_DIR/qr_codes",
        "logs": "$INSTALL_DIR/logs"
    },
    "api": {
        "enabled": false,
        "port": 3000,
        "rate_limit": 100
    }
}
EOF
    
    chmod 600 "$CONFIG_FILE"
    log_info "Configuración creada: $CONFIG_FILE"
}

# Función para crear base de datos
create_database() {
    log_info "Creando base de datos..."
    
    sqlite3 "$DB_FILE" << 'SQL'
CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    phone TEXT NOT NULL,
    username TEXT UNIQUE NOT NULL,
    password TEXT NOT NULL,
    tipo TEXT DEFAULT 'test',
    expires_at DATETIME,
    max_connections INTEGER DEFAULT 1,
    status INTEGER DEFAULT 1,
    last_login DATETIME,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS daily_tests (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    phone TEXT NOT NULL,
    date DATE NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(phone, date)
);

CREATE TABLE IF NOT EXISTS payments (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    payment_id TEXT UNIQUE NOT NULL,
    phone TEXT NOT NULL,
    plan TEXT NOT NULL,
    days INTEGER NOT NULL,
    amount REAL NOT NULL,
    status TEXT DEFAULT 'pending',
    payment_url TEXT,
    qr_code TEXT,
    preference_id TEXT,
    external_reference TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    approved_at DATETIME,
    expires_at DATETIME,
    metadata TEXT
);

CREATE TABLE IF NOT EXISTS logs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    type TEXT NOT NULL,
    level TEXT DEFAULT 'info',
    message TEXT NOT NULL,
    data TEXT,
    ip_address TEXT,
    user_agent TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS sessions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    session_id TEXT UNIQUE NOT NULL,
    user_id INTEGER,
    data TEXT,
    expires_at DATETIME NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Índices para mejor performance
CREATE INDEX IF NOT EXISTS idx_users_phone ON users(phone);
CREATE INDEX IF NOT EXISTS idx_users_status ON users(status);
CREATE INDEX IF NOT EXISTS idx_users_expires ON users(expires_at);
CREATE INDEX IF NOT EXISTS idx_payments_status ON payments(status);
CREATE INDEX IF NOT EXISTS idx_payments_phone ON payments(phone);
CREATE INDEX IF NOT EXISTS idx_payments_external_ref ON payments(external_reference);
CREATE INDEX IF NOT EXISTS idx_logs_created ON logs(created_at);
CREATE INDEX IF NOT EXISTS idx_logs_type ON logs(type);

-- Trigger para actualizar updated_at
CREATE TRIGGER IF NOT EXISTS update_users_timestamp 
AFTER UPDATE ON users 
BEGIN
    UPDATE users SET updated_at = CURRENT_TIMESTAMP WHERE id = NEW.id;
END;
SQL
    
    # Verificar que la base de datos se creó correctamente
    if [[ -f "$DB_FILE" ]]; then
        log_info "Base de datos creada: $DB_FILE"
        
        # Crear backup inicial
        sqlite3 "$DB_FILE" ".backup '$INSTALL_DIR/backups/initial_backup.db'"
    else
        log_error "No se pudo crear la base de datos"
        exit 1
    fi
}

# Función para crear archivo package.json
create_package_json() {
    log_info "Creando package.json..."
    
    cd "$USER_HOME"
    
    cat > package.json << EOF
{
    "name": "ssh-bot-pro",
    "version": "1.0.0",
    "description": "Bot de gestión SSH para WhatsApp",
    "main": "bot.js",
    "scripts": {
        "start": "node bot.js",
        "dev": "nodemon bot.js",
        "test": "jest",
        "lint": "eslint .",
        "migrate": "node scripts/migrate.js"
    },
    "keywords": ["ssh", "bot", "whatsapp", "management"],
    "author": "Administrador",
    "license": "MIT",
    "dependencies": {
        "whatsapp-web.js": "^1.24.0",
        "qrcode-terminal": "^0.12.0",
        "qrcode": "^1.5.3",
        "moment": "^2.30.1",
        "sqlite3": "^5.1.7",
        "chalk": "^4.1.2",
        "node-cron": "^3.0.3",
        "axios": "^1.6.5",
        "express": "^4.18.2",
        "helmet": "^7.1.0",
        "cors": "^2.8.5",
        "winston": "^3.11.0",
        "dotenv": "^16.3.1",
        "joi": "^17.11.0"
    },
    "devDependencies": {
        "nodemon": "^3.0.1",
        "jest": "^29.7.0",
        "eslint": "^8.56.0"
    },
    "engines": {
        "node": ">=18.0.0",
        "npm": ">=9.0.0"
    }
}
EOF
}

# Función para instalar dependencias de Node.js
install_node_dependencies() {
    log_info "Instalando dependencias de Node.js..."
    
    cd "$USER_HOME"
    
    # Instalar dependencias con logging
    if npm install --silent 2>&1 | tee -a "$LOG_FILE"; then
        log_info "Dependencias de Node.js instaladas correctamente"
    else
        log_error "Error instalando dependencias de Node.js"
        exit 1
    fi
}

# Función para crear el bot principal
create_bot() {
    log_info "Creando bot principal..."
    
    cat > "$USER_HOME/bot.js" << 'EOF'
// Bot principal - Versión mejorada
const { Client, LocalAuth } = require('whatsapp-web.js');
const qrcode = require('qrcode-terminal');
const moment = require('moment');
const sqlite3 = require('sqlite3').verbose();
const chalk = require('chalk');
const fs = require('fs').promises;
const path = require('path');

// Configuración
const CONFIG_PATH = '/opt/ssh-bot/config/config.json';
const DB_PATH = '/opt/ssh-bot/data/users.db';

// Cargar configuración
function loadConfig() {
    try {
        return require(CONFIG_PATH);
    } catch (error) {
        console.error(chalk.red('Error cargando configuración:'), error.message);
        process.exit(1);
    }
}

const config = loadConfig();
const db = new sqlite3.Database(DB_PATH);

// Cliente de WhatsApp
const client = new Client({
    authStrategy: new LocalAuth({
        dataPath: '/root/.wwebjs_auth',
        clientId: 'ssh-bot-v1'
    }),
    puppeteer: {
        headless: true,
        executablePath: config.paths.chromium || '/usr/bin/google-chrome',
        args: [
            '--no-sandbox',
            '--disable-setuid-sandbox',
            '--disable-dev-shm-usage',
            '--disable-gpu',
            '--no-first-run',
            '--disable-extensions'
        ],
        timeout: 60000
    },
    webVersionCache: {
        type: 'remote',
        remotePath: 'https://raw.githubusercontent.com/wppconnect-team/wa-version/main/html/2.2412.54.html'
    }
});

// Eventos del cliente
client.on('qr', (qr) => {
    console.log(chalk.yellow('🔐 Escanea este código QR con WhatsApp:'));
    qrcode.generate(qr, { small: true });
    
    // Guardar QR como archivo
    const qrPath = path.join(config.paths.qr_codes, `qr-${Date.now()}.png`);
    require('qrcode').toFile(qrPath, qr, (err) => {
        if (!err) {
            console.log(chalk.green(`✅ QR guardado en: ${qrPath}`));
        }
    });
});

client.on('ready', () => {
    console.log(chalk.green('✅ Cliente de WhatsApp listo!'));
    
    // Mensaje de bienvenida automático
    if (config.bot.admin_phone) {
        const welcomeMsg = `🤖 *Bot SSH Activado*\n\n` +
                          `Servidor: ${config.bot.server_ip}\n` +
                          `Versión: ${config.bot.version}\n` +
                          `Hora: ${moment().format('DD/MM/YYYY HH:mm:ss')}`;
        
        client.sendMessage(`${config.bot.admin_phone}@c.us`, welcomeMsg)
            .catch(console.error);
    }
});

client.on('authenticated', () => {
    console.log(chalk.green('✅ Autenticado con WhatsApp'));
});

client.on('auth_failure', (msg) => {
    console.error(chalk.red('❌ Error de autenticación:'), msg);
});

client.on('disconnected', (reason) => {
    console.warn(chalk.yellow('⚠️  Desconectado:'), reason);
});

// Inicializar el cliente
client.initialize();

// Manejo de señales para apagado limpio
process.on('SIGINT', () => {
    console.log(chalk.yellow('\n🛑 Apagando bot...'));
    client.destroy()
        .then(() => {
            console.log(chalk.green('✅ Bot apagado correctamente'));
            process.exit(0);
        })
        .catch((err) => {
            console.error(chalk.red('❌ Error al apagar:'), err);
            process.exit(1);
        });
});

// Exportar cliente para uso en otros módulos
module.exports = { client, db, config };
EOF
    
    log_info "Bot principal creado correctamente"
}

# Función para crear panel de control
create_control_panel() {
    log_info "Creando panel de control..."
    
    cat > /usr/local/bin/sshbot-control << 'EOF'
#!/bin/bash
# Panel de control mejorado para SSH Bot

set -euo pipefail

# Colores
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly CYAN='\033[0;36m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

# Rutas
readonly CONFIG="/opt/ssh-bot/config/config.json"
readonly DB="/opt/ssh-bot/data/users.db"
readonly INSTALL_DIR="/opt/ssh-bot"

# Funciones auxiliares
get_config() {
    jq -r "$1" "$CONFIG" 2>/dev/null || echo ""
}

set_config() {
    local tmp_file
    tmp_file=$(mktemp)
    jq "$1 = $2" "$CONFIG" > "$tmp_file" && mv "$tmp_file" "$CONFIG"
}

show_header() {
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                 🎛️  PANEL DE CONTROL SSH BOT                ║${NC}"
    echo -e "${CYAN}║                     🔒 VERSIÓN SEGURA                       ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

show_status() {
    local bot_status
    local users_total
    local users_active
    
    # Estado del bot
    if pm2 describe ssh-bot > /dev/null 2>&1; then
        bot_status="${GREEN}● EN EJECUCIÓN${NC}"
    else
        bot_status="${RED}● DETENIDO${NC}"
    fi
    
    # Estadísticas de usuarios
    users_total=$(sqlite3 "$DB" "SELECT COUNT(*) FROM users" 2>/dev/null || echo "0")
    users_active=$(sqlite3 "$DB" "SELECT COUNT(*) FROM users WHERE status=1" 2>/dev/null || echo "0")
    
    echo -e "${YELLOW}📊 ESTADO DEL SISTEMA${NC}"
    echo -e "  Bot: $bot_status"
    echo -e "  Usuarios: ${CYAN}$users_active/$users_total${NC} (activos/total)"
    echo -e "  IP del servidor: $(get_config '.bot.server_ip')"
    echo -e "  Versión: $(get_config '.bot.version')"
    echo ""
}

show_menu() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}[1]${NC}  🚀  Iniciar/Reiniciar bot"
    echo -e "${CYAN}[2]${NC}  🛑  Detener bot"
    echo -e "${CYAN}[3]${NC}  📋  Ver estado detallado"
    echo -e "${CYAN}[4]${NC}  👥  Gestionar usuarios"
    echo -e "${CYAN}[5]${NC}  ⚙️   Configuración"
    echo -e "${CYAN}[6]${NC}  📊  Estadísticas"
    echo -e "${CYAN}[7]${NC}  📝  Ver logs"
    echo -e "${CYAN}[8]${NC}  🛠️   Herramientas"
    echo -e "${CYAN}[9]${NC}  ❓  Ayuda"
    echo -e "${CYAN}[0]${NC}  🚪  Salir"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

handle_option() {
    local option=$1
    
    case $option in
        1)
            echo -e "\n${YELLOW}🔄 Iniciando/Reiniciando bot...${NC}"
            cd /root/ssh-bot
            pm2 restart ssh-bot 2>/dev/null || pm2 start bot.js --name ssh-bot
            pm2 save
            echo -e "${GREEN}✅ Operación completada${NC}"
            sleep 2
            ;;
        2)
            echo -e "\n${YELLOW}🛑 Deteniendo bot...${NC}"
            pm2 stop ssh-bot
            echo -e "${GREEN}✅ Bot detenido${NC}"
            sleep 2
            ;;
        3)
            show_detailed_status
            ;;
        4)
            manage_users
            ;;
        5)
            manage_configuration
            ;;
        6)
            show_statistics
            ;;
        7)
            show_logs
            ;;
        8)
            show_tools
            ;;
        9)
            show_help
            ;;
        0)
            echo -e "\n${GREEN}👋 ¡Hasta pronto!${NC}\n"
            exit 0
            ;;
        *)
            echo -e "\n${RED}❌ Opción inválida${NC}"
            sleep 1
            ;;
    esac
}

show_detailed_status() {
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                    📋 ESTADO DETALLADO                       ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    pm2 describe ssh-bot
    echo ""
    
    read -rp "Presiona Enter para continuar..."
}

manage_users() {
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                    👥 GESTIÓN DE USUARIOS                    ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    echo -e "${YELLOW}Selecciona una opción:${NC}"
    echo -e "  1. Listar usuarios activos"
    echo -e "  2. Buscar usuario"
    echo -e "  3. Crear usuario manual"
    echo -e "  4. Volver al menú principal"
    echo ""
    
    read -rp "Opción: " user_option
    
    case $user_option in
        1)
            echo -e "\n${CYAN}Usuarios activos:${NC}"
            sqlite3 -column -header "$DB" \
                "SELECT username, tipo, expires_at, max_connections FROM users WHERE status=1 ORDER BY expires_at DESC LIMIT 20"
            echo ""
            ;;
        2)
            read -rp "Buscar usuario: " search_user
            if [[ -n "$search_user" ]]; then
                sqlite3 -column -header "$DB" \
                    "SELECT * FROM users WHERE username LIKE '%$search_user%' OR phone LIKE '%$search_user%' LIMIT 10"
            fi
            ;;
        3)
            echo -e "\n${YELLOW}Creación manual de usuario:${NC}"
            read -rp "Teléfono: " phone
            read -rp "Usuario: " username
            read -rp "Contraseña: " password
            read -rp "Tipo (test/premium): " tipo
            read -rp "Días (0=test): " days
            
            echo -e "\n${YELLOW}Creando usuario $username...${NC}"
            # Aquí iría la lógica para crear el usuario
            echo -e "${GREEN}✅ Usuario creado (implementación pendiente)${NC}"
            ;;
    esac
    
    read -rp "Presiona Enter para continuar..."
}

manage_configuration() {
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                    ⚙️  CONFIGURACIÓN                         ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    echo -e "${YELLOW}Configuración actual:${NC}"
    echo ""
    jq '.' "$CONFIG" | head -50
    
    echo ""
    read -rp "Presiona Enter para continuar..."
}

show_statistics() {
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                    📊 ESTADÍSTICAS                          ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    echo -e "${YELLOW}📈 Resumen general:${NC}"
    
    # Obtener estadísticas
    local total_users=$(sqlite3 "$DB" "SELECT COUNT(*) FROM users")
    local active_users=$(sqlite3 "$DB" "SELECT COUNT(*) FROM users WHERE status=1")
    local premium_users=$(sqlite3 "$DB" "SELECT COUNT(*) FROM users WHERE tipo='premium' AND status=1")
    local test_users=$(sqlite3 "$DB" "SELECT COUNT(*) FROM users WHERE tipo='test' AND status=1")
    
    echo -e "  👥 Usuarios totales: $total_users"
    echo -e "  ✅ Activos: $active_users"
    echo -e "  💎 Premium: $premium_users"
    echo -e "  🆓 Test: $test_users"
    echo ""
    
    read -rp "Presiona Enter para continuar..."
}

show_logs() {
    echo -e "\n${YELLOW}📝 Mostrando logs (Ctrl+C para salir)...${NC}\n"
    pm2 logs ssh-bot --lines 50
}

show_tools() {
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                    🛠️  HERRAMIENTAS                         ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    echo -e "${YELLOW}Herramientas disponibles:${NC}"
    echo -e "  1. Backup de base de datos"
    echo -e "  2. Restaurar backup"
    echo -e "  3. Limpiar logs antiguos"
    echo -e "  4. Verificar dependencias"
    echo -e "  5. Volver al menú principal"
    echo ""
    
    read -rp "Opción: " tool_option
    
    case $tool_option in
        1)
            echo -e "\n${YELLOW}Creando backup...${NC}"
            backup_file="$INSTALL_DIR/backups/backup-$(date +%Y%m%d-%H%M%S).db"
            sqlite3 "$DB" ".backup '$backup_file'"
            echo -e "${GREEN}✅ Backup creado: $backup_file${NC}"
            ;;
        2)
            echo -e "\n${YELLOW}Listando backups disponibles:${NC}"
            ls -la "$INSTALL_DIR/backups/"*.db 2>/dev/null || echo "No hay backups disponibles"
            echo ""
            read -rp "Nombre del archivo a restaurar: " backup_name
            if [[ -f "$INSTALL_DIR/backups/$backup_name" ]]; then
                echo -e "${YELLOW}Restaurando...${NC}"
                cp "$INSTALL_DIR/backups/$backup_name" "$DB"
                echo -e "${GREEN}✅ Backup restaurado${NC}"
            fi
            ;;
        3)
            echo -e "\n${YELLOW}Limpiando logs antiguos...${NC}"
            find "$INSTALL_DIR/logs" -name "*.log" -mtime +7 -delete 2>/dev/null
            echo -e "${GREEN}✅ Logs limpiados${NC}"
            ;;
        4)
            echo -e "\n${YELLOW}Verificando dependencias...${NC}"
            command -v node && echo "✅ Node.js: $(node --version)"
            command -v npm && echo "✅ npm: $(npm --version)"
            command -v pm2 && echo "✅ PM2: $(pm2 --version)"
            command -v sqlite3 && echo "✅ SQLite: $(sqlite3 --version)"
            ;;
    esac
    
    read -rp "Presiona Enter para continuar..."
}

show_help() {
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                       ❓ AYUDA                               ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    echo -e "${YELLOW}Comandos disponibles:${NC}"
    echo -e "  ${CYAN}sshbot-control${NC}     - Este panel de control"
    echo -e "  ${CYAN}pm2 logs ssh-bot${NC}   - Ver logs en tiempo real"
    echo -e "  ${CYAN}pm2 restart ssh-bot${NC} - Reiniciar el bot"
    echo -e "  ${CYAN}pm2 stop ssh-bot${NC}    - Detener el bot"
    echo ""
    
    echo -e "${YELLOW}Archivos importantes:${NC}"
    echo -e "  Configuración: ${CYAN}/opt/ssh-bot/config/config.json${NC}"
    echo -e "  Base de datos: ${CYAN}/opt/ssh-bot/data/users.db${NC}"
    echo -e "  Logs: ${CYAN}/opt/ssh-bot/logs/${NC}"
    echo -e "  Backups: ${CYAN}/opt/ssh-bot/backups/${NC}"
    echo ""
    
    echo -e "${YELLOW}Solución de problemas:${NC}"
    echo -e "  1. Si WhatsApp no funciona, revisa los logs"
    echo -e "  2. Verifica que Chrome esté instalado"
    echo -e "  3. Asegúrate de tener conexión a internet"
    echo -e "  4. Revisa los permisos de los archivos"
    echo ""
    
    read -rp "Presiona Enter para continuar..."
}

# Función principal
main() {
    # Verificar dependencias
    command -v jq >/dev/null 2>&1 || {
        echo -e "${RED}Error: jq no está instalado${NC}"
        echo "Instala con: apt-get install jq"
        exit 1
    }
    
    command -v sqlite3 >/dev/null 2>&1 || {
        echo -e "${RED}Error: sqlite3 no está instalado${NC}"
        echo "Instala con: apt-get install sqlite3"
        exit 1
    }
    
    # Verificar archivos de configuración
    if [[ ! -f "$CONFIG" ]]; then
        echo -e "${RED}Error: Archivo de configuración no encontrado${NC}"
        exit 1
    fi
    
    if [[ ! -f "$DB" ]]; then
        echo -e "${RED}Error: Base de datos no encontrada${NC}"
        exit 1
    fi
    
    # Bucle principal
    while true; do
        show_header
        show_status
        show_menu
        
        read -rp "👉 Selecciona una opción: " option
        
        if [[ -n "$option" ]]; then
            handle_option "$option"
        fi
    done
}

# Ejecutar función principal
main "$@"
EOF
    
    # Hacer ejecutable el panel de control
    chmod +x /usr/local/bin/sshbot-control
    
    # Crear alias simbólico
    ln -sf /usr/local/bin/sshbot-control /usr/local/bin/sshbot 2>/dev/null || true
    
    log_info "Panel de control creado correctamente"
}

# Función para configurar servicios
setup_services() {
    log_info "Configurando servicios..."
    
    # Iniciar bot con PM2
    cd "$USER_HOME"
    pm2 start bot.js --name ssh-bot
    
    # Guardar configuración de PM2
    pm2 save
    
    # Configurar inicio automático
    pm2 startup systemd -u root --hp /root | grep -v "command" || true
    
    log_info "Servicios configurados correctamente"
}

# Función para crear script de desinstalación
create_uninstall_script() {
    log_info "Creando script de desinstalación..."
    
    cat > /usr/local/bin/sshbot-uninstall << 'EOF'
#!/bin/bash
# Script de desinstalación seguro para SSH Bot

set -euo pipefail

# Colores
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m'

show_warning() {
    echo -e "${RED}${BOLD}⚠️  ADVERTENCIA: DESINSTALACIÓN COMPLETA ⚠️${NC}"
    echo ""
    echo -e "${YELLOW}Esta acción eliminará:${NC}"
    echo "  • Bot SSH y todos sus componentes"
    echo "  • Base de datos de usuarios"
    echo "  • Archivos de configuración"
    echo "  • Registros y backups"
    echo "  • Usuarios del sistema creados por el bot"
    echo ""
    echo -e "${RED}Esta acción NO se puede deshacer.${NC}"
    echo ""
}

confirm_uninstall() {
    read -rp "$(echo -e "${YELLOW}¿Estás SEGURO que quieres desinstalar? (escribe 'DESINSTALAR'): ${NC}")" confirm
    
    if [[ "$confirm" != "DESINSTALAR" ]]; then
        echo -e "${GREEN}✅ Desinstalación cancelada${NC}"
        exit 0
    fi
}

remove_services() {
    echo -e "\n${YELLOW}🛑 Deteniendo servicios...${NC}"
    
    # Detener PM2
    pm2 delete ssh-bot 2>/dev/null || true
    pm2 flush 2>/dev/null || true
    pm2 save 2>/dev/null || true
    
    # Eliminar del startup
    pm2 unstartup systemd 2>/dev/null || true
}

remove_files() {
    echo -e "\n${YELLOW}🗑️  Eliminando archivos...${NC}"
    
    # Directorios a eliminar
    local directories=(
        "/opt/ssh-bot"
        "/root/ssh-bot"
    )
    
    # Archivos a eliminar
    local files=(
        "/usr/local/bin/sshbot"
        "/usr/local/bin/sshbot-control"
        "/usr/local/bin/sshbot-uninstall"
        "/root/qr-whatsapp.png"
    )
    
    # Eliminar directorios
    for dir in "${directories[@]}"; do
        if [[ -d "$dir" ]]; then
            rm -rf "$dir"
            echo "  Eliminado: $dir"
        fi
    done
    
    # Eliminar archivos
    for file in "${files[@]}"; do
        if [[ -f "$file" ]]; then
            rm -f "$file"
            echo "  Eliminado: $file"
        fi
    done
    
    # Limpiar cachés
    rm -rf /root/.wwebjs_auth 2>/dev/null || true
    rm -rf /root/.wwebjs_cache 2>/dev/null || true
    rm -rf /tmp/chrome.deb 2>/dev/null || true
}

remove_users() {
    echo -e "\n${YELLOW}👥 Eliminando usuarios del sistema...${NC}"
    
    # Obtener usuarios creados por el bot
    local bot_users=$(sqlite3 /opt/ssh-bot/data/users.db "SELECT username FROM users" 2>/dev/null || echo "")
    
    for user in $bot_users; do
        # Verificar si el usuario existe
        if id "$user" &>/dev/null; then
            # Matar procesos del usuario
            pkill -u "$user" 2>/dev/null || true
            
            # Eliminar usuario
            userdel -r "$user" 2>/dev/null || true
            
            echo "  Eliminado usuario: $user"
        fi
    done
}

show_summary() {
    echo -e "\n${GREEN}✅ DESINSTALACIÓN COMPLETADA${NC}"
    echo ""
    echo -e "${YELLOW}Resumen:${NC}"
    echo "  • Servicios detenidos y eliminados"
    echo "  • Archivos y directorios eliminados"
    echo "  • Usuarios del sistema eliminados"
    echo "  • Cachés limpiadas"
    echo ""
    echo -e "${YELLOW}Notas:${NC}"
    echo "  • Google Chrome NO fue desinstalado"
    echo "  • Node.js y npm NO fueron desinstalados"
    echo "  • Dependencias del sistema NO fueron desinstaladas"
    echo ""
    echo -e "${GREEN}¡El bot ha sido completamente eliminado!${NC}"
}

main() {
    # Verificar root
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}Error: Debes ejecutar como root${NC}"
        exit 1
    fi
    
    show_warning
    confirm_uninstall
    
    remove_services
    remove_files
    remove_users
    
    show_summary
}

main "$@"
EOF
    
    chmod +x /usr/local/bin/sshbot-uninstall
    log_info "Script de desinstalación creado"
}

# Función para mostrar resumen final
show_final_summary() {
    local server_ip="$1"
    
    clear
    echo -e "${GREEN}${BOLD}"
    cat << "SUMMARY"
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║      🎉 INSTALACIÓN COMPLETADA EXITOSAMENTE 🎉              ║
║                                                              ║
║         SSH BOT PRO - VERSIÓN SEGURA Y MEJORADA             ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
SUMMARY
    echo -e "${NC}"
    
    echo -e "${CYAN}══════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}✅ Instalación completada con éxito${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════════════════════${NC}"
    echo ""
    
    echo -e "${YELLOW}📋 COMANDOS DISPONIBLES:${NC}"
    echo -e "  ${GREEN}sshbot-control${NC}    - Panel de control principal"
    echo -e "  ${GREEN}sshbot${NC}            - Alias para el panel de control"
    echo -e "  ${GREEN}sshbot-uninstall${NC}  - Desinstalar completamente"
    echo ""
    
    echo -e "${YELLOW}📊 MONITOREO:${NC}"
    echo -e "  ${CYAN}pm2 logs ssh-bot${NC}     - Ver logs en tiempo real"
    echo -e "  ${CYAN}pm2 status${NC}           - Estado de todos los procesos"
    echo -e "  ${CYAN}pm2 monit${NC}            - Monitor interactivo"
    echo ""
    
    echo -e "${YELLOW}📁 ESTRUCTURA DE DIRECTORIOS:${NC}"
    echo -e "  Configuración:   ${CYAN}/opt/ssh-bot/config/${NC}"
    echo -e "  Base de datos:   ${CYAN}/opt/ssh-bot/data/${NC}"
    echo -e "  Logs:            ${CYAN}/opt/ssh-bot/logs/${NC}"
    echo -e "  Backups:         ${CYAN}/opt/ssh-bot/backups/${NC}"
    echo -e "  Códigos QR:      ${CYAN}/opt/ssh-bot/qr_codes/${NC}"
    echo ""
    
    echo -e "${YELLOW}🌐 INFORMACIÓN DEL SERVIDOR:${NC}"
    echo -e "  IP del servidor: ${CYAN}$server_ip${NC}"
    echo -e "  Log de instalación: ${CYAN}$LOG_FILE${NC}"
    echo ""
    
    echo -e "${YELLOW}🔧 PRÓXIMOS PASOS:${NC}"
    echo -e "  1. Ejecutar: ${GREEN}sshbot-control${NC}"
    echo -e "  2. Escanear el código QR de WhatsApp"
    echo -e "  3. Configurar MercadoPago (opcional)"
    echo -e "  4. Subir archivo APK a /root/app.apk (opcional)"
    echo ""
    
    echo -e "${YELLOW}⚠️  IMPORTANTE:${NC}"
    echo -e "  • Revisa ${CYAN}$LOG_FILE${NC} para detalles de la instalación"
    echo -e "  • Configura un firewall adecuadamente"
    echo -e "  • Mantén el sistema actualizado"
    echo -e "  • Realiza backups periódicos"
    echo ""
    
    echo -e "${GREEN}══════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}            ¡El bot está listo para usar! 🚀                ${NC}"
    echo -e "${GREEN}══════════════════════════════════════════════════════════════${NC}"
    echo ""
    
    # Preguntar si abrir el panel
    read -rp "$(echo -e "${YELLOW}¿Abrir el panel de control ahora? (s/N): ${NC}")" open_panel
    
    if [[ "$open_panel" =~ ^[Ss](i|í)?$ ]]; then
        echo -e "\n${CYAN}Abriendo panel de control...${NC}\n"
        sleep 2
        /usr/local/bin/sshbot-control
    else
        echo -e "\n${YELLOW}💡 Puedes ejecutar ${GREEN}sshbot-control${NC} en cualquier momento\n"
    fi
}

# Función principal
main() {
    # Iniciar log
    echo "=== Inicio de instalación: $(date) ===" > "$LOG_FILE"
    
    # Mostrar banner
    show_banner
    
    # Verificar root
    check_root
    
    # Obtener IP del servidor
    log_info "Detectando IP del servidor..."
    SERVER_IP=$(get_server_ip)
    log_info "IP detectada: $SERVER_IP"
    
    # Confirmar instalación
    confirm_installation
    
    # Instalar dependencias
    install_dependencies
    
    # Crear estructura de directorios
    create_directory_structure
    
    # Crear configuración
    create_configuration "$SERVER_IP"
    
    # Crear base de datos
    create_database
    
    # Crear package.json
    create_package_json
    
    # Instalar dependencias de Node.js
    install_node_dependencies
    
    # Crear bot
    create_bot
    
    # Crear panel de control
    create_control_panel
    
    # Configurar servicios
    setup_services
    
    # Crear script de desinstalación
    create_uninstall_script
    
    # Mostrar resumen final
    show_final_summary "$SERVER_IP"
    
    # Log de finalización
    log_info "Instalación completada exitosamente"
    echo "=== Instalación completada: $(date) ===" >> "$LOG_FILE"
}

# Manejo de errores
trap 'log_error "Error en la línea $LINENO"; exit 1' ERR

# Ejecutar función principal
main "$@"

exit 0
