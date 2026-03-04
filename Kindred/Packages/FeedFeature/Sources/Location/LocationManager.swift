import CoreLocation
import Foundation
import os.log

private let locationLogger = Logger(subsystem: "com.ersinkirteke.kindred", category: "Location")

/// Minimal CLLocationManager wrapper. NOT @MainActor — uses DispatchQueue.main
/// explicitly to avoid Swift concurrency / Objective-C delegate interop issues.
public final class LocationManager: NSObject {
    public static let shared: LocationManager = {
        if Thread.isMainThread {
            return LocationManager()
        } else {
            return DispatchQueue.main.sync { LocationManager() }
        }
    }()

    private let clManager = CLLocationManager()
    private var locationContinuation: CheckedContinuation<CLLocation, Error>?
    private var authContinuation: CheckedContinuation<CLAuthorizationStatus, Never>?

    private override init() {
        super.init()
        clManager.delegate = self
        clManager.desiredAccuracy = kCLLocationAccuracyKilometer
        locationLogger.info("LocationManager init, status=\(self.clManager.authorizationStatus.rawValue)")
    }

    public func requestPermissionAndWait() async -> CLAuthorizationStatus {
        await withCheckedContinuation { continuation in
            DispatchQueue.main.async { [self] in
                let status = self.clManager.authorizationStatus
                locationLogger.info("requestPermission: status=\(status.rawValue)")

                if status != .notDetermined {
                    continuation.resume(returning: status)
                } else {
                    self.authContinuation = continuation
                    self.clManager.requestWhenInUseAuthorization()
                }
            }
        }
    }

    public func requestCurrentLocation() async throws -> CLLocation {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.main.async { [self] in
                locationLogger.info("requestCurrentLocation: calling requestLocation()")
                self.locationContinuation = continuation
                self.clManager.requestLocation()
            }
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationManager: CLLocationManagerDelegate {
    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        locationLogger.info("delegate: authChanged status=\(status.rawValue)")

        if let continuation = authContinuation, status != .notDetermined {
            authContinuation = nil
            continuation.resume(returning: status)
        }
    }

    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        locationLogger.info("delegate: didUpdateLocations lat=\(location.coordinate.latitude) lng=\(location.coordinate.longitude)")

        if let continuation = locationContinuation {
            locationContinuation = nil
            continuation.resume(returning: location)
        }
    }

    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationLogger.error("delegate: didFail error=\(error.localizedDescription)")

        if let continuation = locationContinuation {
            locationContinuation = nil
            continuation.resume(throwing: error)
        }
    }
}
