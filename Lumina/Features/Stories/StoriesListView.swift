import SwiftUI
import SwiftData

/// "Historias" tab. Lists the user's strength-tied journal entries in
/// reverse chronological order with a button to add a new one.
///
/// Redesign (2026-04-17): empty state uses ``LuminaEmptyState``; each
/// story row is rebuilt as a richer card — virtue-colored strength chip,
/// body preview, and full-width photo thumbnail when present.
struct StoriesListView: View {
    @Query(sort: \Story.createdAt, order: .reverse) private var stories: [Story]
    @Environment(\.modelContext) private var modelContext
    @State private var isPresentingEditor = false

    var body: some View {
        NavigationStack {
            Group {
                if stories.isEmpty {
                    emptyState
                } else {
                    list
                }
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Historias")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        isPresentingEditor = true
                    } label: {
                        Label("Nueva historia", systemImage: "plus.circle.fill")
                            .foregroundStyle(Theme.accent)
                    }
                    .accessibilityLabel("Nueva historia")
                }
            }
            .sheet(isPresented: $isPresentingEditor) {
                StoryEditorView()
            }
        }
    }

    private var list: some View {
        ScrollView {
            LazyVStack(spacing: Theme.spacingM) {
                ForEach(stories) { story in
                    NavigationLink {
                        StoryDetailView(story: story)
                    } label: {
                        StoryRow(story: story)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(Theme.spacingL)
            .adaptiveReadableWidth()
        }
    }

    private var emptyState: some View {
        LuminaEmptyState(
            bearName: "bear_44",
            title: "Todavía no tienes historias",
            message: "Anota los momentos en los que tus fortalezas se asoman. Aquí vivirán tus relatos.",
            primaryActionTitle: "Escribir mi primera historia",
            primaryActionIcon: "plus",
            primaryAction: { isPresentingEditor = true }
        )
    }
}

private struct StoryRow: View {
    let story: Story
    @State private var thumbnail: UIImage?

    private var strength: Strength? {
        StrengthsCatalog.strength(id: story.strengthID)
    }

    var body: some View {
        CardContainer(padding: 0) {
            VStack(alignment: .leading, spacing: 0) {
                if let thumbnail {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 160)
                        .frame(maxWidth: .infinity)
                        .clipped()
                        .overlay(alignment: .topLeading) {
                            strengthBadge
                                .padding(Theme.spacingM)
                        }
                } else if story.photoFilename != nil {
                    // Photo loading placeholder
                    RoundedRectangle(cornerRadius: 0)
                        .fill(Theme.cardBackground)
                        .frame(height: 160)
                        .overlay(
                            Image(systemName: "photo.fill")
                                .font(.title)
                                .foregroundStyle(Theme.secondaryText)
                        )
                        .overlay(alignment: .topLeading) {
                            strengthBadge
                                .padding(Theme.spacingM)
                        }
                }

                VStack(alignment: .leading, spacing: Theme.spacingS) {
                    if thumbnail == nil && story.photoFilename == nil {
                        strengthBadge
                    }

                    Text(story.body.isEmpty ? "Sin descripción" : story.body)
                        .font(Theme.bodyFont)
                        .foregroundStyle(Theme.primaryText)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack {
                        Image(systemName: "clock")
                            .font(.caption2)
                        Text(story.createdAt.formatted(date: .abbreviated, time: .shortened))
                            .font(Theme.captionFont)
                    }
                    .foregroundStyle(Theme.secondaryText)
                }
                .padding(Theme.spacingM)
            }
        }
        .task {
            if let filename = story.photoFilename {
                thumbnail = PhotoStore.loadImage(filename: filename)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint("Toca para abrir la historia completa.")
    }

    private var accessibilityLabel: String {
        let strengthName = strength?.nameES ?? "Historia"
        let preview = story.body.isEmpty
            ? "Sin descripción"
            : String(story.body.prefix(120))
        let date = story.createdAt.formatted(date: .long, time: .shortened)
        return "Historia de \(strengthName). \(preview). \(date)"
    }

    @ViewBuilder
    private var strengthBadge: some View {
        if let strength {
            HStack(spacing: Theme.spacingXS) {
                Image(systemName: strength.iconSF)
                Text(strength.nameES)
            }
            .font(Theme.captionFont.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, Theme.spacingS + 2)
            .padding(.vertical, Theme.spacingXS + 2)
            .background(Capsule().fill(strength.categoryColor.gradient))
            .luminaShadow(Theme.shadowCard)
        }
    }
}
