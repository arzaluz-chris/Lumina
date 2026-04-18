import SwiftUI
import SwiftData

/// The app's root view. Shows a splash screen on launch, gates
/// first-launch onboarding, and hosts the main tabs.
///
/// Redesign (2026-04-17): tab icons adopt iOS 26 symbol effects (bounce on
/// selection), background is softened with the Lumina subtle gradient, and
/// the initial quiz gate uses the hero gradient for a cohesive feel.
struct RootView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("hasCompletedQuiz") private var hasCompletedQuiz = false
    @State private var selectedTab: Tab = .test
    @State private var isSplashDone = false
    @State private var showStoryEditor = false
    @StateObject private var quickActions = QuickActionsHandler.shared

    enum Tab: Hashable {
        case test
        case results
        case stories
        case buddy
        case settings
    }

    /// The app quietly turns into a 4-tab "no AI" variant on devices
    /// where Apple Intelligence is structurally unsupported (older
    /// hardware). On devices where it's just disabled in Settings we
    /// keep the Buddy tab so the user can act on the CTA inside.
    private var isBuddyTabVisible: Bool {
        !AICapabilityGate.shared.shouldHideAIEntirely
    }

    var body: some View {
        ZStack {
            if !isSplashDone {
                SplashView(isFinished: $isSplashDone)
                    .transition(.opacity)
            } else {
                mainContent
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.4), value: isSplashDone)
    }

    private var mainContent: some View {
        TabView(selection: $selectedTab) {
            TestTabView(onQuizComplete: {
                selectedTab = .results
            })
            .tabItem {
                Label("Test", systemImage: "pencil.and.list.clipboard")
            }
            .tag(Tab.test)

            ResultsTabView()
                .tabItem {
                    Label("Mis 24", systemImage: "chart.bar.fill")
                }
                .tag(Tab.results)

            StoriesListView()
                .tabItem {
                    Label("Historias", systemImage: "book.closed.fill")
                }
                .tag(Tab.stories)

            if isBuddyTabVisible {
                BuddyChatView()
                    .tabItem {
                        Label("Buddy", systemImage: "bubble.left.and.bubble.right.fill")
                    }
                    .tag(Tab.buddy)
            }

            SettingsView()
                .tabItem {
                    Label("Ajustes", systemImage: "gearshape.fill")
                }
                .tag(Tab.settings)
        }
        .tint(Theme.accent)
        .sensoryFeedback(.selection, trigger: selectedTab)
        .sheet(isPresented: $showStoryEditor) {
            StoryEditorView()
        }
        .fullScreenCover(isPresented: .init(
            get: { !hasCompletedOnboarding },
            set: { if !$0 { hasCompletedOnboarding = true } }
        )) {
            OnboardingFlowView {
                hasCompletedOnboarding = true
            }
        }
        .fullScreenCover(isPresented: .init(
            get: { hasCompletedOnboarding && !hasCompletedQuiz },
            set: { if !$0 { hasCompletedQuiz = true } }
        )) {
            InitialQuizGateView {
                hasCompletedQuiz = true
                selectedTab = .results
            }
        }
        // Cold-launch Quick Action: drain once the tabs exist.
        .onAppear {
            if let pending = quickActions.consumePending() {
                handleQuickAction(pending)
            }
        }
        // Warm-launch Quick Action: router subscribes while mounted.
        .onReceive(quickActions.actions) { action in
            handleQuickAction(action)
        }
    }

    /// Routes a Home Screen Quick Action to the corresponding tab or
    /// modal. Kept tiny on purpose — each case either flips
    /// `selectedTab` or toggles `showStoryEditor`.
    private func handleQuickAction(_ action: QuickActionsHandler.Action) {
        switch action {
        case .test:
            selectedTab = .test
        case .buddy:
            // Fall through to results if Buddy isn't reachable on this device.
            selectedTab = isBuddyTabVisible ? .buddy : .results
        case .story:
            selectedTab = .stories
            showStoryEditor = true
        case .results:
            selectedTab = .results
        }
    }
}

/// Hosts the mandatory first-run quiz. Shown after onboarding and before
/// the main tabs unlock. Wraps `QuizFlowView` so it can own its own
/// SwiftData context and hand a completion signal back to RootView.
private struct InitialQuizGateView: View {
    let onFinished: () -> Void

    var body: some View {
        ZStack {
            Theme.heroGradient.ignoresSafeArea()

            QuizFlowView(onComplete: { _ in onFinished() })
        }
    }
}
