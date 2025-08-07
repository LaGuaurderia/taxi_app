#!/bin/bash

echo "🚀 Construyendo app para iOS..."

# Limpiar build anterior
echo "🧹 Limpiando build anterior..."
flutter clean

# Obtener dependencias
echo "📦 Obteniendo dependencias..."
flutter pub get

# Limpiar pods
echo "🧹 Limpiando pods..."
cd ios
rm -rf Pods Podfile.lock
cd ..

# Instalar pods
echo "📦 Instalando pods..."
cd ios
pod install
cd ..

# Construir para iOS
echo "🔨 Construyendo para iOS..."
flutter build ios --release

echo "✅ Build completado!"
echo "📱 El archivo IPA se encuentra en: build/ios/ipa/" 