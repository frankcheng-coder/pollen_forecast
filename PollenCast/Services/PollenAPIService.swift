import Foundation
import CoreLocation
import OSLog

private let logger = Logger(subsystem: "com.pollencast.app", category: "PollenAPI")

// MARK: - Pollen API Error

enum PollenAPIError: LocalizedError {
    case invalidURL
    case networkError(Error)
    case decodingError(Error, responseBody: String)
    case httpError(statusCode: Int, body: String)
    case noData
    case apiKeyMissing
    case apiKeyPlaceholder

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid API URL"
        case .networkError(let error): return "Network error: \(error.localizedDescription)"
        case .decodingError(let error, _): return "Data parsing error: \(error.localizedDescription)"
        case .httpError(let code, let body): return "HTTP \(code): \(body.prefix(200))"
        case .noData: return "No pollen data available for this location"
        case .apiKeyMissing: return "Google Pollen API key is not configured"
        case .apiKeyPlaceholder: return "Google Pollen API key is still the placeholder. Set a real key in Debug.xcconfig."
        }
    }
}

// MARK: - Pollen Debug Info

struct PollenDebugInfo {
    let requestURL: String
    let httpStatusCode: Int?
    let responseBodyPreview: String
    let decodingSucceeded: Bool
    let forecastDaysParsed: Int
    let error: String?
    let timestamp: Date
}

// MARK: - Pollen API Service Protocol

protocol PollenAPIServiceProtocol {
    func fetchForecast(for coordinate: CLLocationCoordinate2D, days: Int) async throws -> PollenForecast
    func fetchCurrentPollen(for coordinate: CLLocationCoordinate2D) async throws -> PollenSnapshot
    var lastDebugInfo: PollenDebugInfo? { get }
}

// MARK: - Pollen API Service

final class PollenAPIService: PollenAPIServiceProtocol {

    private let session: URLSession
    private let apiKey: String
    private(set) var lastDebugInfo: PollenDebugInfo?

    // Google Pollen API base URL
    private let baseURL = "https://pollen.googleapis.com/v1/forecast:lookup"

    private static let placeholderKey = "YOUR_GOOGLE_POLLEN_API_KEY_HERE"

    init(session: URLSession = .shared) {
        self.session = session
        self.apiKey = Bundle.main.infoDictionary?["GOOGLE_POLLEN_API_KEY"] as? String ?? ""
        logger.info("PollenAPIService init — API key length: \(self.apiKey.count), isPlaceholder: \(self.apiKey == Self.placeholderKey)")
    }

    // MARK: - Fetch Forecast

    func fetchForecast(for coordinate: CLLocationCoordinate2D, days: Int = 5) async throws -> PollenForecast {
        // Check for missing key
        if apiKey.isEmpty {
            logger.warning("API key is empty — returning mock data")
            recordDebug(url: "N/A (no key)", status: nil, body: "Using mock data — API key empty", decoded: true, days: 5, error: "API key empty — using mock data")
            return MockDataProvider.mockPollenForecast(for: coordinate)
        }

        // Check for placeholder key
        if apiKey == Self.placeholderKey {
            logger.error("API key is still the placeholder value")
            recordDebug(url: "N/A (placeholder key)", status: nil, body: "", decoded: false, days: 0, error: PollenAPIError.apiKeyPlaceholder.errorDescription)
            throw PollenAPIError.apiKeyPlaceholder
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

        // Log the request (redact API key)
        let redactedURL = url.absoluteString.replacingOccurrences(of: apiKey, with: "REDACTED")
        logger.info("Pollen API request: \(redactedURL)")

        do {
            let (data, response) = try await session.data(from: url)
            let bodyString = String(data: data, encoding: .utf8) ?? "<binary>"

            // Check HTTP status
            let httpResponse = response as? HTTPURLResponse
            let statusCode = httpResponse?.statusCode ?? -1
            logger.info("Pollen API response: HTTP \(statusCode), body length: \(data.count)")
            logger.debug("Pollen API body: \(bodyString.prefix(500))")

            guard (200..<300).contains(statusCode) else {
                let errorMsg = "HTTP \(statusCode)"
                logger.error("Pollen API HTTP error: \(statusCode) — \(bodyString.prefix(300))")
                recordDebug(url: redactedURL, status: statusCode, body: String(bodyString.prefix(500)), decoded: false, days: 0, error: errorMsg)
                throw PollenAPIError.httpError(statusCode: statusCode, body: String(bodyString.prefix(500)))
            }

            // Decode with tolerance
            let decoder = JSONDecoder()
            let decoded: GooglePollenResponse
            do {
                decoded = try decoder.decode(GooglePollenResponse.self, from: data)
            } catch {
                logger.error("Pollen API decoding failed: \(error)")
                logger.error("Response body was: \(bodyString.prefix(1000))")
                recordDebug(url: redactedURL, status: statusCode, body: String(bodyString.prefix(500)), decoded: false, days: 0, error: "Decoding: \(error)")
                throw PollenAPIError.decodingError(error, responseBody: String(bodyString.prefix(1000)))
            }

            let forecast = mapToForecast(response: decoded, coordinate: coordinate)
            logger.info("Pollen API decoded OK: \(forecast.days.count) days, today risk: \(forecast.today?.overallRiskLevel.label ?? "N/A")")
            recordDebug(url: redactedURL, status: statusCode, body: String(bodyString.prefix(300)), decoded: true, days: forecast.days.count, error: nil)
            return forecast

        } catch let error as PollenAPIError {
            throw error
        } catch is CancellationError {
            logger.debug("Pollen API request cancelled")
            throw CancellationError()
        } catch let error as URLError where error.code == .cancelled {
            logger.debug("Pollen API URLSession cancelled")
            throw CancellationError()
        } catch {
            logger.error("Pollen API network error: \(error)")
            recordDebug(url: redactedURL, status: nil, body: "", decoded: false, days: 0, error: "Network: \(error.localizedDescription)")
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
                    displayName: typeInfo.displayName ?? typeInfo.code,
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
        // Normalize: trim, lowercase, collapse whitespace/underscores/hyphens
        let normalized = (category ?? "")
            .trimmingCharacters(in: .whitespaces)
            .lowercased()
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")

        switch normalized {
        case "", "none":       return .none
        case "very low":       return .veryLow
        case "low":            return .low
        case "moderate":       return .moderate
        case "high":           return .high
        case "very high":      return .veryHigh
        default:
            logger.warning("Unknown pollen category: \(category ?? "nil")")
            return .none
        }
    }

    // MARK: - Debug

    private func recordDebug(url: String, status: Int?, body: String, decoded: Bool, days: Int, error: String?) {
        lastDebugInfo = PollenDebugInfo(
            requestURL: url,
            httpStatusCode: status,
            responseBodyPreview: body,
            decodingSucceeded: decoded,
            forecastDaysParsed: days,
            error: error,
            timestamp: Date()
        )
    }
}
