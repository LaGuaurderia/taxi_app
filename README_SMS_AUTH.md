# 📱 Sistema de Autenticación por SMS - Radio Taxi

## 🔐 Nuevo Sistema de Autenticación

### **📞 Autenticación por SMS para Taxistas**

El sistema ahora utiliza autenticación por SMS para los taxistas, proporcionando mayor seguridad y facilidad de uso.

#### **🚀 Flujo de Autenticación:**

1. **Ingreso de Teléfono**
   - Campo para introducir número de teléfono español (+34)
   - Validación de formato y longitud
   - Botón "Enviar código"

2. **Verificación por SMS**
   - Código de 6 dígitos enviado al teléfono
   - Campo para introducir el código
   - Botones "Verificar" y "Reenviar"
   - Opción para cambiar número

3. **Asignación de ID de Taxi**
   - Dropdown con IDs disponibles (M1 a M32)
   - Validación de ID único en Firestore
   - Completar registro

### **🏢 Acceso Sede (Sin Cambios)**

- **Login tradicional** por correo/contraseña
- **Email exclusivo**: `central@radiotaxi.com`
- **Acceso directo** al panel de gestión

## 📋 Configuración Requerida

### **Firebase Authentication**

1. **Habilitar Phone Authentication**
   - Firebase Console → Authentication → Sign-in method
   - Habilitar "Phone"
   - Configurar reCAPTCHA para web

2. **Configurar Dominios Autorizados**
   - Agregar tu dominio en Firebase Console
   - Para desarrollo: `localhost`, `127.0.0.1`

3. **Configurar SHA-1 para Android**
   - Obtener SHA-1 del proyecto
   - Agregar en Firebase Console → Project Settings

### **Estructura de Datos**

#### **Colección `taxistas`**
```json
{
  "uid": "firebase_auth_uid",
  "telefono": "+34621033528",
  "idTaxi": "M12",
  "timestamp": "2024-01-15T10:30:00Z"
}
```

#### **Validaciones**
- ✅ **Teléfono único** por usuario
- ✅ **ID de taxi único** en toda la plataforma
- ✅ **Verificación SMS** obligatoria
- ✅ **Persistencia** de datos localmente

## 🎯 Características del Sistema

### **🔒 Seguridad**
- **Verificación SMS** de Firebase
- **Auto-verificación** en Android
- **Reenvío de códigos** con límites
- **Validación de teléfonos** españoles

### **📱 Experiencia de Usuario**
- **Flujo intuitivo** de 3 pasos
- **Feedback visual** en cada etapa
- **Manejo de errores** claro
- **Persistencia** de sesión

### **🔄 Gestión de Sesiones**
- **Detección automática** de usuarios registrados
- **Redirección inteligente** según estado
- **Cerrar sesión** disponible en panel taxista
- **Limpieza de datos** al cerrar sesión

## 🚀 Uso del Sistema

### **Para Taxistas (Nuevo)**

#### **Primera Vez:**
1. **Abrir aplicación**
2. **Ingresar teléfono** (+34 XXXXXXXX)
3. **Recibir SMS** con código
4. **Verificar código** (6 dígitos)
5. **Seleccionar ID** de taxi (M1-M32)
6. **Completar registro**

#### **Sesiones Posteriores:**
1. **Abrir aplicación**
2. **Acceso directo** al panel taxista
3. **ID automático** cargado desde Firestore

### **Para Sede (Sin Cambios)**

#### **Acceso:**
1. **Botón "Acceso Sede"** en pantalla principal
2. **Login** con `central@radiotaxi.com`
3. **Contraseña** configurada en Firebase Console
4. **Acceso directo** al panel de gestión

## 🔧 Configuración Técnica

### **Dependencias Agregadas**
```yaml
dependencies:
  firebase_auth: ^4.15.3
  intl: ^0.19.0
```

### **Archivos Nuevos**
- `lib/screens/pantalla_autenticacion_sms.dart`
- `lib/main.dart` (actualizado)
- `lib/services/auth_service.dart` (actualizado)
- `lib/services/preferences_service.dart` (actualizado)

### **Funcionalidades Agregadas**
- ✅ **Verificación SMS** completa
- ✅ **Validación de IDs** únicos
- ✅ **Persistencia** de datos
- ✅ **Manejo de errores** robusto
- ✅ **UI responsive** y moderna

## 📊 Ventajas del Nuevo Sistema

### **🔐 Seguridad Mejorada**
- **Verificación de identidad** por SMS
- **Sin contraseñas** que recordar
- **Protección contra** acceso no autorizado

### **👥 Facilidad de Uso**
- **Proceso simplificado** para taxistas
- **Menos pasos** de configuración
- **Acceso rápido** en sesiones posteriores

### **🏢 Gestión Centralizada**
- **Control total** desde Firebase Console
- **Registro de actividad** completo
- **Gestión de usuarios** simplificada

## 🚨 Consideraciones Importantes

### **📱 Costos SMS**
- **Firebase cobra** por SMS enviados
- **Configurar límites** de uso
- **Monitorear** uso mensual

### **🌍 Soporte de Países**
- **Configurado para España** (+34)
- **Expandir** según necesidades
- **Validar** números internacionales

### **🔧 Mantenimiento**
- **Actualizar** Firebase SDK regularmente
- **Monitorear** logs de autenticación
- **Backup** de datos de usuarios

## 📞 Soporte

### **Problemas Comunes**

#### **SMS no recibido:**
1. Verificar número de teléfono
2. Comprobar configuración Firebase
3. Revisar límites de SMS

#### **Error de verificación:**
1. Verificar código de 6 dígitos
2. Comprobar tiempo de expiración
3. Intentar reenvío

#### **ID de taxi en uso:**
1. Verificar en Firebase Console
2. Contactar administrador
3. Asignar ID alternativo

### **Contacto**
- **Desarrollador**: [Tu información]
- **Firebase Support**: [Enlaces útiles]
- **Documentación**: [Referencias]

---

**✅ Sistema implementado y listo para producción** 