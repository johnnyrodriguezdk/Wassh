#!/bin/bash
# ================================================
# ACTUALIZACIÓN SSH BOT - COMANDOS SIMPLES + IA
# Mantiene tu bot funcional y agrega mejoras
# ================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}"
echo "╔═══════════════════════════════════════════════╗"
echo "║      ACTUALIZACIÓN BOT - COMANDOS SIMPLES    ║"
echo "╚═══════════════════════════════════════════════╝"
echo -e "${NC}"

# Verificar si el bot está instalado
if [ ! -d "/root/ssh-bot" ]; then
    echo -e "${RED}❌ No se encontró el bot instalado${NC}"
    echo -e "Ejecuta primero: bash install.sh"
    exit 1
fi

echo -e "${YELLOW}📋 Estado actual del bot:${NC}"
pm2 list | grep ssh-bot || echo "Bot no encontrado en PM2"

echo -e "\n${YELLOW}⚠️  Esta actualización hará:${NC}"
echo "   • Crear backup del bot actual"
echo "   • Agregar comandos simples (prueba, basico, estandar, premium)"
echo "   • Agregar asistente de compra paso a paso"
echo "   • Mantener toda tu configuración actual"
echo "   • No eliminará usuarios ni base de datos"

read -p "$(echo -e "${YELLOW}¿Continuar? (s/N): ${NC}")" -n 1 -r
echo
if [[ ! $REPLY =~ ^[Ss]$ ]]; then
    echo -e "${RED}❌ Actualización cancelada${NC}"
    exit 0
fi

# Crear backup
echo -e "\n${CYAN}💾 Creando backup...${NC}"
BACKUP_DIR="/root/ssh-bot-backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"
cp -r /root/ssh-bot/* "$BACKUP_DIR/" 2>/dev/null || true
cp /opt/ssh-bot/data/users.db "$BACKUP_DIR/users.db.backup" 2>/dev/null || true
echo -e "${GREEN}✅ Backup creado en: $BACKUP_DIR${NC}"

# Detener bot temporalmente
echo -e "\n${YELLOW}⏸️  Deteniendo bot...${NC}"
pm2 stop ssh-bot 2>/dev/null || true

# Agregar dependencias necesarias
echo -e "\n${CYAN}📦 Actualizando dependencias...${NC}"
cd /root/ssh-bot

# Agregar nuevas dependencias al package.json
if ! grep -q "axios" package.json; then
    echo -e "${YELLOW}➕ Agregando dependencias...${NC}"
    npm install axios node-cron --save --silent
fi

# Actualizar el bot.js con comandos simples
echo -e "\n${CYAN}🤖 Actualizando bot con comandos simples...${NC}"

# Crear nueva versión del bot (preservando tu lógica actual)
cat > /root/ssh-bot/bot-mejorado.js << 'BOTEOF'
// ================================================
// SSH BOT PRO - VERSIÓN MEJORADA
// Comandos simples + Asistente IA
// ================================================

const { Client, LocalAuth, MessageMedia } = require('whatsapp-web.js');
const qrcode = require('qrcode-terminal');
const QRCode = require('qrcode');
const moment = require('moment');
const sqlite3 = require('sqlite3').verbose();
const chalk = require('chalk');
const cron = require('node-cron');
const { exec } = require('child_process');
const util = require('util');
const fs = require('fs');

const execPromise = util.promisify(exec);

// Cargar configuración
function loadConfig() {
    try {
        return require('/opt/ssh-bot/config/config.json');
    } catch (error) {
        console.error(chalk.red('❌ Error cargando configuración:'), error.message);
        process.exit(1);
    }
}

const config = loadConfig();
const db = new sqlite3.Database(config.paths.database);
moment.locale('es');

// Estados para asistente IA
const userSessions = {};

// Clase AsistenteSimple
class AsistenteSimple {
    constructor(phone) {
        this.phone = phone;
        this.step = 0;
        this.data = {};
        this.planSelected = null;
    }
    
    async processMessage(text) {
        const textLower = text.toLowerCase().trim();
        
        switch(this.step) {
            case 0: // Inicio
                this.step = 1;
                return this.showPlans();
                
            case 1: // Selección de plan
                return await this.selectPlan(textLower);
                
            case 2: // Confirmación
                return await this.confirmPurchase(textLower);
                
            default:
                return { done: true, message: '✅ Proceso completado' };
        }
    }
    
    showPlans() {
        const message = `📋 *PLANES DISPONIBLES*\n\n` +
                       `🥉 *BASICO* (7 días)\n` +
                       `💰 $${config.prices.price_7d} ARS\n` +
                       `👉 Comando: *basico*\n\n` +
                       `🥈 *ESTANDAR* (15 días)\n` +
                       `💰 $${config.prices.price_15d} ARS\n` +
                       `👉 Comando: *estandar*\n\n` +
                       `🥇 *PREMIUM* (30 días)\n` +
                       `💰 $${config.prices.price_30d} ARS\n` +
                       `👉 Comando: *premium*\n\n` +
                       `🆓 *PRUEBA* (2 horas)\n` +
                       `💰 $0 ARS\n` +
                       `👉 Comando: *prueba*\n\n` +
                       `💡 *Responde con el nombre del plan*`;
        
        return { done: false, message };
    }
    
    async selectPlan(text) {
        const plans = {
            'prueba': { name: 'PRUEBA GRATIS', days: 0, price: 0 },
            'basico': { name: 'PLAN BÁSICO', days: 7, price: config.prices.price_7d },
            'estandar': { name: 'PLAN ESTÁNDAR', days: 15, price: config.prices.price_15d },
            'premium': { name: 'PLAN PREMIUM', days: 30, price: config.prices.price_30d }
        };
        
        if (plans[text]) {
            this.planSelected = text;
            this.data.plan = plans[text];
            this.step = 2;
            
            const plan = plans[text];
            const message = `✅ *PLAN SELECCIONADO: ${plan.name}*\n\n` +
                           `⏰ Duración: ${plan.days > 0 ? `${plan.days} días` : '2 horas'}\n` +
                           `💰 Precio: ${plan.price > 0 ? `$${plan.price} ARS` : 'GRATIS'}\n` +
                           `🔌 Conexiones: 1\n\n` +
                           `👉 *¿Confirmar compra? Responde "si" o "no"*`;
            
            return { done: false, message };
        }
        
        return { done: false, message: '❌ Plan no válido. Opciones: prueba, basico, estandar, premium' };
    }
    
    async confirmPurchase(text) {
        if (text.includes('si') || text.includes('sí')) {
            this.step = 3;
            return { done: true, message: '✅ Compra confirmada. Procesando...', plan: this.planSelected };
        } else if (text.includes('no')) {
            this.step = 1;
            return { done: false, message: '🔙 Volviendo a selección de planes...' };
        }
        
        return { done: false, message: '❓ Responde "si" para confirmar o "no" para cancelar' };
    }
}

// Funciones de utilidad
function generateUsername() {
    return 'user' + Math.random().toString(36).substr(2, 6);
}

function generatePassword() {
    return Math.random().toString(36).substr(2, 10) + Math.random().toString(36).substr(2, 4).toUpperCase();
}

// Cliente WhatsApp
const client = new Client({
    authStrategy: new LocalAuth({ dataPath: '/root/.wwebjs_auth', clientId: 'ssh-bot-mejorado' }),
    puppeteer: {
        headless: true,
        args: ['--no-sandbox', '--disable-setuid-sandbox', '--disable-dev-shm-usage']
    }
});

// Eventos
client.on('qr', (qr) => {
    console.log(chalk.yellow('🔐 QR para WhatsApp:'));
    qrcode.generate(qr, { small: true });
});

client.on('ready', () => {
    console.log(chalk.green('✅ Bot mejorado listo!'));
    console.log(chalk.cyan('📋 Comandos simples activados:'));
    console.log(chalk.cyan('   • prueba, basico, estandar, premium'));
    console.log(chalk.cyan('   • comprar (asistente paso a paso)'));
    console.log(chalk.cyan('   • ayuda, menu, app'));
});

// Manejo de mensajes MEJORADO
client.on('message', async (msg) => {
    const text = msg.body.toLowerCase().trim();
    const phone = msg.from;
    
    if (phone.includes('@g.us')) return;
    
    console.log(chalk.cyan(`📩 [${phone}]: ${text.substring(0, 30)}`));
    
    // COMANDOS SIMPLES MEJORADOS
    if (text === 'menu' || text === 'hola') {
        await sendMenu(phone);
        return;
    }
    
    // Asistente de compra
    if (text === 'comprar') {
        userSessions[phone] = new AsistenteSimple(phone);
        const response = await userSessions[phone].processMessage('');
        await client.sendMessage(phone, response.message, { sendSeen: true });
        return;
    }
    
    // Si hay sesión activa
    if (userSessions[phone]) {
        const response = await userSessions[phone].processMessage(text);
        await client.sendMessage(phone, response.message, { sendSeen: true });
        
        if (response.done && response.plan) {
            await handlePlanPurchase(phone, response.plan);
            delete userSessions[phone];
        }
        return;
    }
    
    // Comandos directos
    switch(text) {
        case 'prueba':
            await handleFreeTrial(phone);
            break;
            
        case 'basico':
            await startPurchase(phone, 'basico', config.prices.price_7d, 7);
            break;
            
        case 'estandar':
            await startPurchase(phone, 'estandar', config.prices.price_15d, 15);
            break;
            
        case 'premium':
            await startPurchase(phone, 'premium', config.prices.price_30d, 30);
            break;
            
        case 'ayuda':
            await sendHelp(phone);
            break;
            
        case 'app':
            await sendApp(phone);
            break;
            
        default:
            // Si no es un comando reconocido, mostrar ayuda
            await client.sendMessage(phone, 
                `🤖 *No entendí ese comando*\n\n` +
                `📋 *Comandos disponibles:*\n` +
                `• *prueba* - 2 horas gratis\n` +
                `• *basico* - Plan 7 días\n` +
                `• *estandar* - Plan 15 días\n` +
                `• *premium* - Plan 30 días\n` +
                `• *comprar* - Asistente de compra\n` +
                `• *ayuda* - Centro de ayuda\n` +
                `• *menu* - Ver menú principal`,
                { sendSeen: true }
            );
    }
});

// Función para mostrar menú
async function sendMenu(phone) {
    await client.sendMessage(phone,
        `🎛️ *MENÚ PRINCIPAL - SSH BOT*\n\n` +
        `🆓 *prueba* - Prueba GRATIS 2h\n` +
        `💰 *PLANES:*\n` +
        `  • *basico* - 7 días ($500)\n` +
        `  • *estandar* - 15 días ($800)\n` +
        `  • *premium* - 30 días ($1200)\n\n` +
        `🤖 *comprar* - Asistente de compra\n` +
        `🆘 *ayuda* - Centro de ayuda\n` +
        `📱 *app* - Descargar aplicación\n\n` +
        `💡 *Ejemplo:* Envía *basico* para comprar`,
        { sendSeen: true }
    );
}

// Función para prueba gratis
async function handleFreeTrial(phone) {
    try {
        const today = moment().format('YYYY-MM-DD');
        
        // Verificar si ya usó prueba hoy
        db.get('SELECT COUNT(*) as count FROM daily_tests WHERE phone = ? AND date = ?', 
            [phone, today], async (err, row) => {
                if (err || (row && row.count > 0)) {
                    await client.sendMessage(phone,
                        `⚠️ *YA USASTE TU PRUEBA HOY*\n\n` +
                        `⏳ Vuelve mañana\n` +
                        `💰 *Escribe *basico* para ver planes pagos*`,
                        { sendSeen: true }
                    );
                    return;
                }
                
                // Crear usuario de prueba
                const username = generateUsername();
                const password = generatePassword();
                
                await createSSHUser(phone, username, password, 0);
                db.run('INSERT INTO daily_tests (phone, date) VALUES (?, ?)', [phone, today]);
                
                await client.sendMessage(phone,
                    `🎉 *PRUEBA ACTIVADA*\n\n` +
                    `👤 Usuario: *${username}*\n` +
                    `🔑 Contraseña: *${password}*\n` +
                    `⏰ Duración: 2 horas\n` +
                    `🔌 Conexiones: 1\n\n` +
                    `📱 Descarga la app (envía *app*)\n` +
                    `💎 ¿Te gustó? Escribe *basico*`,
                    { sendSeen: true }
                );
            }
        );
    } catch (error) {
        await client.sendMessage(phone,
            `❌ Error: ${error.message}\n\nEscribe *ayuda* para soporte`,
            { sendSeen: true }
        );
    }
}

// Función para crear usuario SSH
async function createSSHUser(phone, username, password, days) {
    const tipo = days === 0 ? 'test' : 'premium';
    const expireFull = days === 0 
        ? moment().add(2, 'hours').format('YYYY-MM-DD HH:mm:ss')
        : moment().add(days, 'days').format('YYYY-MM-DD 23:59:59');
    
    try {
        if (days === 0) {
            await execPromise(`useradd -m -s /bin/bash ${username}`);
            await execPromise(`echo "${username}:${password}" | chpasswd`);
        } else {
            const expireDate = moment().add(days, 'days').format('YYYY-MM-DD');
            await execPromise(`useradd -M -s /bin/false -e ${expireDate} ${username}`);
            await execPromise(`echo "${username}:${password}" | chpasswd`);
        }
        
        return new Promise((resolve, reject) => {
            db.run(`INSERT INTO users (phone, username, password, tipo, expires_at, max_connections, status) VALUES (?, ?, ?, ?, ?, ?, 1)`,
                [phone, username, password, tipo, expireFull, 1],
                (err) => err ? reject(err) : resolve(true)
            );
        });
    } catch (error) {
        throw error;
    }
}

// Función para iniciar compra
async function startPurchase(phone, plan, price, days) {
    await client.sendMessage(phone,
        `🔄 *PROCESANDO: ${plan.toUpperCase()}*\n\n` +
        `💰 Precio: $${price} ARS\n` +
        `⏰ Duración: ${days} días\n` +
        `🔌 Conexiones: 1\n\n` +
        `⚠️ *SISTEMA DE PAGOS EN MANTENIMIENTO*\n\n` +
        `📞 Contacta a soporte para completar tu compra:\n` +
        `${config.links?.support || 'No configurado'}`,
        { sendSeen: true }
    );
}

// Función para manejar compra desde asistente
async function handlePlanPurchase(phone, plan) {
    const plans = {
        'prueba': { price: 0, days: 0 },
        'basico': { price: config.prices.price_7d, days: 7 },
        'estandar': { price: config.prices.price_15d, days: 15 },
        'premium': { price: config.prices.price_30d, days: 30 }
    };
    
    const planInfo = plans[plan];
    
    if (plan === 'prueba') {
        await handleFreeTrial(phone);
    } else {
        await startPurchase(phone, plan, planInfo.price, planInfo.days);
    }
}

// Función para enviar ayuda
async function sendHelp(phone) {
    await client.sendMessage(phone,
        `🆘 *CENTRO DE AYUDA*\n\n` +
        `📋 *Comandos rápidos:*\n` +
        `• *prueba* - 2 horas gratis\n` +
        `• *basico/estandar/premium* - Comprar plan\n` +
        `• *comprar* - Asistente paso a paso\n` +
        `• *menu* - Volver al menú\n\n` +
        `📞 *Soporte:*\n` +
        `${config.links?.support || 'No configurado'}\n\n` +
        `💡 *Problemas comunes:*\n` +
        `• No veo el QR → Reinicia el bot\n` +
        `• Error en pago → Contacta soporte\n` +
        `• No funciona → Verifica conexión`,
        { sendSeen: true }
    );
}

// Función para enviar aplicación
async function sendApp(phone) {
    const apkPath = '/root/app.apk';
    
    if (fs.existsSync(apkPath)) {
        try {
            const media = MessageMedia.fromFilePath(apkPath);
            await client.sendMessage(phone, media, {
                caption: '📱 *APLICACIÓN SSH CLIENT*\n\n' +
                        '1. Instala este archivo\n' +
                        '2. Permite "Fuentes desconocidas"\n' +
                        '3. Abre la app y ingresa tus datos',
                sendSeen: true
            });
        } catch (error) {
            await client.sendMessage(phone,
                `❌ No se pudo enviar el APK\n\n` +
                `📥 Descarga manual desde:\n` +
                `http://${config.bot.server_ip}:8000/app.apk`,
                { sendSeen: true }
            );
        }
    } else {
        await client.sendMessage(phone,
            '❌ APK no disponible en el servidor\n\n📞 Contacta al administrador',
            { sendSeen: true }
        );
    }
}

// Inicializar cliente
client.initialize();

// Limpieza automática
cron.schedule('*/15 * * * *', () => {
    const now = moment().format('YYYY-MM-DD HH:mm:ss');
    db.all('SELECT username FROM users WHERE expires_at < ? AND status = 1', [now], (err, rows) => {
        if (!err && rows) {
            rows.forEach(row => {
                exec(`pkill -u ${row.username} 2>/dev/null; userdel -f ${row.username} 2>/dev/null`);
                db.run('UPDATE users SET status = 0 WHERE username = ?', [row.username]);
            });
        }
    });
});

console.log(chalk.green('\n🚀 Bot mejorado iniciado - Comandos simples activados'));
BOTEOF

# Preservar tu bot original como backup
if [ -f "/root/ssh-bot/bot.js" ]; then
    mv /root/ssh-bot/bot.js /root/ssh-bot/bot-original-$(date +%H%M%S).js
fi

# Copiar el bot mejorado
cp /root/ssh-bot/bot-mejorado.js /root/ssh-bot/bot.js

# Crear panel de control simple
cat > /usr/local/bin/sshbot-simple << 'PANEL_EOF'
#!/bin/bash
echo "╔═══════════════════════════════════════════════╗"
echo "║        PANEL SSH BOT - COMANDOS SIMPLES     ║"
echo "╚═══════════════════════════════════════════════╝"
echo ""
echo "📋 Comandos activados en el bot:"
echo "  • prueba    - Prueba gratis 2h"
echo "  • basico    - Plan 7 días ($500)"
echo "  • estandar  - Plan 15 días ($800)"
echo "  • premium   - Plan 30 días ($1200)"
echo "  • comprar   - Asistente paso a paso"
echo "  • ayuda     - Centro de ayuda"
echo "  • menu      - Menú principal"
echo ""
echo "⚙️  Comandos del sistema:"
echo "  pm2 restart ssh-bot  - Reiniciar bot"
echo "  pm2 logs ssh-bot     - Ver logs"
echo "  pm2 status           - Estado"
echo ""
PANEL_EOF

chmod +x /usr/local/bin/sshbot-simple

# Crear archivo de ayuda para usuarios
cat > /opt/ssh-bot/COMANDOS.md << 'HELP_EOF'
# COMANDOS SSH BOT - VERSIÓN MEJORADA

## 📱 COMANDOS PRINCIPALES:

### 🆓 PRUEBA GRATIS
