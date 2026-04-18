import SwiftUI

/// Settings section for configuring notification preferences.
struct NotificationsSection: View {
    @AppStorage("dailyTipsEnabled") private var dailyTipsEnabled = false
    @AppStorage("storyPromptsEnabled") private var storyPromptsEnabled = false
    @AppStorage("quizReminderEnabled") private var quizReminderEnabled = true

    private let manager = NotificationManager.shared

    var body: some View {
        Section {
            Toggle("Tip diario de fortalezas", isOn: $dailyTipsEnabled)
            Toggle("Recordatorio semanal de historias", isOn: $storyPromptsEnabled)
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
                Text("Las notificaciones se envían localmente desde tu dispositivo.")
            } else {
                Text("Activa las notificaciones para recibir tips y recordatorios.")
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
