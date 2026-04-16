import Foundation
import UserNotifications
import os

/// Manages local notification scheduling for Lumina — daily tips,
/// weekly story prompts, and quiz re-test reminders.
@MainActor
@Observable
final class NotificationManager {
    static let shared = NotificationManager()

    var isAuthorized: Bool = false

    private init() {
        Task { await checkAuthorization() }
    }

    // MARK: - Permission

    func requestPermission() async {
        let center = UNUserNotificationCenter.current()
        do {
            isAuthorized = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            Logger.notifications.info("Notification permission \(self.isAuthorized ? "granted" : "denied")")
        } catch {
            Logger.notifications.error("Notification permission request failed: \(error.localizedDescription)")
        }
    }

    func checkAuthorization() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        isAuthorized = settings.authorizationStatus == .authorized
    }

    // MARK: - Daily Tip

    private let dailyTips: [String] = [
        "Hoy intenta usar tu creatividad en algo cotidiano.",
        "Recuerda: la gratitud se entrena notando las cosas pequeñas.",
        "¿Cómo puedes aplicar tu curiosidad hoy?",
        "Un acto de bondad, por pequeño que sea, activa una de tus fortalezas.",
        "La perseverancia se construye un paso a la vez.",
        "Observa cómo tu sentido del humor transforma una situación difícil.",
        "¿Cuándo fue la última vez que ejerciste tu valentía?",
        "La prudencia no es miedo: es sabiduría aplicada.",
        "Tu perspectiva es una fortaleza: compártela con alguien hoy.",
        "El amor por el aprendizaje te acompaña toda la vida.",
        "¿Cómo puedes liderar desde tu lugar hoy?",
        "La honestidad contigo mismo es la base de todas las fortalezas.",
        "Busca la belleza en algo que des por sentado.",
        "El trabajo en equipo multiplica tus fortalezas individuales.",
        "La esperanza no es pasiva: es elegir ver posibilidades.",
        "Tu inteligencia social te permite conectar con los demás.",
        "El perdón es un regalo que te das a ti mismo.",
        "La autorregulación es libertad, no restricción.",
        "La espiritualidad puede ser simplemente buscar sentido.",
        "La justicia empieza con cómo tratas a quienes te rodean.",
    ]

    func scheduleDailyTip(enabled: Bool) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["dailyTip"])
        guard enabled else {
            Logger.notifications.info("Daily tips disabled")
            return
        }

        var dateComponents = DateComponents()
        dateComponents.hour = 9
        dateComponents.minute = 0

        let content = UNMutableNotificationContent()
        content.title = "Lumina"
        content.body = dailyTips.randomElement()!
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "dailyTip", content: content, trigger: trigger)
        center.add(request)
        Logger.notifications.info("Daily tip scheduled at 9:00 AM")
    }

    // MARK: - Weekly Story Prompt

    func scheduleWeeklyStoryPrompt(enabled: Bool) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["storyPrompt"])
        guard enabled else {
            Logger.notifications.info("Weekly story prompts disabled")
            return
        }

        var dateComponents = DateComponents()
        dateComponents.weekday = 1  // Sunday
        dateComponents.hour = 18
        dateComponents.minute = 0

        let content = UNMutableNotificationContent()
        content.title = "Momento de reflexión"
        content.body = "Piensa en un momento de esta semana donde una fortaleza tuya se asomó. Anótalo en Historias."
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "storyPrompt", content: content, trigger: trigger)
        center.add(request)
        Logger.notifications.info("Weekly story prompt scheduled for Sundays at 6:00 PM")
    }

    // MARK: - Quiz Reminder

    func scheduleQuizReminder(lastCompletedAt: Date?) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["quizReminder"])

        guard let lastDate = lastCompletedAt else { return }
        guard let reminderDate = Calendar.current.date(byAdding: .day, value: 30, to: lastDate),
              reminderDate > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = "Hace un mes que no haces el test"
        content.body = "Tus fortalezas pueden haber cambiado. Vuelve a descubrirlas."
        content.sound = .default

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour], from: reminderDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: "quizReminder", content: content, trigger: trigger)
        center.add(request)
        Logger.notifications.info("Quiz reminder scheduled for \(reminderDate.formatted())")
    }
}
