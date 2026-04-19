import SwiftUI
import AVFoundation

/// Lets the user pick which voice the Read Aloud feature uses. Reachable
/// from Settings → Accesibilidad → Voz.
///
/// Apple does not expose Siri to third-party apps, so the menu lists the
/// system-installed Spanish voices (Compacta, Mejorada, Premium). The
/// "Premium" / "Enhanced" voices live behind a separate download that
/// users have to grab from iOS Settings — the footer points them there
/// because nothing the app does can substitute for that download.
struct VoicePickerView: View {
    @State private var selectedID: String? = SpeechService.shared.selectedVoiceID
    private let voices = SpeechService.availableSpanishVoices()

    /// Sample sentence played each time the user picks a different voice
    /// so they can A/B compare immediately without leaving the screen.
    private static let sample = "Hola, soy Lumina. Te leeré tus historias y las preguntas del test."

    var body: some View {
        Form {
            autoSection
            if !voices.isEmpty {
                voicesSection
            }
            installSection
        }
        .navigationTitle("Voz")
        .navigationBarTitleDisplayMode(.inline)
        .scrollContentBackground(.hidden)
        .background(Theme.heroGradient.ignoresSafeArea())
        .tint(Theme.accent)
        .onDisappear {
            SpeechService.shared.stop()
        }
    }

    // MARK: - Sections

    private var autoSection: some View {
        Section {
            voiceRow(
                title: "Automática",
                subtitle: autoSubtitle,
                isSelected: selectedID == nil,
                action: { select(nil) }
            )
        } header: {
            Label("Selección", systemImage: "wand.and.stars")
        } footer: {
            Text("Lumina elige la mejor voz instalada (Premium > Mejorada > Compacta), priorizando español de México.")
        }
    }

    private var voicesSection: some View {
        Section {
            ForEach(voices, id: \.identifier) { voice in
                voiceRow(
                    title: voice.name,
                    subtitle: subtitle(for: voice),
                    isSelected: selectedID == voice.identifier,
                    action: { select(voice.identifier) }
                )
            }
        } header: {
            Label("Voces instaladas", systemImage: "person.wave.2.fill")
        }
    }

    private var installSection: some View {
        Section {
            Link(destination: URL(string: UIApplication.openSettingsURLString)!) {
                Label("Abrir Ajustes de Lumina", systemImage: "gear")
            }
        } header: {
            Label("Más voces", systemImage: "arrow.down.circle")
        } footer: {
            Text("Para una voz casi natural, en iOS abre **Ajustes → Accesibilidad → Contenido hablado → Voces → Español** y descarga \"Premium\" o \"Mejorada\". Después regresa aquí y aparecerá en la lista.")
        }
    }

    // MARK: - Building blocks

    private func voiceRow(title: String, subtitle: String?, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .foregroundStyle(Theme.primaryText)
                    if let subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(Theme.secondaryText)
                    }
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundStyle(Theme.accent)
                        .fontWeight(.semibold)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Selection + sample playback

    private func select(_ id: String?) {
        selectedID = id
        SpeechService.shared.selectedVoiceID = id
        SpeechService.shared.speak(Self.sample)
    }

    // MARK: - Labels

    private var autoSubtitle: String {
        guard let voice = SpeechService.shared.activeVoice else {
            return "Sin voz en español instalada"
        }
        return "Ahora: \(voice.name) (\(qualityLabel(voice.quality)))"
    }

    private func subtitle(for voice: AVSpeechSynthesisVoice) -> String {
        "\(qualityLabel(voice.quality)) · \(localeLabel(voice.language))"
    }

    private func qualityLabel(_ quality: AVSpeechSynthesisVoiceQuality) -> String {
        switch quality {
        case .premium:  "Premium"
        case .enhanced: "Mejorada"
        case .default:  "Compacta"
        @unknown default: "Sistema"
        }
    }

    private func localeLabel(_ language: String) -> String {
        switch language {
        case "es-MX": "Español (México)"
        case "es-US": "Español (EE. UU.)"
        case "es-ES": "Español (España)"
        case "es-AR": "Español (Argentina)"
        case "es-CL": "Español (Chile)"
        case "es-CO": "Español (Colombia)"
        default:      Locale.current.localizedString(forIdentifier: language) ?? language
        }
    }
}

#Preview {
    NavigationStack {
        VoicePickerView()
    }
}
