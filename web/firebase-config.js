// Configuración de Firebase para Web
// Este archivo se puede usar para configuraciones adicionales de Firebase Web

// Configuración de Firebase (ya incluida en el proyecto)
const firebaseConfig = {
  // La configuración se maneja automáticamente desde el proyecto Flutter
  // No es necesario definir aquí ya que se usa firebase_options.dart
};

// Configuraciones adicionales para web
const webConfig = {
  // Configuración de autenticación web
  auth: {
    // Habilitar persistencia de sesión
    persistence: 'local',
    // Configuración de dominio autorizado
    authorizedDomains: ['localhost', '127.0.0.1'],
  },
  
  // Configuración de Firestore para web
  firestore: {
    // Habilitar caché offline
    enableOffline: true,
    // Configuración de sincronización
    syncInterval: 10000, // 10 segundos
  },
  
  // Configuración de geolocalización web
  geolocation: {
    // Habilitar geolocalización en web
    enableWebGeolocation: true,
    // Configuración de permisos
    requestPermission: true,
  }
};

// Exportar configuración
if (typeof module !== 'undefined' && module.exports) {
  module.exports = { firebaseConfig, webConfig };
} else if (typeof window !== 'undefined') {
  window.firebaseWebConfig = { firebaseConfig, webConfig };
} 