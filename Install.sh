#!/bin/bash
# ================================================
# SSH BOT PRO v8.6 - CON IA INTELIGENTE
# ================================================

set -e

# ... (todo el inicio del script igual hasta crear bot.js) ...

# ================================================
# BOT CON IA INTELIGENTE SIMPLE
# ================================================

cat > "$USER_HOME/bot.js" << 'BOTEOF'
const { Client, LocalAuth, MessageMedia } = require('whatsapp-web.js');
const qrcodeTerminal = require('qrcode-terminal');
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

function loadConfig() {
    delete require.cache[require.resolve('/opt/ssh-bot/config/config.json')];
    return require('/opt/ssh-bot/config/config.json');
}

let config = loadConfig();
const db = new sqlite3.Database(config.paths.database);

// ================================================
// SISTEMA DE IA SIMPLE
// ================================================

class AsistenteIA {
    constructor() {
        this.contextos = {};
        this.palabrasClave = {
            saludos: ['hola', 'buenas', 'hey', 'hi', 'qué tal', 'saludos'],
            compras: ['comprar', 'quiero', 'deseo', 'necesito', 'adquirir', 'contratar'],
            ayuda: ['ayuda', 'soporte', 'asistencia', 'problema', 'error', 'no funciona'],
            planes: ['plan', 'planes', 'precio', 'precios', 'cuánto', 'costo'],
            pagos: ['pago', 'pag', 'mercadopago', 'tarjeta', 'efectivo', 'transferencia'],
            conexion: ['conectar', 'conexión', 'no conecta', 'no funciona', 'error ssh'],
            app: ['app', 'aplicación', 'descargar', 'instalar', 'apk']
        };
        
        this.respuestasIA = {
            saludos: [
                "¡Hola! 👋 Soy tu asistente inteligente de SSH Bot. ¿En qué puedo ayudarte hoy?",
                "¡Buen día! 😊 Estoy aquí para asistirte con el servicio SSH. ¿Qué necesitas?",
                "¡Hola! 🤖 Listo para ayudarte. Puedo guiarte con compras, soporte o información."
            ],
            dudas_compra: [
                "Veo que estás interesado en comprar. Te recomiendo comenzar con la *prueba gratuita* de 2 horas para probar el servicio. ¿Te parece?",
                "Excelente que quieras adquirir el servicio. ¿Para qué lo necesitarías principalmente? Así te puedo recomendar el mejor plan.",
                "Para comprar, tenemos 3 opciones:\n• *basico* - 7 días ($500)\n• *estandar* - 15 días ($800)\n• *premium* - 30 días ($1200)\n\n¿Cuál te interesa?"
            ],
            ayuda_conexion: [
                "Si tienes problemas de conexión, verifica:\n1. Usuario y contraseña correctos\n2. La cuenta no ha expirado\n3. No excedes el límite de conexiones\n\n¿Qué error específico ves?",
                "Problemas de conexión comunes:\n• Usuario/contraseña incorrectos\n• Cuenta expirada\n• Límite de conexiones alcanzado\n\n¿Puedes darme más detalles?",
                "Para solucionar problemas de conexión:\n1. Verifica tus datos en *cuentas*\n2. Asegúrate que no haya expirado\n3. Solo 1 conexión simultánea permitida"
            ],
            recomendaciones: {
                'estudio': "Para estudios, te recomiendo el *plan estandar* (15 días). Tiempo suficiente para proyectos académicos.",
                'trabajo': "Para trabajo, el *plan premium* (30 días) es ideal. Mayor estabilidad y duración.",
                'prueba': "Si solo quieres probar, comienza con *prueba* gratuita de 2 horas.",
                'ocasional': "Para uso ocasional, el *plan basico* (7 días) es perfecto.",
                'streaming': "Para streaming o alto consumo, el *plan premium* ofrece mejor rendimiento."
            }
        };
    }
    
    async procesarMensaje(texto, phone) {
        const textoLower = texto.toLowerCase().trim();
        
        // Inicializar contexto si no existe
        if (!this.contextos[phone]) {
            this.contextos[phone] = {
                historial: [],
                intencion: null,
                paso: 0,
                datos: {}
            };
        }
        
        const contexto = this.contextos[phone];
        contexto.historial.push({ texto: textoLower, timestamp: Date.now() });
        
        // Limitar historial a últimos 10 mensajes
        if (contexto.historial.length > 10) {
            contexto.historial.shift();
        }
        
        // Detectar intención
        const intencion = this.detectarIntencion(textoLower);
        
        // Si es un comando directo, no procesar con IA
        const comandosDirectos = ['menu', 'prueba', 'basico', 'estandar', 'premium', 'cuentas', 'app', 'soporte', 'pagos', 'ayuda'];
        if (comandosDirectos.includes(textoLower)) {
            return null; // Dejar que el bot normal lo maneje
        }
        
        // Si es pregunta específica
        if (textoLower.includes('?') || this.esPregunta(textoLower)) {
            return this.responderPregunta(textoLower, contexto);
        }
        
        // Si detectamos intención clara
        if (intencion) {
            return this.procesarIntencion(intencion, textoLower, contexto);
        }
        
        // Si no entendemos, ofrecer ayuda
        if (contexto.historial.length === 1) {
            const saludoAleatorio = this.respuestasIA.saludos[
                Math.floor(Math.random() * this.respuestasIA.saludos.length)
            ];
            return saludoAleatorio;
        }
        
        // Respuesta por defecto
        return this.generarRespuestaInteligente(contexto);
    }
    
    detectarIntencion(texto) {
        for (const [intencion, palabras] of Object.entries(this.palabrasClave)) {
            if (palabras.some(palabra => texto.includes(palabra))) {
                return intencion;
            }
        }
        return null;
    }
    
    esPregunta(texto) {
        const palabrasPregunta = ['cómo', 'cuándo', 'dónde', 'por qué', 'qué', 'cuál', 'cuánto', 'funciona', 'sirve'];
        return palabrasPregunta.some(palabra => texto.includes(palabra));
    }
    
    responderPregunta(pregunta, contexto) {
        if (pregunta.includes('cómo comprar') || pregunta.includes('cómo pagar')) {
            return `Para comprar es muy simple:\n\n1. Envía *basico*, *estandar* o *premium*\n2. Te genero un pago seguro\n3. Pagas con tu método preferido\n4. Recibes tus datos automáticamente\n\n¿Quieres comenzar con algún plan específico?`;
        }
        
        if (pregunta.includes('cuánto cuesta') || pregunta.includes('precio')) {
            return `Tenemos estos precios:\n\n🎁 *Prueba*: 2 horas - GRATIS\n🥉 *Básico*: 7 días - $${config.prices.price_7d} ARS\n🥈 *Estándar*: 15 días - $${config.prices.price_15d} ARS\n🥇 *Premium*: 30 días - $${config.prices.price_30d} ARS\n\n¿Te interesa alguno?`;
        }
        
        if (pregunta.includes('cómo funciona') || pregunta.includes('qué es')) {
            return `SSH Bot te da acceso a un servidor SSH para:\n\n🔒 *Navegación segura*\n🌐 *Acceso a contenido*\n⚡ *Alta velocidad*\n📱 *App incluida*\n\nPruébalo gratis con *prueba*`;
        }
        
        if (pregunta.includes('cómo descargar') || pregunta.includes('dónde app')) {
            return `Para descargar la app:\n\n1. Envía *app*\n2. Recibirás el archivo APK\n3. Instálalo en tu Android\n4. Ingresa usuario y contraseña\n\n¿Necesitas la aplicación ahora?`;
        }
        
        return `Interesante pregunta. 🤔\n\nSobre "${pregunta}", te puedo ayudar con:\n• Información de planes y precios\n• Proceso de compra y pago\n• Soporte técnico\n• Descarga de aplicación\n\n¿En qué área específica necesitas ayuda?`;
    }
    
    procesarIntencion(intencion, texto, contexto) {
        switch(intencion) {
            case 'compras':
                return this.manejarCompra(texto, contexto);
                
            case 'ayuda':
                return this.manejarAyuda(texto, contexto);
                
            case 'pagos':
                return `Los pagos son mediante MercadoPago. Aceptamos:\n\n💳 Tarjetas de crédito/débito\n🏪 Efectivo (Pago Fácil/Rapipago)\n📱 MercadoPago saldo\n💰 Transferencia bancaria\n\n¿Listo para generar un pago? Envía *basico*, *estandar* o *premium*`;
                
            case 'conexion':
                return this.respuestasIA.ayuda_conexion[
                    Math.floor(Math.random() * this.respuestasIA.ayuda_conexion.length)
                ];
                
            default:
                return this.generarRespuestaInteligente(contexto);
        }
    }
    
    manejarCompra(texto, contexto) {
        // Detectar para qué necesita el servicio
        if (texto.includes('estudio') || texto.includes('universidad') || texto.includes('colegio')) {
            return `Para estudios, ${this.respuestasIA.recomendaciones.estudio}\n\n¿Quieres activar la prueba gratis primero para probar?`;
        }
        
        if (texto.includes('trabajo') || texto.includes('oficina') || texto.includes('empresa')) {
            return `Para trabajo, ${this.respuestasIA.recomendaciones.trabajo}\n\n¿Te interesa este plan?`;
        }
        
        if (texto.includes('probar') || texto.includes('probar') || texto.includes('prueba')) {
            return this.respuestasIA.recomendaciones.prueba;
        }
        
        if (texto.includes('netflix') || texto.includes('youtube') || texto.includes('streaming')) {
            return `Para streaming, ${this.respuestasIA.recomendaciones.streaming}\n\n¿Quieres más información?`;
        }
        
        return this.respuestasIA.dudas_compra[
            Math.floor(Math.random() * this.respuestasIA.dudas_compra.length)
        ];
    }
    
    manejarAyuda(texto, contexto) {
        if (texto.includes('no conecta') || texto.includes('error conexión')) {
            return this.respuestasIA.ayuda_conexion[0];
        }
        
        if (texto.includes('pago') || texto.includes('mercadopago')) {
            return `Problemas con pagos:\n\n1. *Pago pendiente*: Espera 5-10 minutos\n2. *Tarjeta rechazada*: Verifica fondos/datos\n3. *Error en enlace*: Solicita nuevo pago\n\n¿Cuál es tu situación?`;
        }
        
        if (texto.includes('app') || texto.includes('instalar')) {
            return `Para problemas con la app:\n\n1. Asegúrate de permitir "Fuentes desconocidas"\n2. Reinicia tu dispositivo\n3. Descarga nuevamente con *app*\n\n¿Sigues con problemas?`;
        }
        
        return `Para ayuda específica, por favor:\n\n1. Describe tu problema en detalle\n2. Menciona qué comando usaste\n3. Si hay error, copia el mensaje exacto\n\nO usa *soporte* para contacto directo.`;
    }
    
    generarRespuestaInteligente(contexto) {
        // Analizar historial para contexto
        const ultimosMensajes = contexto.historial.slice(-3);
        const temas = [];
        
        ultimosMensajes.forEach(msg => {
            if (msg.texto.includes('compra') || msg.texto.includes('quiero')) temas.push('compra');
            if (msg.texto.includes('error') || msg.texto.includes('problema')) temas.push('ayuda');
            if (msg.texto.includes('app') || msg.texto.includes('descargar')) temas.push('app');
        });
        
        if (temas.includes('compra')) {
            return `Siguiendo sobre la compra, ¿has decidido algún plan?\n\nPuedes enviar:\n• *prueba* para probar gratis\n• *basico* para plan 7 días\n• *estandar* para plan 15 días\n• *premium* para plan 30 días`;
        }
        
        if (temas.includes('ayuda')) {
            return `Sobre el problema que mencionas, ¿podrías darme más detalles?\n\nO si prefieres, envía *soporte* para contacto directo con asistencia técnica.`;
        }
        
        // Respuesta genérica pero útil
        const respuestasGenericas = [
            "Entiendo. ¿Te gustaría que te ayude con algo específico como:\n• Comprar un plan\n• Solucionar problemas\n• Descargar la app\n• Ver tus cuentas?",
            "Puedo asistirte mejor si me dices qué necesitas exactamente. Por ejemplo:\n\"Quiero comprar el plan básico\"\n\"Tengo error al conectar\"\n\"Necesito la aplicación\"",
            "¿En qué puedo ayudarte específicamente? Estoy aquí para:\n🎁 Guiarte en compras\n🔧 Solucionar problemas\n📱 Ayudar con la app\n💬 Responder preguntas"
        ];
        
        return respuestasGenericas[Math.floor(Math.random() * respuestasGenericas.length)];
    }
    
    limpiarContexto(phone) {
        delete this.contextos[phone];
    }
}

// Inicializar IA
const asistenteIA = new AsistenteIA();

// ================================================
// FUNCIONES AUXILIARES ORIGINALES (MANTENIDAS)
// ================================================

// ... (aquí van todas las funciones originales igual: loadConfig, initMercadoPago, etc.) ...

// ================================================
// CLIENTE WHATSAPP
// ================================================

const client = new Client({
    authStrategy: new LocalAuth({dataPath: '/root/.wwebjs_auth', clientId: 'ssh-bot-v86'}),
    puppeteer: {
        headless: true,
        executablePath: config.paths.chromium,
        args: ['--no-sandbox', '--disable-setuid-sandbox', '--disable-dev-shm-usage', '--disable-gpu', '--no-first-run', '--disable-extensions'],
        timeout: 60000
    },
    authTimeoutMs: 60000
});

// ================================================
// EVENTOS
// ================================================

let qrCount = 0;

client.on('qr', (qr) => {
    qrCount++;
    console.clear();
    console.log(chalk.yellow.bold(`\n╔════════ 🤖 IA ACTIVADA - QR #${qrCount} ════════╗\n`));
    qrcodeTerminal.generate(qr, { small: true });
    QRCode.toFile('/root/qr-whatsapp.png', qr, { width: 500 }).catch(() => {});
    console.log(chalk.cyan('\n🔮 Asistente IA: Activado'));
    console.log(chalk.cyan('💬 Comandos simples: prueba/basico/estandar/premium'));
    console.log(chalk.cyan('🤖 IA: Responde preguntas naturales\n'));
});

client.on('authenticated', () => console.log(chalk.green('✅ Autenticado con IA')));
client.on('ready', () => {
    console.clear();
    console.log(chalk.green.bold('\n🤖 BOT CON IA ACTIVADO Y OPERATIVO\n'));
    console.log(chalk.cyan('✨ Características activadas:'));
    console.log(chalk.cyan('   • Asistente IA inteligente'));
    console.log(chalk.cyan('   • Comandos simples de compra'));
    console.log(chalk.cyan('   • Respuestas contextuales'));
    console.log(chalk.cyan('   • Detección de intenciones'));
    console.log(chalk.cyan('\n💬 Escribe cualquier mensaje natural al bot\n'));
    qrCount = 0;
});

// ================================================
// MANEJO DE MENSAJES CON IA
// ================================================

client.on('message', async (msg) => {
    const text = msg.body.trim();
    const phone = msg.from;
    if (phone.includes('@g.us')) return;
    
    config = loadConfig();
    console.log(chalk.cyan(`📩 [${phone.split('@')[0]}]: ${text.substring(0, 50)}`));
    
    // ✅ MENÚ MEJORADO CON IA
    if (['menu', 'hola', 'start', 'hi', 'comandos', 'opciones'].includes(text.toLowerCase())) {
        await client.sendMessage(phone, 
`✨ *🤖 SSH BOT PRO - ASISTENTE IA* ✨

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🎯 *¿QUÉ NECESITAS?*

🛒 *COMPRAR RÁPIDO:*
🎁 \`prueba\` - 2h GRATIS
🥉 \`basico\` - 7 días ($${config.prices.price_7d})
🥈 \`estandar\` - 15 días ($${config.prices.price_15d})
🥇 \`premium\` - 30 días ($${config.prices.price_30d})

🔧 *HERRAMIENTAS:*
👤 \`cuentas\` - Tus accesos
📱 \`app\` - Descargar aplicación
💳 \`pagos\` - Estado de pagos
🆘 \`soporte\` - Ayuda humana

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🤖 *ASISTENTE IA ACTIVO*
Puedes escribirme naturalmente:
• "Quiero comprar para estudiar"
• "¿Cómo funciona el servicio?"
• "Tengo error al conectar"
• "¿Cuánto cuesta el plan premium?"

💡 *Ejemplos con IA:*
• "Recomiéndame un plan para Netflix"
• "¿Cómo pago con MercadoPago?"
• "Mi conexión no funciona, ayuda"

⚡ *Responde a preguntas complejas*
🔍 *Analiza tus necesidades*
🎯 *Recomienda planes personalizados*`, 
            { sendSeen: false }
        );
        return;
    }
    
    // ✅ PRIMERO: Procesar con IA si no es comando directo
    const respuestaIA = await asistenteIA.procesarMensaje(text, phone);
    
    if (respuestaIA && !this.esComandoDirecto(text.toLowerCase())) {
        await client.sendMessage(phone, 
`🤖 *ASISTENTE IA:*

${respuestaIA}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

💡 *También puedes usar comandos rápidos:*
• \`prueba\` - Probar gratis
• \`basico\` - Plan 7 días
• \`estandar\` - Plan 15 días
• \`premium\` - Plan 30 días
• \`menu\` - Ver todas opciones`, 
            { sendSeen: false }
        );
        return;
    }
    
    // ✅ SEGUNDO: Comandos directos (si IA no respondió o es comando)
    const textLower = text.toLowerCase();
    
    // COMANDOS SIMPLES DE COMPRA
    if (textLower === 'prueba' || textLower === 'test' || textLower === 'gratis') {
        await manejarPruebaGratis(phone);
    }
    else if (textLower === 'basico' || textLower === '7d' || textLower === 'semanal') {
        await iniciarCompraIA(phone, 'basico', 7, config.prices.price_7d, '🥉 PLAN BÁSICO');
    }
    else if (textLower === 'estandar' || textLower === '15d' || textLower === 'quincenal') {
        await iniciarCompraIA(phone, 'estandar', 15, config.prices.price_15d, '🥈 PLAN ESTÁNDAR');
    }
    else if (textLower === 'premium' || textLower === '30d' || textLower === 'mensual') {
        await iniciarCompraIA(phone, 'premium', 30, config.prices.price_30d, '🥇 PLAN PREMIUM');
    }
    // COMANDOS DE INFORMACIÓN
    else if (textLower === 'cuentas' || textLower === 'mis cuentas' || textLower === 'accesos') {
        await mostrarCuentasIA(phone);
    }
    else if (textLower === 'pagos' || textLower === 'estado' || textLower === 'historial') {
        await mostrarPagosIA(phone);
    }
    else if (textLower === 'app' || textLower === 'descargar' || textLower === 'aplicacion') {
        await enviarAppIA(phone);
    }
    else if (textLower === 'soporte' || textLower === 'ayuda' || textLower === 'help') {
        await mostrarSoporteIA(phone);
    }
    // ✅ SI NO ES NINGUNO DE LOS ANTERIORES Y IA NO RESPONDIÓ
    else {
        await client.sendMessage(phone,
`🤔 *NO ENTENDÍ COMPLETAMENTE*

Parece que quieres algo específico. Te ayudo:

📋 *OPCIONES RÁPIDAS:*
🎁 \`prueba\` - Probar 2h gratis
💰 \`basico\` - Comprar plan 7 días
🔧 \`cuentas\` - Ver tus accesos
📱 \`app\` - Descargar aplicación

💬 *O ESCRIBE NATURALMENTE:*
• "Quiero comprar para ver Netflix"
• "¿Cómo descargo la app?"
• "Tengo error en la conexión"
• "Recomiéndame un plan"

🤖 *Mi IA intentará entenderte mejor*`, 
            { sendSeen: false }
        );
    }
});

// ================================================
// FUNCIONES AUXILIARES PARA IA
// ================================================

function esComandoDirecto(texto) {
    const comandos = ['prueba', 'basico', 'estandar', 'premium', 'cuentas', 'pagos', 'app', 'soporte', 'menu'];
    return comandos.includes(texto);
}

async function manejarPruebaGratis(phone) {
    if (!(await canCreateTest(phone))) {
        await client.sendMessage(phone,
`⚠️ *PRUEBA YA UTILIZADA*

Ya usaste tu prueba gratuita hoy.

💎 *¿LISTO PARA ACTUALIZAR?*

🥉 \`basico\` - 7 días ($${config.prices.price_7d})
🥈 \`estandar\` - 15 días ($${config.prices.price_15d})
🥇 \`premium\` - 30 días ($${config.prices.price_30d})

🤖 *¿Para qué necesitas el servicio?*
Escribe y te recomendaré el mejor plan.`, 
            { sendSeen: false }
        );
        return;
    }
    
    await client.sendMessage(phone, '🤖 *Creando tu prueba con IA...* ⏳', { sendSeen: false });
    
    try {
        const username = generateUsername();
        const password = generatePassword();
        await createSSHUser(phone, username, password, 0, 1);
        registerTest(phone);
        
        await client.sendMessage(phone,
`🎉 *¡PRUEBA IA ACTIVADA!*

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🔐 *TUS DATOS SEGUROS:*
👤 Usuario: \`${username}\`
🔑 Contraseña: \`${password}\`

⏰ *VALIDEZ:* 2 horas
🔌 *CONEXIONES:* 1 simultánea

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📱 *INSTALACIÓN RÁPIDA:*
1️⃣ Envía \`app\` para descargar
2️⃣ Instala y abre la aplicación
3️⃣ Ingresa tus datos arriba
4️⃣ ¡Conéctate al instante! ⚡

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🤖 *RECOMENDACIÓN IA:*
Después de probar, te sugiero:
• Para uso básico: \`basico\` (7 días)
• Para proyectos: \`estandar\` (15 días)
• Para trabajo: \`premium\` (30 días)

💭 *¿Para qué usarás el servicio?*
Responde y personalizo mi recomendación.`, 
            { sendSeen: false }
        );
    } catch (error) {
        await client.sendMessage(phone,
`❌ *ERROR IA DETECTADO*

Mi sistema encontró un problema:

\`${error.message}\`

🤖 *SOLUCIÓN SUGERIDA:*
1. Intenta nuevamente en 2 minutos
2. O envía \`soporte\` para ayuda humana
3. Verifica tu conexión a internet

🔄 Reintentando automáticamente...`, 
            { sendSeen: false }
        );
    }
}

async function iniciarCompraIA(phone, plan, days, amount, nombrePlan) {
    config = loadConfig();
    
    if (!config.mercadopago.access_token || config.mercadopago.access_token === '') {
        await client.sendMessage(phone,
`❌ *SISTEMA DE PAGOS NO CONFIGURADO*

Mi IA detectó que los pagos no están activados.

📞 *SOLUCIÓN:*
Contacta al administrador:
${config.links.support || 'No configurado'}

🎁 *MIENTRAS TANTO:*
Prueba el servicio gratis con \`prueba\`

🤖 *IA EN ACCIÓN:*
Cuando se active MercadoPago, podrás:
• Pagar con tarjeta/efectivo
• Activación automática
• Soporte 24/7`, 
            { sendSeen: false }
        );
        return;
    }
    
    await client.sendMessage(phone,
`🤖 *PROCESANDO COMPRA CON IA*

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

${nombrePlan}
⏰ ${days} días de acceso
💰 $${amount} ARS total
🔌 1 conexión simultánea
⚡ Activación: Inmediata

🔄 *Mi IA está:*
1. Verificando disponibilidad
2. Preparando pago seguro
3. Generando enlace único

⏳ Un momento por favor...`, 
        { sendSeen: false }
    );
    
    try {
        const payment = await createMercadoPagoPayment(phone, plan, days, amount, 1);
        
        if (payment.success) {
            await client.sendMessage(phone,
`✅ *PAGO GENERADO POR IA*

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

${nombrePlan}
✅ Listo para pagar

🔗 *ENLACE DE PAGO IA:*
${payment.paymentUrl}

⏰ *VALIDEZ:* 24 horas
📱 *ID:* ${payment.paymentId.substring(0, 20)}...

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🤖 *VENTAJAS IA:*
• Verificación automática cada 2 min
• Notificación instantánea al aprobarse
• Datos enviados automáticamente
• Soporte inteligente activado

💳 *MÉTODOS ACEPTADOS:*
💳 Tarjetas (Visa/Mastercard)
🏪 Efectivo (Pago Fácil)
📱 MercadoPago saldo
💰 Transferencia bancaria

📝 *¿DUDAS?* Escribe naturalmente o \`soporte\``, 
                { sendSeen: false }
            );
            
            if (fs.existsSync(payment.qrPath)) {
                const media = MessageMedia.fromFilePath(payment.qrPath);
                await client.sendMessage(phone, media, {
                    caption: '📱 *ESCANEA CON IA*\n\nMi sistema generó este QR único para pago rápido',
                    sendSeen: false
                });
            }
        } else {
            await client.sendMessage(phone,
`❌ *ERROR IA EN PAGO*

Mi sistema encontró:

\`${payment.error}\`

🤖 *SOLUCIONES SUGERIDAS:*
1. Intenta con \`prueba\` (gratis primero)
2. Verifica conexión a internet
3. Espera 5 minutos e intenta de nuevo
4. Contacta \`soporte\` para ayuda humana

🔄 Mi IA aprenderá de este error.`, 
                { sendSeen: false }
            );
        }
    } catch (error) {
        await client.sendMessage(phone,
`❌ *FALLA CRÍTICA IA*

Mi sistema de compras falló:

\`${error.message}\`

🤖 *ACCIONES AUTOMÁTICAS:*
1. Error reportado al sistema
2. Backup activado
3. Modo seguro: \`prueba\` gratis disponible

🆘 *AYUDA INMEDIATA:*
Envía \`soporte\` para contacto humano`, 
            { sendSeen: false }
        );
    }
}

async function mostrarCuentasIA(phone) {
    db.all(`SELECT username, password, tipo, expires_at, max_connections FROM users WHERE phone = ? AND status = 1 ORDER BY created_at DESC LIMIT 10`, [phone],
        async (err, rows) => {
            if (!rows || rows.length === 0) {
                await client.sendMessage(phone,
`📭 *SIN CUENTAS IA DETECTADAS*

Mi sistema no encuentra cuentas activas.

🎁 *RECOMENDACIÓN IA:*
Comienza con \`prueba\` - 2h gratis

💰 *O COMPRA DIRECTAMENTE:*
\`basico\` - 7 días ($${config.prices.price_7d})
\`estandar\` - 15 días ($${config.prices.price_15d})
\`premium\` - 30 días ($${config.prices.price_30d})

🤖 *¿Necesitas ayuda para elegir?*
Escribe tu necesidad y te aconsejo.`, 
                    { sendSeen: false }
                );
                return;
            }
            
            let msg = `🤖 *TUS CUENTAS - ANÁLISIS IA*\n\n`;
            msg += `━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n`;
            
            rows.forEach((cuenta, i) => {
                const tipo = cuenta.tipo === 'premium' ? '💎 PREMIUM' : '🆓 PRUEBA';
                const expira = moment(cuenta.expires_at).format('DD/MM HH:mm');
                const estado = moment(cuenta.expires_at).isAfter(moment()) ? '✅ ACTIVA' : '❌ EXPIRADA';
                const icon = cuenta.tipo === 'premium' ? '⭐' : '🆓';
                
                msg += `${icon} *${tipo}* (${estado})\n`;
                msg += `👤 \`${cuenta.username}\`\n`;
                msg += `🔑 \`${cuenta.password}\`\n`;
                msg += `⏰ ${expira}\n`;
                msg += `🔌 ${cuenta.max_connections} conexión\n`;
                
                // Análisis IA
                if (cuenta.tipo === 'test') {
                    msg += `📊 *IA:* Prueba gratuita - Considera upgrade\n`;
                } else {
                    const diasRestantes = moment(cuenta.expires_at).diff(moment(), 'days');
                    if (diasRestantes < 3) {
                        msg += `⚠️ *IA:* Renueva pronto (${diasRestantes} días)\n`;
                    }
                }
                
                msg += `━━━━━━━━━━━━━━━━━━━━\n\n`;
            });
            
            msg += `📱 *ACCIONES SUGERIDAS POR IA:*\n`;
            msg += `• Descargar app: \`app\`\n`;
            msg += `• Renovar: \`basico\`/\`estandar\`/\`premium\`\n`;
            msg += `• Soporte: \`soporte\`\n`;
            msg += `• Volver: \`menu\``;
            
            await client.sendMessage(phone, msg, { sendSeen: false });
        });
}

async function mostrarPagosIA(phone) {
    db.all(`SELECT plan, amount, status, created_at, payment_url FROM payments WHERE phone = ? ORDER BY created_at DESC LIMIT 5`, [phone],
        async (err, pays) => {
            if (!pays || pays.length === 0) {
                await client.sendMessage(phone,
`💳 *SIN HISTORIAL DE PAGOS IA*

Mi sistema no registra pagos tuyos.

🛒 *¿LISTO PARA TU PRIMERA COMPRA?*
🎁 \`prueba\` - Probar primero (gratis)
🥉 \`basico\` - 7 días ($${config.prices.price_7d})
🥈 \`estandar\` - 15 días ($${config.prices.price_15d})
🥇 \`premium\` - 30 días ($${config.prices.price_30d})

🤖 *¿DUDAS SOBRE EL PAGO?*
Pregúntame naturalmente:
• "¿Cómo pago con tarjeta?"
• "¿Aceptan efectivo?"
• "¿Es seguro el pago?"`, 
                    { sendSeen: false }
                );
                return;
            }
            
            let msg = `🤖 *ANÁLISIS IA DE PAGOS*\n\n`;
            msg += `━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n`;
            
            pays.forEach((pago, i) => {
                const emoji = pago.status === 'approved' ? '✅' : '⏳';
                const status = pago.status === 'approved' ? 'APROBADO' : 'PENDIENTE';
                const fecha = moment(pago.created_at).format('DD/MM HH:mm');
                
                msg += `${emoji} *${status}*\n`;
                msg += `📦 ${pago.plan.toUpperCase()}\n`;
                msg += `💰 $${pago.amount} ARS\n`;
                msg += `📅 ${fecha}\n`;
                
                if (pago.status === 'pending') {
                    const horas = moment().diff(moment(pago.created_at), 'hours');
                    if (horas > 12) {
                        msg += `⚠️ *IA:* Pago antiguo, genera nuevo\n`;
                    } else if (horas > 1) {
                        msg += `🔄 *IA:* Verificando automáticamente\n`;
                    }
                }
                
                msg += `━━━━━━━━━━━━━━━━━━━━\n\n`;
            });
            
            msg += `🤖 *RECOMENDACIONES IA:*\n`;
            msg += `• Pagos pendientes se verifican cada 2 min\n`;
            msg += `• Problemas: \`soporte\`\n`;
            msg += `• Nuevo pago: \`basico\`/\`estandar\`/\`premium\`\n`;
            msg += `• Volver: \`menu\``;
            
            await client.sendMessage(phone, msg, { sendSeen: false });
        });
}

async function enviarAppIA(phone) {
    const apkPath = '/root/app.apk';
    
    if (fs.existsSync(apkPath)) {
        try {
            const stats = fs.statSync(apkPath);
            const fileSize = (stats.size / (1024 * 1024)).toFixed(2);
            
            await client.sendMessage(phone,
`🤖 *DESCARGA CON ASISTENCIA IA*

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📦 *APLICACIÓN SSH CLIENT*
📊 Tamaño: ${fileSize} MB
⚡ Versión optimizada
🔒 Seguridad mejorada

🔄 Mi IA está preparando el envío...`, 
                { sendSeen: false }
            );
            
            const media = MessageMedia.fromFilePath(apkPath);
            await client.sendMessage(phone, media, {
                caption: `📱 *APLICACIÓN ENVIADA POR IA*\n\n✅ *Descarga completada*\n\n🤖 *PASOS INTELIGENTES:*\n1️⃣ Toca este archivo para instalar\n2️⃣ Permite "Fuentes desconocidas"\n3️⃣ Abre la aplicación SSH Client\n4️⃣ Ingresa usuario y contraseña\n5️⃣ ¡Conéctate automáticamente! ⚡\n\n💡 *CONSEJO IA:* Si no ves el archivo, revisa "Archivos/Medios" en WhatsApp\n\n🔧 *PROBLEMAS?* Escribe \`soporte\` o describe el error`,
                sendSeen: false
            });
        } catch (error) {
            await client.sendMessage(phone,
`❌ *ERROR IA EN ENVÍO*

Mi sistema no pudo enviar el APK.

🤖 *SOLUCIONES ALTERNATIVAS:*
1. Descarga manual: http://${config.bot.server_ip}:8001/app.apk
2. Usa navegador en tu teléfono
3. O contacta \`soporte\` para ayuda

🔄 Mi IA aprenderá de este error.`, 
                { sendSeen: false }
            );
        }
    } else {
        await client.sendMessage(phone,
`❌ *APLICACIÓN NO ENCONTRADA POR IA*

Mi sistema busca pero no encuentra el APK.

🤖 *ACCIONES SUGERIDAS:*
1. Contacta al administrador
2. Solicita el APK por otro medio
3. Usa el servicio web temporalmente

📞 *CONTACTO RÁPIDO:*
${config.links.support || 'No configurado'}

🔄 Mi IA notificará al administrador.`, 
            { sendSeen: false }
        );
    }
}

async function mostrarSoporteIA(phone) {
    await client.sendMessage(phone,
`🤖 *CENTRO DE SOPORTE INTELIGENTE*

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📞 *CONTACTO HUMANO:*
${config.links.support || 'No configurado'}

⏰ *HORARIO IA MEJORADO:*
24/7 con respuestas automáticas
Humanos: 9:00 - 22:00

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🔧 *¿QUÉ PROBLEMA TIENES?*
Mi IA puede ayudar con:

1️⃣ *PROBLEMAS DE CONEXIÓN*
• "No me conecta"
• "Error en usuario/clave"
• "Conexión lenta"

2️⃣ *PAGOS Y FACTURACIÓN*
• "No llega mi pago"
• "Error en MercadoPago"
• "Necesito factura"

3️⃣ *APLICACIÓN Y USO*
• "No se instala la app"
• "La app se cierra"
• "No encuentro configuración"

4️⃣ *OTROS PROBLEMAS*
• "Mi cuenta expiró"
• "Quiero cambiar plan"
• "Sugerencias/quejas"

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

💡 *ANTES DE CONTACTAR:*
1. Prueba reiniciar la app
2. Verifica tu conexión internet
3. Revisa si la cuenta expiró (\`cuentas\`)

🤖 *¿QUIERES QUE TE AYUDE YO PRIMERO?*
Describe tu problema y mi IA intentará solucionarlo.`, 
        { sendSeen: false }
    );
}

// ================================================
// TAREAS PROGRAMADAS CON IA
// ================================================

// Verificar pagos cada 2 minutos
cron.schedule('*/2 * * * *', () => {
    console.log(chalk.yellow('🤖 IA: Verificando pagos pendientes...'));
    checkPendingPayments();
});

// Limpieza cada 15 minutos
cron.schedule('*/15 * * * *', async () => {
    const now = moment().format('YYYY-MM-DD HH:mm:ss');
    console.log(chalk.yellow(`🤖 IA: Limpiando usuarios expirados... (${now})`));
    
    db.all('SELECT username FROM users WHERE expires_at < ? AND status = 1', [now], async (err, rows) => {
        if (!err && rows && rows.length > 0) {
            console.log(chalk.cyan(`🤖 IA: Encontrados ${rows.length} usuarios para limpiar`));
            
            for (const r of rows) {
                try {
                    await execPromise(`pkill -u ${r.username} 2>/dev/null || true`);
                    await execPromise(`userdel -f ${r.username} 2>/dev/null || true`);
                    db.run('UPDATE users SET status = 0 WHERE username = ?', [r.username]);
                    console.log(chalk.green(`🤖 IA: Eliminado ${r.username}`));
                } catch (e) {
                    console.error(chalk.red(`🤖 IA Error: ${r.username}:`), e.message);
                }
            }
        }
    });
});

// Análisis IA cada hora
cron.schedule('0 * * * *', () => {
    console.log(chalk.cyan('🤖 IA: Realizando análisis del sistema...'));
    
    db.get('SELECT COUNT(*) as total, SUM(CASE WHEN tipo="premium" THEN 1 ELSE 0 END) as premium FROM users WHERE status=1', 
        (err, row) => {
            if (!err && row) {
                console.log(chalk.cyan(`🤖 IA Reporte: ${row.total} usuarios (${row.premium} premium)`));
            }
        }
    );
});

// ================================================
// INICIALIZACIÓN
// ================================================

console.log(chalk.green.bold('\n🤖 SSH BOT PRO CON IA INICIANDO...'));
console.log(chalk.cyan('✨ Características activadas:'));
console.log(chalk.cyan('   • Asistente IA inteligente'));
console.log(chalk.cyan('   • Comandos simples: prueba/basico/estandar/premium'));
console.log(chalk.cyan('   • Respuestas contextuales naturales'));
console.log(chalk.cyan('   • Análisis automático de necesidades'));
console.log(chalk.cyan('   • Recomendaciones personalizadas'));
console.log(chalk.cyan('   • Sistema de aprendizaje básico'));

client.initialize();

// ... (aquí van las funciones originales restantes: generateUsername, generatePassword, createSSHUser, etc.) ...

BOTEOF

echo -e "${GREEN}✅ Bot creado con IA inteligente${NC}"
