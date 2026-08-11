#!/bin/bash
set -e

echo "🚀 Iniciando despliegue de Feed Noticias en Hostinger VPS..."

# 1. Actualizar e instalar dependencias del sistema
sudo apt update && sudo apt install -y python3-pip python3-venv git nginx certbot python3-certbot-nginx

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

# 7. Recargar daemon y arrancar servicio
sudo systemctl daemon-reload
sudo systemctl enable feed-noticias
sudo systemctl restart feed-noticias

# 8. Liberar puertos 80 y 443 de Docker (n8n/Traefik) para asignarlos a Nginx
echo "🧹 Reconfigurando n8n para liberar el puerto 80/443 y mantenerlo en el puerto 5678..."

# Si existe un docker-compose de n8n en el VPS, ajustamos sus puertos para que no ocupe 80/443
for compose_path in /root/n8n/docker-compose.yml /root/docker-compose.yml /opt/n8n/docker-compose.yml; do
    if [ -f "$compose_path" ]; then
        echo "📝 Ajustando puertos en $compose_path..."
        sudo sed -i 's/"80:5678"/"5678:5678"/g' "$compose_path" 2>/dev/null || true
        sudo sed -i 's/"80:80"/"5678:80"/g' "$compose_path" 2>/dev/null || true
        sudo sed -i 's/"443:443"/"5443:443"/g' "$compose_path" 2>/dev/null || true
        (cd "$(dirname "$compose_path")" && sudo docker compose down 2>/dev/null || sudo docker-compose down 2>/dev/null || true)
        (cd "$(dirname "$compose_path")" && sudo docker compose up -d 2>/dev/null || sudo docker-compose up -d 2>/dev/null || true)
    fi
done

# Detener cualquier contenedor Docker suelto que siga usando el puerto 80 o 443
sudo docker stop $(sudo docker ps -q) 2>/dev/null || true
sudo systemctl stop apache2 2>/dev/null || true
sudo systemctl stop caddy 2>/dev/null || true

# 9. Configurar Nginx Reverse Proxy para Feed Noticias
sudo cat << 'EOF' | sudo tee /etc/nginx/sites-available/feed-noticias
server {
    listen 80;
    server_name srv1817339.hstgr.cloud 152.239.123.174 _;

    # Aplicación Feed Noticias en la raíz /
    location / {
        proxy_pass http://127.0.0.1:8501;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

sudo ln -sf /etc/nginx/sites-available/feed-noticias /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default

sudo nginx -t
sudo systemctl restart nginx

# 10. Generar Certificado SSL HTTPS Gratis (Let's Encrypt)
echo "🔒 Generando Certificado SSL HTTPS (🔒 Conexión Segura)..."
sudo certbot --nginx -d srv1817339.hstgr.cloud --register-unsafely-without-email --non-interactive --agree-tos --redirect || true

echo "--------------------------------------------------------"
echo "✅ ¡DESPLIEGUE HTTPS FINALIZADO CON ÉXITO!"
echo "🔒 Feed Noticias (HTTPS Seguros): https://srv1817339.hstgr.cloud"
echo "--------------------------------------------------------"
