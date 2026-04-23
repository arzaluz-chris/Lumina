# Lumina — App Store Submission Checklist

Resumen de lo que el proyecto ya trae configurado y lo que queda por hacer
manualmente en App Store Connect antes de enviar a revisión.

## Ya resuelto en código

- [x] **App Icon 1024×1024 PNG RGB opaco** (`Assets.xcassets/AppIcon.appiconset/AppIcon.png`), con variantes Dark y Tinted.
- [x] **iOS 26 deployment target** (`IPHONEOS_DEPLOYMENT_TARGET = 26.0`).
- [x] **Universal** (`TARGETED_DEVICE_FAMILY = "1,2"`). iPhone + iPad.
- [x] **Orientaciones iPad**: portrait, portrait-upside-down, landscape L/R.
- [x] **Privacy manifest** (`Lumina/PrivacyInfo.xcprivacy`): 0 tracking, 0
      datos recolectados, Required Reason APIs declarados (UserDefaults
      CA92.1, FileTimestamp C617.1).
- [x] **Purpose strings**: ninguno requerido. La app usa `PhotosPicker`
      (sandboxed) para fotos — no requiere
      `NSPhotoLibraryUsageDescription`. TTS es output-only
      (`AVSpeechSynthesizer`), no accede al micrófono.
- [x] **Accesibilidad**: VoiceOver labels en controles clave,
      botones "Leer en voz alta" en Test / Resultados / Historias /
      Onboarding / Buddy, auto-lectura de preguntas en el Test
      (Ajustes → Accesibilidad). Tap targets ≥ 44pt garantizados
      (incluido el `ReadAloudButton.small`, que expande el hit area
      sin agrandar el glifo). Dynamic Type con tope razonable en
      pantallas con tipografía de despliegue fija (splash,
      onboarding, quiz, detalle de fortaleza) para evitar roturas
      en AX5.
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
- [x] **Referencias bibliográficas in-app** con URLs tocables a las
      fuentes (VIA Institute, DOI del paper de Park et al. 2004, OUP,
      Hogrefe). Ajustes → Referencias.
- [x] **"Sobre esta app"** (Ajustes → Sobre esta app): disclaimer
      educativo explícito + enlaces directos a Referencias y Aviso de
      privacidad.
- [x] **Onboarding con paso "Una herramienta educativa"** que establece
      propósito no-diagnóstico antes del test.
- [x] **Disclaimer visible en cada superficie IA** (Análisis
      personalizado, Reflexión del día): banda que enlaza a Referencias.
- [x] **Buddy disclaimer** al primer uso con advertencia explícita de IA.
- [x] **Quick Actions** (test, Buddy, nueva historia, resultados).
- [x] **Review prompt** tras 5+ acciones significativas, una vez por
      versión, ≥ 3 días desde instalación.
- [x] **Notificaciones locales** con permiso + aniversarios/recuerdos de
      historias con foto adjunta.

## Queda para App Store Connect / diseño

- [ ] **Capturas de pantalla** iPhone 6.9" y 5.5", iPad 13" y 12.9":
      Test, Resultados top-3, Evolución, Buddy, Historias, Ajustes.
      Todas en español.
- [ ] **Nombre de la app**: Lumina.
- [ ] **Subtítulo** (máx. 30 car.): "Explora tus 24 fortalezas".
- [ ] **Descripción**: herramienta educativa basada en VIA Character
      Strengths; resalta Apple Intelligence on-device, privacidad
      total y uso escolar. **Debe terminar con el disclaimer**:
      > "Aviso importante. Lumina es una herramienta educativa. No
      > ofrece diagnóstico, tratamiento ni consejo médico o
      > psicológico. Consulta siempre a un profesional de la salud
      > antes de tomar decisiones sobre tu bienestar o el de un menor
      > bajo tu cuidado."
- [ ] **Keywords**: fortalezas, VIA, educación, carácter, psicología
      positiva, Walden, reflexión, estudiante, escuela, familia.
- [ ] **Categoría**: **Educación (primaria)**. Estilo de vida
      (secundaria) opcional. Coincide con
      `INFOPLIST_KEY_LSApplicationCategoryType = public.app-category.education`.
- [ ] **Made for Kids / Kids Category**: **desmarcado**. La app no está
      diseñada para niños de 11 años o menos (Guideline 1.3).
- [ ] **Age rating**: 4+.
- [ ] **URL de soporte**: página del colegio.
- [ ] **URL de política de privacidad**: apuntar a una copia pública
      del texto que está en `Features/Legal/PrivacyPolicyView.swift`.
- [ ] **App Privacy labels** (en App Store Connect → Privacy):
      - Data Not Collected → Sí.
      - Data Used to Track You → No.
- [ ] **Review notes** para el revisor (en la sección Notes):
      > Lumina es una **app educativa** de fortalezas de carácter (VIA)
      > para el Colegio Walden Dos de México. Público objetivo:
      > adolescentes, adultos jóvenes, familias y docentes. **No está
      > dirigida a menores de 11** y no solicita la categoría Kids.
      >
      > La app no ofrece diagnóstico, tratamiento ni consejo médico o
      > psicológico. No tenemos ni requerimos regulatory clearance
      > porque no se hacen afirmaciones médicas. El disclaimer aparece:
      > (1) al final de la descripción en App Store, (2) en un paso
      > dedicado del onboarding ("Una herramienta educativa"), (3) en
      > Ajustes → "Sobre esta app", y (4) en una banda visible debajo
      > de cada tarjeta con contenido generado por IA (análisis
      > personalizado, reflexión del día, chat Buddy).
      >
      > Todas las referencias bibliográficas (Peterson & Seligman 2004,
      > Niemiec 2018, Park et al. 2004, VIA Institute, Skinner 1948)
      > están en Ajustes → Referencias, con enlaces tocables a la
      > fuente. Cada banda de IA tiene un acceso directo a esa
      > pantalla.
      >
      > Todo el procesamiento de IA ocurre en el dispositivo vía
      > Foundation Models (iOS 26). El revisor puede probar Buddy y
      > los insights en un dispositivo con Apple Intelligence habilitado
      > (iPhone 15 Pro o superior). En dispositivos sin Apple
      > Intelligence, la pestaña Buddy y las tarjetas AI no aparecen —
      > comportamiento esperado.
      >
      > La app usa `AVSpeechSynthesizer` con `AVAudioSession`
      > `.playback + .duckOthers` para la función opcional "Leer en
      > voz alta" (accesibilidad / Dynamic Type). Esto permite que la
      > narración se oiga aunque el dispositivo esté en silencio. No
      > hay reproducción en segundo plano y la narración se detiene al
      > salir de la pantalla. Se puede desactivar en Ajustes →
      > Accesibilidad.
- [ ] **Demo account**: no requerido (la app no tiene login).
- [ ] **TestFlight build** antes de enviar a revisión.
- [ ] **Reply al reviewer** en Resolution Center: ver
      `.claude/plans/spicy-foraging-plum.md` sección 3 para el borrador
      bilingüe (ES + EN) punto por punto contra los tres hallazgos de la
      submission 1b55ff81.

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
- **1.5 Developer Information / 2.3 Accurate Metadata**: créditos en
      Ajustes → Acerca de, vigencia del aviso de privacidad y correo
      de contacto en la pantalla "Aviso de privacidad".

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
