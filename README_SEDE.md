# 🏢 Configuración de la Sede - Radio Taxi

## 📋 Instrucciones para Configurar la Cuenta de Sede

### 🔐 Crear Cuenta de Sede en Firebase Console

1. **Acceder a Firebase Console**
   - Ve a [https://console.firebase.google.com](https://console.firebase.google.com)
   - Selecciona tu proyecto `taxi-app-example`

2. **Ir a Authentication**
   - En el menú lateral, haz clic en "Authentication"
   - Ve a la pestaña "Users"

3. **Agregar Usuario Manualmente**
   - Haz clic en "Add user"
   - **Email**: `central@radiotaxi.com`
   - **Password**: [Establece una contraseña segura]
   - Haz clic en "Add user"

### 🚀 Acceso a la Sede

#### **Desde Aplicación Móvil:**
1. Abre la aplicación en el dispositivo
2. Inicia sesión con:
   - **Email**: `central@radiotaxi.com`
   - **Password**: [La contraseña configurada]
3. Serás redirigido automáticamente al panel de sede

#### **Desde Navegador Web:**
1. Abre la aplicación web en: `http://localhost:8080`
2. Inicia sesión con las mismas credenciales
3. Acceso directo al panel de gestión de colas

### 🛡️ Seguridad

#### **Restricciones Implementadas:**
- ✅ Solo `central@radiotaxi.com` puede acceder al modo sede
- ✅ Otros usuarios son redirigidos al modo taxista
- ✅ No se puede registrar con el correo de la sede
- ✅ Contraseña gestionada desde Firebase Console

#### **Funcionalidades de Sede:**
- 📊 **Gestión de Colas**: Ver todas las paradas en tiempo real
- 🗑️ **Eliminar Taxis**: Quitar taxis de las colas
- 📈 **Monitoreo**: Estado de cada parada con contadores
- 🔄 **Actualización en Tiempo Real**: Cambios instantáneos

### 🔧 Configuración Adicional

#### **Para Desarrollo Local:**
```bash
# Ejecutar en modo web
flutter run -d chrome --web-port 8080

# Ejecutar en emulador Android
flutter run

# Ejecutar en dispositivo iOS
flutter run -d ios
```

#### **Para Producción:**
```bash
# Construir para web
flutter build web

# Construir para Android
flutter build apk --release

# Construir para iOS
flutter build ios --release
```

### 📱 Características del Panel de Sede

#### **Interfaz:**
- 🎨 **Diseño Responsive**: Funciona en móvil y escritorio
- 🎯 **3 Columnas**: Una para cada parada (Hospital, Avenida, Estación)
- 🚨 **Indicadores Visuales**: Color de advertencia si hay más de 5 taxis
- 🔔 **Notificaciones**: Feedback visual para todas las acciones

#### **Funcionalidades:**
- 👥 **Gestión de Taxis**: Ver y eliminar taxis de las colas
- 📊 **Estadísticas**: Contador de taxis por parada
- 🔄 **Sincronización**: Datos en tiempo real con Firestore
- 📝 **Historial**: Registro de todas las acciones

### 🔐 Gestión de Contraseñas

#### **Cambiar Contraseña:**
1. Ve a Firebase Console > Authentication > Users
2. Encuentra `central@radiotaxi.com`
3. Haz clic en "More" > "Reset password"
4. Se enviará un email de restablecimiento

#### **Restablecer desde la App:**
1. En la pantalla de login, haz clic en "¿Olvidaste tu contraseña?"
2. Ingresa `central@radiotaxi.com`
3. Revisa el email y sigue las instrucciones

### 🚨 Notas Importantes

#### **Seguridad:**
- 🔒 La contraseña debe ser fuerte (mínimo 8 caracteres)
- 🔐 Cambia la contraseña regularmente
- 📧 Solo usa `central@radiotaxi.com` para la sede
- 🚫 No compartas las credenciales

#### **Mantenimiento:**
- 🔄 Actualiza la aplicación regularmente
- 📊 Revisa los logs de Firebase para auditoría
- 🛠️ Mantén Firebase Console actualizado
- 📱 Prueba en diferentes dispositivos

### 📞 Soporte

Si tienes problemas con el acceso a la sede:
1. Verifica que la cuenta existe en Firebase Console
2. Confirma que el email es exactamente `central@radiotaxi.com`
3. Intenta restablecer la contraseña
4. Contacta al administrador del sistema

---

**⚠️ IMPORTANTE**: Esta cuenta tiene acceso completo al sistema. Úsala solo para gestión administrativa de la sede. 