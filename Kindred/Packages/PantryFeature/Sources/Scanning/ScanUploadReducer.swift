import Apollo
import ComposableArchitecture
import Foundation
import KindredAPI
import NetworkClient
import UIKit

@Reducer
public struct ScanUploadReducer {
    @ObservableState
    public struct State: Equatable {
        public var image: UIImage
        public var scanType: ScanType
        public var userId: String
        public var uploadProgress: Double = 0
        public var uploadState: UploadState = .compressing
        public var scanJob: ScanJob? = nil
        public var error: String? = nil
        public var isOfflineQueued: Bool = false

        public init(image: UIImage, scanType: ScanType, userId: String) {
            self.image = image
            self.scanType = scanType
            self.userId = userId
        }

        public enum UploadState: Equatable {
            case compressing
            case uploading
            case processing
            case completed
            case failed
        }
    }

    public enum Action {
        case startUpload
        case compressionCompleted(Data)
        case compressionFailed
        case uploadProgressUpdated(Double)
        case uploadCompleted(ScanJob)
        case uploadFailed(String)
        case retryUpload
        case cancelUpload
        case backToPantryTapped
        case delegate(Delegate)

        public enum Delegate {
            case dismissed
            case uploadStarted(ScanJob)
        }
    }

    @Dependency(\.apolloClient) var apolloClient
    @Dependency(\.continuousClock) var clock

    private enum CancelID { case upload }

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .startUpload:
                state.uploadState = .compressing
                state.error = nil

                // Compress image on background thread
                let image = state.image
                return .run { send in
                    let compressedData = await Task.detached {
                        autoreleasepool {
                            image.compressForUpload(maxDimension: 2048, quality: 0.8)
                        }
                    }.value

                    if let data = compressedData {
                        await send(.compressionCompleted(data))
                    } else {
                        await send(.compressionFailed)
                    }
                }

            case let .compressionCompleted(data):
                state.uploadState = .uploading
                state.uploadProgress = 0

                // Upload via Apollo mutation
                let scanType = state.scanType
                let userId = state.userId
                return .run { send in
                    do {
                        // Convert to base64
                        let base64Data = data.base64EncodedString()

                        // Create mutation
                        let graphqlScanType: GraphQLEnum<KindredAPI.ScanType> = scanType == .fridge ? .case(.fridge) : .case(.receipt)
                        let mutation = UploadScanPhotoMutation(
                            userId: userId,
                            scanType: graphqlScanType,
                            photoData: base64Data
                        )

                        // Execute mutation
                        let result = try await apolloClient.perform(mutation: mutation)

                        if let response = result.data?.uploadScanPhoto {
                            // Map GraphQL response to ScanJob
                            let job = ScanJob(
                                id: response.id,
                                status: .init(rawValue: response.status.rawValue.lowercased()) ?? .processing,
                                photoUrl: response.photoUrl,
                                scanType: scanType
                            )
                            await send(.uploadCompleted(job))
                        } else {
                            await send(.uploadFailed("Upload failed - no response"))
                        }
                    } catch {
                        await send(.uploadFailed(error.localizedDescription))
                    }
                }
                .cancellable(id: CancelID.upload)

            case .compressionFailed:
                state.uploadState = .failed
                state.error = String(localized: "scan.upload.compression_failed", defaultValue: "Failed to prepare photo", bundle: .main)
                return .none

            case let .uploadProgressUpdated(progress):
                state.uploadProgress = progress
                return .none

            case let .uploadCompleted(job):
                state.scanJob = job
                state.uploadState = .processing
                state.uploadProgress = 1.0
                return .send(.delegate(.uploadStarted(job)))

            case let .uploadFailed(errorMessage):
                state.uploadState = .failed
                state.error = errorMessage
                return .none

            case .retryUpload:
                state.isOfflineQueued = false
                return .send(.startUpload)

            case .cancelUpload:
                return .run { send in
                    await send(.delegate(.dismissed))
                }
                .cancellable(id: CancelID.upload, cancelInFlight: true)

            case .backToPantryTapped:
                return .send(.delegate(.dismissed))

            case .delegate:
                return .none
            }
        }
    }
}
