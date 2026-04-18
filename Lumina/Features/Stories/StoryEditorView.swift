import SwiftUI
import SwiftData
import PhotosUI
import FoundationModels
import StoreKit

/// Create a new strength-tied story. Supports text, an optional photo
/// from the user's library, and requires the user to pick a strength.
/// Includes an AI-powered writing prompt suggestion.
///
/// Redesign (2026-04-17): preserves the Form structure but adds a glass
/// AI prompt card with a soft glow while generating, and a larger photo
/// preview with rounded corners.
struct StoryEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.requestReview) private var requestReview

    @State private var storyText: String = ""
    @State private var selectedStrengthID: String = StrengthsCatalog.all.first?.id ?? ""
    @State private var photoItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var isSaving = false
    @State private var storyDate: Date = Date()
    @State private var aiPrompt: String?
    @State private var isGeneratingPrompt = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Fortaleza", selection: $selectedStrengthID) {
                        ForEach(StrengthsCatalog.all) { strength in
                            Label(strength.nameES, systemImage: strength.iconSF)
                                .tag(strength.id)
                        }
                    }
                    .pickerStyle(.menu)
                } header: {
                    Label("Fortaleza", systemImage: "tag.fill")
                }

                Section {
                    if let prompt = aiPrompt {
                        HStack(alignment: .top, spacing: Theme.spacingS) {
                            Image(systemName: "sparkles")
                                .foregroundStyle(Theme.gold)
                            Text(prompt)
                                .font(Theme.captionFont)
                                .foregroundStyle(Theme.secondaryText)
                                .italic()
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(Theme.spacingS)
                        .background(
                            RoundedRectangle(cornerRadius: Theme.chipRadius, style: .continuous)
                                .fill(Theme.gold.opacity(0.10))
                        )
                        .aiGlow(isActive: isGeneratingPrompt)
                        .listRowInsets(EdgeInsets(
                            top: Theme.spacingS,
                            leading: Theme.spacingM,
                            bottom: Theme.spacingS,
                            trailing: Theme.spacingM
                        ))
                    }

                    TextEditor(text: $storyText)
                        .frame(minHeight: 180)
                        .font(Theme.bodyFont)

                    Button {
                        Task { await generateWritingPrompt() }
                    } label: {
                        HStack(spacing: Theme.spacingS) {
                            if isGeneratingPrompt {
                                ProgressView()
                                    .controlSize(.small)
                            } else {
                                Image(systemName: "sparkles")
                            }
                            Text(aiPrompt == nil ? "Sugiéreme una historia" : "Otra sugerencia")
                        }
                        .font(Theme.captionFont.weight(.semibold))
                        .foregroundStyle(Theme.accent)
                    }
                    .disabled(isGeneratingPrompt)
                } header: {
                    Label("Tu historia", systemImage: "text.quote")
                }

                Section {
                    DatePicker(
                        "Fecha",
                        selection: $storyDate,
                        in: ...Date(),
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .datePickerStyle(.compact)
                } header: {
                    Label("Fecha y hora", systemImage: "calendar")
                }

                Section {
                    PhotosPicker(selection: $photoItem, matching: .images) {
                        Label(
                            selectedImage == nil ? "Agregar foto" : "Cambiar foto",
                            systemImage: "photo.on.rectangle.angled"
                        )
                    }
                    if let selectedImage {
                        Image(uiImage: selectedImage)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 220)
                            .frame(maxWidth: .infinity)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
                                    .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                            )
                    }
                } header: {
                    Label("Foto (opcional)", systemImage: "photo.stack.fill")
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
                        .fontWeight(.semibold)
                        .disabled(storyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSaving)
                }
            }
            .onChange(of: photoItem) { _, newItem in
                Task { await loadImage(from: newItem) }
            }
            .sensoryFeedback(.success, trigger: isSaving)
        }
    }

    private func loadImage(from item: PhotosPickerItem?) async {
        guard let item else { return }
        if let data = try? await item.loadTransferable(type: Data.self),
           let image = UIImage(data: data) {
            selectedImage = image
        }
    }

    private static let fallbackPrompts: [String: String] = [
        "creatividad": "¿En qué momento reciente resolviste algo de una forma original o inesperada?",
        "curiosidad": "¿Qué descubriste recientemente que te haya sorprendido o fascinado?",
        "juicio": "¿Cuándo fue la última vez que analizaste una situación desde varios ángulos antes de decidir?",
        "amor_aprendizaje": "¿Qué aprendiste recientemente que te haya entusiasmado compartir?",
        "perspectiva": "¿Alguien te pidió consejo recientemente? ¿Qué le dijiste?",
        "valentia": "¿En qué momento reciente actuaste a pesar de sentir miedo o incertidumbre?",
        "perseverancia": "¿Qué proyecto o meta seguiste adelante aunque fue difícil?",
        "honestidad": "¿Cuándo elegiste ser transparente aunque hubiera sido más fácil no serlo?",
        "coraje": "¿En qué momento defendiste algo en lo que crees?",
        "amor": "¿Cómo expresaste cariño o cercanía con alguien importante esta semana?",
        "bondad": "¿Qué acto de generosidad hiciste recientemente, por pequeño que fuera?",
        "inteligencia_social": "¿Cuándo percibiste lo que alguien necesitaba sin que te lo dijera?",
        "humanidad": "¿En qué momento conectaste profundamente con otra persona?",
        "trabajo_equipo": "¿Cómo contribuiste al éxito de un grupo o equipo recientemente?",
        "justicia": "¿Cuándo te aseguraste de que todos fueran tratados de forma equitativa?",
        "liderazgo": "¿En qué situación tomaste la iniciativa para guiar a otros?",
        "perdon": "¿Cuándo elegiste soltar un resentimiento o dar una segunda oportunidad?",
        "prudencia": "¿En qué momento tu cautela te protegió de una mala decisión?",
        "autorregulacion": "¿Cuándo lograste mantener la calma o el control en una situación difícil?",
        "apreciacion_belleza": "¿Qué momento de belleza cotidiana te detuvo recientemente?",
        "gratitud": "¿Por qué pequeño detalle te sentiste agradecido hoy o esta semana?",
        "esperanza": "¿Qué te hace sentir optimista sobre el futuro en este momento?",
        "humor": "¿Cuándo tu sentido del humor alivió una situación tensa o difícil?",
        "espiritualidad": "¿En qué momento sentiste que algo más grande le daba sentido a tu día?",
    ]

    private func generateWritingPrompt() async {
        guard case .available = SystemLanguageModel.default.availability else {
            aiPrompt = Self.fallbackPrompts[selectedStrengthID]
            return
        }
        let strengthName = StrengthsCatalog.strength(id: selectedStrengthID)?.nameES ?? selectedStrengthID

        isGeneratingPrompt = true
        defer { isGeneratingPrompt = false }

        do {
            let session = LanguageModelSession(
                model: .default,
                instructions: Instructions(
                    "Eres un asistente de escritura reflexiva enfocado en psicología positiva y fortalezas de carácter VIA. " +
                    "Tu tarea es sugerir una pregunta reflexiva breve (1-2 oraciones) en español que inspire al usuario a " +
                    "recordar una experiencia cotidiana positiva relacionada con la fortaleza de carácter '\(strengthName)'. " +
                    "Ejemplo de tono: '¿Recuerdas algún momento esta semana donde tu curiosidad te llevó a aprender algo nuevo?'. " +
                    "Solo responde con la pregunta, sin explicaciones adicionales."
                )
            )
            let response = try await session.respond(to: "Sugiere una pregunta reflexiva sobre la fortaleza \(strengthName).")
            aiPrompt = response.content.trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            aiPrompt = Self.fallbackPrompts[selectedStrengthID]
        }
    }

    private func save() {
        isSaving = true
        var photoFilename: String?
        if let selectedImage {
            photoFilename = try? PhotoStore.save(selectedImage)
        }

        let story = Story(
            createdAt: storyDate,
            body: storyText.trimmingCharacters(in: .whitespacesAndNewlines),
            strengthID: selectedStrengthID,
            photoFilename: photoFilename
        )
        modelContext.insert(story)
        try? modelContext.save()

        // Schedule "On this day" anniversaries and a 90-day memory
        // reminder for this story, if the user has enabled the feature.
        StoryReminderScheduler.schedule(for: story)

        // A saved story counts as a meaningful action for the App Store
        // review prompt. Guardrails inside the coordinator decide whether
        // the prompt actually fires.
        ReviewRequestCoordinator.shared.recordMilestone(.addedStory) {
            requestReview()
        }

        dismiss()
    }
}
