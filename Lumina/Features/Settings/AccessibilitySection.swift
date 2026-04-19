import SwiftUI

/// Settings section grouping the read-aloud / VoiceOver-complementary
/// toggles. Added 2026-04-18 so kids, pre-readers, and anyone who prefers
/// to hear content aloud can tailor the app without enabling the system
/// screen reader.
struct AccessibilitySection: View {
    /// Master switch for every ``ReadAloudButton`` in the app. When off,
    /// the buttons render dimmed and ``SpeechService.speak(_:id:)`` is a
    /// no-op.
    @AppStorage("readAloudEnabled") private var readAloudEnabled: Bool = true

    /// When on (default), the quiz reads each question aloud as soon as
    /// the card appears — the main affordance for children who can't
    /// read the prompts on their own.
    @AppStorage("quizAutoReadEnabled") private var quizAutoReadEnabled: Bool = true

    var body: some View {
        Section {
            Toggle(isOn: $readAloudEnabled) {
                Label("Leer en voz alta", systemImage: "speaker.wave.2.fill")
            }
            .onChange(of: readAloudEnabled) { _, newValue in
                // Keep the shared service in sync so in-flight playback
                // stops immediately when the user flips the master
                // toggle off.
                SpeechService.shared.isEnabled = newValue
            }

            Toggle(isOn: $quizAutoReadEnabled) {
                Label("Leer preguntas del test automáticamente", systemImage: "text.bubble.fill")
            }
            .disabled(!readAloudEnabled)
        } header: {
            Label("Accesibilidad", systemImage: "figure.wave.circle.fill")
                .foregroundStyle(Theme.VirtueCategory.humanity.color)
        } footer: {
            Text("Para niños y personas que aún no leen: Lumina puede leer en voz alta las preguntas, historias y respuestas de Buddy. También funciona con VoiceOver.")
        }
    }
}

#Preview {
    Form {
        AccessibilitySection()
    }
}
