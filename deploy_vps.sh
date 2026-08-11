#!/bin/bash
set -e

echo "🚀 Iniciando despliegue de Feed Noticias en Hostinger VPS con HTTPS Seguro Cloudflare..."

# 1. Actualizar e instalar dependencias del sistema
sudo apt update && sudo apt install -y python3-pip python3-venv git curl

# 2. Crear directorio de la app
sudo mkdir -p /var/www/feed-noticias
sudo chown -R $USER:$USER /var/www/feed-noticias

# 3. Clonar repositorio o actualizarlo
if [ -d "/var/www/feed-noticias/.git" ]; then
    cd /var/www/feed-noticias && git pull origin main
else
    git clone https://github.com/SotaDeEspadas/feed-noticias.git /var/www/feed-noticias
    cd /var/www/feed-noticias
fi

# 4. Crear entorno virtual de Python e instalar librerías
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt

# 5. Configurar archivo de variables de entorno (.env)
cat << 'EOF' > /var/www/feed-noticias/.env
GEMINI_API_KEY=AIzaSyCZkuWaXN2Br2DOHQwKzMaUA4V7hgUqXhQ
EOF

# 6. Crear Servicio de Sistema (systemd) para que Streamlit ejecute 24/7
sudo cat << 'EOF' | sudo tee /etc/systemd/system/feed-noticias.service
[Unit]
Description=Streamlit Feed Noticias App
After=network.target

[Service]
User=root
WorkingDirectory=/var/www/feed-noticias
ExecStart=/var/www/feed-noticias/venv/bin/streamlit run /var/www/feed-noticias/frontend/app.py --server.port 8501 --server.address 0.0.0.0 --server.headless true
Restart=always
RestartSec=5
Environment="PYTHONPATH=/var/www/feed-noticias"

[Install]
WantedBy=multi-user.target
EOF

# 7. Recargar daemon y arrancar servicio systemd de Streamlit
sudo systemctl daemon-reload
sudo systemctl enable feed-noticias
sudo systemctl restart feed-noticias

# 8. Instalar Cloudflare Tunnel (cloudflared) para ofrecer HTTPS 100% oficial y seguro sin conflictos
if ! command -v cloudflared &> /dev/null; then
    echo "📦 Instalando Cloudflare Tunnel para HTTPS 100% Oficial..."
    curl -L --output /tmp/cloudflared.deb https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
    sudo dpkg -i /tmp/cloudflared.deb || sudo apt-get install -f -y
    rm -f /tmp/cloudflared.deb
fi

CLOUDFLARED_PATH=$(which cloudflared || echo "/usr/bin/cloudflared")

# 9. Crear servicio de túnel seguro 24/7 con Cloudflare (forzando TCP/http2 para evitar bloqueos UDP de firewall)
sudo cat << EOF | sudo tee /etc/systemd/system/cloudflared-tunnel.service
[Unit]
Description=Cloudflare Tunnel HTTPS 24/7 para Feed Noticias
After=network.target feed-noticias.service

[Service]
ExecStart=${CLOUDFLARED_PATH} tunnel --protocol http2 --url http://127.0.0.1:8501 --no-autoupdate
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable cloudflared-tunnel
sudo systemctl restart cloudflared-tunnel

sleep 5

# 10. Extraer la URL oficial HTTPS generada con candado SSL verificado
HTTPS_URL=$(sudo journalctl -u cloudflared-tunnel -n 100 --no-pager | grep -o 'https://[-a-zA-Z0-9]*\.trycloudflare\.com' | tail -n 1 || true)

echo "--------------------------------------------------------"
echo "✅ ¡DESPLIEGUE HTTPS 100% SEGURO COMPLETADO!"
if [ -n "$HTTPS_URL" ]; then
    echo "🔒 TU URL HTTPS OFICIAL (CANDADO SEGURO 24/7):"
    echo "👉 $HTTPS_URL"
else
    echo "🔒 Tu túnel Cloudflare está activo. Puedes ver la URL HTTPS ejecutando:"
    echo "   sudo journalctl -u cloudflared-tunnel -n 30 | grep trycloudflare"
fi
echo "--------------------------------------------------------"
