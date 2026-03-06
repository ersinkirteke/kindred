import CoreLocation
import Dependencies
import Foundation
import os.log

private let locationClientLogger = Logger(subsystem: "com.ersinkirteke.kindred", category: "LocationClient")

public struct LocationClient {
    public var requestAuthorization: @Sendable () async -> CLAuthorizationStatus
    public var currentLocation: @Sendable () async throws -> CLLocation
    public var reverseGeocode: @Sendable (CLLocation) async throws -> String
}

// MARK: - DependencyKey

extension LocationClient: DependencyKey {
    public static var liveValue: LocationClient {
        return LocationClient(
            requestAuthorization: {
                locationClientLogger.info("📍 requestAuthorization called")
                let result = await LocationManager.shared.requestPermissionAndWait()
                locationClientLogger.info("📍 auth result: \(result.rawValue)")
                return result
            },
            currentLocation: {
                locationClientLogger.info("📍 currentLocation: using LocationManager.shared")
                let location = try await LocationManager.shared.requestCurrentLocation()
                locationClientLogger.info("📍 currentLocation resolved: \(location.coordinate.latitude), \(location.coordinate.longitude)")
                return location
            },
            reverseGeocode: { location in
                locationClientLogger.info("📍 reverseGeocode for \(location.coordinate.latitude), \(location.coordinate.longitude)")
                let geocoder = CLGeocoder()
                let placemarks = try await geocoder.reverseGeocodeLocation(location)

                guard let placemark = placemarks.first else {
                    locationClientLogger.error("❌ reverseGeocode: no placemarks")
                    throw LocationError.geocodingFailed
                }

                locationClientLogger.info("📍 placemark — locality: \(placemark.locality ?? "nil"), admin: \(placemark.administrativeArea ?? "nil"), country: \(placemark.country ?? "nil")")

                if let city = placemark.locality {
                    return city
                } else if let area = placemark.administrativeArea {
                    return area
                } else if let country = placemark.country {
                    return country
                } else {
                    throw LocationError.noCityFound
                }
            }
        )
    }

    public static var testValue: LocationClient {
        let istanbulLocation = CLLocation(latitude: 41.0082, longitude: 28.9784)

        return LocationClient(
            requestAuthorization: { .authorizedWhenInUse },
            currentLocation: { istanbulLocation },
            reverseGeocode: { _ in "Istanbul" }
        )
    }
}

extension DependencyValues {
    public var locationClient: LocationClient {
        get { self[LocationClient.self] }
        set { self[LocationClient.self] = newValue }
    }
}

// MARK: - Errors

public enum LocationError: Error, LocalizedError {
    case geocodingFailed
    case noCityFound

    public var errorDescription: String? {
        switch self {
        case .geocodingFailed:
            return "Failed to reverse geocode location"
        case .noCityFound:
            return "Could not determine city from location"
        }
    }
}
