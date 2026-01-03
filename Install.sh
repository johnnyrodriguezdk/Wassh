#!/bin/bash

CONF="/opt/wassh/config/bot.json"
BOT_DIR="/opt/wassh/bot"
LOG="/var/log/wassh.log"
SESSION_DIR="/opt/wassh/session"

check_root() {
  if [[ $EUID -eq 0 ]]; then
    echo "⚠️  No se recomienda ejecutar como root. Usa sudo solo cuando sea necesario."
  fi
}

start_bot() {
  echo "🤖 Iniciando bot WhatsApp..."
  pkill -f "node.*index.js" 2>/dev/null || true
  cd "$BOT_DIR"
  nohup node index.js >> "$LOG" 2>&1 &
  sleep 3
  echo "✅ Bot iniciado en segundo plano"
  echo "📋 Ver logs: tail -f $LOG"
  echo "📱 Si no ves el QR, revisa los logs arriba"
}

stop_bot() {
  echo "🛑 Deteniendo bot..."
  pkill -f "node.*index.js" 2>/dev/null || true
  sleep 2
  echo "✅ Bot detenido"
}

view_logs() {
  echo "📋 Últimas 50 líneas del log:"
  echo "------------------------------"
  tail -n 50 "$LOG"
  echo "------------------------------"
  echo "Ver en tiempo real: tail -f $LOG"
}

config_whatsapp() {
  echo "📱 CONFIGURAR WHATSAPP"
  echo "----------------------"
  current=$(jq -r '.whatsapp // empty' "$CONF" 2>/dev/null || echo "")
  if [[ -n "$current" ]]; then
    echo "Número actual: $current"
  fi
  read -p "Número WhatsApp (54911xxxxxxxx): " num
  if [[ -z "$num" ]]; then
    echo "⚠️  No se modificó"
    return
  fi
  if ! jq ".whatsapp=\"$num\"" "$CONF" > "/tmp/bot.json.tmp"; then
    echo "❌ Error actualizando configuración"
    return
  fi
  mv "/tmp/bot.json.tmp" "$CONF"
  echo "✅ Número guardado: $num"
}

config_mercadopago() {
  echo "💰 CONFIGURAR MERCADO PAGO"
  echo "--------------------------"
  current_token=$(jq -r '.mp.access_token // empty' "$CONF" 2>/dev/null || echo "")
  if [[ -n "$current_token" ]]; then
    echo "Token actual: ${current_token:0:20}..."
  fi
  
  read -p "Access Token MP: " token
  read -p "Precio TEST (ej: 100): " test
  read -p "Precio MES (ej: 1000): " mes
  
  # Validar números
  if ! [[ "$test" =~ ^[0-9]+$ ]]; then
    echo "❌ Precio TEST debe ser número"
    return
  fi
  if ! [[ "$mes" =~ ^[0-9]+$ ]]; then
    echo "❌ Precio MES debe ser número"
    return
  fi
  
  if jq ".mp.access_token=\"$token\" | .mp.price_test=$test | .mp.price_month=$mes" "$CONF" > "/tmp/bot.json.tmp"; then
    mv "/tmp/bot.json.tmp" "$CONF"
    echo "✅ MercadoPago configurado"
    echo "   Token: ${token:0:20}..."
    echo "   TEST: \$$test"
    echo "   MES: \$$mes"
  else
    echo "❌ Error guardando configuración"
  fi
}

view_config() {
  echo "⚙️  CONFIGURACIÓN ACTUAL"
  echo "-----------------------"
  if [[ -f "$CONF" ]]; then
    jq . "$CONF"
  else
    echo "❌ Archivo de configuración no encontrado"
  fi
}

show_pairing_code() {
  echo "🔢 GENERAR CÓDIGO PAIRING"
  echo "-------------------------"
  
  # Verificar si el bot está corriendo
  if pgrep -f "node.*index.js" > /dev/null; then
    echo "❌ El bot está en ejecución. Detenlo primero para generar código pairing."
    read -p "¿Detener bot ahora? (s/n): " stop_choice
    if [[ "$stop_choice" == "s" || "$stop_choice" == "S" ]]; then
      stop_bot
      sleep 2
    else
      echo "Operación cancelada"
      return
    fi
  fi
  
  # Verificar número configurado
  whatsapp_number=$(jq -r '.whatsapp // empty' "$CONF" 2>/dev/null)
  if [[ -z "$whatsapp_number" ]]; then
    echo "❌ No hay número WhatsApp configurado"
    read -p "¿Configurar número ahora? (s/n): " config_choice
    if [[ "$config_choice" == "s" || "$config_choice" == "S" ]]; then
      config_whatsapp
      whatsapp_number=$(jq -r '.whatsapp // empty' "$CONF" 2>/dev/null)
    else
      echo "❌ Necesitas configurar un número primero"
      return
    fi
  fi
  
  echo "📱 Número configurado: $whatsapp_number"
  echo ""
  echo "⚠️  IMPORTANTE:"
  echo "1. Tu teléfono debe tener conexión a internet"
  echo "2. El número debe estar en WhatsApp"
  echo "3. Debes poder recibir notificaciones"
  echo ""
  read -p "¿Generar código pairing ahora? (s/n): " confirm
  
  if [[ "$confirm" != "s" && "$confirm" != "S" ]]; then
    echo "Operación cancelada"
    return
  fi
  
  # Crear script temporal para generar código
  cat > /tmp/generate_pairing.js << 'EOF'
import fs from 'fs';
import { makeWASocket } from '@whiskeysockets/baileys';
import * as baileys from '@whiskeysockets/baileys';

const CONF = '/opt/wassh/config/bot.json';
const config = JSON.parse(fs.readFileSync(CONF, 'utf8'));

async function generatePairingCode() {
  try {
    console.log('🔗 Conectando con WhatsApp...');
    
    // Usar una sesión temporal
    const sock = makeWASocket({
      auth: {
        creds: {
          noiseKey: { private: new Uint8Array(32), public: new Uint8Array(32) },
          signedIdentityKey: { private: new Uint8Array(32), public: new Uint8Array(32) },
          signedPreKey: { keyPair: { private: new Uint8Array(32), public: new Uint8Array(32) } },
          registrationId: 0,
          advSecretKey: new Uint8Array(32).toString('base64')
        },
        keys: {}
      },
      printQRInTerminal: false,
      browser: ['WASSH', 'Chrome', '1.0']
    });

    const phone = config.whatsapp.replace(/\D/g, '');
    console.log(`📞 Solicitando código para: ${phone}`);
    
    // Solicitar código de vinculación
    const code = await sock.requestPairingCode(phone);
    
    console.log('\n' + '='.repeat(50));
    console.log('✅ CÓDIGO PAIRING GENERADO');
    console.log('='.repeat(50));
    console.log('');
    console.log('📱 CÓDIGO: ' + code);
    console.log('');
    console.log('='.repeat(50));
    console.log('INSTRUCCIONES:');
    console.log('1. Abre WhatsApp en tu teléfono');
    console.log('2. Ve a Ajustes > Dispositivos vinculados');
    console.log('3. Toca "Vincular un dispositivo"');
    console.log('4. Elige "Vincular con código de vinculación"');
    console.log('5. Ingresa este código: ' + code);
    console.log('='.repeat(50));
    
    // Guardar código en archivo temporal por si acaso
    fs.writeFileSync('/tmp/wassh_pairing_code.txt', `Código: ${code}\nGenerado: ${new Date().toLocaleString()}\nPara: ${phone}`);
    console.log('\n📄 Código también guardado en: /tmp/wassh_pairing_code.txt');
    
    sock.end(null);
    
  } catch (error) {
    console.error('❌ Error generando código:', error.message);
    console.log('\nPOSIBLES SOLUCIONES:');
    console.log('1. Verifica que el número esté correcto (54911...)');
    console.log('2. Asegúrate de tener internet en el teléfono');
    console.log('3. Intenta de nuevo en 1 minuto');
    console.log('4. Prueba usando el código QR en su lugar');
    
    if (error.message.includes('not registered')) {
      console.log('\n⚠️  El número no está registrado en WhatsApp');
    }
    if (error.message.includes('timeout')) {
      console.log('\n⚠️  Tiempo de espera agotado. Revisa tu conexión');
    }
  }
}

generatePairingCode().finally(() => {
  setTimeout(() => process.exit(0), 3000);
});
EOF

  echo "⏳ Generando código pairing..."
  echo ""
  
  # Ejecutar el script
  cd "$BOT_DIR"
  node /tmp/generate_pairing.js
  
  echo ""
  read -p "¿Deseas iniciar el bot ahora? (s/n): " start_now
  if [[ "$start_now" == "s" || "$start_now" == "S" ]]; then
    start_bot
  else
    echo "✅ Código generado. Puedes iniciar el bot luego desde el menú."
  fi
  
  # Limpiar archivo temporal
  rm -f /tmp/generate_pairing.js
}

reset_session() {
  echo "🔄 RESET DE SESIÓN"
  echo "-----------------"
  echo "Esto eliminará la sesión actual y necesitarás"
  echo "escanean el QR o código pairing nuevamente."
  echo ""
  read -p "¿Estás seguro? (s/n): " confirm
  
  if [[ "$confirm" == "s" || "$confirm" == "S" ]]; then
    stop_bot
    echo "🗑️  Eliminando sesión..."
    rm -rf "$SESSION_DIR"/* 2>/dev/null
    rm -rf "$SESSION_DIR"/.[!.]* 2>/dev/null
    echo "✅ Sesión eliminada"
    echo ""
    read -p "¿Iniciar bot ahora para nuevo QR? (s/n): " start_now
    if [[ "$start_now" == "s" || "$start_now" == "S" ]]; then
      start_bot
    fi
  else
    echo "❌ Operación cancelada"
  fi
}

menu() {
  while true; do
    clear
    echo "=================================="
    echo "        WASSH MANAGER v1.1"
    echo "=================================="
    echo
    
    # Mostrar estado del bot
    if pgrep -f "node.*index.js" > /dev/null; then
      echo "🔵 Estado: BOT EN EJECUCIÓN"
    else
      echo "🔴 Estado: BOT DETENIDO"
    fi
    
    # Mostrar número configurado (si existe)
    if [[ -f "$CONF" ]]; then
      whatsapp_number=$(jq -r '.whatsapp // empty' "$CONF" 2>/dev/null)
      if [[ -n "$whatsapp_number" ]]; then
        echo "📱 Número: $whatsapp_number"
      else
        echo "📱 Número: No configurado"
      fi
    fi
    
    echo ""
    echo "MENÚ PRINCIPAL:"
    echo "1) 🚀 Iniciar bot (Mostrar QR)"
    echo "2) 🛑 Detener bot"
    echo "3) 🔢 Generar código pairing"
    echo "4) 📱 Configurar WhatsApp"
    echo "5) 💰 Configurar MercadoPago"
    echo "6) 📋 Ver logs"
    echo "7) ⚙️  Ver configuración"
    echo "8) 🔄 Reiniciar bot"
    echo "9) 🗑️  Reset sesión (Nuevo QR)"
    echo "0) ❌ Salir"
    echo
    read -p "Selecciona una opción [0-9]: " op

    case $op in
      1) start_bot ;;
      2) stop_bot ;;
      3) show_pairing_code ;;
      4) config_whatsapp ;;
      5) config_mercadopago ;;
      6) view_logs ;;
      7) view_config ;;
      8) 
        stop_bot
        sleep 2
        start_bot
        ;;
      9) reset_session ;;
      0) 
        echo "👋 ¡Hasta luego!"
        exit 0
        ;;
      *) 
        echo "❌ Opción inválida"
        ;;
    esac
    
    if [[ "$op" != "0" ]]; then
      echo
      read -p "Presiona ENTER para volver al menú..."
    fi
  done
}

# Manejo de argumentos
case "$1" in
  "start")
    start_bot
    ;;
  "stop")
    stop_bot
    ;;
  "restart")
    stop_bot
    sleep 2
    start_bot
    ;;
  "logs")
    view_logs
    ;;
  "pairing")
    show_pairing_code
    ;;
  "config")
    view_config
    ;;
  "reset")
    reset_session
    ;;
  "")
    check_root
    menu
    ;;
  *)
    echo "Uso: wassh [comando]"
    echo "Comandos disponibles:"
    echo "  start     - Iniciar bot"
    echo "  stop      - Detener bot"
    echo "  restart   - Reiniciar bot"
    echo "  logs      - Ver logs"
    echo "  pairing   - Generar código pairing"
    echo "  config    - Ver configuración"
    echo "  reset     - Resetear sesión"
    echo "  (sin comando) - Menú interactivo"
    exit 1
    ;;
esac
