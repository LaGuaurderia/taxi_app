# 🚕 Radio Taxi - Sistema de Gestión de Colas

Una aplicación Flutter completa para gestionar colas de taxis en tiempo real usando Firebase Firestore y Authentication.

## 🔐 Sistema de Autenticación

### 👥 Roles de Usuario

#### **🏢 Sede Central**
- **Email**: `central@radiotaxi.com`
- **Acceso**: Panel de gestión de todas las colas
- **Funciones**: Ver, eliminar taxis, monitoreo en tiempo real
- **Plataformas**: Web, móvil

#### **🚗 Taxistas**
- **Registro**: Email + contraseña + ID de taxi único
- **Acceso**: Panel de taxista con geolocalización
- **Funciones**: Apuntarse/salir de colas, ubicación automática
- **Plataformas**: Móvil (Android/iOS)

### 🔒 Seguridad
- ✅ Autenticación con Firebase Auth
- ✅ ID de taxi único por usuario
- ✅ Restricción de acceso por rol
- ✅ Contraseñas gestionadas desde Firebase Console
- ✅ Sesiones persistentes

## 🚀 Características

### **🔐 Autenticación y Seguridad**
- **Sistema de login/registro** con Firebase Authentication
- **Roles diferenciados**: Sede central y taxistas
- **ID de taxi único** por usuario registrado
- **Sesiones persistentes** con SharedPreferences
- **Restricción de acceso** por correo electrónico

### **📱 Funcionalidades Móviles**
- **Geolocalización pasiva** para taxistas
- **Alertas automáticas** de proximidad a paradas
- **Gestión de colas** en tiempo real
- **Interfaz responsive** para diferentes tamaños de pantalla

### **🌐 Funcionalidades Web**
- **Acceso desde navegador** para la sede
- **Panel de gestión completo** con 3 columnas
- **Actualización en tiempo real** de todas las colas
- **Diseño adaptativo** para escritorio y móvil

### **📊 Gestión de Datos**
- **Sincronización en tiempo real** con Firebase Firestore
- **Historial de acciones** con timestamps
- **Validación de datos** en tiempo real
- **Backup automático** en la nube

## Paradas Disponibles

1. **Hospital Mollet**
2. **Avenida Libertad**
3. **Estación Mollet-San Fost**

## Estructura de la Base de Datos

```
Collection: colas
├── Document: hospital
│   └── Field: orden (array) ["M1", "M5", "M12"]
├── Document: avenida
│   └── Field: orden (array) ["M2", "M8"]
└── Document: estacion
    └── Field: orden (array) ["M3", "M7", "M10"]
```

## 🛠️ Instalación

### Prerrequisitos

- Flutter SDK (versión 3.0.0 o superior)
- Android Studio / VS Code
- Cuenta de Firebase
- Git

### Pasos de Instalación

1. **Clonar el repositorio**
   ```bash
   git clone <url-del-repositorio>
   cd taxi_app
   ```

2. **Instalar dependencias**
   ```bash
   flutter pub get
   ```

3. **Configurar Firebase**

   a. Crear un proyecto en [Firebase Console](https://console.firebase.google.com/)
   
   b. Habilitar Firestore Database
   
   c. Configurar las reglas de seguridad de Firestore:
   ```javascript
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       match /colas/{document=**} {
         allow read, write: if true;
       }
     }
   }
   ```
   
   d. Descargar el archivo `google-services.json` y colocarlo en `android/app/`
   
   e. Reemplazar el archivo `android/app/google-services.json` con tu configuración real

4. **Ejecutar la aplicación**

   **Opción 1: Script automático**
   ```bash
   ./scripts/run_app.sh web      # Ejecutar en navegador
   ./scripts/run_app.sh android  # Ejecutar en Android
   ./scripts/run_app.sh ios      # Ejecutar en iOS
   ```

   **Opción 2: Comandos manuales**
   ```bash
   flutter run -d chrome --web-port 8080  # Web
   flutter run                            # Android
   flutter run -d ios                     # iOS
   ```

## 📖 Uso

### 🔐 Configuración Inicial

#### **Para la Sede Central:**
1. **Crear cuenta en Firebase Console**:
   - Ve a [Firebase Console](https://console.firebase.google.com)
   - Authentication > Users > Add user
   - Email: `central@radiotaxi.com`
   - Password: [Establece una contraseña segura]

2. **Acceso a la aplicación**:
   - Inicia sesión con las credenciales configuradas
   - Serás redirigido automáticamente al panel de sede

#### **Para Taxistas:**
1. **Registro**: Crear cuenta con email, contraseña e ID de taxi único
2. **Verificación**: El sistema valida que el ID no esté en uso
3. **Acceso**: Panel de taxista con geolocalización automática

### 🚗 Para Taxistas

1. **Iniciar sesión** con credenciales registradas
2. **Geolocalización automática** cada 10 segundos
3. **Alertas de proximidad** a paradas (30m)
4. **Apuntarse/salir** de colas automáticamente
5. **Gestión manual** de colas si es necesario

### 🏢 Para Sedes

1. **Acceso directo** al panel de gestión con login
2. **Vista completa** de las 3 paradas en columnas
3. **Gestión de taxis** con botones de eliminación
4. **Monitoreo en tiempo real** de todas las colas
5. **Indicadores visuales** para colas con más de 5 taxis

## Configuración de Firebase

### Crear Proyecto Firebase

1. Ve a [Firebase Console](https://console.firebase.google.com/)
2. Crea un nuevo proyecto
3. Habilita Firestore Database
4. Configura las reglas de seguridad

### Configurar Android

1. En Firebase Console, ve a Project Settings > General
2. Añade una app Android
3. Usa el package name: `com.example.taxi_app`
4. Descarga el archivo `google-services.json`
5. Colócalo en `android/app/`

### Reglas de Firestore

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /colas/{document=**} {
      allow read, write: if true;
    }
  }
}
```

## Estructura del Proyecto

```
lib/
├── main.dart                 # Punto de entrada de la app
├── models/
│   └── cola_taxis.dart      # Modelos de datos
├── screens/
│   ├── pantalla_principal.dart
│   ├── pantalla_taxista.dart
│   ├── pantalla_sede.dart
│   └── configuracion_taxi.dart
└── services/
    ├── firestore_service.dart
    └── preferences_service.dart
```

## Dependencias Principales

- `firebase_core`: Inicialización de Firebase
- `cloud_firestore`: Base de datos en tiempo real
- `provider`: Gestión de estado
- `shared_preferences`: Almacenamiento local

## Colores del Diseño

- **Fondo principal**: `#F8F6F3`
- **Títulos**: `#584130`
- **Subtítulos**: `#BDA697`
- **Fondos de secciones**: `#E8E1DA`
- **Botones**: `#A28C7D`

## Notas Importantes

- No se usa GPS, solo selección manual de paradas
- Los taxis se identifican mediante códigos únicos
- La sincronización es en tiempo real
- La app funciona offline con sincronización automática

## Solución de Problemas

### Error de Firebase
- Verificar que `google-services.json` esté en la ubicación correcta
- Comprobar que las reglas de Firestore permitan lectura/escritura

### Error de Dependencias
```bash
flutter clean
flutter pub get
```

### Error de Compilación
- Verificar versión de Flutter: `flutter --version`
- Actualizar dependencias si es necesario

## Contribuir

1. Fork el proyecto
2. Crea una rama para tu feature
3. Commit tus cambios
4. Push a la rama
5. Abre un Pull Request

## 🏢 Configuración de la Sede

Para información detallada sobre la configuración de la cuenta de sede, consulta el archivo [README_SEDE.md](README_SEDE.md).

### 🔑 Acceso Rápido
- **Email**: `central@radiotaxi.com`
- **Configuración**: Firebase Console > Authentication
- **Acceso Web**: `http://localhost:8080`
- **Funciones**: Gestión completa de colas

## 📚 Documentación Adicional

- [README_SEDE.md](README_SEDE.md) - Configuración detallada de la sede
- [scripts/run_app.sh](scripts/run_app.sh) - Scripts de ejecución
- [web/firebase-config.js](web/firebase-config.js) - Configuración web

## Licencia

Este proyecto está bajo la Licencia MIT. # taxi_app
