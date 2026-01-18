# 💰 Monea - Gestor de Finanzas Personales

> **🤖 Aplicación desarrollada 100% con Inteligencia Artificial**
> 
> Este proyecto fue creado completamente utilizando IA (Claude Code / Cursor), desde el diseño de la arquitectura hasta la implementación del código, demostrando las capacidades de la IA en el desarrollo de aplicaciones móviles completas y funcionales.

## 📱 ¿Qué es Monea?

Monea es una aplicación móvil offline que te ayuda a **registrar, categorizar y analizar tus gastos e ingresos personales** de manera automática y manual. La app está diseñada específicamente para usuarios colombianos que utilizan servicios bancarios como Bancolombia.

### ✨ Características Principales

- **📨 Lectura Automática de SMS Bancarios**: Detecta y procesa automáticamente mensajes de transacciones bancarias
- **💵 Parseo Inteligente de Montos**: Interpreta correctamente el formato colombiano de números ($413,300.00)
- **📊 Análisis Visual**: Gráficos y estadísticas de tus gastos e ingresos
- **🏷️ Categorización**: Organiza tus transacciones por categorías personalizables
- **💾 100% Offline**: Todos tus datos se almacenan localmente (Hive database)
- **🔒 Privacidad Total**: Sin conexión a internet, tus datos nunca salen de tu dispositivo
- **📤 Exportar/Importar**: Respaldo y restauración de datos en formato JSON
- **💰 Presupuestos**: Configura y monitorea presupuestos mensuales por categoría

## 🎯 Propósito

El objetivo de Monea es **democratizar el control financiero personal** mediante una herramienta:
- **Gratuita** y de código abierto
- **Simple** de usar
- **Automática** en la medida de lo posible
- **Privada** y segura (sin enviar datos a servidores externos)
- **Adaptada** al contexto colombiano (formato de números, bancos locales)

## 🛠️ Tecnologías Utilizadas

- **Framework**: Flutter 3.x
- **Lenguaje**: Dart
- **Base de Datos**: Hive (NoSQL local)
- **Gráficos**: FL Chart
- **Permisos SMS**: Telephony plugin
- **Plataforma**: Android (con soporte potencial para iOS, Web, Desktop)

## 📋 Funcionalidades Detalladas

### 1. Detección Automática de Transacciones
- Lee SMS de bancos colombianos (Bancolombia, Davivienda, BBVA, etc.)
- Extrae automáticamente: monto, fecha, descripción
- Clasifica como ingreso o gasto
- Evita duplicados

### 2. Gestión Manual de Transacciones
- Agregar gastos e ingresos manualmente
- Editar y eliminar transacciones
- Asignar categorías y etiquetas

### 3. Análisis y Reportes
- Gráficos de gastos por categoría
- Tendencias temporales (diario, semanal, mensual)
- Balance general (ingresos vs gastos)
- Filtros por fecha y categoría

### 4. Presupuestos
- Configurar límites de gasto por categoría
- Alertas visuales de presupuesto excedido
- Seguimiento de progreso mensual

### 5. Exportación de Datos
- Exportar todas las transacciones a JSON
- Importar datos desde respaldos
- Compartir reportes

## 🚀 Instalación

### Desde APK (Recomendado)
1. Descarga el archivo `app-release.apk` desde la carpeta `build/app/outputs/flutter-apk/`
2. Habilita "Instalar apps de fuentes desconocidas" en tu dispositivo Android
3. Instala el APK
4. Otorga permisos de lectura de SMS cuando se solicite

### Compilar desde Código Fuente
```bash
# Clonar el repositorio
git clone <repository-url>
cd monea_generic

# Instalar dependencias
flutter pub get

# Generar archivos de Hive
flutter pub run build_runner build

# Compilar APK
flutter build apk --release
```

## 📱 Requisitos

- Android 6.0 (API 23) o superior
- Permisos de lectura de SMS (para detección automática)
- ~52 MB de espacio de almacenamiento

## 🔐 Privacidad y Seguridad

- ✅ **Sin conexión a internet**: La app funciona 100% offline
- ✅ **Datos locales**: Toda la información se almacena en tu dispositivo
- ✅ **Sin tracking**: No se recopilan datos de uso ni analíticas
- ✅ **Código abierto**: Puedes revisar todo el código fuente
- ✅ **Sin anuncios**: Completamente libre de publicidad

## 🤖 Desarrollo con IA

Este proyecto es un **experimento de desarrollo asistido por IA** que demuestra:

- **Diseño de arquitectura** completo generado por IA
- **Implementación de features** end-to-end
- **Resolución de bugs** y optimizaciones
- **Testing** y validación
- **Documentación** automática

### Conversaciones de Desarrollo Destacadas
- Implementación del sistema de lectura de SMS
- Corrección del parseo de números en formato colombiano
- Sistema de presupuestos y categorías
- Dashboard de análisis con gráficos

## 📝 Estructura del Proyecto

```
lib/
├── models/          # Modelos de datos (Transaction, Budget)
├── screens/         # Pantallas de la aplicación
├── services/        # Servicios (SMS, Storage)
├── widgets/         # Componentes reutilizables
└── main.dart        # Punto de entrada

test/                # Tests unitarios
android/             # Configuración Android
```

## 🐛 Problemas Conocidos

- El parseo de SMS solo funciona con formatos específicos de bancos colombianos
- Algunos mensajes promocionales pueden ser detectados como transacciones

## 🔮 Roadmap Futuro

- [ ] Soporte para más bancos colombianos
- [ ] Modo oscuro
- [ ] Widgets de inicio rápido
- [ ] Recordatorios de presupuesto
- [ ] Exportación a Excel/CSV
- [ ] Sincronización opcional en la nube (encriptada)

## 📄 Licencia

Este proyecto es de código abierto y está disponible bajo la licencia MIT.

## 🤝 Contribuciones

Las contribuciones son bienvenidas. Si encuentras un bug o tienes una sugerencia:
1. Abre un issue describiendo el problema o feature
2. Si quieres contribuir código, crea un fork y envía un pull request

## 👨‍💻 Autor

Desarrollado completamente con **Google Gemini AI** para demostrar las capacidades de la IA en el desarrollo de software.

---

**⚠️ Disclaimer**: Esta aplicación lee SMS bancarios para automatizar el registro de transacciones. Asegúrate de entender los permisos que otorgas y revisa el código fuente si tienes dudas sobre la privacidad.
