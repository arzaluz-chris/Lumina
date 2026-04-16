import SwiftUI
import SwiftData

/// Sheet listing past Buddy conversations, sorted by most recent first.
/// Allows loading a past conversation or starting a new one.
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
                    }
                }
            }
        }
    }

    private var list: some View {
        ScrollView {
            LazyVStack(spacing: Theme.spacingS) {
                ForEach(conversations) { conversation in
                    Button {
                        onSelect(conversation)
                        dismiss()
                    } label: {
                        CardContainer(padding: Theme.spacingM) {
                            VStack(alignment: .leading, spacing: Theme.spacingXS) {
                                Text(conversation.title)
                                    .font(Theme.subheadFont)
                                    .foregroundStyle(Theme.primaryText)
                                    .lineLimit(1)
                                HStack {
                                    Text(conversation.updatedAt.formatted(date: .abbreviated, time: .shortened))
                                        .font(Theme.captionFont)
                                        .foregroundStyle(Theme.secondaryText)
                                    Spacer()
                                    Text("\(conversation.messages.count) mensajes")
                                        .font(Theme.captionFont)
                                        .foregroundStyle(Theme.secondaryText)
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
        VStack(spacing: Theme.spacingL) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 56))
                .foregroundStyle(Theme.secondaryText)
            Text("Sin conversaciones aún")
                .font(Theme.headlineFont)
            Text("Inicia una nueva conversación con Buddy.")
                .font(Theme.bodyFont)
                .foregroundStyle(Theme.secondaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(Theme.spacingL)
    }
}
