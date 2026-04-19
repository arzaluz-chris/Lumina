import SwiftUI
import SwiftData

/// The Lumina Buddy chat tab.
///
/// Streams replies from the on-device Foundation Models session seeded
/// with the user's latest strength snapshot. Supports conversation
/// persistence, smart suggestions, and markdown rendering.
///
/// Redesign (2026-04-17): welcome hero when the conversation is fresh,
/// input bar uses iOS 26 `.ultraThinMaterial` (Liquid Glass), send button
/// becomes a gradient circle, and the chat area sits on the hero gradient.
/// AIGlowOverlay at line ~28 is preserved exactly.
struct BuddyChatView: View {
    @Query(sort: \TestResult.completedAt, order: .reverse) private var results: [TestResult]
    @State private var chatState = BuddyChatState()
    @FocusState private var isInputFocused: Bool
    @State private var showConversationList = false
    @State private var showDisclaimer = false
    @AppStorage("hasSeenBuddyDisclaimer") private var hasSeenBuddyDisclaimer = false
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        NavigationStack {
            Group {
                if chatState.isAvailable {
                    chatContent
                } else {
                    unavailableState
                }
            }
            .background(Theme.heroGradient.ignoresSafeArea())
            .aiGlow(isActive: chatState.isThinking)
            .navigationTitle("Buddy")
            .navigationBarTitleDisplayMode(.inline)
            .sensoryFeedback(.impact(weight: .light), trigger: chatState.messages.count)
            .sensoryFeedback(.impact(weight: .light), trigger: chatState.streamingChunkCount / 4)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { showConversationList = true } label: {
                        Image(systemName: "list.bullet")
                            .foregroundStyle(Theme.accent)
                    }
                    .accessibilityLabel("Conversaciones anteriores")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        chatState.startNewConversation()
                        let snapshot = results.first?.snapshot()
                        chatState.start(with: snapshot, force: true)
                    } label: {
                        Image(systemName: "square.and.pencil")
                            .foregroundStyle(Theme.accent)
                    }
                    .accessibilityLabel("Nueva conversación")
                }
            }
            .sheet(isPresented: $showConversationList) {
                ConversationListView(
                    onSelect: { conversation in
                        chatState.loadConversation(conversation)
                    },
                    onNew: {
                        chatState.startNewConversation()
                        let snapshot = results.first?.snapshot()
                        chatState.start(with: snapshot, force: true)
                    }
                )
            }
            .sheet(isPresented: $showDisclaimer) {
                BuddyDisclaimerSheet {
                    hasSeenBuddyDisclaimer = true
                }
            }
            .task(id: results.first?.id) {
                chatState.configure(modelContext: modelContext)
                let snapshot = results.first?.snapshot()
                chatState.start(with: snapshot, force: true)
            }
            .onAppear {
                // One-time, first-run disclaimer. Only surface it on
                // devices where Buddy is actually usable (Apple
                // Intelligence available) — otherwise the user sees
                // the unavailable-state first and the sheet would feel
                // orphaned.
                if !hasSeenBuddyDisclaimer && chatState.isAvailable {
                    showDisclaimer = true
                }
            }
        }
    }

    private var chatContent: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: Theme.spacingM) {
                        if chatState.messages.isEmpty {
                            welcomeHero
                                .padding(.top, Theme.spacingL)
                        }
                        ForEach(chatState.messages) { message in
                            ChatBubble(message: message)
                                .id(message.id)
                                .transition(.asymmetric(
                                    insertion: .move(edge: .bottom).combined(with: .opacity),
                                    removal: .opacity
                                ))
                        }
                    }
                    .padding(Theme.spacingL)
                    .animation(Theme.AnimationStyle.smooth, value: chatState.messages.count)
                }
                .scrollDismissesKeyboard(.interactively)
                .onChange(of: chatState.messages.last?.content) {
                    if let lastID = chatState.messages.last?.id {
                        withAnimation {
                            proxy.scrollTo(lastID, anchor: .bottom)
                        }
                    }
                }
            }

            // Smart suggestions (visible when conversation is fresh)
            if !chatState.suggestions.isEmpty && chatState.messages.count <= 1 {
                SuggestionChipsView(suggestions: chatState.suggestions) { suggestion in
                    chatState.input = suggestion
                    Task { await chatState.send() }
                }
                .padding(.vertical, Theme.spacingS)
            }

            inputBar
        }
    }

    private var welcomeHero: some View {
        VStack(spacing: Theme.spacingM) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Theme.accent.opacity(0.3), Theme.accent.opacity(0)],
                            center: .center,
                            startRadius: 8,
                            endRadius: 160
                        )
                    )
                    .frame(width: 220, height: 220)
                BearImage(name: "bear_10")
                    .frame(maxHeight: 160)
            }
            Text("Hola, soy Buddy")
                .font(Theme.heroFont)
                .foregroundStyle(Theme.primaryText)
            Text("Pregúntame sobre tus fortalezas o cómo aplicarlas en tu día.")
                .font(Theme.bodyFont)
                .foregroundStyle(Theme.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Theme.spacingL)

            // Permanent reminder that this is AI content. Complements
            // the one-time first-run disclaimer sheet.
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.caption2.weight(.bold))
                Text("Respuestas generadas por IA. Pueden equivocarse.")
                    .font(.caption2.weight(.semibold))
            }
            .foregroundStyle(Theme.accent)
            .padding(.horizontal, Theme.spacingM)
            .padding(.vertical, 6)
            .background(
                Capsule(style: .continuous)
                    .fill(Theme.accent.opacity(0.12))
            )
        }
        .padding(.bottom, Theme.spacingS)
    }

    private var inputBar: some View {
        HStack(spacing: Theme.spacingS) {
            TextField("Pregúntale a Buddy…", text: $chatState.input, axis: .vertical)
                .textFieldStyle(.plain)
                .lineLimit(1...4)
                .padding(.horizontal, Theme.spacingM)
                .padding(.vertical, Theme.spacingS + 4)
                .background(
                    Capsule(style: .continuous)
                        .fill(.ultraThinMaterial)
                )
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [Color.white.opacity(0.28), Color.white.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .focused($isInputFocused)

            Button {
                isInputFocused = false
                Task { await chatState.send() }
            } label: {
                Image(systemName: "arrow.up")
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle().fill(
                            isSendEnabled
                                ? AnyShapeStyle(Theme.accentGradient)
                                : AnyShapeStyle(Color.secondary.opacity(0.35))
                        )
                    )
                    .luminaShadow(isSendEnabled ? Theme.shadowCard : Theme.ShadowStyle(color: .clear, radius: 0, x: 0, y: 0))
            }
            .buttonStyle(.plain)
            .disabled(!isSendEnabled)
            .animation(Theme.AnimationStyle.snappy, value: isSendEnabled)
            .accessibilityLabel("Enviar mensaje")
        }
        .padding(.horizontal, Theme.spacingL)
        .padding(.vertical, Theme.spacingM)
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea(edges: .bottom)
        )
    }

    private var isSendEnabled: Bool {
        !chatState.input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !chatState.isThinking
    }

    private var unavailableState: some View {
        LuminaEmptyState(
            bearName: "bear_33",
            title: "Lumina Buddy no está disponible",
            message: "Activa Apple Intelligence en Ajustes para chatear con Buddy. Esta función funciona completamente en tu dispositivo, sin enviar datos a ningún servidor."
        )
    }
}
