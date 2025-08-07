# Solución para Error de Firestore

## Problema
El error `[cloud_firestore/unknown] null` aparece cuando intentas apuntarte a una tanda. Este error indica un problema con la configuración o conexión de Firebase.

## Soluciones Implementadas

### 1. Mejorado el Manejo de Errores
- ✅ Agregado manejo robusto de errores en `FirestoreService`
- ✅ Mensajes de error más específicos y útiles
- ✅ Indicadores de carga visual en los botones
- ✅ Opción de reintentar operaciones fallidas

### 2. Verificación de Configuración
Ejecuta el script de verificación:
```bash
./scripts/verificar_firebase.sh
```

### 3. Pasos para Solucionar el Problema

#### Paso 1: Verificar Configuración de Firebase
1. Ve a [Firebase Console](https://console.firebase.google.com/)
2. Selecciona tu proyecto
3. Ve a **Configuración del proyecto** > **General**
4. Descarga los archivos de configuración:
   - `google-services.json` para Android
   - `GoogleService-Info.plist` para iOS

#### Paso 2: Colocar Archivos de Configuración
```bash
# Para Android
cp google-services.json android/app/

# Para iOS  
cp GoogleService-Info.plist ios/Runner/
```

#### Paso 3: Configurar FlutterFire
```bash
# Instalar FlutterFire CLI si no lo tienes
dart pub global activate flutterfire_cli

# Configurar Firebase
flutterfire configure
```

#### Paso 4: Limpiar y Reconstruir
```bash
flutter clean
flutter pub get
flutter run
```

### 4. Verificar Reglas de Firestore

Asegúrate de que las reglas de Firestore permitan lectura y escritura:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /colas/{document=**} {
      allow read, write: if true; // Para desarrollo
    }
    match /historial/{document=**} {
      allow read, write: if true; // Para desarrollo
    }
  }
}
```

### 5. Verificar Conexión a Internet
- Asegúrate de tener conexión a internet estable
- Verifica que no haya restricciones de firewall
- Prueba en diferentes redes si es posible

### 6. Verificar Proyecto de Firebase
- Confirma que el proyecto esté activo
- Verifica que no hayas alcanzado los límites gratuitos
- Asegúrate de que Firestore esté habilitado

## Mejoras Implementadas en el Código

### FirestoreService
- ✅ Manejo de errores con `try-catch` y `handleError`
- ✅ Validación de parámetros antes de operaciones
- ✅ Conversión robusta de datos
- ✅ Fallbacks para casos de error

### Pantalla de Selección de Parada
- ✅ Indicadores de carga visual
- ✅ Mensajes de error específicos
- ✅ Botón de reintentar
- ✅ Prevención de múltiples clics durante carga

## Pruebas Recomendadas

1. **Prueba de Conexión Básica**:
   ```dart
   // En la consola de Flutter
   FirebaseFirestore.instance.collection('test').add({
     'timestamp': FieldValue.serverTimestamp(),
   });
   ```

2. **Verificar Configuración**:
   ```bash
   flutter doctor -v
   flutter pub deps
   ```

3. **Probar en Diferentes Dispositivos**:
   - Android físico
   - iOS físico
   - Emulador Android
   - Simulador iOS

## Contacto
Si el problema persiste después de seguir estos pasos, verifica:
- Los logs de Firebase Console
- Los logs de la aplicación en la consola
- La configuración de red del dispositivo

## Notas Importantes
- El error puede ser temporal debido a problemas de red
- Las reglas de Firestore deben permitir las operaciones necesarias
- La configuración de Firebase debe ser correcta para cada plataforma 