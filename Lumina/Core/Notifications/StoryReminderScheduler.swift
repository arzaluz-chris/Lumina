import Foundation
import UserNotifications
import UIKit
import SwiftData
import os

/// Schedules memory-style local notifications that resurface stories
/// the user wrote months or years earlier — "Hoy hace un año…" — with
/// the story's photo as an attachment when one exists.
///
/// Modelled after Photos-style "On This Day" prompts. Everything is
/// local (no push), runs on-device, respects the gate toggle stored
/// in `AppStorage("storyRemindersEnabled")`, and auto-drains to stay
/// under iOS's ~64 pending request limit by only scheduling the
/// 20 most recent stories.
@MainActor
enum StoryReminderScheduler {
    private static let anniversaryHour = 10
    private static let anniversaryMinute = 0
    private static let memoryDayOffset = 90  // days from createdAt
    private static let maxScheduledStories = 20

    /// `UNUserNotificationCenter` identifier prefix used so we can
    /// bulk-cancel reminders tied to one story.
    static func anniversaryIdentifier(for storyID: UUID) -> String {
        "story.anniversary.\(storyID.uuidString)"
    }

    static func memoryIdentifier(for storyID: UUID) -> String {
        "story.memory.\(storyID.uuidString)"
    }

    // MARK: - Gate

    private static var isEnabled: Bool {
        UserDefaults.standard.object(forKey: "storyRemindersEnabled") as? Bool ?? false
    }

    // MARK: - Per-story scheduling

    /// Schedules both the anniversary (repeating, every year on the
    /// month/day of the story) and a one-shot "memory" reminder 90
    /// days after the story was saved. Safe to call multiple times —
    /// existing requests for the same story are removed first.
    static func schedule(for story: Story) {
        guard isEnabled else { return }

        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [
            anniversaryIdentifier(for: story.id),
            memoryIdentifier(for: story.id),
        ])

        let truncatedBody = truncatedBody(for: story)
        let attachment = buildAttachment(for: story)

        scheduleAnniversary(for: story, body: truncatedBody, attachment: attachment)
        scheduleMemory(for: story, body: truncatedBody, attachment: attachment)
    }

    /// Cancels any pending reminders for a deleted story.
    static func cancelAll(for storyID: UUID) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [
            anniversaryIdentifier(for: storyID),
            memoryIdentifier(for: storyID),
        ])
    }

    /// Removes every story-related pending request. Used when the
    /// user turns the toggle off.
    static func cancelAllStoryReminders() async {
        let center = UNUserNotificationCenter.current()
        let pending = await center.pendingNotificationRequests()
        let identifiers = pending
            .map(\.identifier)
            .filter { $0.hasPrefix("story.anniversary.") || $0.hasPrefix("story.memory.") }
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    // MARK: - Bulk rehydration

    /// Re-schedules reminders for the most recent stories. Called on
    /// app launch because UNUserNotificationCenter's pending list is
    /// preserved by iOS, so in practice this is a cheap no-op; but
    /// if the user purges notifications from Settings we'll repopulate.
    static func rehydrate(from stories: [Story]) {
        guard isEnabled else { return }
        let recent = stories
            .sorted { $0.createdAt > $1.createdAt }
            .prefix(maxScheduledStories)
        for story in recent {
            schedule(for: story)
        }
    }

    // MARK: - Internals

    private static func scheduleAnniversary(
        for story: Story,
        body: String,
        attachment: UNNotificationAttachment?
    ) {
        let content = UNMutableNotificationContent()
        content.title = String(localized: "Hoy hace un año…")
        content.body = body
        content.sound = .default
        if let attachment {
            content.attachments = [attachment]
        }

        // Repeat yearly on the month/day of the story, at 10:00 local.
        let components = Calendar.current.dateComponents([.month, .day], from: story.createdAt)
        var trigger = DateComponents()
        trigger.month = components.month
        trigger.day = components.day
        trigger.hour = anniversaryHour
        trigger.minute = anniversaryMinute

        let request = UNNotificationRequest(
            identifier: anniversaryIdentifier(for: story.id),
            content: content,
            trigger: UNCalendarNotificationTrigger(dateMatching: trigger, repeats: true)
        )
        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                Logger.notifications.error("Anniversary schedule failed: \(error.localizedDescription)")
            }
        }
    }

    private static func scheduleMemory(
        for story: Story,
        body: String,
        attachment: UNNotificationAttachment?
    ) {
        guard let memoryDate = Calendar.current.date(
            byAdding: .day,
            value: memoryDayOffset,
            to: story.createdAt
        ), memoryDate > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = String(localized: "¿Recuerdas este momento?")
        content.body = body
        content.sound = .default
        if let attachment {
            content.attachments = [attachment]
        }

        var components = Calendar.current.dateComponents([.year, .month, .day], from: memoryDate)
        components.hour = anniversaryHour
        components.minute = anniversaryMinute

        let request = UNNotificationRequest(
            identifier: memoryIdentifier(for: story.id),
            content: content,
            trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        )
        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                Logger.notifications.error("Memory schedule failed: \(error.localizedDescription)")
            }
        }
    }

    private static func truncatedBody(for story: Story) -> String {
        let trimmed = story.body.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            let strengthName = StrengthsCatalog.strength(id: story.strengthID)?.nameES
                ?? String(localized: "tus fortalezas")
            return String(localized: "Una historia que guardaste sobre \(strengthName).")
        }
        if trimmed.count <= 90 { return trimmed }
        let cutoff = trimmed.index(trimmed.startIndex, offsetBy: 90)
        return String(trimmed[..<cutoff]) + "…"
    }

    /// Copies the story's photo into a short-lived temporary file with
    /// a `.jpg` extension (UNNotificationAttachment enforces known file
    /// extensions) and wraps it in a notification attachment.
    ///
    /// Returns `nil` when the story has no photo, the file is missing,
    /// or the copy fails — callers must handle the text-only fallback.
    private static func buildAttachment(for story: Story) -> UNNotificationAttachment? {
        guard let filename = story.photoFilename else { return nil }
        guard let image = PhotoStore.loadImage(filename: filename) else { return nil }

        let tmpDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("StoryReminders", isDirectory: true)
        do {
            try FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true)
        } catch {
            Logger.notifications.error("Couldn't create reminder tmp dir: \(error.localizedDescription)")
            return nil
        }

        let url = tmpDir
            .appendingPathComponent("\(story.id.uuidString).jpg")
        do {
            if FileManager.default.fileExists(atPath: url.path) {
                try FileManager.default.removeItem(at: url)
            }
            guard let data = image.jpegData(compressionQuality: 0.8) else { return nil }
            try data.write(to: url, options: .atomic)
            return try UNNotificationAttachment(
                identifier: story.id.uuidString,
                url: url,
                options: [UNNotificationAttachmentOptionsTypeHintKey: "public.jpeg"]
            )
        } catch {
            Logger.notifications.error("Attachment build failed: \(error.localizedDescription)")
            return nil
        }
    }
}
