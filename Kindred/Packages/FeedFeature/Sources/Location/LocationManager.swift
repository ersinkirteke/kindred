import CoreLocation
import Foundation
import os.log

private let locationLogger = Logger(subsystem: "com.ersinkirteke.kindred", category: "Location")

/// Minimal CLLocationManager wrapper. Polling-based, thread-safe property reads.
public final class LocationManager: NSObject, @unchecked Sendable, CLLocationManagerDelegate {
    public private(set) static var shared: LocationManager!

    public static func warmUp() {
        assert(Thread.isMainThread)
        if shared == nil {
            shared = LocationManager()
        }
    }

    let clManager = CLLocationManager()

    // Thread-safe storage for values set by delegate on main thread, read from any thread
    private let lock = NSLock()
    private var _lastAuthStatus: CLAuthorizationStatus = .notDetermined
    private var _lastLocation: CLLocation?

    private var safeAuthStatus: CLAuthorizationStatus {
        lock.lock(); defer { lock.unlock() }
        return _lastAuthStatus
    }

    private var safeLocation: CLLocation? {
        lock.lock(); defer { lock.unlock() }
        return _lastLocation
    }

    private override init() {
        super.init()
        _lastAuthStatus = clManager.authorizationStatus
        clManager.delegate = self
        clManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationLogger.info("📍 LocationManager init, status=\(self._lastAuthStatus.rawValue)")
    }

    // MARK: - Authorization

    /// Call from main thread to trigger the system permission dialog immediately
    public func requestPermission() {
        assert(Thread.isMainThread, "requestPermission must be called on main thread")
        clManager.requestWhenInUseAuthorization()
    }

    public func requestPermissionAndWait() async -> CLAuthorizationStatus {
        let currentStatus = safeAuthStatus
        locationLogger.info("📍 auth current: \(currentStatus.rawValue)")

        if currentStatus != .notDetermined {
            if currentStatus == .authorizedWhenInUse || currentStatus == .authorizedAlways {
                DispatchQueue.main.async { [self] in
                    self.clManager.startUpdatingLocation()
                }
            }
            return currentStatus
        }

        // Must be called on main thread to show dialog
        DispatchQueue.main.async { [self] in
            self.clManager.requestWhenInUseAuthorization()
        }

        // Poll thread-safe status
        for _ in 0..<60 {
            try? await Task.sleep(nanoseconds: 500_000_000)
            let status = safeAuthStatus
            if status != .notDetermined {
                locationLogger.info("📍 auth resolved: \(status.rawValue)")
                if status == .authorizedWhenInUse || status == .authorizedAlways {
                    DispatchQueue.main.async { [self] in
                        self.clManager.startUpdatingLocation()
                    }
                }
                return status
            }
        }

        return .denied
    }

    // MARK: - Location Fetching

    public func requestCurrentLocation() async throws -> CLLocation {
        DispatchQueue.main.async { [self] in
            self.clManager.startUpdatingLocation()
        }

        for i in 0..<30 {
            try? await Task.sleep(nanoseconds: 500_000_000)
            if let location = safeLocation, location.horizontalAccuracy >= 0 {
                locationLogger.info("📍 location: \(location.coordinate.latitude), \(location.coordinate.longitude) after \(i) polls")
                DispatchQueue.main.async { [self] in
                    self.clManager.stopUpdatingLocation()
                }
                return location
            }
        }

        DispatchQueue.main.async { [self] in
            self.clManager.stopUpdatingLocation()
        }
        throw LocationError.noCityFound
    }

    // MARK: - Delegate (runs on main thread, writes to thread-safe storage)

    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        lock.lock()
        _lastAuthStatus = status
        lock.unlock()
        locationLogger.info("📍 delegate authChanged: \(status.rawValue)")

        if status == .authorizedWhenInUse || status == .authorizedAlways {
            clManager.startUpdatingLocation()
        }
    }

    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let loc = locations.last {
            lock.lock()
            _lastLocation = loc
            lock.unlock()
            locationLogger.info("📍 delegate didUpdate: \(loc.coordinate.latitude), \(loc.coordinate.longitude) acc=\(loc.horizontalAccuracy)")
        }
    }

    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationLogger.error("📍 delegate didFail: \(error.localizedDescription)")
    }
}
