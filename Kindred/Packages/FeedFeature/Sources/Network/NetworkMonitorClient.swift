import Dependencies
import Foundation
import Network

@DependencyClient
public struct NetworkMonitorClient {
    public var isConnected: @Sendable () -> Bool = { true }
    public var connectivityStream: @Sendable () -> AsyncStream<Bool> = {
        AsyncStream { _ in }
    }
}

extension NetworkMonitorClient: DependencyKey {
    public static var liveValue: NetworkMonitorClient {
        let monitor = NetworkMonitor.shared

        return NetworkMonitorClient(
            isConnected: {
                monitor.isConnected
            },
            connectivityStream: {
                AsyncStream { continuation in
                    let task = Task {
                        for await isConnected in monitor.connectivityUpdates {
                            continuation.yield(isConnected)
                        }
                    }

                    continuation.onTermination = { _ in
                        task.cancel()
                    }
                }
            }
        )
    }

    public static var testValue: NetworkMonitorClient {
        return NetworkMonitorClient(
            isConnected: { true },
            connectivityStream: {
                AsyncStream { continuation in
                    continuation.yield(true)
                    continuation.finish()
                }
            }
        )
    }
}

extension DependencyValues {
    public var networkMonitorClient: NetworkMonitorClient {
        get { self[NetworkMonitorClient.self] }
        set { self[NetworkMonitorClient.self] = newValue }
    }
}

// MARK: - Network Monitor

private class NetworkMonitor {
    static let shared = NetworkMonitor()

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.kindred.networkmonitor")

    private var _isConnected = true
    private let connectivitySubject = AsyncStream<Bool>.makeStream()

    var isConnected: Bool {
        _isConnected
    }

    var connectivityUpdates: AsyncStream<Bool> {
        connectivitySubject.stream
    }

    private init() {
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }

            let isConnected = path.status == .satisfied
            self._isConnected = isConnected

            // Send connectivity update
            self.connectivitySubject.continuation.yield(isConnected)
        }

        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
        connectivitySubject.continuation.finish()
    }
}
