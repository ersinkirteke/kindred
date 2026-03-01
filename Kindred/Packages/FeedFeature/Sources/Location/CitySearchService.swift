import Foundation
import MapKit

// MARK: - City Search Service

/// Service for searching cities using MapKit's MKLocalSearch
public struct CitySearchService {

    // MARK: - Types

    /// Result from city search
    public struct CityResult: Equatable, Identifiable {
        public let id = UUID()
        public let name: String
        public let fullName: String
        public let latitude: Double
        public let longitude: Double

        public init(name: String, fullName: String, latitude: Double, longitude: Double) {
            self.name = name
            self.fullName = fullName
            self.latitude = latitude
            self.longitude = longitude
        }
    }

    /// Popular cities shown when search is empty
    public static let popularCities: [CityResult] = [
        CityResult(name: "Istanbul", fullName: "Istanbul, Turkey", latitude: 41.0082, longitude: 28.9784),
        CityResult(name: "New York", fullName: "New York, United States", latitude: 40.7128, longitude: -74.0060),
        CityResult(name: "London", fullName: "London, United Kingdom", latitude: 51.5074, longitude: -0.1278),
        CityResult(name: "Tokyo", fullName: "Tokyo, Japan", latitude: 35.6762, longitude: 139.6503),
        CityResult(name: "Paris", fullName: "Paris, France", latitude: 48.8566, longitude: 2.3522),
        CityResult(name: "Los Angeles", fullName: "Los Angeles, United States", latitude: 34.0522, longitude: -118.2437),
        CityResult(name: "Bangkok", fullName: "Bangkok, Thailand", latitude: 13.7563, longitude: 100.5018),
        CityResult(name: "Dubai", fullName: "Dubai, United Arab Emirates", latitude: 25.2048, longitude: 55.2708)
    ]

    // MARK: - Search

    /// Search for cities matching the query
    ///
    /// - Parameters:
    ///   - query: Search query (minimum 2 characters recommended)
    /// - Returns: Array of city results, filtered to city-level locations
    /// - Note: Caller should implement debouncing (300ms recommended)
    public static func searchCities(query: String) async throws -> [CityResult] {
        // Return popular cities if query is too short
        guard query.count >= 2 else {
            return popularCities
        }

        let searchRequest = MKLocalSearch.Request()
        searchRequest.naturalLanguageQuery = query
        searchRequest.resultTypes = .address

        let search = MKLocalSearch(request: searchRequest)
        let response = try await search.start()

        // Filter to city-level results
        let cityResults = response.mapItems.compactMap { item -> CityResult? in
            guard let placemark = item.placemark.mkPlacemark as? MKPlacemark else {
                return nil
            }

            // Only include results that have a locality (city name)
            guard let cityName = placemark.locality else {
                return nil
            }

            // Build full name with country
            var fullNameParts: [String] = [cityName]

            if let country = placemark.country {
                fullNameParts.append(country)
            }

            let fullName = fullNameParts.joined(separator: ", ")

            return CityResult(
                name: cityName,
                fullName: fullName,
                latitude: placemark.coordinate.latitude,
                longitude: placemark.coordinate.longitude
            )
        }

        // Remove duplicates by city name
        var seen = Set<String>()
        let uniqueResults = cityResults.filter { result in
            guard !seen.contains(result.name) else {
                return false
            }
            seen.insert(result.name)
            return true
        }

        return uniqueResults
    }
}

// MARK: - MKPlacemark Extension

extension MKPlacemark {
    /// Cast to MKPlacemark if needed
    var mkPlacemark: MKPlacemark? {
        return self as? MKPlacemark ?? self
    }
}
