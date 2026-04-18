# Lumina — App Store Submission Checklist

Resumen de lo que el proyecto ya trae configurado y lo que queda por hacer
manualmente en App Store Connect antes de enviar a revisión.

## Ya resuelto en código

- [x] **iOS 26 deployment target** (`IPHONEOS_DEPLOYMENT_TARGET = 26.0`).
- [x] **Universal** (`TARGETED_DEVICE_FAMILY = "1,2"`). iPhone + iPad.
- [x] **Orientaciones iPad**: portrait, portrait-upside-down, landscape L/R.
- [x] **Privacy manifest** (`Lumina/PrivacyInfo.xcprivacy`): 0 tracking, 0
      datos recolectados, Required Reason APIs declarados (UserDefaults
      CA92.1, FileTimestamp C617.1).
- [x] **Purpose strings**: `NSPhotoLibraryUsageDescription` presente.
- [x] **Export compliance**: `ITSAppUsesNonExemptEncryption = NO`.
- [x] **Catálogo de strings** (`Lumina/Localizable.xcstrings`) con
      `SWIFT_EMIT_LOC_STRINGS = YES` y
      `LOCALIZATION_PREFERS_STRING_CATALOGS = YES`. Xcode lo llena al
      compilar.
- [x] **Development region**: `es`. Idioma único: Español (México).
- [x] **Apple Intelligence graceful degradation**: la pestaña Buddy
      y las tarjetas AI se ocultan en dispositivos no elegibles
      (`AICapabilityGate.shouldHideAIEntirely`).
- [x] **Aviso de privacidad in-app** (Ajustes → Aviso de privacidad).
- [x] **Referencias bibliográficas in-app** (Ajustes → Referencias).
- [x] **Buddy disclaimer** al primer uso con advertencia explícita de IA.
- [x] **Quick Actions** (test, Buddy, nueva historia, resultados).
- [x] **Review prompt** tras 5+ acciones significativas, una vez por
      versión, ≥ 3 días desde instalación.
- [x] **Notificaciones locales** con permiso + aniversarios/recuerdos de
      historias con foto adjunta.

## Queda para App Store Connect / diseño

- [ ] **App Icon 1024×1024**. El asset catalog ya tiene el slot
      (`AppIcon`); sube la PNG final.
- [ ] **Capturas de pantalla** iPhone 6.9" y 5.5", iPad 13" y 12.9":
      Test, Resultados top-3, Evolución, Buddy, Historias, Ajustes.
      Todas en español.
- [ ] **Nombre de la app**: Lumina.
- [ ] **Subtítulo** (máx. 30 car.): "Descubre tus 24 fortalezas".
- [ ] **Descripción**: resalta Apple Intelligence on-device, privacidad,
      VIA Character Strengths, Colegio Walden Dos de México.
- [ ] **Keywords**: fortalezas, VIA, carácter, bienestar, psicología
      positiva, Walden, coaching, reflexión, estudiante, escuela.
- [ ] **Categoría**: Salud y forma física (primaria). Educación
      (secundaria) opcional.
- [ ] **Age rating**: 4+.
- [ ] **URL de soporte**: página del colegio.
- [ ] **URL de política de privacidad**: apuntar a una copia pública
      del texto que está en `Features/Legal/PrivacyPolicyView.swift`.
- [ ] **App Privacy labels** (en App Store Connect → Privacy):
      - Data Not Collected → Sí.
      - Data Used to Track You → No.
- [ ] **Review notes** para el revisor (en la sección Notes):
      > Lumina es una app de fortalezas de carácter (VIA) para el
      > Colegio Walden Dos de México. Todo el procesamiento de IA
      > ocurre en el dispositivo vía Foundation Models (iOS 26). El
      > revisor puede probar Buddy y los insights en un dispositivo
      > con Apple Intelligence habilitado (iPhone 15 Pro o superior).
      > En dispositivos sin Apple Intelligence, la pestaña Buddy y
      > las tarjetas AI no aparecen — esto es comportamiento esperado.
- [ ] **Demo account**: no requerido (la app no tiene login).
- [ ] **TestFlight build** antes de enviar a revisión.

## Guidelines Apple tocados explícitamente

- **1.1 Objectionable Content**: n/a.
- **2.1 App Completeness**: sin placeholders. Verificado.
- **2.5.1 Software Requirements**: uso correcto de API públicas,
      incluido `@Environment(\.requestReview)` y `SystemLanguageModel`.
- **3.1 Payments**: n/a, app gratuita sin IAP.
- **4.0 Design / 4.2.6 Spam**: n/a.
- **5.1.1 Data Collection and Storage**: privacy manifest y aviso
      de privacidad coherentes con lo que la app hace (nada).
- **5.1.2 Data Use and Sharing**: n/a, la app no comparte datos.
- **5.2 Intellectual Property**: referencias bibliográficas APA-7 de
      la clasificación VIA Character Strengths, atribuidas a Peterson,
      Seligman, Park, Niemiec y al VIA Institute on Character.
- **Foundation Models acceptable-use**: Buddy incluye disclaimer
      obligatorio al primer uso + banda permanente "Respuestas
      generadas por IA. Pueden equivocarse." + aclaración "no
      sustituye valoración de un profesional" explícita.

## Verificación manual sugerida antes de archivar

1. `xcodebuild -scheme Lumina -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=26.0' build`.
2. Lo mismo con `name=iPad Pro 11-inch (M4)`.
3. Instalar en dispositivo físico con Apple Intelligence.
4. Instalar en dispositivo físico sin Apple Intelligence (p. ej.
   iPhone 13) y confirmar que la pestaña Buddy desaparece.
5. Probar los 4 Quick Actions desde la pantalla de inicio (long-press
   del ícono).
6. Crear una historia con foto, verificar que se agendan notificaciones
   (`UNUserNotificationCenter.current().getPendingNotificationRequests`).
7. Hacer un segundo test y confirmar que aparece la tarjeta "Ver
   evolución" con las 3 gráficas.
