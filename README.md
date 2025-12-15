# 🎁 Amigo Invisible – Flutter & Firebase

Aplicación móvil desarrollada en **Flutter** para organizar sorteos de **Amigo Invisible**, permitiendo crear sorteos, unirse mediante código y realizar el sorteo de forma automática y justa, evitando que una persona se regale a sí misma.

La app utiliza **Firebase Firestore** como backend en tiempo real y está pensada para un uso sencillo sin necesidad de registro.

---

## ✨ Funcionalidades

### 🟢 Crear sorteo
- Introducir nombre del creador
- Nombre del sorteo
- Presupuesto
- Generación automática de un **código de 4 dígitos**
- El creador se añade automáticamente como participante

### 🟦 Unirse a un sorteo
- Unirse introduciendo:
  - Nombre del participante
  - Código del sorteo
- El participante aparece en tiempo real en la lista

### 👥 Gestión de participantes
- Lista en tiempo real de participantes
- El creador puede **eliminar participantes** antes de realizar el sorteo
- Tras realizar el sorteo, ya no se pueden eliminar participantes

### 🎲 Realizar sorteo
- Solo visible para el creador
- Solo si hay **mínimo 2 participantes**
- El algoritmo garantiza que **nadie se regale a sí mismo**
- El sorteo se guarda en Firestore

### 🔔 Resultado del sorteo
- Cada participante recibe un **popup solo la primera vez**
- El resultado queda guardado y visible en la pantalla del sorteo
- El popup no vuelve a mostrarse al reabrir la app

### 📤 Compartir por WhatsApp
- Envío del código del sorteo directamente por WhatsApp

### 🗂️ Mis sorteos
- Lista de sorteos en los que el usuario participa
- Opción de **eliminar su participación** desde el menú de opciones

---

## 🛠️ Tecnologías usadas

- **Flutter**
- **Firebase**
  - Firebase Core
  - Cloud Firestore
- **SharedPreferences**
- **url_launcher**
- **font_awesome_flutter**
- **Material 3**

---

## 📱 Plataformas

- ✅ Android (APK generada)
- ⚠️ iOS:
  - Instalación local en iPhone mediante Xcode (Apple ID gratuito)
  - Para distribución pública es necesario Apple Developer Program

---

## 🚀 Instalación y ejecución

### 1️⃣ Clonar el proyecto
```bash
git clone https://github.com/tu-usuario/amigo_invisible.git
cd amigo_invisible
