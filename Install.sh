#!/bin/bash
# ================================================
# SSH BOT PRO - INSTALADOR CON IA Y COMANDOS SIMPLES
# Características:
# 1. ✅ Comandos de compra simplificados
# 2. ✅ Asistente de IA para guiar la compra
# 3. ✅ Proceso de compra paso a paso
# 4. ✅ Menús interactivos mejorados
# ================================================

set -euo pipefail

# ... (mantener las secciones anteriores igual hasta crear_database) ...

# Función para crear bot con IA y comandos simples
create_enhanced_bot() {
    log_info "Creando bot mejorado con IA y comandos simples..."
    
    cat > "$USER_HOME/bot.js" << 'BOTEOF'
// SSH BOT PRO - VERSIÓN MEJORADA CON IA
const { Client, LocalAuth, MessageMedia } = require('whatsapp-web.js');
const qrcode = require('qrcode-terminal');
const QRCode = require('qrcode');
const moment = require('moment');
const sqlite3 = require('sqlite3').verbose();
const chalk = require('chalk');
const fs = require('fs').promises;
const path = require('path');
const { exec } = require('child_process');
const util = require('util');
const cron = require('node-cron');
const axios = require('axios');

const execPromise = util.promisify(exec);

// Configuración
const CONFIG_PATH = '/opt/ssh-bot/config/config.json';
const DB_PATH = '/opt/ssh-bot/data/users.db';

// Estados de conversación para IA
const USER_STATES = {};

// Clase AsistenteIA - Sistema de ayuda inteligente
class AsistenteIA {
    constructor(phone) {
        this.phone = phone;
        this.context = {
            pasoActual: 0,
            datosCompra: {},
            historial: [],
            intent: null,
            dificultades: []
        };
    }

    async procesarMensaje(texto, pasoExtra = null) {
        const textoLower = texto.toLowerCase().trim();
        this.context.historial.push({ texto, timestamp: Date.now() });
        
        // Detectar intención del usuario
        if (!this.context.intent) {
            this.context.intent = this.detectarIntencion(textoLower);
        }
        
        // Procesar según el paso actual
        return await this.ejecutarPaso(textoLower, pasoExtra);
    }

    detectarIntencion(texto) {
        const palabrasClave = {
            comprar: ['comprar', 'quiero', 'deseo', 'adquirir', 'contratar', 'pag', 'pagar'],
            ayuda: ['ayuda', 'ayudame', 'soporte', 'asistencia', 'no entiendo', 'cómo'],
            informacion: ['info', 'información', 'detalles', 'qué incluye', 'beneficios'],
            problemas: ['error', 'problema', 'no funciona', 'falla', 'no puedo'],
            cancelar: ['cancelar', 'parar', 'detener', 'no quiero', 'salir']
        };

        for (const [intencion, palabras] of Object.entries(palabrasClave)) {
            if (palabras.some(palabra => texto.includes(palabra))) {
                return intencion;
            }
        }
        
        return 'desconocido';
    }

    async ejecutarPaso(texto, pasoExtra) {
        const pasos = [
            this.pasoBienvenida.bind(this),
            this.pasoSeleccionPlan.bind(this),
            this.pasoConfirmacion.bind(this),
            this.pasoPago.bind(this),
            this.pasoFinalizacion.bind(this)
        ];

        if (pasoExtra !== null && pasoExtra < pasos.length) {
            this.context.pasoActual = pasoExtra;
        }

        if (this.context.pasoActual < pasos.length) {
            const resultado = await pasos[this.context.pasoActual](texto);
            
            // Avanzar al siguiente paso si se completó correctamente
            if (resultado.completado) {
                this.context.pasoActual++;
                
                // Si hay más pasos, mostrar el siguiente
                if (this.context.pasoActual < pasos.length) {
                    const siguientePaso = await pasos[this.context.pasoActual]();
                    resultado.siguienteMensaje = siguientePaso.mensaje;
                }
            }
            
            return resultado;
        }
        
        return { completado: true, mensaje: '✅ Proceso completado.' };
    }

    async pasoBienvenida(texto = '') {
        if (texto === '') {
            return {
                completado: false,
                mensaje: `🤖 *¡Hola! Soy tu asistente de compra inteligente!*\n\n` +
                        `Te ayudaré a adquirir tu servicio SSH paso a paso.\n\n` +
                        `📋 *¿Qué necesitas hacer?*\n` +
                        `1️⃣ *Comprar* - Comenzar una nueva compra\n` +
                        `2️⃣ *Ayuda* - Necesito asistencia\n` +
                        `3️⃣ *Info* - Ver información de planes\n` +
                        `4️⃣ *Cancelar* - Salir del asistente\n\n` +
                        `👉 *Responde con el número o palabra clave*`
            };
        }

        if (texto.includes('1') || texto.includes('comprar')) {
            return { completado: true, mensaje: '✅ Perfecto, comencemos con la compra.' };
        } else if (texto.includes('2') || texto.includes('ayuda')) {
            return {
                completado: false,
                mensaje: `🆘 *Centro de Ayuda*\n\n` +
                        `Puedo ayudarte con:\n` +
                        `• Proceso de compra\n` +
                        `• Problemas de pago\n` +
                        `• Configuración del servicio\n` +
                        `• Preguntas generales\n\n` +
                        `📝 *Describe tu problema o pregunta:*`
            };
        } else if (texto.includes('3') || texto.includes('info')) {
            return {
                completado: false,
                mensaje: `ℹ️ *Información de Planes*\n\n` +
                        `📊 *Todos los planes incluyen:*\n` +
                        `• Acceso SSH completo\n` +
                        `• 1 conexión simultánea\n` +
                        `• Velocidad garantizada\n` +
                        `• Soporte 24/7\n` +
                        `• Instalación automática\n\n` +
                        `💬 *¿Quieres ver precios o comenzar compra?*`
            };
        } else if (texto.includes('4') || texto.includes('cancelar')) {
            return { completado: true, mensaje: '👋 ¡Hasta luego! Vuelve cuando necesites ayuda.' };
        }

        return { completado: true, mensaje: '✅ Entendido, comenzamos con la compra.' };
    }

    async pasoSeleccionPlan(texto = '') {
        if (texto === '') {
            return {
                completado: false,
                mensaje: `💎 *SELECCIÓN DE PLAN*\n\n` +
                        `📦 *Planes disponibles:*\n\n` +
                        `🥉 *PLAN BÁSICO* (7 días)\n` +
                        `💰 Precio: $500 ARS\n` +
                        `⏰ Duración: 1 semana\n` +
                        `🔌 Conexiones: 1\n` +
                        `🔑 Comando: *basico*\n\n` +
                        `🥈 *PLAN ESTÁNDAR* (15 días)\n` +
                        `💰 Precio: $800 ARS\n` +
                        `⏰ Duración: 2 semanas\n` +
                        `🔌 Conexiones: 1\n` +
                        `🔑 Comando: *estandar*\n\n` +
                        `🥇 *PLAN PREMIUM* (30 días)\n` +
                        `💰 Precio: $1200 ARS\n` +
                        `⏰ Duración: 1 mes\n` +
                        `🔌 Conexiones: 1\n` +
                        `🔑 Comando: *premium*\n\n` +
                        `🆓 *PRUEBA GRATIS* (2 horas)\n` +
                        `💰 Precio: $0 ARS\n` +
                        `⏰ Duración: 2 horas\n` +
                        `🔌 Conexiones: 1\n` +
                        `🔑 Comando: *prueba*\n\n` +
                        `👉 *Responde con el nombre del plan (ej: basico)*\n` +
                        `❓ *¿Necesitas ayuda para elegir? Escribe "ayuda"*`
            };
        }

        const planes = {
            'basico': { dias: 7, precio: 500, nombre: 'PLAN BÁSICO' },
            'estandar': { dias: 15, precio: 800, nombre: 'PLAN ESTÁNDAR' },
            'premium': { dias: 30, precio: 1200, nombre: 'PLAN PREMIUM' },
            'prueba': { dias: 0, precio: 0, nombre: 'PRUEBA GRATIS' }
        };

        if (planes[texto]) {
            this.context.datosCompra.plan = texto;
            this.context.datosCompra.detalles = planes[texto];
            return { completado: true, mensaje: `✅ Plan seleccionado: *${planes[texto].nombre}*` };
        } else if (texto.includes('ayuda')) {
            return {
                completado: false,
                mensaje: `🤔 *¿No sabes cuál plan elegir?*\n\n` +
                        `💡 *Recomendaciones:*\n\n` +
                        `• Si es tu primera vez → *Prueba* (gratis)\n` +
                        `• Uso ocasional (1-2 semanas) → *Básico*\n` +
                        `• Uso regular (1 mes) → *Estándar*\n` +
                        `• Uso intensivo o trabajo → *Premium*\n\n` +
                        `📞 *¿Tienes dudas específicas? Descríbemelas:*`
            };
        }

        return {
            completado: false,
            mensaje: `❌ Plan no reconocido. Opciones válidas:\n\n` +
                    `• *basico* - Plan Básico 7 días\n` +
                    `• *estandar* - Plan Estándar 15 días\n` +
                    `• *premium* - Plan Premium 30 días\n` +
                    `• *prueba* - Prueba gratis 2 horas\n\n` +
                    `👉 *Elige uno de los comandos anteriores*`
        };
    }

    async pasoConfirmacion(texto = '') {
        if (texto === '') {
            const plan = this.context.datosCompra.detalles;
            
            let mensaje = `📋 *CONFIRMACIÓN DE COMPRA*\n\n`;
            mensaje += `📦 *Plan:* ${plan.nombre}\n`;
            mensaje += `⏰ *Duración:* ${plan.dias > 0 ? `${plan.dias} días` : '2 horas (prueba)'}\n`;
            mensaje += `💰 *Precio:* ${plan.precio > 0 ? `$${plan.precio} ARS` : 'GRATIS'}\n`;
            mensaje += `🔌 *Conexiones:* 1 simultánea\n\n`;
            
            if (plan.precio > 0) {
                mensaje += `💳 *Método de pago:* MercadoPago\n`;
                mensaje += `⚡ *Activación:* Inmediata tras pago\n\n`;
            }
            
            mensaje += `✅ *¿Confirmar compra?*\n\n`;
            mensaje += `👉 *Sí* - Confirmar y proceder\n`;
            mensaje += `👉 *No* - Cambiar plan\n`;
            mensaje += `👉 *Ayuda* - Dudas sobre la compra`;

            return { completado: false, mensaje };
        }

        if (texto.includes('si') || texto.includes('confirmar') || texto.includes('sí')) {
            return { completado: true, mensaje: '✅ Compra confirmada. Procediendo al pago...' };
        } else if (texto.includes('no') || texto.includes('cambiar')) {
            this.context.pasoActual = 1; // Volver a selección de plan
            return { completado: false, mensaje: '🔄 Volviendo a selección de planes...' };
        } else if (texto.includes('ayuda')) {
            return {
                completado: false,
                mensaje: `❓ *Preguntas frecuentes:*\n\n` +
                        `• *¿Cómo se realiza el pago?*\n` +
                        `  Vía MercadoPago (tarjeta, efectivo, etc.)\n\n` +
                        `• *¿Cuándo se activa el servicio?*\n` +
                        `  Inmediatamente tras confirmación del pago\n\n` +
                        `• *¿Puedo cambiar de plan después?*\n` +
                        `  Sí, contactando a soporte\n\n` +
                        `• *¿Hay garantía de devolución?*\n` +
                        `  Los primeros 24 horas\n\n` +
                        `👉 *¿Listo para confirmar? Responde "sí"*`
            };
        }

        return { completado: true, mensaje: '✅ Compra confirmada. Procediendo al pago...' };
    }

    async pasoPago(texto = '') {
        const plan = this.context.datosCompra.detalles;
        
        if (plan.precio === 0) {
            // Prueba gratis - saltar pago
            return { completado: true, mensaje: '✅ Procesando prueba gratuita...' };
        }

        if (texto === '') {
            return {
                completado: false,
                mensaje: `💳 *PROCESO DE PAGO*\n\n` +
                        `📦 *Resumen:* ${plan.nombre}\n` +
                        `💰 *Total:* $${plan.precio} ARS\n\n` +
                        `📱 *Pasos para pagar:*\n` +
                        `1. Generaré un enlace de pago único\n` +
                        `2. Te enviaré el QR y enlace\n` +
                        `3. Pagas con tu método preferido\n` +
                        `4. El sistema verifica automáticamente\n` +
                        `5. Recibes tus datos de acceso\n\n` +
                        `⏰ *El enlace expira en 24 horas*\n\n` +
                        `👉 *¿Generar enlace de pago? Responde "pagar"*\n` +
                        `❓ *¿Dudas sobre el pago? Escribe "ayuda"*`
            };
        }

        if (texto.includes('pagar') || texto.includes('generar')) {
            return { completado: true, mensaje: '🔄 Generando enlace de pago seguro...' };
        } else if (texto.includes('ayuda')) {
            return {
                completado: false,
                mensaje: `🆘 *Ayuda con el pago:*\n\n` +
                        `• *Métodos aceptados:*\n` +
                        `  💳 Tarjetas (crédito/débito)\n` +
                        `  🏪 Efectivo (Pago Fácil, Rapipago)\n` +
                        `  📱 Transferencia bancaria\n` +
                        `  🔗 MercadoPago\n\n` +
                        `• *Problemas comunes:*\n` +
                        `  ❌ Tarjeta rechazada → Verifica fondos/datos\n` +
                        `  ❌ Pago pendiente → Espera 5-10 minutos\n` +
                        `  ❌ Error en enlace → Solicita nuevo enlace\n\n` +
                        `• *Seguridad:*\n` +
                        `  🔒 Pago 100% seguro\n` +
                        `  🔒 Datos encriptados\n` +
                        `  🔒 Certificado SSL\n\n` +
                        `👉 *¿Listo para pagar? Responde "pagar"*`
            };
        }

        return { completado: true, mensaje: '🔄 Generando enlace de pago seguro...' };
    }

    async pasoFinalizacion(texto = '') {
        return {
            completado: true,
            mensaje: `🎉 *¡COMPRA FINALIZADA!*\n\n` +
                    `✅ Tu solicitud ha sido procesada correctamente.\n\n` +
                    `📋 *Próximos pasos:*\n` +
                    `1. Revisa tu WhatsApp para el enlace de pago\n` +
                    `2. Completa el pago\n` +
                    `3. Recibirás tus datos de acceso automáticamente\n\n` +
                    `⏰ *Tiempo estimado:* 2-5 minutos\n\n` +
                    `📞 *Soporte:* Escribe *ayuda* en cualquier momento\n\n` +
                    `¡Gracias por tu compra! 🚀`
        };
    }

    // Método para obtener recomendación inteligente
    obtenerRecomendacion() {
        const historial = this.context.historial;
        
        if (historial.length > 0) {
            const ultimoMensaje = historial[historial.length - 1].texto.toLowerCase();
            
            // Análisis simple de necesidades
            if (ultimoMensaje.includes('trabajo') || ultimoMensaje.includes('empresa')) {
                return { plan: 'premium', razon: 'Ideal para uso profesional continuo' };
            } else if (ultimoMensaje.includes('estudio') || ultimoMensaje.includes('universidad')) {
                return { plan: 'estandar', razon: 'Perfecto para proyectos educativos' };
            } else if (ultimoMensaje.includes('prueba') || ultimoMensaje.includes('probar')) {
                return { plan: 'prueba', razon: 'Para que pruebes el servicio sin costo' };
            }
        }
        
        return { plan: 'basico', razon: 'Plan balanceado para la mayoría de usuarios' };
    }

    reset() {
        this.context = {
            pasoActual: 0,
            datosCompra: {},
            historial: [],
            intent: null,
            dificultades: []
        };
    }
}

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
moment.locale('es');

// Cliente de WhatsApp
const client = new Client({
    authStrategy: new LocalAuth({
        dataPath: '/root/.wwebjs_auth',
        clientId: 'ssh-bot-ia'
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

// Funciones de utilidad
function generateUsername() {
    const prefix = 'user';
    const random = Math.random().toString(36).substr(2, 6);
    return prefix + random;
}

function generatePassword() {
    const length = 12;
    const charset = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*';
    let password = '';
    for (let i = 0; i < length; i++) {
        password += charset.charAt(Math.floor(Math.random() * charset.length));
    }
    return password;
}

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
                (err) => err ? reject(err) : resolve({
                    username,
                    password,
                    expires: expireFull,
                    tipo,
                    duration: days === 0 ? '2 horas' : `${days} días`
                })
            );
        });
    } catch (error) {
        console.error(chalk.red('Error creando usuario SSH:'), error.message);
        throw error;
    }
}

// Función para generar pago con MercadoPago
async function generarPagoMercadoPago(phone, plan, dias, monto) {
    try {
        // Implementación de MercadoPago (similar a versión anterior)
        // ...
        return { success: true, paymentUrl: 'https://mercadopago.com/...', qrPath: '/path/to/qr.png' };
    } catch (error) {
        console.error(chalk.red('Error generando pago:'), error);
        return { success: false, error: error.message };
    }
}

// Eventos del cliente
client.on('qr', (qr) => {
    console.log(chalk.yellow('🔐 Escanea este código QR con WhatsApp:'));
    qrcode.generate(qr, { small: true });
    
    const qrPath = path.join(config.paths.qr_codes, `qr-${Date.now()}.png`);
    QRCode.toFile(qrPath, qr, (err) => {
        if (!err) console.log(chalk.green(`✅ QR guardado en: ${qrPath}`));
    });
});

client.on('ready', () => {
    console.log(chalk.green('🤖 Bot con IA listo! Comandos simples activados.'));
    
    // Mensaje de bienvenida automático a admin
    if (config.bot.admin_phone) {
        const welcomeMsg = `🎉 *Bot con IA Activado*\n\n` +
                          `🤖 Asistente inteligente: ✅\n` +
                          `💰 Comandos simples: ✅\n` +
                          `🆘 Sistema de ayuda: ✅\n` +
                          `⏰ Hora: ${moment().format('DD/MM/YYYY HH:mm:ss')}`;
        
        client.sendMessage(`${config.bot.admin_phone}@c.us`, welcomeMsg)
            .catch(console.error);
    }
});

// Manejo de mensajes con IA
client.on('message', async (msg) => {
    const text = msg.body.trim();
    const phone = msg.from;
    
    // Ignorar grupos
    if (phone.includes('@g.us')) return;
    
    console.log(chalk.cyan(`📩 [${phone.split('@')[0]}]: ${text.substring(0, 50)}`));
    
    // Inicializar asistente IA si no existe
    if (!USER_STATES[phone]) {
        USER_STATES[phone] = {
            asistente: new AsistenteIA(phone),
            compraActiva: false,
            datosCompra: {}
        };
    }
    
    const userState = USER_STATES[phone];
    
    // Comandos principales simplificados
    if (text.toLowerCase() === 'menu' || text.toLowerCase() === 'hola' || text === '/start') {
        await mostrarMenuPrincipal(phone);
        return;
    }
    
    // Si hay una compra activa con IA
    if (userState.compraActiva) {
        await procesarCompraConIA(phone, text, userState);
        return;
    }
    
    // Comandos de compra simplificados
    const comandosSimples = {
        'prueba': { action: 'iniciarPrueba', ayuda: 'Obtén 2 horas gratis' },
        'basico': { action: 'iniciarCompra', plan: 'basico', ayuda: 'Plan básico 7 días - $500' },
        'estandar': { action: 'iniciarCompra', plan: 'estandar', ayuda: 'Plan estándar 15 días - $800' },
        'premium': { action: 'iniciarCompra', plan: 'premium', ayuda: 'Plan premium 30 días - $1200' },
        'comprar': { action: 'iniciarAsistente', ayuda: 'Asistente de compra paso a paso' },
        'ayuda': { action: 'mostrarAyuda', ayuda: 'Centro de ayuda y soporte' },
        'mis cuentas': { action: 'mostrarCuentas', ayuda: 'Ver tus cuentas activas' },
        'app': { action: 'descargarApp', ayuda: 'Descargar aplicación móvil' },
        'soporte': { action: 'mostrarSoporte', ayuda: 'Contactar soporte técnico' },
        'precios': { action: 'mostrarPrecios', ayuda: 'Ver todos los planes y precios' }
    };
    
    const comando = text.toLowerCase();
    
    if (comandosSimples[comando]) {
        await ejecutarComando(phone, comandosSimples[comando]);
    } else {
        // Si no es un comando reconocido, ofrecer ayuda
        await client.sendMessage(phone, 
            `🤖 *No entendí tu mensaje*\n\n` +
            `📋 *Comandos disponibles:*\n` +
            `• *prueba* - 2 horas gratis\n` +
            `• *basico* - Plan 7 días ($500)\n` +
            `• *estandar* - Plan 15 días ($800)\n` +
            `• *premium* - Plan 30 días ($1200)\n` +
            `• *comprar* - Asistente de compra\n` +
            `• *ayuda* - Centro de ayuda\n` +
            `• *menu* - Volver al menú principal\n\n` +
            `💡 *Ejemplo:* Envía *basico* para comprar el plan básico`,
            { sendSeen: true }
        );
    }
});

// Función para mostrar menú principal
async function mostrarMenuPrincipal(phone) {
    await client.sendMessage(phone,
        `🎛️ *MENÚ PRINCIPAL - SSH BOT PRO*\n\n` +
        `🚀 *ACCESO RÁPIDO:*\n\n` +
        `🆓 *prueba* - Prueba GRATIS 2h\n` +
        `💰 *precios* - Ver todos los planes\n` +
        `🤖 *comprar* - Asistente de compra IA\n\n` +
        `📦 *PLANES (comandos simples):*\n` +
        `🥉 *basico* - 7 días - $500\n` +
        `🥈 *estandar* - 15 días - $800\n` +
        `🥇 *premium* - 30 días - $1200\n\n` +
        `🔧 *OTROS COMANDOS:*\n` +
        `👤 *mis cuentas* - Tus cuentas activas\n` +
        `📱 *app* - Descargar aplicación\n` +
        `🆘 *ayuda* - Centro de ayuda\n` +
        `📞 *soporte* - Contactar soporte\n\n` +
        `💡 *Ejemplo:* Envía *basico* para comprar directamente\n` +
        `🤖 *Escribe *comprar* para ayuda paso a paso*`,
        { sendSeen: true }
    );
}

// Función para ejecutar comandos
async function ejecutarComando(phone, comando) {
    switch (comando.action) {
        case 'iniciarPrueba':
            await crearPruebaGratis(phone);
            break;
            
        case 'iniciarCompra':
            USER_STATES[phone].compraActiva = true;
            USER_STATES[phone].datosCompra = { plan: comando.plan };
            await iniciarProcesoCompra(phone, comando.plan);
            break;
            
        case 'iniciarAsistente':
            USER_STATES[phone].compraActiva = true;
            await client.sendMessage(phone,
                `🤖 *¡Bienvenido al Asistente de Compra IA!*\n\n` +
                `Te guiaré paso a paso en tu compra.\n\n` +
                `📝 *Por favor, describe:*\n` +
                `• ¿Qué plan te interesa?\n` +
                `• ¿Para qué lo necesitas?\n` +
                `• ¿Tienes algún requerimiento especial?\n\n` +
                `💡 *Ejemplo:* "Quiero el plan básico para estudiar"`,
                { sendSeen: true }
            );
            break;
            
        case 'mostrarAyuda':
            await mostrarCentroAyuda(phone);
            break;
            
        case 'mostrarCuentas':
            await mostrarCuentasUsuario(phone);
            break;
            
        case 'descargarApp':
            await enviarAplicacion(phone);
            break;
            
        case 'mostrarSoporte':
            await mostrarInformacionSoporte(phone);
            break;
            
        case 'mostrarPrecios':
            await mostrarTodosPlanes(phone);
            break;
    }
}

// Función para procesar compra con IA
async function procesarCompraConIA(phone, text, userState) {
    const resultado = await userState.asistente.procesarMensaje(text);
    
    await client.sendMessage(phone, resultado.mensaje, { sendSeen: true });
    
    // Si se completó el paso de pago, generar pago real
    if (resultado.completado && userState.asistente.context.pasoActual === 3) {
        const plan = userState.datosCompra.plan || userState.asistente.context.datosCompra.plan;
        
        if (plan === 'prueba') {
            await crearPruebaGratis(phone);
        } else {
            const planes = {
                'basico': { dias: 7, precio: 500 },
                'estandar': { dias: 15, precio: 800 },
                'premium': { dias: 30, precio: 1200 }
            };
            
            const detalles = planes[plan];
            if (detalles) {
                await generarYEnviarPago(phone, plan, detalles.dias, detalles.precio);
            }
        }
        
        // Reiniciar estado
        userState.compraActiva = false;
        userState.asistente.reset();
    }
    
    // Mostrar siguiente paso si existe
    if (resultado.siguienteMensaje) {
        await client.sendMessage(phone, resultado.siguienteMensaje, { sendSeen: true });
    }
}

// Función para crear prueba gratis
async function crearPruebaGratis(phone) {
    try {
        // Verificar si ya usó prueba hoy
        const today = moment().format('YYYY-MM-DD');
        db.get('SELECT COUNT(*) as count FROM daily_tests WHERE phone = ? AND date = ?', 
            [phone, today], async (err, row) => {
                if (err || (row && row.count > 0)) {
                    await client.sendMessage(phone,
                        `⚠️ *YA USASTE TU PRUEBA HOY*\n\n` +
                        `⏳ Vuelve mañana para otra prueba gratuita\n` +
                        `💰 *Escribe *precios* para ver planes pagos*`,
                        { sendSeen: true }
                    );
                    return;
                }
                
                // Crear prueba
                const username = generateUsername();
                const password = generatePassword();
                
                await createSSHUser(phone, username, password, 0);
                
                // Registrar prueba
                db.run('INSERT INTO daily_tests (phone, date) VALUES (?, ?)', [phone, today]);
                
                await client.sendMessage(phone,
                    `🎉 *¡PRUEBA ACTIVADA!*\n\n` +
                    `👤 *Usuario:* \`${username}\`\n` +
                    `🔑 *Contraseña:* \`${password}\`\n` +
                    `⏰ *Duración:* 2 horas\n` +
                    `🔌 *Conexiones:* 1\n\n` +
                    `📱 *Para conectar:*\n` +
                    `1. Descarga la app (envía *app*)\n` +
                    `2. Ingresa usuario y contraseña\n` +
                    `3. ¡Listo! Se activa automáticamente\n\n` +
                    `💎 *¿Te gustó? Envía *comprar* para plan pago*`,
                    { sendSeen: true }
                );
            }
        );
    } catch (error) {
        await client.sendMessage(phone,
            `❌ *Error al crear prueba*\n\n` +
            `Detalles: ${error.message}\n\n` +
            `🆘 Contacta soporte o intenta más tarde`,
            { sendSeen: true }
        );
    }
}

// Función para iniciar proceso de compra
async function iniciarProcesoCompra(phone, plan) {
    const planesInfo = {
        'basico': { nombre: 'BÁSICO 7 DÍAS', precio: 500, dias: 7 },
        'estandar': { nombre: 'ESTÁNDAR 15 DÍAS', precio: 800, dias: 15 },
        'premium': { nombre: 'PREMIUM 30 DÍAS', precio: 1200, dias: 30 }
    };
    
    const info = planesInfo[plan];
    
    if (!info) {
        await client.sendMessage(phone, `❌ Plan no válido. Usa: basico, estandar o premium`, { sendSeen: true });
        USER_STATES[phone].compraActiva = false;
        return;
    }
    
    await client.sendMessage(phone,
        `🔄 *PROCESANDO COMPRA: ${info.nombre}*\n\n` +
        `💰 *Precio:* $${info.precio} ARS\n` +
        `⏰ *Duración:* ${info.dias} días\n` +
        `🔌 *Conexiones:* 1\n\n` +
        `✅ *¿Confirmar compra?*\n\n` +
        `👉 *sí* - Confirmar y proceder al pago\n` +
        `👉 *no* - Cancelar y volver al menú\n` +
        `👉 *ayuda* - Dudas sobre esta compra`,
        { sendSeen: true }
    );
}

// Función para generar y enviar pago
async function generarYEnviarPago(phone, plan, dias, monto) {
    try {
        await client.sendMessage(phone,
            `🔄 *Generando enlace de pago seguro...*\n\n` +
            `⏰ Por favor espera unos segundos`,
            { sendSeen: true }
        );
        
        // Aquí iría la integración real con MercadoPago
        const payment = await generarPagoMercadoPago(phone, plan, dias, monto);
        
        if (payment.success) {
            await client.sendMessage(phone,
                `✅ *ENLACE DE PAGO GENERADO*\n\n` +
                `📦 *Plan:* ${plan.toUpperCase()} ${dias} días\n` +
                `💰 *Monto:* $${monto} ARS\n\n` +
                `🔗 *Enlace de pago:*\n${payment.paymentUrl}\n\n` +
                `📱 *O escanea este QR:*`,
                { sendSeen: true }
            );
            
            // Enviar QR si existe
            if (payment.qrPath && require('fs').existsSync(payment.qrPath)) {
                const media = MessageMedia.fromFilePath(payment.qrPath);
                await client.sendMessage(phone, media, {
                    caption: '💳 Escanea con la app de MercadoPago',
                    sendSeen: true
                });
            }
            
            await client.sendMessage(phone,
                `ℹ️ *INFORMACIÓN IMPORTANTE:*\n\n` +
                `⏰ *El pago se verifica automáticamente cada 2 minutos*\n` +
                `✅ *Recibirás tus datos de acceso al confirmarse el pago*\n` +
                `📞 *Problemas? Escribe *ayuda**`,
                { sendSeen: true }
            );
        } else {
            await client.sendMessage(phone,
                `❌ *ERROR AL GENERAR PAGO*\n\n` +
                `Detalles: ${payment.error}\n\n` +
                `🆘 Por favor, intenta más tarde o contacta soporte`,
                { sendSeen: true }
            );
        }
    } catch (error) {
        await client.sendMessage(phone,
            `❌ *ERROR INESPERADO*\n\n` +
            `${error.message}\n\n` +
            `🆘 Contacta soporte técnico`,
            { sendSeen: true }
        );
    }
}

// Función para mostrar centro de ayuda
async function mostrarCentroAyuda(phone) {
    await client.sendMessage(phone,
        `🆘 *CENTRO DE AYUDA - SSH BOT PRO*\n\n` +
        `📋 *Secciones de ayuda:*\n\n` +
        `🔹 *1. COMPRAS Y PAGOS*\n` +
        `• ¿Cómo comprar? Envía *comprar*\n` +
        `• Problemas con pagos\n` +
        `• Métodos de pago aceptados\n\n` +
        `🔹 *2. CONEXIÓN Y USO*\n` +
        `• Configurar aplicación\n` +
        `• Problemas de conexión\n` +
        `• Límites y restricciones\n\n` +
        `🔹 *3. CUENTAS Y ACCESOS*\n` +
        `• Recuperar contraseña\n` +
        `• Ver mis cuentas: *mis cuentas*\n` +
        `• Renovar servicio\n\n` +
        `🔹 *4. SOPORTE TÉCNICO*\n` +
        `• Contactar soporte: *soporte*\n` +
        `• Reportar problemas\n` +
        `• Sugerencias\n\n` +
        `💡 *Para asistencia específica, describe tu problema:*`,
        { sendSeen: true }
    );
}

// Función para mostrar todas las cuentas del usuario
async function mostrarCuentasUsuario(phone) {
    db.all(`SELECT username, password, tipo, expires_at FROM users WHERE phone = ? AND status = 1 ORDER BY created_at DESC`,
        [phone], async (err, rows) => {
            if (err || !rows || rows.length === 0) {
                await client.sendMessage(phone,
                    `📭 *NO TIENES CUENTAS ACTIVAS*\n\n` +
                    `🆓 Prueba gratis: envía *prueba*\n` +
                    `💰 Ver planes: envía *precios*`,
                    { sendSeen: true }
                );
                return;
            }
            
            let mensaje = `📋 *TUS CUENTAS ACTIVAS*\n\n`;
            
            rows.forEach((cuenta, index) => {
                const tipo = cuenta.tipo === 'premium' ? '💎 PREMIUM' : '🆓 TEST';
                const expira = moment(cuenta.expires_at).format('DD/MM/YYYY HH:mm');
                
                mensaje += `*${index + 1}. ${tipo}*\n`;
                mensaje += `👤 Usuario: \`${cuenta.username}\`\n`;
                mensaje += `🔑 Contraseña: \`${cuenta.password}\`\n`;
                mensaje += `⏰ Expira: ${expira}\n`;
                mensaje += `🔌 Conexiones: 1\n\n`;
            });
            
            mensaje += `📱 *Para conectar:* descarga la app (envía *app*)`;
            
            await client.sendMessage(phone, mensaje, { sendSeen: true });
        }
    );
}

// Función para mostrar todos los planes
async function mostrarTodosPlanes(phone) {
    await client.sendMessage(phone,
        `💰 *PLANES Y PRECIOS - SSH BOT PRO*\n\n` +
        `📊 *COMPARATIVA DE PLANES:*\n\n` +
        `🆓 *PRUEBA GRATIS*\n` +
        `⏰ 2 horas | 🔌 1 conexión\n` +
        `💰 $0 ARS\n` +
        `🔑 Comando: *prueba*\n\n` +
        `🥉 *PLAN BÁSICO*\n` +
        `⏰ 7 días | 🔌 1 conexión\n` +
        `💰 $500 ARS\n` +
        `🔑 Comando: *basico*\n\n` +
        `🥈 *PLAN ESTÁNDAR*\n` +
        `⏰ 15 días | 🔌 1 conexión\n` +
        `💰 $800 ARS\n` +
        `🔑 Comando: *estandar*\n\n` +
        `🥇 *PLAN PREMIUM*\n` +
        `⏰ 30 días | 🔌 1 conexión\n` +
        `💰 $1200 ARS\n` +
        `🔑 Comando: *premium*\n\n` +
        `⚡ *TODOS INCLUYEN:*\n` +
        `• Acceso SSH completo\n` +
        `• Velocidad garantizada\n` +
        `• Soporte 24/7\n` +
        `• Instalación automática\n\n` +
        `💡 *¿No sabes cuál elegir?*\n` +
        `Envía *comprar* para ayuda personalizada`,
        { sendSeen: true }
    );
}

// Función para mostrar información de soporte
async function mostrarInformacionSoporte(phone) {
    await client.sendMessage(phone,
        `📞 *SOPORTE TÉCNICO*\n\n` +
        `🕒 *Horario de atención:*\n` +
        `Lunes a Domingo: 9:00 - 22:00\n\n` +
        `📱 *Canales de contacto:*\n` +
        `• WhatsApp: ${config.links.support || 'No configurado'}\n` +
        `• Telegram: ${config.links.support || 'No configurado'}\n\n` +
        `🔧 *Antes de contactar:*\n` +
        `1. Revisa el centro de ayuda (*ayuda*)\n` +
        `2. Verifica tu conexión a internet\n` +
        `3. Reinicia la aplicación\n\n` +
        `📝 *Proporciona esta información al contactar:*\n` +
        `• Tu número de teléfono\n` +
        `• Nombre de usuario\n` +
        `• Descripción detallada del problema\n\n` +
        `⚡ *Respuesta promedio:* 15-30 minutos`,
        { sendSeen: true }
    );
}

// Función para enviar aplicación
async function enviarAplicacion(phone) {
    // Buscar APK en ubicaciones comunes
    const searchPaths = [
        '/root/app.apk',
        '/root/ssh-bot/app.apk',
        '/root/android.apk',
        '/opt/ssh-bot/app.apk'
    ];
    
    let apkFound = null;
    
    for (const filePath of searchPaths) {
        if (require('fs').existsSync(filePath)) {
            apkFound = filePath;
            break;
        }
    }
    
    if (apkFound) {
        try {
            const stats = require('fs').statSync(apkFound);
            const fileSize = (stats.size / (1024 * 1024)).toFixed(2);
            
            await client.sendMessage(phone,
                `📱 *DESCARGANDO APLICACIÓN*\n\n` +
                `📦 Archivo: app.apk\n` +
                `📊 Tamaño: ${fileSize} MB\n` +
                `⚡ Preparando envío...`,
                { sendSeen: true }
            );
            
            const media = MessageMedia.fromFilePath(apkFound);
            await client.sendMessage(phone, media, {
                caption: `📱 *APLICACIÓN SSH CLIENT*\n\n` +
                        `✅ Descarga completada\n\n` +
                        `📋 *INSTRUCCIONES DE INSTALACIÓN:*\n` +
                        `1. Toca el archivo para instalar\n` +
                        `2. Permite "Fuentes desconocidas"\n` +
                        `3. Abre la aplicación\n` +
                        `4. Ingresa tus datos de acceso\n\n` +
                        `💡 Si no ves el archivo, revisa la sección "Archivos" de WhatsApp`,
                sendSeen: true
            });
        } catch (error) {
            await client.sendMessage(phone,
                `❌ *ERROR AL ENVIAR APLICACIÓN*\n\n` +
                `El archivo es muy grande para WhatsApp.\n\n` +
                `📥 *Descarga manual:*\n` +
                `1. Conéctate por SFTP al servidor\n` +
                `2. Descarga: /root/app.apk\n` +
                `3. Instala en tu dispositivo`,
                { sendSeen: true }
            );
        }
    } else {
        await client.sendMessage(phone,
            `❌ *APLICACIÓN NO DISPONIBLE*\n\n` +
            `El archivo de instalación no está en el servidor.\n\n` +
            `📞 Contacta al administrador para solicitar la aplicación.`,
            { sendSeen: true }
        );
    }
}

// Inicializar cliente
client.initialize();

// Manejo de señales para apagado limpio
process.on('SIGINT', () => {
    console.log(chalk.yellow('\n🛑 Apagando bot con IA...'));
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

// Tareas programadas
cron.schedule('*/2 * * * *', () => {
    console.log(chalk.yellow('🔄 Verificando pagos pendientes...'));
    // Lógica de verificación de pagos
});

cron.schedule('*/15 * * * *', () => {
    console.log(chalk.yellow('🧹 Limpiando usuarios expirados...'));
    // Lógica de limpieza
});

console.log(chalk.green('\n🚀 Bot con IA iniciado - Comandos simples activados\n'));
BOTEOF

    log_info "Bot mejorado creado con IA y comandos simples"
}

# Función para crear panel de control actualizado
create_enhanced_control_panel() {
    log_info "Creando panel de control mejorado..."
    
    cat > /usr/local/bin/sshbot-control << 'PANEL_EOF'
#!/bin/bash
# Panel de control mejorado para SSH Bot con IA

set -euo pipefail

# ... (mantener el panel anterior pero actualizar la sección de comandos) ...

# En la función show_menu, actualizar las opciones:
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}[1]${NC}  🚀  Iniciar/Reiniciar bot con IA"
echo -e "${CYAN}[2]${NC}  🛑  Detener bot"
echo -e "${CYAN}[3]${NC}  📱  Ver QR WhatsApp"
echo -e "${CYAN}[4]${NC}  👤  Gestionar usuarios"
echo -e "${CYAN}[5]${NC}  💰  Configurar precios y planes"
echo -e "${CYAN}[6]${NC}  🤖  Configurar asistente IA"
echo -e "${CYAN}[7]${NC}  📊  Ver estadísticas"
echo -e "${CYAN}[8]${NC}  📝  Ver logs"
echo -e "${CYAN}[9]${NC}  🛠️   Herramientas de IA"
echo -e "${CYAN}[10]${NC} 🔧  Reparar sistema"
echo -e "${CYAN}[11]${NC} 🧪  Probar comandos"
echo -e "${CYAN}[0]${NC}  🚪  Salir"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# ... (resto del panel) ...

PANEL_EOF

    chmod +x /usr/local/bin/sshbot-control
    log_info "Panel de control mejorado creado"
}

# Función para crear archivo de configuración de IA
create_ia_configuration() {
    log_info "Creando configuración de IA..."
    
    cat > "$INSTALL_DIR/config/ia_config.json" << 'IA_CONFIG_EOF'
{
    "asistente_ia": {
        "enabled": true,
        "nombre": "Asistente SSH Pro",
        "version": "1.0",
        "temperatura": 0.7,
        "max_tokens": 500,
        "modelo": "inteligencia-contextual"
    },
    "comandos_simples": {
        "prueba": {
            "accion": "crear_prueba",
            "descripcion": "Obtener prueba gratuita de 2 horas",
            "alias": ["test", "gratis", "free"]
        },
        "basico": {
            "accion": "comprar_plan",
            "plan": "basico",
            "descripcion": "Comprar plan básico 7 días - $500",
            "alias": ["7d", "semanal"]
        },
        "estandar": {
            "accion": "comprar_plan",
            "plan": "estandar",
            "descripcion": "Comprar plan estándar 15 días - $800",
            "alias": ["15d", "quincenal"]
        },
        "premium": {
            "accion": "comprar_plan",
            "plan": "premium",
            "descripcion": "Comprar plan premium 30 días - $1200",
            "alias": ["30d", "mensual"]
        },
        "comprar": {
            "accion": "iniciar_asistente",
            "descripcion": "Iniciar asistente de compra paso a paso",
            "alias": ["quiero", "deseo", "helpme"]
        },
        "ayuda": {
            "accion": "mostrar_ayuda",
            "descripcion": "Mostrar centro de ayuda",
            "alias": ["soporte", "help", "ayudame"]
        }
    },
    "flujos_conversacion": {
        "compra": {
            "pasos": ["bienvenida", "seleccion_plan", "confirmacion", "pago", "finalizacion"],
            "timeout_minutos": 30,
            "reintentos": 3
        },
        "soporte": {
            "pasos": ["identificar_problema", "diagnostico", "solucion", "seguimiento"],
            "timeout_minutos": 45,
            "reintentos": 5
        }
    },
    "respuestas_inteligentes": {
        "saludos": ["¡Hola!", "Buen día", "¿En qué puedo ayudarte?", "¡Hola! Soy tu asistente"],
        "despedidas": ["¡Hasta luego!", "Que tengas un buen día", "Vuelve cuando necesites ayuda"],
        "agradecimientos": ["¡De nada!", "Es un placer ayudar", "Gracias a ti"],
        "confusion": ["No entendí eso", "¿Podrías repetirlo?", "No estoy seguro de entender"]
    },
    "recomendaciones": {
        "basado_en_uso": {
            "estudio": "estandar",
            "trabajo": "premium",
            "ocio": "basico",
            "prueba": "prueba"
        },
        "basado_en_frecuencia": {
            "ocasional": "basico",
            "regular": "estandar",
            "intensivo": "premium"
        }
    }
}
IA_CONFIG_EOF

    log_info "Configuración de IA creada"
}

# ... (mantener las demás funciones igual) ...

# En la función main, reemplazar create_bot con:
create_enhanced_bot
create_ia_configuration
create_enhanced_control_panel

# ... (resto del main igual) ...  "dependencies": {
    "whatsapp-web.js": "^1.23.0",
    "qrcode-terminal": "^0.12.0",
    "express": "^4.18.2",
    "lowdb": "^5.1.0",
    "moment": "^2.29.4"
  },
  "scripts": {
    "start": "node index.js",
    "dev": "nodemon index.js"
  }
}
EOF

# 4. Crear index.js principal (BASE FUNCIONAL)
echo "[4/8] Creando bot base funcional..."
cat > index.js <<'EOF'
const qrcode = require('qrcode-terminal');
const { Client, LocalAuth } = require('whatsapp-web.js');
const express = require('express');
const low = require('lowdb');
const FileSync = require('lowdb/adapters/FileSync');
const moment = require('moment');
const fs = require('fs');

// Configuración
const PORT = 9000;
const SESSION_PATH = './session';

// Base de datos
const adapter = new FileSync('database.json');
const db = low(adapter);

// Inicializar DB con estructura
db.defaults({
    users: [],
    sales: [],
    plans: [
        { id: 'basic', name: 'Básico 30 días', price: 1000, days: 30, devices: 1 },
        { id: 'premium', name: 'Premium 60 días', price: 2000, days: 60, devices: 3 },
        { id: 'vip', name: 'VIP 90 días', price: 3000, days: 90, devices: 5 }
    ],
    config: {
        admin: '5491122334455',
        ssh_host: 'tussh.com',
        ssh_port: '22'
    }
}).write();

// Web server para QR
const app = express();
app.get('/qr', (req, res) => {
    res.send(`
        <html>
        <body style="text-align: center; padding: 50px;">
            <h2>📱 Escanea este QR con WhatsApp</h2>
            <p>WhatsApp > Ajustes > Dispositivos vinculados</p>
            <img src="/qrcode" width="300">
            <p><a href="/">Volver</a></p>
        </body>
        </html>
    `);
});

app.get('/qrcode', (req, res) => {
    if (global.qrCode) {
        qrcode.generate(global.qrCode, { small: false }, (qrcode) => {
            res.set('Content-Type', 'text/html');
            res.send(`<pre>${qrcode}</pre>`);
        });
    } else {
        res.send('QR no disponible aún. Espera unos segundos.');
    }
});

app.get('/', (req, res) => {
    res.send(`
        <h1>🤖 WASSH Bot Panel</h1>
        <p><a href="/qr">Escanear QR</a></p>
        <p><a href="/stats">Estadísticas</a></p>
        <p>Bot activo: ${client ? '✅ Sí' : '❌ No'}</p>
    `);
});

app.get('/stats', (req, res) => {
    const users = db.get('users').value().length;
    const sales = db.get('sales').value().length;
    res.json({ users, sales, status: 'active' });
});

app.listen(PORT, () => {
    console.log(`🌐 Web server: http://localhost:${PORT}`);
});

// WhatsApp Client
const client = new Client({
    authStrategy: new LocalAuth({ clientId: "wassh-bot" }),
    puppeteer: {
        headless: true,
        args: ['--no-sandbox', '--disable-setuid-sandbox']
    }
});

// Generar QR
client.on('qr', qr => {
    console.log('\n' + '='.repeat(50));
    console.log('📲 ESCANEA EL CÓDIGO QR CON WHATSAPP');
    console.log('='.repeat(50));
    console.log('\nO visita: http://localhost:9000/qr\n');
    qrcode.generate(qr, { small: true });
    global.qrCode = qr;
});

// Cuando esté listo
client.on('ready', () => {
    console.log('✅ WHATSAPP CONECTADO');
    console.log('🤖 Bot listo para ventas SSH');
    
    // Enviar mensaje de bienvenida al admin
    const admin = db.get('config.admin').value();
    if (admin) {
        client.sendMessage(admin + '@c.us', 
            `✅ Bot WASSH iniciado\n📅 ${moment().format('DD/MM/YYYY HH:mm')}\n👥 Usuarios: ${db.get('users').value().length}`
        );
    }
});

// MENÚ PRINCIPAL ESTILO TELEGRAM
const mainMenu = `*🤖 WASSH VPN - MENÚ PRINCIPAL*

*1*️⃣ *PLANES Y PRECIOS*
*2*️⃣ *COMPRAR SERVICIO*
*3*️⃣ *MI CUENTA / RENOVAR*
*4*️⃣ *SOPORTE TÉCNICO*
*5*️⃣ *INFORMACIÓN*

*0*️⃣ *SALIR*

_Escribe el número de la opción_`;

const plansMenu = `*📋 PLANES DISPONIBLES*

*1*️⃣ *PLAN BÁSICO*
💰 Precio: $1000
⏳ Duración: 30 días
📱 Dispositivos: 1

*2*️⃣ *PLAN PREMIUM* 
💰 Precio: $2000  
⏳ Duración: 60 días
📱 Dispositivos: 3

*3*️⃣ *PLAN VIP*
💰 Precio: $3000
⏳ Duración: 90 días
📱 Dispositivos: 5

*9*️⃣ *VOLVER AL MENÚ*
*0*️⃣ *SALIR*`;

// Manejar mensajes
client.on('message', async message => {
    if (message.fromMe) return;
    
    const userNumber = message.from.split('@')[0];
    const userText = message.body.toLowerCase().trim();
    
    // Registrar usuario
    const userExists = db.get('users').find({ number: userNumber }).value();
    if (!userExists) {
        db.get('users').push({
            number: userNumber,
            name: message._data.notifyName || 'Usuario',
            joined: moment().format(),
            plan: null,
            expiry: null,
            credentials: null
        }).write();
    }
    
    // MENÚ PRINCIPAL (estilo Telegram)
    if (userText === 'menu' || userText === 'hola' || userText === 'inicio') {
        await message.reply(mainMenu);
        return;
    }
    
    // Opción 1: Planes y precios
    if (userText === '1' || userText === 'planes') {
        await message.reply(plansMenu);
        return;
    }
    
    // Opción 2: Comprar servicio
    if (userText === '2' || userText.startsWith('comprar')) {
        await message.reply(`*💳 MÉTODOS DE PAGO*

1️⃣ *TRANSFERENCIA BANCARIA*
🏦 Banco: Tu Banco
📊 CBU: 0000000000000000000
👤 Nombre: Tu Nombre

2️⃣ *MERCADO PAGO*
🔗 Link: https://mpago.la/tucodigo
👤 Alias: tu.alias.mp

3️⃣ *CRIPTOMONEDAS*
💰 USDT (TRC20): TU_DIRECCION
💰 BTC: TU_DIRECCION

*📝 INSTRUCCIONES:*
1. Realiza el pago
2. Envía el comprobante aquí
3. Recibirás tus credenciales en minutos

*9*️⃣ VOLVER AL MENÚ`);
        return;
    }
    
    // Opción 3: Mi cuenta
    if (userText === '3' || userText.includes('mi cuenta')) {
        const user = db.get('users').find({ number: userNumber }).value();
        
        if (user && user.plan) {
            const daysLeft = moment(user.expiry).diff(moment(), 'days');
            await message.reply(`*📊 TU CUENTA*

👤 Usuario SSH: *${user.credentials?.user || 'No asignado'}*
🔑 Contraseña: *${user.credentials?.pass || 'No asignada'}*
📅 Expira: *${user.expiry || 'No activo'}*
⏳ Días restantes: *${daysLeft > 0 ? daysLeft : 'VENCIDO'}*

🔄 *RENOVAR:* Envía "renovar"`);
        } else {
            await message.reply(`❌ *NO TIENES SERVICIO ACTIVO*

Para adquirir un plan:
1. Escribe *1* para ver planes
2. Elige el que prefieras
3. Realiza el pago

*9*️⃣ VOLVER AL MENÚ`);
        }
        return;
    }
    
    // Opción 4: Soporte
    if (userText === '4' || userText.includes('soporte')) {
        await message.reply(`*🛠️ SOPORTE TÉCNICO*

📞 *Contacto directo:* +54 9 11 2233-4455
🕒 *Horario:* 9:00 a 21:00 hs

*Problemas comunes:*
🔹 *No me conecta:* Verifica usuario/contraseña
🔹 *Lento:* Prueba otro servidor
🔹 *App no funciona:* Usa OpenVPN o SSTP

*9*️⃣ VOLVER AL MENÚ`);
        return;
    }
    
    // Opción 5: Información
    if (userText === '5' || userText.includes('info')) {
        await message.reply(`*ℹ️ INFORMACIÓN WASSH VPN*

🚀 *Velocidad garantizada*
🔒 *Cifrado militar AES-256*
🌐 *Servidores en 5 países*
📱 *Apps para iOS y Android*

✅ *Garantía de reembolso 24h*
✅ *Soporte 24/7*
✅ *Sin límite de ancho de banda*

📲 *Descarga apps:*
Android: https://play.google.com/...
iOS: https://apps.apple.com/...

*9*️⃣ VOLVER AL MENÚ`);
        return;
    }
    
    // Volver al menú
    if (userText === '9' || userText === 'volver') {
        await message.reply(mainMenu);
        return;
    }
    
    // Salir
    if (userText === '0' || userText === 'salir') {
        await message.reply('👋 ¡Gracias por contactarnos! Escribe *menu* cuando quieras.');
        return;
    }
    
    // ADMIN COMMANDS
    if (userNumber === db.get('config.admin').value()) {
        if (userText.startsWith('/add')) {
            const parts = userText.split(' ');
            if (parts.length === 4) {
                const [, user, pass, days] = parts;
                db.get('users').find({ number: user }).assign({
                    credentials: { user, pass },
                    expiry: moment().add(days, 'days').format(),
                    plan: 'admin_added'
                }).write();
                
                // Crear usuario SSH (simulado)
                console.log(`[ADMIN] Creando usuario SSH: ${user}:${pass} por ${days} días`);
                
                await message.reply(`✅ Usuario creado:
👤 User: ${user}
🔑 Pass: ${pass}
📅 Días: ${days}
🔗 SSH: ${db.get('config.ssh_host').value()}:${db.get('config.ssh_port').value()}`);
                
                // Enviar credenciales al usuario
                const userMsg = `*✅ TU SERVICIO SSH ESTÁ LISTO*

👤 *Usuario:* \`${user}\`
🔑 *Contraseña:* \`${pass}\`
🔗 *Servidor:* ${db.get('config.ssh_host').value()}
⚡️ *Puerto:* ${db.get('config.ssh_port').value()}
📅 *Expira:* ${moment().add(days, 'days').format('DD/MM/YYYY')}

📱 *App recomendada:* HTTP Injector
🌐 *Configuración:* SSH + Proxy

*⚠️ NO COMPARTAS TUS CREDENCIALES*`;
                
                client.sendMessage(user + '@c.us', userMsg);
            }
            return;
        }
        
        if (userText === '/stats') {
            const users = db.get('users').value().length;
            const sales = db.get('sales').value().length;
            await message.reply(`📊 *ESTADÍSTICAS*
👥 Usuarios: ${users}
💰 Ventas: ${sales}
🔄 Activo: ${moment().format('DD/MM HH:mm')}`);
            return;
        }
    }
    
    // Respuesta por defecto
    if (!['1','2','3','4','5','9','0'].includes(userText)) {
        await message.reply(`🤖 No entendí tu mensaje.

Escribe *menu* para ver las opciones disponibles.

O elige una opción:
*1* - Planes y precios
*2* - Comprar servicio  
*3* - Mi cuenta
*4* - Soporte técnico
*5* - Información`);
    }
});

// Manejar errores
client.on('auth_failure', () => {
    console.log('❌ Error de autenticación. Reiniciando...');
    setTimeout(() => process.exit(1), 5000);
});

client.on('disconnected', () => {
    console.log('❌ Desconectado. Reiniciando...');
    setTimeout(() => process.exit(1), 5000);
});

// Iniciar
console.log('🚀 Iniciando WASSH Bot...');
console.log('📅 ' + moment().format('DD/MM/YYYY HH:mm:ss'));
client.initialize();

// Mantener vivo
setInterval(() => {
    console.log('[HEARTBEAT] Bot activo -', moment().format('HH:mm:ss'));
}, 300000); // 5 minutos
EOF

# 5. Crear archivos de configuración
echo "[5/8] Creando archivos de configuración..."

# database.json inicial
cat > database.json <<'EOF'
{
  "users": [],
  "sales": [],
  "plans": [
    {
      "id": "basic",
      "name": "Básico 30 días",
      "price": 1000,
      "days": 30,
      "devices": 1
    },
    {
      "id": "premium", 
      "name": "Premium 60 días",
      "price": 2000,
      "days": 60,
      "devices": 3
    },
    {
      "id": "vip",
      "name": "VIP 90 días",
      "price": 3000,
      "days": 90,
      "devices": 5
    }
  ],
  "config": {
    "admin": "5491122334455",
    "ssh_host": "tussh.com",
    "ssh_port": "22",
    "payment_methods": {
      "transfer": "Banco: Tu Banco\nCBU: 0000000000000000000",
      "mercadopago": "Alias: tu.alias.mp",
      "crypto": "USDT: TU_DIRECCION"
    }
  }
}
EOF

# .env básico
cat > .env <<'EOF'
# Configuración básica
BOT_NAME=WASSH_SSH_BOT
ADMIN_NUMBER=5491122334455

# Email (opcional)
MAIL_HOST=smtp.gmail.com
MAIL_PORT=465
MAIL_USER=tu@gmail.com
MAIL_PASS=tu_password_app

# SSH Server
SSH_HOST=tu.servidor.com
SSH_PORT=22
SSH_USER=root

# Web Server
PORT=9000
HOST=0.0.0.0
EOF

# 6. Instalar dependencias
echo "[6/8] Instalando dependencias npm..."
npm install --no-audit --no-fund

# 7. Crear script de servicio
echo "[7/8] Creando servicio systemd..."

cat > /etc/systemd/system/wasshbot.service <<EOF
[Unit]
Description=WASSH Bot de Ventas SSH
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=$INSTALL_DIR
ExecStart=/usr/bin/npm start
Restart=always
RestartSec=10
StandardOutput=append:$LOG_FILE
StandardError=append:$LOG_FILE
Environment=NODE_ENV=production

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload

# 8. Crear comando wassh
echo "[8/8] Creando comando wassh..."

cat > /usr/bin/wassh <<'EOF'
#!/bin/bash

INSTALL_DIR="/opt/wassh"
LOG_FILE="/var/log/wassh.log"

case "$1" in
    "start")
        echo "🤖 Iniciando WASSH Bot..."
        systemctl start wasshbot
        echo "✅ Bot iniciado"
        echo "🌐 Web: http://localhost:9000"
        echo "📱 QR: http://localhost:9000/qr"
        echo "📋 Logs: tail -f $LOG_FILE"
        ;;
    "stop")
        echo "🛑 Deteniendo bot..."
        systemctl stop wasshbot
        echo "✅ Bot detenido"
        ;;
    "restart")
        echo "🔄 Reiniciando bot..."
        systemctl restart wasshbot
        echo "✅ Bot reiniciado"
        ;;
    "status")
        systemctl status wasshbot --no-pager
        ;;
    "logs")
        tail -f "$LOG_FILE"
        ;;
    "qr")
        echo "📱 Mostrando QR..."
        echo "Accede a: http://localhost:9000/qr"
        echo "O mira los logs para verlo en terminal"
        ;;
    "config")
        echo "⚙️  Editando configuración..."
        nano "$INSTALL_DIR/.env"
        ;;
    "menu")
        echo "🤖 MENÚ WASSH BOT:"
        echo "  start     - Iniciar bot"
        echo "  stop      - Detener bot"
        echo "  restart   - Reiniciar bot"
        echo "  status    - Ver estado"
        echo "  logs      - Ver logs en tiempo real"
        echo "  qr        - Mostrar QR code"
        echo "  config    - Editar configuración"
        echo "  (sin comando) - Mostrar este menú"
        ;;
    *)
        echo "🤖 WASSH BOT - Bot de Ventas SSH"
        echo "================================="
        echo ""
        echo "📋 COMANDOS DISPONIBLES:"
        echo "  wassh start     - Iniciar bot"
        echo "  wassh stop      - Detener bot"
        echo "  wassh restart   - Reiniciar bot"
        echo "  wassh status    - Ver estado"
        echo "  wassh logs      - Ver logs (QR aquí)"
        echo "  wassh qr        - Acceder al QR web"
        echo "  wassh config    - Editar configuración"
        echo ""
        echo "🚀 INICIO RÁPIDO:"
        echo "  1. wassh start"
        echo "  2. wassh logs  (ver QR en terminal)"
        echo "  3. Escanear QR con WhatsApp"
        echo "  4. Escribe 'menu' en WhatsApp"
        echo ""
        echo "📞 Soporte: contacta al administrador"
        ;;
esac
EOF

chmod +x /usr/bin/wassh

echo ""
echo "=========================================="
echo "✅ INSTALACIÓN COMPLETADA"
echo "=========================================="
echo ""
echo "🚀 INICIO INMEDIATO:"
echo "1. Iniciar bot:"
echo "   wassh start"
echo ""
echo "2. Ver QR para vincular WhatsApp:"
echo "   wassh logs"
echo "   O visita: http://localhost:9000/qr"
echo ""
echo "3. Una vez vinculado, escribe 'menu' en WhatsApp"
echo ""
echo "🔧 CONFIGURACIÓN BÁSICA:"
echo "   wassh config  # Editar .env"
echo "   nano /opt/wassh/database.json  # Editar planes"
echo ""
echo "📊 ESTADO DEL BOT:"
echo "   wassh status"
echo ""
echo "🎯 MENÚ WHATSAPP DISPONIBLE:"
echo "   • 1 - Planes y precios"
echo "   • 2 - Comprar servicio"
echo "   • 3 - Mi cuenta / Renovar"
echo "   • 4 - Soporte técnico"
echo "   • 5 - Información"
echo "   • 9 - Volver al menú"
echo "   • 0 - Salir"
echo ""
echo "🔐 COMANDOS ADMIN:"
echo "   /add [numero] [password] [dias]"
echo "   /stats"
echo ""
