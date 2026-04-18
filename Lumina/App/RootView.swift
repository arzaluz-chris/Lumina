import SwiftUI
import SwiftData

/// The app's root view. Shows a splash screen on launch, gates
/// first-launch onboarding, and hosts the main tabs.
struct RootView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("hasCompletedQuiz") private var hasCompletedQuiz = false
    @State private var selectedTab: Tab = .test
    @State private var isSplashDone = false

    enum Tab: Hashable {
        case test
        case results
        case stories
        case buddy
        case settings
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

            BuddyChatView()
                .tabItem {
                    Label("Buddy", systemImage: "bubble.left.and.bubble.right.fill")
                }
                .tag(Tab.buddy)

            SettingsView()
                .tabItem {
                    Label("Ajustes", systemImage: "gearshape.fill")
                }
                .tag(Tab.settings)
        }
        .tint(Theme.accent)
        .sensoryFeedback(.selection, trigger: selectedTab)
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
    }
}

/// Hosts the mandatory first-run quiz. Shown after onboarding and before
/// the main tabs unlock. Wraps `QuizFlowView` so it can own its own
/// SwiftData context and hand a completion signal back to RootView.
private struct InitialQuizGateView: View {
    let onFinished: () -> Void

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Theme.background, Theme.accent.opacity(0.06)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            QuizFlowView(onComplete: { _ in onFinished() })
        }
    }
}
