# ⚡ Terminal Financiero & Feed de Noticias

> **Plataforma de Inteligencia de Mercado en Tiempo Real para Banca Privada y Asesoría Patrimonial**

[![Streamlit App](https://static.streamlit.io/badges/streamlit_badge_black_white.svg)](https://feed-noticias-ydjjjqwwgwjiywmadsru8j.streamlit.app/)
[![Licencia](https://img.shields.io/badge/Licencia-MIT-blue.svg)](LICENSE)
[![Python](https://img.shields.io/badge/Python-3.11+-brightgreen.svg)](https://www.python.org/)

🌐 **Aplicación en Vivo (Producción)**: [https://feed-noticias-ydjjjqwwgwjiywmadsru8j.streamlit.app/](https://feed-noticias-ydjjjqwwgwjiywmadsru8j.streamlit.app/)

---

## 📌 Visión General

El **Terminal Financiero & Feed de Noticias** es una solución de inteligencia automatizada diseñada para monitorear, categorizar y enriquecer noticias y publicaciones clave de los principales portales del sector financiero e inversión alternativa:

- 📰 **Funds Society**
- 📰 **Funds People**
- ⚡ **FundsPeople (Alterforum - Fondos Alternativos)**
- 🌐 **EFPA España**
- 🌐 **Citywire**

La plataforma integra inteligencia artificial generativa (**Google Gemini AI**) para categorizar noticias, asignar el tono de mercado (*Oportunidad*, *Neutro*, *Alerta Regulatoria*), responder consultas complejas en lenguaje natural (*Chat RAG sobre el Feed*) y redactar informes ejecutivos diarios (*Digest Diario*).

---

## 🔥 Funcionalidades Clave

1. **Scraping Real en Vivo**: Extracción directa y continua de titulares y enlaces reales publicadas en tiempo real.
2. **Especial Fondos Alternativos**: Módulo de alta visibilidad para seguimiento de *Private Equity*, *Venture Capital*, *Family Office* y activos no cotizados.
3. **🤖 Pregunta a tu Feed (Chat RAG)**: Asistente virtual impulsado por Gemini AI que analiza todas las noticias capturadas del día para responder preguntas sobre la actualidad de mercados, regulaciones (como la Directiva RIS) o movimientos de la banca privada.
4. **📝 Generador de Digest Diario**: Compilación instantánea de resúmenes ejecutivos diarios descargables en formato `.md` para compartir con equipos y clientes.
5. **⭐ Mis Favoritos**: Guardado persistente de noticias clave en base de datos SQLite para lectura posterior.
6. **🎨 Interfaz Dark Executive Glassmorphism**: Diseño oscuro de alto contraste optimizado para entornos profesionales.

---

## 🛠️ Arquitectura Técnica

```text
Feed noticias/
├── frontend/
│   └── app.py               # Aplicación e interfaz principal en Streamlit
├── backend/
│   ├── scraper.py           # Conector web scraper HTTPX + BeautifulSoup en vivo
│   ├── ai_enricher.py       # Integrador de Google Gemini AI (google-genai SDK)
│   ├── db_manager.py        # Gestor de persistencia SQLite
│   └── gmail_reader.py      # Lector/parser opcional de newsletters por IMAP
├── .agents/
│   └── AGENTS.md            # Reglas de calidad y gobernanza de desarrollo
├── requirements.txt         # Dependencias optimizadas para despliegue en la nube
└── README.md                # Documentación principal del proyecto
```

---

## 🚀 Despliegue en la Nube

La aplicación está desplegada en **Streamlit Community Cloud** y conectada al repositorio de GitHub:

- **Repositorio GitHub**: `https://github.com/SotaDeEspadas/feed-noticias`
- **URL Pública de Producción**: [https://feed-noticias-ydjjjqwwgwjiywmadsru8j.streamlit.app/](https://feed-noticias-ydjjjqwwgwjiywmadsru8j.streamlit.app/)

---

## 💻 Ejecución Local

1. **Clonar el repositorio**:
   ```bash
   git clone https://github.com/SotaDeEspadas/feed-noticias.git
   cd feed-noticias
   ```

2. **Instalar dependencias**:
   ```bash
   pip install -r requirements.txt
   ```

3. **Configurar la Clave de Gemini AI**:
   Crea un archivo `.env` en la raíz con tu clave API de Gemini:
   ```env
   GEMINI_API_KEY=tu_api_key_aqui
   ```

4. **Lanzar la Aplicación**:
   ```bash
   streamlit run frontend/app.py
   ```

---

## 📄 Licencia

Este proyecto está bajo la Licencia MIT. Consulta el archivo [LICENSE](LICENSE) para más detalles.
