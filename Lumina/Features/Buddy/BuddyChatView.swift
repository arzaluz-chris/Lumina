import SwiftUI
import SwiftData

/// The Lumina Buddy chat tab.
///
/// Streams replies from the on-device Foundation Models session seeded
/// with the user's latest strength snapshot. Shows a graceful empty
/// state on devices without Apple Intelligence.
struct BuddyChatView: View {
    @Query(sort: \TestResult.completedAt, order: .reverse) private var results: [TestResult]
    @State private var chatState = BuddyChatState()
    @FocusState private var isInputFocused: Bool

    var body: some View {
        NavigationStack {
            Group {
                if chatState.isAvailable {
                    chatContent
                } else {
                    unavailableState
                }
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Buddy")
            .navigationBarTitleDisplayMode(.inline)
            .task(id: results.first?.id) {
                let snapshot = results.first?.snapshot()
                chatState.start(with: snapshot, force: true)
            }
        }
    }

    private var chatContent: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: Theme.spacingM) {
                        ForEach(chatState.messages) { message in
                            ChatBubble(message: message)
                                .id(message.id)
                        }
                    }
                    .padding(Theme.spacingL)
                }
                .onChange(of: chatState.messages.last?.content) {
                    if let lastID = chatState.messages.last?.id {
                        withAnimation {
                            proxy.scrollTo(lastID, anchor: .bottom)
                        }
                    }
                }
            }

            inputBar
        }
    }

    private var inputBar: some View {
        HStack(spacing: Theme.spacingS) {
            TextField("Pregúntale a Buddy…", text: $chatState.input, axis: .vertical)
                .textFieldStyle(.plain)
                .lineLimit(1...4)
                .padding(.horizontal, Theme.spacingM)
                .padding(.vertical, Theme.spacingS + 2)
                .background(
                    RoundedRectangle(cornerRadius: Theme.chipRadius, style: .continuous)
                        .fill(Theme.cardBackground)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.chipRadius, style: .continuous)
                        .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                )
                .focused($isInputFocused)

            Button {
                Task { await chatState.send() }
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 34))
                    .foregroundStyle(
                        chatState.input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            ? Theme.secondaryText
                            : Theme.accent
                    )
            }
            .buttonStyle(.plain)
            .disabled(
                chatState.input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                || chatState.isThinking
            )
        }
        .padding(.horizontal, Theme.spacingL)
        .padding(.vertical, Theme.spacingM)
        .background(Theme.background)
    }

    private var unavailableState: some View {
        VStack(spacing: Theme.spacingL) {
            BearImage(name: "bear_33")
                .frame(maxHeight: 220)
            Text("Lumina Buddy no está disponible")
                .font(Theme.headlineFont)
                .multilineTextAlignment(.center)
            Text("Activa Apple Intelligence en Ajustes para chatear con Buddy. Esta función funciona completamente en tu dispositivo, sin enviar datos a ningún servidor.")
                .font(Theme.bodyFont)
                .foregroundStyle(Theme.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Theme.spacingL)
        }
        .padding(Theme.spacingL)
    }
}
