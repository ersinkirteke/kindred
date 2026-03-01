import CoreLocation
import Dependencies
import Foundation

@DependencyClient
public struct LocationClient {
    public var requestAuthorization: @Sendable () async -> CLAuthorizationStatus
    public var currentLocation: @Sendable () async throws -> CLLocation
    public var reverseGeocode: @Sendable (CLLocation) async throws -> String
}

extension LocationClient: DependencyKey {
    public static var liveValue: LocationClient {
        return LocationClient(
            requestAuthorization: {
                await LocationManager.shared.requestPermission()
                // Give the system time to process the permission request
                try? await Task.sleep(for: .milliseconds(500))
                return await LocationManager.shared.authorizationStatus
            },
            currentLocation: {
                try await LocationManager.shared.requestCurrentLocation()
            },
            reverseGeocode: { location in
                let geocoder = CLGeocoder()
                let placemarks = try await geocoder.reverseGeocodeLocation(location)

                guard let placemark = placemarks.first else {
                    throw LocationError.geocodingFailed
                }

                // Try to get city name (locality), fallback to administrative area
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
        // Istanbul coordinates for testing
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
