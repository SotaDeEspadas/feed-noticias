#!/bin/bash
set -e

echo "🚀 Configurando Feed Noticias para Traefik nativo de Hostinger..."

# 1. Detener y deshabilitar Nginx del host para liberar los puertos 80 y 443 para Traefik
echo "🧹 Deteniendo Nginx local para entregar los puertos 80/443 a Traefik..."
sudo systemctl stop nginx 2>/dev/null || true
sudo systemctl disable nginx 2>/dev/null || true
sudo systemctl stop apache2 2>/dev/null || true
sudo systemctl disable apache2 2>/dev/null || true

# 2. Actualizar e instalar dependencias del sistema
sudo apt update && sudo apt install -y python3-pip python3-venv git curl

# 3. Crear directorio de la app
sudo mkdir -p /var/www/feed-noticias
sudo chown -R $USER:$USER /var/www/feed-noticias

# 4. Clonar repositorio o actualizarlo
if [ -d "/var/www/feed-noticias/.git" ]; then
    cd /var/www/feed-noticias && git pull origin main
else
    git clone https://github.com/SotaDeEspadas/feed-noticias.git /var/www/feed-noticias
    cd /var/www/feed-noticias
fi

# 5. Crear entorno virtual de Python e instalar librerías
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt

# 6. Configurar archivo de variables de entorno (.env)
cat << 'EOF' > /var/www/feed-noticias/.env
GEMINI_API_KEY=AIzaSyCZkuWaXN2Br2DOHQwKzMaUA4V7hgUqXhQ
EOF

# 7. Crear Servicio de Sistema (systemd) para Feed Noticias en puerto 8502
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

# 8. Recargar daemon y arrancar servicio systemd de Streamlit en puerto 8502
sudo systemctl daemon-reload
sudo systemctl enable feed-noticias
sudo systemctl restart feed-noticias

echo "--------------------------------------------------------"
echo "✅ ¡PUERTOS 80 Y 443 LIBERADOS CON ÉXITO PARA TRAEFIK!"
echo "👉 Ahora vuelve al panel de Hostinger y dale a Guardar en Traefik."
echo "--------------------------------------------------------"
