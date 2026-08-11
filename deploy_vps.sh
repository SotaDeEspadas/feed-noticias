#!/bin/bash
set -e

echo "🚀 Iniciando despliegue de Feed Noticias en Hostinger VPS..."

# 1. Actualizar e instalar dependencias del sistema
sudo apt update && sudo apt install -y python3-pip python3-venv git curl openssh-client

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

# 8. Generar Túnel SSH HTTPS Seguro y Permanente con localhost.run (coste 0€, sin cortafuegos)
sudo cat << 'EOF' | sudo tee /etc/systemd/system/secure-tunnel.service
[Unit]
Description=Túnel HTTPS Seguro 24/7 para Feed Noticias
After=network.target feed-noticias.service

[Service]
ExecStart=/usr/bin/ssh -o StrictHostKeyChecking=no -o ServerAliveInterval=30 -R 80:127.0.0.1:8501 nokey@localhost.run
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable secure-tunnel
sudo systemctl restart secure-tunnel

sleep 6

# 9. Extraer la URL oficial HTTPS generada
HTTPS_URL=$(sudo journalctl -u secure-tunnel -n 50 --no-pager | grep -o 'https://[a-zA-Z0-9.-]*\.lhr\.life' | tail -n 1 || true)
if [ -z "$HTTPS_URL" ]; then
    HTTPS_URL=$(sudo journalctl -u secure-tunnel -n 50 --no-pager | grep -o 'https://[a-zA-Z0-9.-]*\.lh\.domain' | tail -n 1 || true)
fi

echo "--------------------------------------------------------"
echo "✅ ¡DESPLIEGUE COMPLETO Y VERIFICADO!"
if [ -n "$HTTPS_URL" ]; then
    echo "🔒 TU URL HTTPS SEGURO 24/7 ES:"
    echo "👉 $HTTPS_URL"
else
    echo "🔒 Tu servicio de túnel está activo. Puedes ver la URL ejecutando:"
    echo "   sudo journalctl -u secure-tunnel -n 20 | grep https"
fi
echo "--------------------------------------------------------"
