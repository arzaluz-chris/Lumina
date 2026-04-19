import SwiftUI

/// Full privacy policy screen, reachable from Settings.
///
/// Deliberately long-form and written in plain Spanish (es-MX). Content
/// mirrors the factual guarantees encoded in `PrivacyInfo.xcprivacy`:
/// no tracking, no collected data, no third-party servers. Apple reviews
/// this kind of text against the app's declared privacy labels; keeping
/// them aligned avoids review friction.
struct PrivacyPolicyView: View {
    private static let effectiveDate: String = "18 de abril de 2026"
    private static let contactEmail: String = "eduardogarcia@waldendos.edu.mx"

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.spacingL) {
                header

                section(
                    title: "Responsable del tratamiento",
                    body: "Colegio Walden Dos de México (Walden Dos), con domicilio en México, es el responsable de la aplicación Lumina. Puedes contactarnos en \(Self.contactEmail)."
                )

                section(
                    title: "Qué datos recolectamos",
                    body: "Ninguno. Lumina no envía a servidores propios ni de terceros tus respuestas al test, tus historias, tus conversaciones con Buddy ni tus fotos. Todo queda dentro del sandbox de la app en tu dispositivo."
                )

                section(
                    title: "Procesamiento en el dispositivo",
                    body: "Las respuestas de análisis, las reflexiones diarias y las conversaciones con Buddy se generan con Apple Intelligence y el framework Foundation Models, que se ejecutan completamente en tu iPhone o iPad. Apple no recibe ni almacena estos datos; nosotros tampoco."
                )

                section(
                    title: "Notificaciones locales",
                    body: "Si las activas, Lumina programa recordatorios (tips diarios, aniversarios de historias, re-test) usando el sistema de notificaciones locales de iOS. La decisión de entregarlas la toma tu dispositivo; no hay servidores de push involucrados."
                )

                section(
                    title: "Fotos",
                    body: "Cuando adjuntas una foto a una historia, la guardamos dentro del contenedor privado de la aplicación. Nunca se envía fuera de tu dispositivo. Al borrar la historia, la foto se elimina del almacenamiento de la app."
                )

                section(
                    title: "Tus derechos",
                    body: "Puedes borrar todos tus datos en cualquier momento desde Ajustes → Datos → Borrar todo. En términos de la Ley Federal de Protección de Datos Personales en Posesión de los Particulares (México), conservas los derechos ARCO (acceso, rectificación, cancelación y oposición). Como no almacenamos tus datos fuera de tu dispositivo, puedes ejercer cancelación y oposición borrando la app o usando la opción anterior."
                )

                section(
                    title: "Menores de edad",
                    body: "Lumina es utilizada por estudiantes y familias del Colegio Walden Dos de México. La app no requiere crear cuenta y no recoge información personal identificable. Recomendamos que niñas y niños usen la app con acompañamiento de un adulto responsable."
                )

                section(
                    title: "Cambios a este aviso",
                    body: "Si modificamos este aviso, actualizaremos la fecha de vigencia al inicio del documento y comunicaremos el cambio en la siguiente actualización de la app."
                )

                section(
                    title: "Contacto",
                    body: "Cualquier duda sobre privacidad o tratamiento de datos: \(Self.contactEmail)."
                )

                footer
            }
            .padding(Theme.spacingL)
            .adaptiveReadableWidth()
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle("Aviso de privacidad")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Subviews

    private var header: some View {
        VStack(alignment: .leading, spacing: Theme.spacingS) {
            Text("Aviso de privacidad")
                .font(Theme.titleFont)
                .foregroundStyle(Theme.primaryText)
            Text("Vigente desde el \(Self.effectiveDate).")
                .font(Theme.captionFont)
                .foregroundStyle(Theme.secondaryText)
        }
    }

    private func section(title: LocalizedStringKey, body: LocalizedStringKey) -> some View {
        VStack(alignment: .leading, spacing: Theme.spacingS) {
            Text(title)
                .font(Theme.headlineFont)
                .foregroundStyle(Theme.primaryText)
            Text(body)
                .font(Theme.bodyFont)
                .foregroundStyle(Theme.primaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var footer: some View {
        Text("Lumina se construye para acompañarte en el descubrimiento de tus fortalezas de carácter, no para recolectar información sobre ti.")
            .font(Theme.captionFont)
            .italic()
            .foregroundStyle(Theme.secondaryText)
            .padding(.top, Theme.spacingM)
    }
}

#Preview {
    NavigationStack {
        PrivacyPolicyView()
    }
}
