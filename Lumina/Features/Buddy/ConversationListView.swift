import SwiftUI
import SwiftData

/// Sheet listing past Buddy conversations, sorted by most recent first.
/// Allows loading a past conversation or starting a new one.
///
/// Redesign (2026-04-17): each row gets a leading chat icon badge and a
/// message-count pill; empty state uses ``LuminaEmptyState``.
struct ConversationListView: View {
    @Query(sort: \Conversation.updatedAt, order: .reverse)
    private var conversations: [Conversation]
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let onSelect: (Conversation) -> Void
    let onNew: () -> Void

    var body: some View {
        NavigationStack {
            Group {
                if conversations.isEmpty {
                    emptyState
                } else {
                    list
                }
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Conversaciones")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        onNew()
                        dismiss()
                    } label: {
                        Label("Nueva", systemImage: "square.and.pencil")
                            .foregroundStyle(Theme.accent)
                    }
                }
            }
        }
    }

    private var list: some View {
        ScrollView {
            LazyVStack(spacing: Theme.spacingS + 2) {
                ForEach(conversations) { conversation in
                    Button {
                        onSelect(conversation)
                        dismiss()
                    } label: {
                        CardContainer(padding: Theme.spacingM) {
                            HStack(alignment: .top, spacing: Theme.spacingM) {
                                Image(systemName: "bubble.left.and.bubble.right.fill")
                                    .font(.title3.weight(.semibold))
                                    .foregroundStyle(Theme.accent)
                                    .frame(width: 44, height: 44)
                                    .background(Circle().fill(Theme.accent.opacity(0.14)))

                                VStack(alignment: .leading, spacing: Theme.spacingXS) {
                                    Text(conversation.title)
                                        .font(Theme.subheadFont)
                                        .foregroundStyle(Theme.primaryText)
                                        .lineLimit(1)
                                    HStack(spacing: Theme.spacingS) {
                                        Text(conversation.updatedAt.formatted(date: .abbreviated, time: .shortened))
                                            .font(Theme.captionFont)
                                            .foregroundStyle(Theme.secondaryText)
                                        Spacer()
                                        LuminaChip(
                                            title: "\(conversation.messages.count)",
                                            systemImage: "text.bubble",
                                            style: .accent
                                        )
                                    }
                                }
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button(role: .destructive) {
                            modelContext.delete(conversation)
                            try? modelContext.save()
                        } label: {
                            Label("Eliminar", systemImage: "trash")
                        }
                    }
                }
            }
            .padding(Theme.spacingL)
        }
    }

    private var emptyState: some View {
        LuminaEmptyState(
            bearName: "bear_10",
            title: "Sin conversaciones aún",
            message: "Inicia una nueva conversación con Buddy desde el botón arriba."
        )
    }
}
