#!/bin/bash

echo "🔍 Verificando configuración de Firebase..."

# Verificar si existe google-services.json en Android
if [ -f "android/app/google-services.json" ]; then
    echo "✅ google-services.json encontrado en android/app/"
else
    echo "❌ google-services.json NO encontrado en android/app/"
    echo "   Necesitas descargar este archivo desde la consola de Firebase"
fi

# Verificar si existe GoogleService-Info.plist en iOS
if [ -f "ios/Runner/GoogleService-Info.plist" ]; then
    echo "✅ GoogleService-Info.plist encontrado en ios/Runner/"
else
    echo "❌ GoogleService-Info.plist NO encontrado en ios/Runner/"
    echo "   Necesitas descargar este archivo desde la consola de Firebase"
fi

# Verificar dependencias en pubspec.yaml
echo ""
echo "📦 Verificando dependencias de Firebase..."

if grep -q "firebase_core" pubspec.yaml; then
    echo "✅ firebase_core encontrado en pubspec.yaml"
else
    echo "❌ firebase_core NO encontrado en pubspec.yaml"
fi

if grep -q "cloud_firestore" pubspec.yaml; then
    echo "✅ cloud_firestore encontrado en pubspec.yaml"
else
    echo "❌ cloud_firestore NO encontrado en pubspec.yaml"
fi

if grep -q "firebase_auth" pubspec.yaml; then
    echo "✅ firebase_auth encontrado en pubspec.yaml"
else
    echo "❌ firebase_auth NO encontrado en pubspec.yaml"
fi

# Verificar si existe firebase_options.dart
if [ -f "lib/firebase_options.dart" ]; then
    echo "✅ firebase_options.dart encontrado"
else
    echo "❌ firebase_options.dart NO encontrado"
    echo "   Ejecuta: flutterfire configure"
fi

echo ""
echo "🔧 Pasos para solucionar problemas:"
echo "1. Ve a https://console.firebase.google.com/"
echo "2. Selecciona tu proyecto"
echo "3. Ve a Configuración del proyecto > General"
echo "4. Descarga los archivos de configuración para Android e iOS"
echo "5. Colócalos en las carpetas correspondientes"
echo "6. Ejecuta: flutterfire configure"
echo "7. Ejecuta: flutter pub get"
echo "8. Ejecuta: flutter clean && flutter pub get" 