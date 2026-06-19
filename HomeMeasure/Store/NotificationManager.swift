//
//  NotificationManager.swift
//  HomeMeasure
//
//  Wraps UNUserNotificationCenter for local-only reminders. Used by the
//  Settings toggle and by scheduling reminders for upcoming milestones/tasks.
//  No remote / push anything — everything is on-device.
//

import Foundation
import UserNotifications

final class NotificationManager: ObservableObject {
    static let shared = NotificationManager()

    @Published var authorized: Bool = false

    private init() { refreshStatus() }

    func refreshStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.authorized = settings.authorizationStatus == .authorized
                    || settings.authorizationStatus == .provisional
            }
        }
    }

    /// Request permission. Completion reports the final granted state.
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
                DispatchQueue.main.async {
                    self.authorized = granted
                    completion(granted)
                }
            }
    }

    /// Schedule a one-off reminder. Date in the past fires shortly after.
    func schedule(id: String, title: String, body: String, at date: Date) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let interval = max(5, date.timeIntervalSinceNow)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }

    func cancel(id: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
    }

    func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    /// Demonstrates a working schedule the user can verify immediately.
    func scheduleSampleReminder() {
        schedule(id: "sample.reminder",
                 title: "HomeMeasure",
                 body: "Reminder: review your project progress today.",
                 at: Date().addingTimeInterval(10))
    }
}
