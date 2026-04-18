import SwiftUI
import SwiftData

/// Read-only detail view for a single story. Supports deleting the
/// story from the nav bar.
///
/// Redesign (2026-04-17): optional photo takes the lead as a full-bleed
/// rounded hero; the strength header uses virtue color + gradient badge;
/// the body text sits in a CardContainer.
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
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 260)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: Theme.heroRadius, style: .continuous))
                        .luminaShadow(Theme.shadowElevated)
                }

                if let strength {
                    HStack(spacing: Theme.spacingM) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(strength.categoryColor.gradient)
                                .frame(width: 64, height: 64)
                                .luminaShadow(Theme.shadowCard)
                            Image(systemName: strength.iconSF)
                                .font(.title.weight(.semibold))
                                .foregroundStyle(.white)
                        }
                        VStack(alignment: .leading, spacing: Theme.spacingXS) {
                            Text(Theme.virtueCategory(for: strength.id).nameES)
                                .font(Theme.captionFont.weight(.heavy))
                                .foregroundStyle(strength.categoryColor)
                                .textCase(.uppercase)
                            Text(strength.nameES)
                                .font(Theme.heroFont)
                                .foregroundStyle(Theme.primaryText)
                            Text(story.createdAt.formatted(date: .long, time: .shortened))
                                .font(Theme.captionFont)
                                .foregroundStyle(Theme.secondaryText)
                        }
                        Spacer()
                    }
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
                        .foregroundStyle(Theme.danger)
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
        if let filename = story.photoFilename {
            PhotoStore.delete(filename: filename)
        }
        // Cancel any pending "on this day" / memory reminders before
        // removing the record so we don't leak stale notifications.
        StoryReminderScheduler.cancelAll(for: story.id)
        modelContext.delete(story)
        try? modelContext.save()
        dismiss()
    }
}
