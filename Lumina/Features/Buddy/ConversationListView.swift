import SwiftUI
import SwiftData

/// Sheet listing past Buddy conversations, sorted by most recent first.
/// Allows loading a past conversation, deleting one, or starting a new one.
///
/// Redesign (2026-04-17): each row gets a leading chat icon badge and a
/// message-count pill; empty state uses ``LuminaEmptyState``.
/// 2026-04-22: added explicit per-row delete UI (visible trailing menu
/// plus long-press context menu). Deleting the currently active chat is
/// forwarded to the parent via `onDelete` so it can reset the state.
struct ConversationListView: View {
    @Query(sort: \Conversation.updatedAt, order: .reverse)
    private var conversations: [Conversation]
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let onSelect: (Conversation) -> Void
    let onNew: () -> Void
    /// Called after a conversation has been deleted from the store. The
    /// parent can use this to reset its chat state if the deleted item was
    /// the one currently loaded. Optional — defaults to a no-op.
    var onDelete: (Conversation) -> Void = { _ in }

    @State private var pendingDelete: Conversation?

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
            .confirmationDialog(
                "¿Eliminar conversación?",
                isPresented: Binding(
                    get: { pendingDelete != nil },
                    set: { if !$0 { pendingDelete = nil } }
                ),
                titleVisibility: .visible,
                presenting: pendingDelete
            ) { conversation in
                Button("Eliminar", role: .destructive) {
                    delete(conversation)
                }
                Button("Cancelar", role: .cancel) {
                    pendingDelete = nil
                }
            } message: { conversation in
                Text("\"\(conversation.title)\" se borrará de forma permanente. Esta acción no se puede deshacer.")
            }
        }
    }

    private var list: some View {
        ScrollView {
            LazyVStack(spacing: Theme.spacingS + 2) {
                ForEach(conversations) { conversation in
                    row(for: conversation)
                }
            }
            .padding(Theme.spacingL)
        }
    }

    @ViewBuilder
    private func row(for conversation: Conversation) -> some View {
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

                    // Explicit per-row menu — more discoverable than the
                    // long-press context menu alone, and works on iPad
                    // with a mouse or trackpad.
                    Menu {
                        Button(role: .destructive) {
                            pendingDelete = conversation
                        } label: {
                            Label("Eliminar", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.callout.weight(.semibold))
                            .foregroundStyle(Theme.secondaryText)
                            .frame(width: 32, height: 32)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Más acciones")
                }
            }
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(role: .destructive) {
                pendingDelete = conversation
            } label: {
                Label("Eliminar", systemImage: "trash")
            }
        }
    }

    private func delete(_ conversation: Conversation) {
        modelContext.delete(conversation)
        try? modelContext.save()
        onDelete(conversation)
        pendingDelete = nil
    }

    private var emptyState: some View {
        LuminaEmptyState(
            bearName: "bear_10",
            title: "Sin conversaciones aún",
            message: "Inicia una nueva conversación con Buddy desde el botón arriba."
        )
    }
}
