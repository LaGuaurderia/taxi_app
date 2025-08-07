#!/bin/bash

# Script para compilar la versión web exclusiva de la sede
# Uso: ./scripts/build_sede_web.sh

echo "🏢 Radio Taxi - Compilando Versión Web de la Sede"
echo "=================================================="

# Verificar si Flutter está instalado
if ! command -v flutter &> /dev/null; then
    echo "❌ Error: Flutter no está instalado o no está en el PATH"
    echo "Por favor, instala Flutter desde: https://flutter.dev/docs/get-started/install"
    exit 1
fi

# Verificar que estamos en el directorio correcto
if [ ! -f "pubspec.yaml" ]; then
    echo "❌ Error: No se encontró pubspec.yaml"
    echo "Por favor, ejecuta este script desde el directorio raíz del proyecto"
    exit 1
fi

# Verificar que existe el archivo main_sede_web.dart
if [ ! -f "lib/main_sede_web.dart" ]; then
    echo "❌ Error: No se encontró lib/main_sede_web.dart"
    echo "Asegúrate de que el archivo existe antes de compilar"
    exit 1
fi

echo "📦 Instalando dependencias..."
flutter pub get

echo "🧹 Limpiando build anterior..."
flutter clean

echo "🌐 Compilando versión web de la sede..."
echo "📁 Usando: lib/main_sede_web.dart"

# Crear directorio de salida si no existe
mkdir -p build/sede_web

# Compilar para web
flutter build web \
  --target lib/main_sede_web.dart \
  --output build/sede_web \
  --release

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Compilación exitosa!"
    echo "📁 Archivos generados en: build/sede_web/"
    echo ""
    echo "🚀 Para desplegar:"
    echo "   1. Sube el contenido de build/sede_web/ a tu servidor web"
    echo "   2. Configura el dominio (ej: central.radiotaxi.com)"
    echo "   3. Asegúrate de que Firebase esté configurado correctamente"
    echo ""
    echo "🔐 Acceso:"
    echo "   - Email: central@radiotaxi.com"
    echo "   - Contraseña: [Configurada en Firebase Console]"
    echo ""
    echo "📱 Características incluidas:"
    echo "   ✅ Login exclusivo para sede"
    echo "   ✅ 3 columnas de gestión de colas"
    echo "   ✅ Botones Reset y Asignar servicio"
    echo "   ✅ Diseño 100% responsive"
    echo "   ✅ Eliminación individual de taxis"
    echo "   ✅ Indicadores visuales de estado"
    echo ""
    echo "🌐 Para probar localmente:"
    echo "   cd build/sede_web"
    echo "   python3 -m http.server 8080"
    echo "   # Luego abre: http://localhost:8080"
else
    echo ""
    echo "❌ Error en la compilación"
    echo "Revisa los errores arriba y corrige los problemas"
    exit 1
fi 