import SwiftUI
import SwiftData

/// Settings section for data management — export and delete.
struct DataSection: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var showDeleteConfirmation = false

    var body: some View {
        Section {
            Button(role: .destructive) {
                showDeleteConfirmation = true
            } label: {
                Label("Eliminar todos los datos", systemImage: "trash")
            }
        } header: {
            Label("Datos", systemImage: "externaldrive")
                .foregroundStyle(Theme.danger)
        } footer: {
            Text("Eliminar los datos borra tus resultados, historias y conversaciones de forma permanente.")
        }
        .confirmationDialog(
            "¿Eliminar todos los datos?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Eliminar todo", role: .destructive) {
                deleteAll()
            }
        } message: {
            Text("Esta acción no se puede deshacer. Se borrarán tus resultados, historias y conversaciones.")
        }
    }

    private func deleteAll() {
        do {
            try modelContext.delete(model: TestResult.self)
            try modelContext.delete(model: Story.self)
            try modelContext.delete(model: Conversation.self)
            try modelContext.delete(model: AIInsight.self)
            try modelContext.save()
            hasCompletedOnboarding = false
        } catch { }
    }
}
