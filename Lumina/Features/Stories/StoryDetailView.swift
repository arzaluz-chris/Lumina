import SwiftUI
import SwiftData
import os

/// Read-only detail view for a single story. Supports deleting the
/// story from the nav bar.
struct StoryDetailView: View {
    let story: Story

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var image: UIImage?
    @State private var isShowingDeleteConfirmation = false

    private var strength: Strength? {
        StrengthsCatalog.strength(id: story.strengthID)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.spacingL) {
                if let strength {
                    HStack(spacing: Theme.spacingM) {
                        Image(systemName: strength.iconSF)
                            .font(.title)
                            .foregroundStyle(Theme.accent)
                            .frame(width: 56, height: 56)
                            .background(Circle().fill(Theme.accent.opacity(0.12)))
                        VStack(alignment: .leading, spacing: Theme.spacingXS) {
                            Text(strength.nameES)
                                .font(Theme.headlineFont)
                            Text(story.createdAt.formatted(date: .long, time: .shortened))
                                .font(Theme.captionFont)
                                .foregroundStyle(Theme.secondaryText)
                        }
                    }
                }

                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))
                }

                CardContainer {
                    Text(story.body)
                        .font(Theme.bodyFont)
                        .foregroundStyle(Theme.primaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(Theme.spacingL)
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle(strength?.nameES ?? "Historia")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .destructiveAction) {
                Button(role: .destructive) {
                    isShowingDeleteConfirmation = true
                } label: {
                    Image(systemName: "trash")
                }
            }
        }
        .confirmationDialog(
            "¿Eliminar esta historia?",
            isPresented: $isShowingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Eliminar", role: .destructive, action: delete)
            Button("Cancelar", role: .cancel) { }
        }
        .task {
            if let filename = story.photoFilename {
                image = PhotoStore.loadImage(filename: filename)
            }
        }
    }

    private func delete() {
        Logger.stories.info("=== DELETING STORY (id: \(story.id)) ===")
        if let filename = story.photoFilename {
            Logger.stories.debug("Deleting attached photo: \(filename)")
            PhotoStore.delete(filename: filename)
        }
        modelContext.delete(story)
        try? modelContext.save()
        Logger.stories.info("Story deleted from SwiftData")
        dismiss()
    }
}
