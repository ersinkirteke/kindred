import Combine
import CoreLocation
import Foundation

@MainActor
public class LocationManager: NSObject, ObservableObject {
    public static let shared = LocationManager()

    private let locationManager = CLLocationManager()

    @Published public var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published public var lastLocation: CLLocation?

    private var locationContinuation: CheckedContinuation<CLLocation, Error>?

    private override init() {
        super.init()
        locationManager.delegate = self
        authorizationStatus = locationManager.authorizationStatus
    }

    public func requestPermission() {
        locationManager.requestWhenInUseAuthorization()
    }

    public func requestCurrentLocation() async throws -> CLLocation {
        return try await withCheckedThrowingContinuation { continuation in
            self.locationContinuation = continuation
            locationManager.requestLocation()
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationManager: CLLocationManagerDelegate {
    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
    }

    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }

        lastLocation = location

        // Fulfill continuation if waiting for location
        if let continuation = locationContinuation {
            locationContinuation = nil
            continuation.resume(returning: location)
        }
    }

    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // Fulfill continuation with error if waiting for location
        if let continuation = locationContinuation {
            locationContinuation = nil
            continuation.resume(throwing: error)
        }
    }
}
