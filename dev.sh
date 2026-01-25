#!/bin/bash
set -euo pipefail

RED="\033[0;31m"
GREEN="\033[0;32m"
NC="\033[0m"

echo "🚀 Iniciando AppScrom en modo Desarrollo (CORS desactivado)..."

os_name="$(uname -s)"
if [ "$os_name" = "Darwin" ]; then
  echo "👋 Hola, usuario de macOS."
elif [ "$os_name" = "Linux" ]; then
  echo "👋 Hola, usuario de Linux."
else
  echo "👋 Hola."
fi

if [ ! -f "secrets.json" ]; then
  echo -e "${RED}❌ Error: No se encontró secrets.json. Crea este archivo con tu GEMINI_API_KEY antes de continuar.${NC}"
  exit 1
fi

echo "🧹 Limpiando procesos previos en el puerto 8080..."
if command -v lsof >/dev/null 2>&1; then
  pids="$(lsof -ti tcp:8080 || true)"
  if [ -n "${pids}" ]; then
    kill -9 ${pids} >/dev/null 2>&1 || true
  fi
elif command -v fuser >/dev/null 2>&1; then
  fuser -k 8080/tcp >/dev/null 2>&1 || true
fi

echo -e "${GREEN}✅ Entorno listo. Lanzando Flutter...${NC}"
flutter run -d chrome --web-port 8080 --dart-define-from-file=secrets.json --web-browser-flag "--disable-web-security" --web-browser-flag "--user-data-dir=./chrome_profile"
