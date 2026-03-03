import Foundation

// MARK: - StepSyncEngine

public struct StepSyncEngine: Sendable {
    /// Returns the index of the current step at the given playback time
    /// Uses binary search for O(log n) performance
    /// Returns the index of the last timestamp that is <= current time
    /// Returns nil if timestamps array is empty or time is before first timestamp
    public static func currentStepIndex(at time: TimeInterval, timestamps: [TimeInterval]) -> Int? {
        guard !timestamps.isEmpty else { return nil }
        guard time >= timestamps[0] else { return nil }

        // If time is >= last timestamp, return last step index
        if time >= timestamps[timestamps.count - 1] {
            return timestamps.count - 1
        }

        // Binary search for the last timestamp <= time
        var left = 0
        var right = timestamps.count - 1
        var result: Int?

        while left <= right {
            let mid = left + (right - left) / 2
            let timestamp = timestamps[mid]

            if timestamp <= time {
                result = mid
                left = mid + 1
            } else {
                right = mid - 1
            }
        }

        return result
    }
}
