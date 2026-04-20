#if DEBUG
import SwiftUI
import SwiftData

/// DEBUG-only Settings section for populating the app with demo content
/// ahead of App Store screenshot capture. Never surfaces in release builds.
struct ScreenshotSection: View {
    @AppStorage(ScreenshotMode.storageKey) private var isScreenshotMode = false
    @Environment(\.modelContext) private var modelContext
    @State private var banner: String?

    var body: some View {
        Section {
            Toggle("Modo screenshots", isOn: $isScreenshotMode)

            Button {
                seed()
            } label: {
                Label("Poblar datos de demo", systemImage: "sparkles")
            }

            Button(role: .destructive) {
                clear()
            } label: {
                Label("Limpiar datos de demo", systemImage: "trash")
            }

            if let banner {
                Text(banner)
                    .font(Theme.captionFont)
                    .foregroundStyle(Theme.secondaryText)
            }
        } header: {
            Label("Screenshots (DEBUG)", systemImage: "camera.viewfinder")
                .foregroundStyle(Theme.gold)
        } footer: {
            Text("Solo visible en compilaciones de depuración. Activa el modo y pulsa \"Poblar\" para llenar la app con contenido realista para las capturas de pantalla. La sesión de IA real queda desactivada mientras el modo esté activo.")
        }
    }

    private func seed() {
        ScreenshotSeeder.seed(container: modelContext.container)
        banner = "Datos poblados. Reinicia la app si alguna pestaña no refleja el cambio."
    }

    private func clear() {
        ScreenshotSeeder.clear(container: modelContext.container)
        banner = "Datos de demo eliminados."
    }
}
#endif
