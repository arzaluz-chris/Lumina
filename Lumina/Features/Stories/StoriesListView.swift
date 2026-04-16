import SwiftUI
import SwiftData

/// "Historias" tab. Lists the user's strength-tied journal entries in
/// reverse chronological order with a button to add a new one.
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
                        Label("Nueva historia", systemImage: "plus")
                    }
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
        }
    }

    private var emptyState: some View {
        VStack(spacing: Theme.spacingL) {
            BearImage(name: "bear_44")
                .frame(maxHeight: 220)
            Text("Todavía no tienes historias")
                .font(Theme.headlineFont)
            Text("Anota los momentos en los que tus fortalezas se asoman. Aquí vivirán tus relatos.")
                .font(Theme.bodyFont)
                .foregroundStyle(Theme.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Theme.spacingL)
            LuminaButton(title: "Escribir mi primera historia", systemImage: "plus") {
                isPresentingEditor = true
            }
            .padding(.horizontal, Theme.spacingL)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(Theme.spacingL)
    }
}

private struct StoryRow: View {
    let story: Story
    @State private var thumbnail: UIImage?

    private var strength: Strength? {
        StrengthsCatalog.strength(id: story.strengthID)
    }

    var body: some View {
        CardContainer(padding: Theme.spacingM) {
            HStack(alignment: .top, spacing: Theme.spacingM) {
                if let strength {
                    Image(systemName: strength.iconSF)
                        .font(.title2)
                        .foregroundStyle(strength.categoryColor)
                        .frame(width: 40, height: 40)
                        .background(Circle().fill(strength.categoryColor.opacity(0.12)))
                }
                VStack(alignment: .leading, spacing: Theme.spacingXS) {
                    Text(strength?.nameES ?? "Fortaleza")
                        .font(Theme.subheadFont)
                        .foregroundStyle(strength?.categoryColor ?? Theme.accent)
                    Text(story.body.isEmpty ? "Sin descripción" : story.body)
                        .font(Theme.bodyFont)
                        .foregroundStyle(Theme.primaryText)
                        .lineLimit(2)
                    Text(story.createdAt.formatted(date: .abbreviated, time: .shortened))
                        .font(Theme.captionFont)
                        .foregroundStyle(Theme.secondaryText)
                }
                Spacer()
                if let thumbnail {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 56, height: 56)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.chipRadius, style: .continuous))
                } else if story.photoFilename != nil {
                    RoundedRectangle(cornerRadius: Theme.chipRadius, style: .continuous)
                        .fill(Theme.cardBackground)
                        .frame(width: 56, height: 56)
                        .overlay(
                            Image(systemName: "photo.fill")
                                .foregroundStyle(Theme.secondaryText)
                        )
                }
            }
        }
        .task {
            if let filename = story.photoFilename {
                thumbnail = PhotoStore.loadImage(filename: filename)
            }
        }
    }
}
