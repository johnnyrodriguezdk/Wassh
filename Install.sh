cat > /root/instalar_dtunnel.sh << 'EOF'
#!/bin/bash
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

ok()   { echo -e "${GREEN}[✓]${NC} $1"; }
info() { echo -e "${BLUE}[→]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
err()  { echo -e "${RED}[✗]${NC} $1"; exit 1; }

clear
echo ""
echo -e "${CYAN}============================================================${NC}"
echo -e "${WHITE}   DTunnelMod Panel - Instalador Automático${NC}"
echo -e "${WHITE}   Nginx + PHP 8.1 + SQLite + SSL${NC}"
echo -e "${CYAN}============================================================${NC}"
echo ""

# Verificar root
if [[ $EUID -ne 0 ]]; then
    err "Este script debe ejecutarse como root."
fi

# ============================================================
# CONFIGURACIÓN
# ============================================================
GITHUB_USER="johnnyrodriguezdk"
GITHUB_REPO="pserve"
GITHUB_BRANCH="main"
ZIP_NAME="pannel.zip"
GITHUB_ZIP_URL="https://raw.githubusercontent.com/$GITHUB_USER/$GITHUB_REPO/$GITHUB_BRANCH/$ZIP_NAME"

WEBROOT="/var/www/html"

# Datos
read -p "$(echo -e ${YELLOW}Dominio \$ej: mipanel.com\$ o Enter para usar solo IP: ${NC})" DOMINIO
read -p "$(echo -e ${YELLOW}Email para SSL/Let\'s Encrypt: ${NC})" EMAIL

# ============================================================
# PASO 1 - Dependencias
# ============================================================
echo ""
echo -e "${CYAN}============================================================${NC}"
echo -e "${WHITE} Paso 1: Instalando dependencias...${NC}"
echo -e "${CYAN}============================================================${NC}"
echo ""

info "Actualizando repositorios..."
apt update -qq

info "Instalando paquetes necesarios..."
apt install -y \
    nginx \
    php8.1-fpm \
    php8.1-sqlite3 \
    php8.1-curl \
    php8.1-mbstring \
    php8.1-xml \
    php8.1-zip \
    php8.1-pdo \
    unzip \
    sqlite3 \
    wget \
    curl \
    certbot \
    python3-certbot-nginx > /dev/null 2>&1

ok "Todas las dependencias instaladas"

# ============================================================
# PASO 2 - Descargar ZIP desde GitHub
# ============================================================
echo ""
echo -e "${CYAN}============================================================${NC}"
echo -e "${WHITE} Paso 2: Descargando pannel.zip desde GitHub...${NC}"
echo -e "${CYAN}============================================================${NC}"
echo ""

info "URL: $GITHUB_ZIP_URL"
info "Descargando pannel.zip..."

wget -q --show-progress -O /tmp/pannel.zip "$GITHUB_ZIP_URL"

if [ $? -ne 0 ]; then
    err "No se pudo descargar pannel.zip desde GitHub."
fi

# Verificar que el ZIP no esté vacío o corrupto
ZIP_SIZE=$(stat -c%s /tmp/pannel.zip)
if [ "$ZIP_SIZE" -lt 1000 ]; then
    err "El archivo descargado parece estar corrupto o vacío (${ZIP_SIZE} bytes)"
fi

ok "pannel.zip descargado correctamente (${ZIP_SIZE} bytes)"

# Limpiar directorio web
info "Limpiando directorio web..."
rm -rf "$WEBROOT"/*

# Descomprimir
info "Descomprimiendo archivos..."
mkdir -p /tmp/dtunnel_extract
unzip -o /tmp/pannel.zip -d /tmp/dtunnel_extract/ > /dev/null 2>&1

if [ $? -ne 0 ]; then
    err "Error al descomprimir pannel.zip"
fi

# Detectar subcarpeta
SUBDIR_COUNT=$(ls /tmp/dtunnel_extract/ | wc -l)
EXTRACTED=$(ls /tmp/dtunnel_extract/ | head -1)

if [ "$SUBDIR_COUNT" -eq 1 ] && [ -d "/tmp/dtunnel_extract/$EXTRACTED" ]; then
    info "Detectada subcarpeta: $EXTRACTED"
    cp -r /tmp/dtunnel_extract/$EXTRACTED/* "$WEBROOT/"
    cp -r /tmp/dtunnel_extract/$EXTRACTED/.[!.]* "$WEBROOT/" 2>/dev/null || true
else
    cp -r /tmp/dtunnel_extract/* "$WEBROOT/"
    cp -r /tmp/dtunnel_extract/.[!.]* "$WEBROOT/" 2>/dev/null || true
fi

# Limpiar temporales
rm -rf /tmp/dtunnel_extract /tmp/pannel.zip
ok "Archivos instalados en $WEBROOT"

# Verificar archivos críticos
info "Verificando archivos críticos..."
CRITICAL=("index.php" "db.php" "auth.php")
for FILE in "${CRITICAL[@]}"; do
    if [ -f "$WEBROOT/$FILE" ]; then
        ok "  $FILE encontrado"
    else
        warn "  $FILE NO encontrado"
    fi
done

# Copiar register como registro
if [ -f "$WEBROOT/pages/register.php" ]; then
    cp "$WEBROOT/pages/register.php" "$WEBROOT/pages/registro.php"
    ok "Página de registro duplicada como registro.php"
fi

# Crear directorios necesarios
info "Creando directorios necesarios..."
mkdir -p "$WEBROOT/database"
mkdir -p "$WEBROOT/db"
ok "Directorios creados"

# ============================================================
# PASO 3 - Permisos
# ============================================================
echo ""
echo -e "${CYAN}============================================================${NC}"
echo -e "${WHITE} Paso 3: Configurando permisos...${NC}"
echo -e "${CYAN}============================================================${NC}"
echo ""

chown -R www-data:www-data "$WEBROOT"
find "$WEBROOT" -type f -exec chmod 644 {} \;
find "$WEBROOT" -type d -exec chmod 755 {} \;
chmod 775 "$WEBROOT/database"
chmod 775 "$WEBROOT/db"
chown -R www-data:www-data "$WEBROOT/database"
chown -R www-data:www-data "$WEBROOT/db"

ok "Permisos configurados correctamente"

# ============================================================
# PASO 4 - PHP-FPM
# ============================================================
echo ""
echo -e "${CYAN}============================================================${NC}"
echo -e "${WHITE} Paso 4: Configurando PHP 8.1-FPM...${NC}"
echo -e "${CYAN}============================================================${NC}"
echo ""

systemctl enable php8.1-fpm > /dev/null 2>&1
systemctl restart php8.1-fpm

if systemctl is-active --quiet php8.1-fpm; then
    ok "PHP 8.1-FPM activo y corriendo"
else
    err "PHP 8.1-FPM no pudo iniciarse"
fi

info "Verificando extensiones PHP..."
EXTENSIONS=("pdo_sqlite" "sqlite3" "curl" "mbstring" "zip")
for EXT in "${EXTENSIONS[@]}"; do
    if php -m | grep -qi "$EXT"; then
        ok "  Extensión $EXT: habilitada"
    else
        warn "  Extensión $EXT: NO encontrada"
    fi
done

# ============================================================
# PASO 5 - Nginx
# ============================================================
echo ""
echo -e "${CYAN}============================================================${NC}"
echo -e "${WHITE} Paso 5: Configurando Nginx...${NC}"
echo -e "${CYAN}============================================================${NC}"
echo ""

[ -n "$DOMINIO" ] && SN="$DOMINIO www.$DOMINIO" || SN="_"

cat > /etc/nginx/sites-available/dtunnel << NGINX
server {
    listen 80;
    server_name $SN;
    root $WEBROOT;
    index index.php;

    access_log /var/log/nginx/dtunnel_access.log;
    error_log  /var/log/nginx/dtunnel_error.log;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php8.1-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
        fastcgi_read_timeout 300;
    }

    location ~ ^/(pages|includes|database|db)/ {
        deny all;
        return 403;
    }

    location ~ /\. {
        deny all;
        return 403;
    }

    location ~* \.(css|js|png|jpg|jpeg|gif|svg|ico|woff|woff2)\$ {
        expires 30d;
        add_header Cache-Control "public, no-transform";
    }
}
NGINX

ln -sf /etc/nginx/sites-available/dtunnel /etc/nginx/sites-enabled/dtunnel
rm -f /etc/nginx/sites-enabled/default

nginx -t > /dev/null 2>&1 && ok "Configuración de Nginx válida" || err "Error en Nginx"
systemctl enable nginx > /dev/null 2>&1
systemctl restart nginx

if systemctl is-active --quiet nginx; then
    ok "Nginx activo y corriendo"
else
    err "Nginx no pudo iniciarse"
fi

# ============================================================
# PASO 6 - SSL
# ============================================================
echo ""
echo -e "${CYAN}============================================================${NC}"
echo -e "${WHITE} Paso 6: Configurando SSL...${NC}"
echo -e "${CYAN}============================================================${NC}"
echo ""

if [ -n "$DOMINIO" ] && [ -n "$EMAIL" ]; then
    info "Obteniendo certificado SSL para $DOMINIO..."
    certbot --nginx \
        -d "$DOMINIO" \
        -d "www.$DOMINIO" \
        --non-interactive \
        --agree-tos \
        -m "$EMAIL" > /dev/null 2>&1

    if [ $? -eq 0 ]; then
        ok "SSL instalado correctamente"
        systemctl restart nginx
    else
        warn "SSL falló - intentalo después con: certbot --nginx -d $DOMINIO"
    fi
else
    warn "Sin dominio o email - SSL omitido"
fi

# ============================================================
# PASO 7 - Correcciones
# ============================================================
echo ""
echo -e "${CYAN}============================================================${NC}"
echo -e "${WHITE} Paso 7: Aplicando correcciones...${NC}"
echo -e "${CYAN}============================================================${NC}"
echo ""

if [ -f "$WEBROOT/pages/login.php" ]; then
    php -r "
        \$f = '$WEBROOT/pages/login.php';
        \$c = file_get_contents(\$f);
        \$c = preg_replace(
            '/if\s*\$!empty\$\\\$_POST\$.contact_email_hp.\$\$\$/',
            'if (false)',
            \$c
        );
        file_put_contents(\$f, \$c);
    " 2>/dev/null && ok "Honeypot desactivado" || warn "Honeypot: no se pudo desactivar"
else
    warn "login.php no encontrado"
fi

[ -f "$WEBROOT/index.php" ] && ok "index.php encontrado"    || warn "index.php NO encontrado"
[ -d "$WEBROOT/database" ] && ok "Directorio database listo"
[ -d "$WEBROOT/db" ]       && ok "Directorio db listo"

# ============================================================
# PASO 8 - Verificación
# ============================================================
echo ""
echo -e "${CYAN}============================================================${NC}"
echo -e "${WHITE} Paso 8: Verificación final...${NC}"
echo -e "${CYAN}============================================================${NC}"
echo ""

[ -n "$DOMINIO" ] && BASE="https://$DOMINIO" || BASE="http://$(hostname -I | awk '{print $1}')"

HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$BASE" 2>/dev/null || echo "000")

if [[ "$HTTP_CODE" == "200" || "$HTTP_CODE" == "302" || "$HTTP_CODE" == "301" ]]; then
    ok "Panel responde correctamente (HTTP $HTTP_CODE)"
else
    warn "Panel responde con HTTP $HTTP_CODE"
fi

# ============================================================
# RESUMEN FINAL
# ============================================================
echo ""
echo -e "${CYAN}============================================================${NC}"
echo -e "${GREEN}   ✅ INSTALACIÓN COMPLETA${NC}"
echo -e "${CYAN}============================================================${NC}"
echo ""
echo -e "  ${WHITE}📌 ZIP descargado desde:${NC}"
echo -e "  ${GREEN}$GITHUB_ZIP_URL${NC}"
echo ""
echo -e "  ${WHITE}📌 Accesos:${NC}"
echo -e "  Panel:     ${GREEN}$BASE${NC}"
echo -e "  Registro:  ${GREEN}$BASE/register${NC}"
echo -e "  Login:     ${GREEN}$BASE/login${NC}"
echo ""
echo -e "  ${WHITE}📌 API Pública:${NC}"
echo -e "  Config:    ${GREEN}$BASE/api/dtunnel.php?token=TOKEN&action=config${NC}"
echo -e "  Textos:    ${GREEN}$BASE/api/dtunnel.php?token=TOKEN&action=text${NC}"
echo -e "  Versión:   ${GREEN}$BASE/api/dtunnel.php?action=version${NC}"
echo ""
echo -e "${CYAN}============================================================${NC}"
echo -e "${YELLOW}  📋 PASOS DESPUÉS DE INSTALAR:${NC}"
echo -e "${CYAN}============================================================${NC}"
echo ""
echo -e "  ${GREEN}1.${NC} Creá tu cuenta en: ${YELLOW}$BASE/register${NC}"
echo ""
echo -e "  ${GREEN}2.${NC} Ejecutá este comando para hacerte ADMIN:"
echo ""
echo -e "  ${WHITE}php -r '\$f=\"$WEBROOT/db/usuarios.json\";\$u=json_decode(file_get_contents(\$f),true);\$u[0][\"expires_at\"]=\"2099-12-31 00:00:00\";\$u[0][\"role\"]=\"admin\";file_put_contents(\$f,json_encode(\$u,JSON_PRETTY_PRINT));echo \"Listo!\n\";'${NC}"
echo ""
echo -e "  ${GREEN}3.${NC} Cerrá sesión y volvé a loguearte"
echo ""
echo -e "  ${GREEN}4.${NC} Si hay error fatal ejecutá:"
echo -e "     ${YELLOW}apt install -y php8.1-zip && systemctl restart php8.1-fpm${NC}"
echo ""
echo -e "  ${WHITE}📌 Logs:${NC}"
echo -e "  Error:  /var/log/nginx/dtunnel_error.log"
echo -e "  Acceso: /var/log/nginx/dtunnel_access.log"
echo ""
echo -e "${CYAN}============================================================${NC}"
echo -e "${WHITE}  DTunnelMod Panel - Instalado correctamente 🚀${NC}"
echo -e "${CYAN}============================================================${NC}"
echo ""

EOF

chmod +x /root/instalar_dtunnel.sh
bash /root/instalar_dtunnel.sh
