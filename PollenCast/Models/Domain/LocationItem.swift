import Foundation
import CoreLocation

// MARK: - Location Item

struct LocationItem: Identifiable, Codable, Equatable {
    let id: UUID
    let name: String
    let locality: String? // city
    let administrativeArea: String? // state/province
    let country: String?
    let latitude: Double
    let longitude: Double
    let isCurrent: Bool

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var displayName: String {
        if isCurrent { return "Current Location" }
        var parts: [String] = []
        parts.append(name)
        if let area = administrativeArea, area != name {
            parts.append(area)
        }
        return parts.joined(separator: ", ")
    }

    var subtitle: String? {
        if isCurrent { return name }
        return country
    }

    init(
        id: UUID = UUID(),
        name: String,
        locality: String? = nil,
        administrativeArea: String? = nil,
        country: String? = nil,
        latitude: Double,
        longitude: Double,
        isCurrent: Bool = false
    ) {
        self.id = id
        self.name = name
        self.locality = locality
        self.administrativeArea = administrativeArea
        self.country = country
        self.latitude = latitude
        self.longitude = longitude
        self.isCurrent = isCurrent
    }

    static func currentLocation(coordinate: CLLocationCoordinate2D, name: String = "Current Location") -> LocationItem {
        LocationItem(
            name: name,
            latitude: coordinate.latitude,
            longitude: coordinate.longitude,
            isCurrent: true
        )
    }

    static func == (lhs: LocationItem, rhs: LocationItem) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Map Selection State

enum MapSelectionState: Equatable {
    case none
    case currentLocation
    case savedLocation(LocationItem)
    case customPoint(CLLocationCoordinate2D)

    static func == (lhs: MapSelectionState, rhs: MapSelectionState) -> Bool {
        switch (lhs, rhs) {
        case (.none, .none): return true
        case (.currentLocation, .currentLocation): return true
        case (.savedLocation(let a), .savedLocation(let b)): return a.id == b.id
        case (.customPoint(let a), .customPoint(let b)):
            return a.latitude == b.latitude && a.longitude == b.longitude
        default: return false
        }
    }
}
