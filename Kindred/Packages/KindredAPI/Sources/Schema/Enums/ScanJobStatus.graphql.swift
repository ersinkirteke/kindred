// @generated
// This file was automatically generated and should not be edited.

@_spi(Internal) import ApolloAPI

/// Current status of scan job processing
public enum ScanJobStatus: String, EnumType {
  case completed = "COMPLETED"
  case failed = "FAILED"
  case processing = "PROCESSING"
  case uploading = "UPLOADING"
}
