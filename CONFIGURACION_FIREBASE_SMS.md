# 🔧 Configuración Firebase SMS - Solución de Errores

## ✅ Problema Identificado y Solucionado

**Problema:** Error al enviar códigos SMS
**Causa:** Faltaba el `debug.keystore` para Android
**Solución:** ✅ **COMPLETADA** - Keystore creado exitosamente

## 🔑 SHA-1 para Firebase Console

**SHA-1 Debug:** `C6:83:C5:CE:DC:8D:CB:05:F9:E3:8A:BF:E2:B7:BB:68:EB:B4:4D:BF`

## 📋 Pasos para Configurar Firebase Console

### 1. 🔐 Habilitar Phone Authentication
1. Ve a [Firebase Console](https://console.firebase.google.com)
2. Selecciona tu proyecto
3. Ve a **Authentication** → **Sign-in method**
4. Habilita **Phone** como método de autenticación
5. Guarda los cambios

### 2. 🔑 Agregar SHA-1 a Project Settings
1. Ve a **Project Settings** (ícono de engranaje)
2. En la pestaña **General**
3. En la sección **Your apps**, selecciona tu app Android
4. Haz clic en **Add fingerprint**
5. Agrega: `C6:83:C5:CE:DC:8D:CB:05:F9:E3:8A:BF:E2:B7:BB:68:EB:B4:4D:BF`
6. Guarda

### 3. 🌐 Configurar Dominios Autorizados
1. Ve a **Authentication** → **Settings**
2. En **Authorized domains**, agrega:
   - `localhost`
   - `127.0.0.1`
   - Tu dominio de producción (si lo tienes)

### 4. 📱 Configurar reCAPTCHA (Opcional)
1. En **Authentication** → **Settings**
2. En **reCAPTCHA Enterprise**, configura las claves si es necesario

## 🚀 Probar la Aplicación

### Limpiar y Recompilar
```bash
flutter clean
flutter pub get
flutter run
```

### Usar el Número de Teléfono
- **Número configurado:** `+34 621 03 35 28`
- El sistema automáticamente agregará el prefijo `+34`

## 🔍 Verificar Configuración

Ejecuta el script de verificación:
```bash
./scripts/verificar_firebase.sh
```

## 📞 Límites de SMS

**Firebase Free Tier:**
- 10,000 SMS por mes
- Verifica en Firebase Console → Usage

## 🆘 Si el Error Persiste

1. **Verifica la consola de Firebase** para errores específicos
2. **Revisa los logs** de la aplicación
3. **Confirma que Phone Auth está habilitado**
4. **Verifica que el SHA-1 está agregado correctamente**
5. **Asegúrate de que los dominios están autorizados**

## 📱 Números de Prueba (Desarrollo)

Para desarrollo, puedes usar estos números de prueba:
- `+1 650-555-1234` (código: 123456)
- `+1 650-555-0000` (código: 000000)

## ✅ Estado Actual

- ✅ **Keystore creado**
- ✅ **SHA-1 obtenido**
- ⏳ **Pendiente:** Configurar Firebase Console
- ⏳ **Pendiente:** Probar envío de SMS

---

**Nota:** Una vez configurado Firebase Console, el envío de SMS debería funcionar correctamente. 