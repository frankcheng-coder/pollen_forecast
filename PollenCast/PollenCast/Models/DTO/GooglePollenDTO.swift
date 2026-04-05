import Foundation

// MARK: - Google Pollen API Response DTOs

/// Response from Google Pollen API /forecast:lookup endpoint
struct GooglePollenResponse: Codable {
    let regionCode: String?
    let dailyInfo: [GooglePollenDayInfo]?
}

struct GooglePollenDayInfo: Codable {
    let date: GooglePollenDate
    let pollenTypeInfo: [GooglePollenTypeInfo]?
    let plantInfo: [GooglePlantInfo]?
}

struct GooglePollenDate: Codable {
    let year: Int
    let month: Int
    let day: Int

    var asDate: Date? {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        return Calendar.current.date(from: components)
    }
}

struct GooglePollenTypeInfo: Codable {
    let code: String // "TREE", "GRASS", "WEED"
    let displayName: String
    let indexInfo: GooglePollenIndexInfo?
    let healthRecommendations: [String]?
    let inSeason: Bool?
}

struct GooglePollenIndexInfo: Codable {
    let code: String // "UPI" (Universal Pollen Index)
    let displayName: String
    let value: Int?
    let category: String // "NONE", "LOW", "MODERATE", "HIGH", "VERY_HIGH"
    let indexDescription: String?
    let color: GooglePollenColor?
}

struct GooglePollenColor: Codable {
    let red: Double?
    let green: Double?
    let blue: Double?
    let alpha: Double?
}

struct GooglePlantInfo: Codable {
    let code: String
    let displayName: String
    let indexInfo: GooglePollenIndexInfo?
    let plantDescription: PlantDescription?
    let inSeason: Bool?
}

struct PlantDescription: Codable {
    let type: String?
    let family: String?
    let season: String?
    let specialColors: String?
    let specialShapes: String?
    let crossReaction: String?
    let picture: String?
    let pictureCloseup: String?
}
