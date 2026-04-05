import Foundation
import CoreLocation

// MARK: - Date Extensions

extension Date {
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }

    var shortDayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: self)
    }

    var mediumDateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }

    var timeAgoDescription: String {
        let minutes = Int(Date().timeIntervalSince(self) / 60)
        if minutes < 1 { return "Just now" }
        if minutes == 1 { return "1 min ago" }
        if minutes < 60 { return "\(minutes) min ago" }
        let hours = minutes / 60
        if hours == 1 { return "1 hour ago" }
        return "\(hours) hours ago"
    }
}

// MARK: - CLLocationCoordinate2D Equatable-like

extension CLLocationCoordinate2D {
    func isNearlyEqual(to other: CLLocationCoordinate2D, threshold: Double = 0.001) -> Bool {
        abs(latitude - other.latitude) < threshold && abs(longitude - other.longitude) < threshold
    }
}
