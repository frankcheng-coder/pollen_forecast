import Foundation
import CoreLocation

// MARK: - Pollen API Error

enum PollenAPIError: LocalizedError {
    case invalidURL
    case networkError(Error)
    case decodingError(Error)
    case noData
    case apiKeyMissing

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid API URL"
        case .networkError(let error): return "Network error: \(error.localizedDescription)"
        case .decodingError(let error): return "Data parsing error: \(error.localizedDescription)"
        case .noData: return "No pollen data available for this location"
        case .apiKeyMissing: return "Google Pollen API key is not configured"
        }
    }
}

// MARK: - Pollen API Service Protocol

protocol PollenAPIServiceProtocol {
    func fetchForecast(for coordinate: CLLocationCoordinate2D, days: Int) async throws -> PollenForecast
    func fetchCurrentPollen(for coordinate: CLLocationCoordinate2D) async throws -> PollenSnapshot
}

// MARK: - Pollen API Service

final class PollenAPIService: PollenAPIServiceProtocol {

    private let session: URLSession
    private let apiKey: String

    // Google Pollen API base URL
    private let baseURL = "https://pollen.googleapis.com/v1/forecast:lookup"

    init(session: URLSession = .shared) {
        self.session = session
        // TODO: Move to xcconfig — do not commit real key
        self.apiKey = Bundle.main.infoDictionary?["GOOGLE_POLLEN_API_KEY"] as? String ?? ""
    }

    // MARK: - Fetch Forecast

    func fetchForecast(for coordinate: CLLocationCoordinate2D, days: Int = 5) async throws -> PollenForecast {
        guard !apiKey.isEmpty else {
            // Return mock data when API key is missing (development)
            return MockDataProvider.mockPollenForecast(for: coordinate)
        }

        var components = URLComponents(string: baseURL)!
        components.queryItems = [
            URLQueryItem(name: "key", value: apiKey),
            URLQueryItem(name: "location.longitude", value: String(coordinate.longitude)),
            URLQueryItem(name: "location.latitude", value: String(coordinate.latitude)),
            URLQueryItem(name: "days", value: String(min(days, 5))),
            URLQueryItem(name: "languageCode", value: "en"),
            URLQueryItem(name: "plantsDescription", value: "false")
        ]

        guard let url = components.url else {
            throw PollenAPIError.invalidURL
        }

        do {
            let (data, _) = try await session.data(from: url)
            let response = try JSONDecoder().decode(GooglePollenResponse.self, from: data)
            return mapToForecast(response: response, coordinate: coordinate)
        } catch let error as DecodingError {
            throw PollenAPIError.decodingError(error)
        } catch let error as PollenAPIError {
            throw error
        } catch {
            throw PollenAPIError.networkError(error)
        }
    }

    // MARK: - Fetch Current

    func fetchCurrentPollen(for coordinate: CLLocationCoordinate2D) async throws -> PollenSnapshot {
        let forecast = try await fetchForecast(for: coordinate, days: 1)
        guard let today = forecast.today else {
            throw PollenAPIError.noData
        }

        return PollenSnapshot(
            coordinate: coordinate,
            timestamp: Date(),
            overallIndex: today.overallIndex,
            overallRiskLevel: today.overallRiskLevel,
            typeBreakdowns: today.typeBreakdowns,
            dominantType: today.dominantType
        )
    }

    // MARK: - Mapping

    private func mapToForecast(response: GooglePollenResponse, coordinate: CLLocationCoordinate2D) -> PollenForecast {
        let days = (response.dailyInfo ?? []).compactMap { dayInfo -> PollenDay? in
            guard let date = dayInfo.date.asDate else { return nil }

            let breakdowns = (dayInfo.pollenTypeInfo ?? []).map { typeInfo -> PollenTypeBreakdown in
                let indexValue = typeInfo.indexInfo?.value ?? 0
                let category = PollenCategory(rawValue: typeInfo.code) ?? .tree
                let riskLevel = mapCategoryToRisk(typeInfo.indexInfo?.category)

                return PollenTypeBreakdown(
                    category: category,
                    indexValue: indexValue,
                    riskLevel: riskLevel,
                    displayName: typeInfo.displayName,
                    inSeason: typeInfo.inSeason ?? false
                )
            }

            let maxIndex = breakdowns.map(\.indexValue).max() ?? 0
            let maxRisk = breakdowns.map(\.riskLevel).max() ?? .none

            return PollenDay(
                date: date,
                overallIndex: maxIndex,
                overallRiskLevel: maxRisk,
                typeBreakdowns: breakdowns
            )
        }

        return PollenForecast(
            coordinate: coordinate,
            fetchedAt: Date(),
            days: days
        )
    }

    private func mapCategoryToRisk(_ category: String?) -> PollenRiskLevel {
        switch category?.uppercased() {
        case "NONE", .none: return .none
        case "LOW": return .low
        case "MODERATE": return .moderate
        case "HIGH": return .high
        case "VERY_HIGH": return .veryHigh
        default: return .none
        }
    }
}
