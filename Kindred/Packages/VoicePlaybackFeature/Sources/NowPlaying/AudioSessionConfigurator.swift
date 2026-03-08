import AVFoundation
import Foundation
import OSLog

extension Logger {
    private static var subsystem = Bundle.main.bundleIdentifier!
    static let audioSession = Logger(subsystem: subsystem, category: "audio-session")
}

/// Configures AVAudioSession for background audio playback with interruption and route change handling
public enum AudioSessionConfigurator {
    /// Configures the shared audio session for background voice narration playback
    /// Call this from AppDelegate.didFinishLaunchingWithOptions to enable background audio
    public static func configure() {
        do {
            let session = AVAudioSession.sharedInstance()

            // Configure for background playback with spoken audio optimization
            // .playback category: Allows background audio when screen locks or app backgrounds
            // .spokenAudio mode: Optimizes EQ and ducking for voice narration
            try session.setCategory(.playback, mode: .spokenAudio, options: [])
            try session.setActive(true)

            // Register for interruption notifications (phone calls, Siri, alarms)
            NotificationCenter.default.addObserver(
                forName: AVAudioSession.interruptionNotification,
                object: session,
                queue: .main
            ) { notification in
                handleInterruption(notification)
            }

            // Register for route change notifications (headphone unplug, Bluetooth disconnect)
            NotificationCenter.default.addObserver(
                forName: AVAudioSession.routeChangeNotification,
                object: session,
                queue: .main
            ) { notification in
                handleRouteChange(notification)
            }

        } catch {
            Logger.audioSession.error("Failed to configure AVAudioSession: \(error.localizedDescription, privacy: .public)")
        }
    }

    // MARK: - Interruption Handling

    private static func handleInterruption(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }

        switch type {
        case .began:
            // Interruption began (phone call, Siri, etc.)
            // AVPlayer automatically pauses - no action needed
            Logger.audioSession.info("Audio session interrupted")

        case .ended:
            // Interruption ended - check if we should resume
            if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
                let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                if options.contains(.shouldResume) {
                    // System recommends resuming playback
                    // AVPlayer will handle resume via MPRemoteCommandCenter
                    Logger.audioSession.info("Audio session interruption ended - resume recommended")
                } else {
                    // System recommends NOT resuming (user declined call, etc.)
                    Logger.audioSession.info("Audio session interruption ended - resume NOT recommended")
                }
            }

        @unknown default:
            break
        }
    }

    // MARK: - Route Change Handling

    private static func handleRouteChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else {
            return
        }

        switch reason {
        case .oldDeviceUnavailable:
            // Audio route changed because a device was removed (headphones unplugged)
            // Pause playback to prevent unexpected audio through device speaker
            Logger.audioSession.info("Audio device disconnected - pausing playback")
            // AVPlayer will receive pause command via MPRemoteCommandCenter

        case .newDeviceAvailable:
            // New audio route available (headphones plugged in, Bluetooth connected)
            Logger.audioSession.info("New audio device connected")

        case .categoryChange:
            // Audio session category changed by another app
            Logger.audioSession.info("Audio session category changed")

        default:
            break
        }
    }
}
