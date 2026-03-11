import Foundation

public enum ItemSource: String, Codable, Equatable, Sendable {
    case manual
    case fridgeScan = "fridge_scan"
    case receiptScan = "receipt_scan"
}
