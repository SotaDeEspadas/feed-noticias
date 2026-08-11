# Reglas de Calidad y Verificación Rigurosa para este Workspace

## 1. Verificación Empírica Obligatoria Antes de Entregar
- **Nunca dar una tarea por finalizada sin ejecutar una prueba funcional previa en consola.**
- Validar mediante scripts de verificación (ej. `python -c "..."`) que no existan excepciones en tiempo de ejecución (`AttributeError`, `KeyError`, `ImportError`, etc.).

## 2. Garantía de No Regresión
- **Preservar todas las funcionalidades, fuentes de datos y contratos existentes.**
- Al tocar un módulo (como scrapers o procesadores), verificar explícitamente que la lista completa de fuentes de datos (`Funds Society`, `Funds People`, `EFPA España`, `Citywire`, `Alterforum`) continúe presente y operativa.

## 3. Control de Calidad en UI / UX
- Probar que las modificaciones en CSS o componentes no oscurezcan textos ni rompan el contraste.
- Garantizar que los identificadores de Streamlit (`key=...`) sean únicos y no generen errores de renderizado.

## 4. Arquitectura y Despliegue en la Nube (Lección Aprendida)
- **Anticipar restricciones de entorno antes de actuar**: Al desplegar en la nube (Streamlit Cloud), aislamos la app en un repositorio personal independiente desde el primer minuto para evitar bloqueos de permisos de Organizaciones de GitHub (*Deploy Keys*).
- **Despliegues en VPS y Certificados SSL**: Los subdominios genéricos de infraestructura (como `*.hstgr.cloud`) no soportan emisión directa de Let's Encrypt y chocan con proxies preinstalados (Traefik/n8n). Para garantizar coste cero y conexión HTTPS 100% segura (candado 🔒) desde el primer intento sin hacer perder tiempo al usuario, utilizar **Cloudflare Tunnel (`cloudflared`)** como estándar primario en VPS.
- Mantener siempre un `requirements.txt` ligero y rutas de archivos compatibles con sistemas de solo lectura (`/tmp` para SQLite en Linux).
