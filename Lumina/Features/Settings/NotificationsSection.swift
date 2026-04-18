import SwiftUI
import SwiftData

/// Settings section for configuring notification preferences.
struct NotificationsSection: View {
    @AppStorage("dailyTipsEnabled") private var dailyTipsEnabled = false
    @AppStorage("storyPromptsEnabled") private var storyPromptsEnabled = false
    @AppStorage("quizReminderEnabled") private var quizReminderEnabled = true
    @AppStorage("storyRemindersEnabled") private var storyRemindersEnabled = false

    @Query(sort: \Story.createdAt, order: .reverse) private var stories: [Story]

    private let manager = NotificationManager.shared

    var body: some View {
        Section {
            Toggle("Tip diario de fortalezas", isOn: $dailyTipsEnabled)
            Toggle("Recordatorio semanal de historias", isOn: $storyPromptsEnabled)
            Toggle("Recuerdos de historias", isOn: $storyRemindersEnabled)
            Toggle("Recordatorio de re-test (30 días)", isOn: $quizReminderEnabled)

            if !manager.isAuthorized {
                Button("Permitir notificaciones") {
                    Task { await manager.requestPermission() }
                }
                .foregroundStyle(Theme.accent)
            }
        } header: {
            Label("Notificaciones", systemImage: "bell.badge")
                .foregroundStyle(Theme.gold)
        } footer: {
            if manager.isAuthorized {
                Text("Los recuerdos te avisan del aniversario de tus historias y de momentos pasados, como hace Fotos.")
            } else {
                Text("Activa las notificaciones para recibir tips, recuerdos y recordatorios.")
            }
        }
        .onChange(of: dailyTipsEnabled) { _, enabled in
            ensurePermissionAndSchedule {
                manager.scheduleDailyTip(enabled: enabled)
            }
        }
        .onChange(of: storyPromptsEnabled) { _, enabled in
            ensurePermissionAndSchedule {
                manager.scheduleWeeklyStoryPrompt(enabled: enabled)
            }
        }
        .onChange(of: storyRemindersEnabled) { _, enabled in
            if enabled {
                ensurePermissionAndSchedule {
                    StoryReminderScheduler.rehydrate(from: stories)
                }
            } else {
                Task { await StoryReminderScheduler.cancelAllStoryReminders() }
            }
        }
    }

    private func ensurePermissionAndSchedule(_ schedule: @escaping () -> Void) {
        if manager.isAuthorized {
            schedule()
        } else {
            Task {
                await manager.requestPermission()
                if manager.isAuthorized {
                    schedule()
                }
            }
        }
    }
}
