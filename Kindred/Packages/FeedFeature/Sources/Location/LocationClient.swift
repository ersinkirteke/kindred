import CoreLocation
import Dependencies
import Foundation

public struct LocationClient {
    public var requestAuthorization: @Sendable () async -> CLAuthorizationStatus
    public var currentLocation: @Sendable () async throws -> CLLocation
    public var reverseGeocode: @Sendable (CLLocation) async throws -> String
}

extension LocationClient: DependencyKey {
    public static var liveValue: LocationClient {
        // Shared CLLocationManager — created on main thread for CoreLocation
        let manager: CLLocationManager = {
            if Thread.isMainThread {
                return CLLocationManager()
            } else {
                return DispatchQueue.main.sync { CLLocationManager() }
            }
        }()

        return LocationClient(
            requestAuthorization: {
                let status = await MainActor.run { manager.authorizationStatus }
                if status != .notDetermined {
                    return status
                }

                await MainActor.run { manager.requestWhenInUseAuthorization() }

                // Poll for authorization change (max 30 seconds for user to respond)
                for _ in 0..<300 {
                    try? await Task.sleep(for: .milliseconds(100))
                    let current = await MainActor.run { manager.authorizationStatus }
                    if current != .notDetermined {
                        return current
                    }
                }
                return await MainActor.run { manager.authorizationStatus }
            },
            currentLocation: {
                // Use iOS 17+ CLLocationUpdate async API — no delegates needed
                for try await update in CLLocationUpdate.liveUpdates(.default) {
                    if let location = update.location {
                        return location
                    }
                }
                throw LocationError.noCityFound
            },
            reverseGeocode: { location in
                let geocoder = CLGeocoder()
                let placemarks = try await geocoder.reverseGeocodeLocation(location)

                guard let placemark = placemarks.first else {
                    throw LocationError.geocodingFailed
                }

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
