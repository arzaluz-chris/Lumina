import SwiftUI
import SwiftData
import PhotosUI
import os

/// Create a new strength-tied story. Supports text, an optional photo
/// from the user's library, and requires the user to pick a strength.
struct StoryEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var storyText: String = ""
    @State private var selectedStrengthID: String = StrengthsCatalog.all.first?.id ?? ""
    @State private var photoItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Fortaleza") {
                    Picker("Fortaleza", selection: $selectedStrengthID) {
                        ForEach(StrengthsCatalog.all) { strength in
                            Label(strength.nameES, systemImage: strength.iconSF)
                                .tag(strength.id)
                        }
                    }
                    .pickerStyle(.menu)
                }

                Section("Tu historia") {
                    TextEditor(text: $storyText)
                        .frame(minHeight: 160)
                        .font(Theme.bodyFont)
                }

                Section("Foto (opcional)") {
                    PhotosPicker(selection: $photoItem, matching: .images) {
                        Label(
                            selectedImage == nil ? "Agregar foto" : "Cambiar foto",
                            systemImage: "photo.on.rectangle.angled"
                        )
                    }
                    if let selectedImage {
                        Image(uiImage: selectedImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 200)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.chipRadius))
                    }
                }
            }
            .navigationTitle("Nueva historia")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar", action: save)
                        .disabled(storyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSaving)
                }
            }
            .onChange(of: photoItem) { _, newItem in
                Task { await loadImage(from: newItem) }
            }
        }
    }

    private func loadImage(from item: PhotosPickerItem?) async {
        guard let item else { return }
        if let data = try? await item.loadTransferable(type: Data.self),
           let image = UIImage(data: data) {
            selectedImage = image
        }
    }

    private func save() {
        Logger.stories.info("=== SAVING STORY ===")
        Logger.stories.debug("Strength: \(selectedStrengthID), text length: \(storyText.count), has photo: \(selectedImage != nil)")
        isSaving = true
        var photoFilename: String?
        if let selectedImage {
            photoFilename = try? PhotoStore.save(selectedImage)
            Logger.stories.info("Photo saved as: \(photoFilename ?? "FAILED")")
        }

        let story = Story(
            body: storyText.trimmingCharacters(in: .whitespacesAndNewlines),
            strengthID: selectedStrengthID,
            photoFilename: photoFilename
        )
        modelContext.insert(story)
        try? modelContext.save()
        Logger.stories.info("Story saved (id: \(story.id), strength: \(selectedStrengthID))")
        dismiss()
    }
}
