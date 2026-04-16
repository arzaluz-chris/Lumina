import SwiftUI

/// Settings section for customizing Buddy's AI personality.
struct AIPersonalitySection: View {
    @AppStorage("aiTone") private var aiTone = "calida"
    @AppStorage("aiLength") private var aiLength = "media"

    var body: some View {
        Section {
            Picker("Tono", selection: $aiTone) {
                Text("Cálida").tag("calida")
                Text("Concisa").tag("concisa")
                Text("Motivadora").tag("motivadora")
                Text("Analítica").tag("analitica")
            }
            Picker("Longitud de respuestas", selection: $aiLength) {
                Text("Corta").tag("corta")
                Text("Media").tag("media")
                Text("Larga").tag("larga")
            }
        } header: {
            Label("Personalidad de Buddy", systemImage: "sparkles")
        } footer: {
            Text("Estos ajustes definen cómo Buddy responde a tus preguntas. Los cambios aplican en la siguiente conversación.")
        }
    }
}
