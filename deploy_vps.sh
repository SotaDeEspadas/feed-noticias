#!/bin/bash
set -e

echo "🚀 Iniciando despliegue HTTPS Seguro en Hostinger VPS para Feed Noticias..."

# 1. Actualizar e instalar dependencias del sistema
sudo apt update && sudo apt install -y python3-pip python3-venv git nginx certbot python3-certbot-nginx curl

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

# 6. Crear Servicio de Sistema (systemd) para Feed Noticias en puerto 8502
sudo cat << 'EOF' | sudo tee /etc/systemd/system/feed-noticias.service
[Unit]
Description=Streamlit Feed Noticias App
After=network.target

[Service]
User=root
WorkingDirectory=/var/www/feed-noticias
ExecStart=/var/www/feed-noticias/venv/bin/streamlit run /var/www/feed-noticias/frontend/app.py --server.port 8502 --server.address 0.0.0.0 --server.headless true
Restart=always
RestartSec=5
Environment="PYTHONPATH=/var/www/feed-noticias"

[Install]
WantedBy=multi-user.target
EOF

# 7. Recargar daemon y arrancar servicio systemd de Streamlit en puerto 8502
sudo systemctl daemon-reload
sudo systemctl enable feed-noticias
sudo systemctl restart feed-noticias

# 8. Liberar puertos 80 y 443 de Docker/Traefik para entregarlos a Nginx + Let's Encrypt
echo "🧹 Liberando puertos 80 y 443 para Nginx..."
sudo docker update --restart=no $(sudo docker ps -q) 2>/dev/null || true
sudo docker stop $(sudo docker ps -q) 2>/dev/null || true
sudo systemctl stop apache2 2>/dev/null || true
sudo systemctl stop caddy 2>/dev/null || true

DOMAIN="152.239.123.174.nip.io"

# 9. Configurar Nginx Reverse Proxy apuntando al puerto 8502
sudo cat << EOF | sudo tee /etc/nginx/sites-available/feed-noticias
server {
    listen 80;
    server_name $DOMAIN 152.239.123.174;

    location / {
        proxy_pass http://127.0.0.1:8502;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

sudo ln -sf /etc/nginx/sites-available/feed-noticias /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default

sudo nginx -t
sudo systemctl restart nginx

# 10. Emite el certificado SSL HTTPS oficial e indiscutible con Let's Encrypt
echo "🔒 Generando Certificado SSL HTTPS Oficial con Let's Encrypt..."
sudo certbot --nginx -d $DOMAIN --register-unsafely-without-email --non-interactive --agree-tos --redirect

echo "--------------------------------------------------------"
echo "✅ ¡DESPLIEGUE HTTPS SEGURO COMPLETADO CON ÉXITO!"
echo "🔒 TU URL SEGURO HTTPS 24/7 PARA TU EMPRESA ES:"
echo "👉 https://$DOMAIN"
echo "--------------------------------------------------------"
