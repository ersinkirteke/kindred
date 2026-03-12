import Foundation

/// Represents a scan job for processing pantry photos
public struct ScanJob: Equatable, Sendable {
    public let id: String
    public let status: ScanJobStatus
    public let photoUrl: String
    public let scanType: ScanType

    public init(id: String, status: ScanJobStatus, photoUrl: String, scanType: ScanType) {
        self.id = id
        self.status = status
        self.photoUrl = photoUrl
        self.scanType = scanType
    }
}

/// Status of a scan job
public enum ScanJobStatus: String, Equatable, Sendable {
    case uploading
    case processing
    case completed
    case failed
}

/// Type of scan being performed
public enum ScanType: String, Equatable, Sendable, CaseIterable {
    case fridge
    case receipt

    public var displayName: String {
        switch self {
        case .fridge:
            return "Fridge"
        case .receipt:
            return "Receipt"
        }
    }

    public var iconName: String {
        switch self {
        case .fridge:
            return "refrigerator.fill"
        case .receipt:
            return "doc.text.fill"
        }
    }
}
