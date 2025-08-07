#!/bin/bash

# Script para ejecutar la aplicación Radio Taxi en diferentes plataformas
# Uso: ./scripts/run_app.sh [web|android|ios]

echo "🚕 Radio Taxi - Sistema de Gestión de Colas"
echo "=========================================="

# Función para mostrar ayuda
show_help() {
    echo "Uso: $0 [web|android|ios|help]"
    echo ""
    echo "Opciones:"
    echo "  web     - Ejecutar en navegador web (Chrome)"
    echo "  android - Ejecutar en emulador/dispositivo Android"
    echo "  ios     - Ejecutar en simulador/dispositivo iOS"
    echo "  help    - Mostrar esta ayuda"
    echo ""
    echo "Ejemplos:"
    echo "  $0 web      # Ejecutar en web en puerto 8080"
    echo "  $0 android  # Ejecutar en Android"
    echo "  $0 ios      # Ejecutar en iOS"
}

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

# Función para ejecutar en web
run_web() {
    echo "🌐 Iniciando aplicación en navegador web..."
    echo "📱 URL: http://localhost:8080"
    echo "🔐 Acceso Sede: central@radiotaxi.com"
    echo ""
    flutter run -d chrome --web-port 8080
}

# Función para ejecutar en Android
run_android() {
    echo "🤖 Iniciando aplicación en Android..."
    echo "📱 Asegúrate de tener un emulador ejecutándose o un dispositivo conectado"
    echo ""
    flutter run
}

# Función para ejecutar en iOS
run_ios() {
    echo "🍎 Iniciando aplicación en iOS..."
    echo "📱 Asegúrate de tener un simulador ejecutándose o un dispositivo conectado"
    echo ""
    flutter run -d ios
}

# Procesar argumentos
case "${1:-help}" in
    "web")
        run_web
        ;;
    "android")
        run_android
        ;;
    "ios")
        run_ios
        ;;
    "help"|"-h"|"--help")
        show_help
        ;;
    *)
        echo "❌ Opción no válida: $1"
        echo ""
        show_help
        exit 1
        ;;
esac 