import SwiftUI
import SwiftData
import os

/// The app's root view. Gates first-launch onboarding and hosts the
/// four main tabs (Test, Mis 24, Historias, Buddy).
struct RootView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var selectedTab: Tab = .test

    enum Tab: Hashable {
        case test
        case results
        case stories
        case buddy
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            TestTabView(onQuizComplete: {
                Logger.app.info("Quiz complete → switching to Results tab")
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
        }
        .tint(Theme.accent)
        .fullScreenCover(isPresented: .init(
            get: { !hasCompletedOnboarding },
            set: { if !$0 { hasCompletedOnboarding = true } }
        )) {
            WelcomeView {
                Logger.app.info("Onboarding completed — user tapped Empezar")
                hasCompletedOnboarding = true
            }
        }
        .onChange(of: selectedTab) { old, new in
            Logger.app.info("Tab changed: \(String(describing: old)) → \(String(describing: new))")
        }
        .onAppear {
            Logger.app.info("RootView appeared — onboarding completed: \(hasCompletedOnboarding)")
        }
    }
}
