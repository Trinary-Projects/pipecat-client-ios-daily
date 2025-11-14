import Foundation
import PipecatClientIOS
import Daily

extension Daily.AudioTrack {
    func toRtvi() -> PipecatClientIOS.MediaStreamTrack {
        return MediaStreamTrack(
            id: MediaTrackId(id: id),
            kind: .audio
        )
    }
}

extension Daily.VideoTrack {
    func toRtvi() -> PipecatClientIOS.MediaStreamTrack {
        return MediaStreamTrack(
            id: MediaTrackId(id: id),
            kind: .video
        )
    }
}

extension Daily.ParticipantID {
    func toRtvi() -> PipecatClientIOS.ParticipantId {
        return PipecatClientIOS.ParticipantId(
            id: self.uuidString
        )
    }
}

extension Daily.Participant {
    func toRtvi() -> PipecatClientIOS.Participant {
        return PipecatClientIOS.Participant(
            id: self.id.toRtvi(),
            name: self.info.username,
            local: self.info.isLocal
        )
    }
}

extension Daily.Device {
    func toRtvi() -> PipecatClientIOS.MediaDeviceInfo {
        return PipecatClientIOS.MediaDeviceInfo(id: MediaDeviceId(id: self.deviceID), name: self.label)
    }
}

extension ClientSettingsUpdate {
    /// Creates a new ClientSettingsUpdate by merging the current settings with camera and microphone enable preferences
    /// - Parameters:
    ///   - enableCam: Whether the camera should be enabled
    ///   - enableMic: Whether the microphone should be enabled
    /// - Returns: A new ClientSettingsUpdate with merged settings
    func mergingCameraAndMicrophoneSettings(enableCam: Bool, enableMic: Bool) -> ClientSettingsUpdate {
        var mergedInputs = self.inputs

        // Override camera and microphone enabled states
        if case .set(var inputSettings) = mergedInputs {
            // Update camera settings
            if case .set(var cameraSettings) = inputSettings.camera {
                cameraSettings.isEnabled = .set(enableCam)
                inputSettings.camera = .set(cameraSettings)
            } else {
                inputSettings.camera = .set(
                    CameraInputSettingsUpdate(
                        isEnabled: .set(enableCam)
                    )
                )
            }

            // Update microphone settings
            if case .set(var micSettings) = inputSettings.microphone {
                micSettings.isEnabled = .set(enableMic)
                inputSettings.microphone = .set(micSettings)
            } else {
                inputSettings.microphone = .set(
                    MicrophoneInputSettingsUpdate(
                        isEnabled: .set(enableMic)
                    )
                )
            }

            mergedInputs = .set(inputSettings)
        } else {
            // If inputs wasn't set, create new input settings
            mergedInputs = .set(
                InputSettingsUpdate(
                    camera: .set(
                        CameraInputSettingsUpdate(
                            isEnabled: .set(enableCam)
                        )
                    ),
                    microphone: .set(
                        MicrophoneInputSettingsUpdate(
                            isEnabled: .set(enableMic)
                        )
                    )
                )
            )
        }

        return ClientSettingsUpdate(
            inputs: mergedInputs,
            publishing: self.publishing
        )
    }
}

extension Daily.NetworkStats {
    func toRtvi() -> PipecatClientIOS.RTVINetworkStats {
        return RTVINetworkStats(
            quality: self.quality,
            threshold: {
                switch self.threshold {
                case .good:
                    return .Good
                case .low:
                    return .Low
                case .veryLow:
                    return .VeryLow
                default:
                    return .Good
                }
            }(),
            previousThreshold: {
                guard let prevThreshold = self.previousThreshold else {
                    return nil
                }
                switch prevThreshold {
                case .good:
                    return .Good
                case .low:
                    return .Low
                case .veryLow:
                    return .VeryLow
                default:
                    return .Good
                }
            }(),
            stats: self.stats.toRtvi()
        )
    }
}

extension Daily.DetailedNetworkStats {
    func toRtvi() -> PipecatClientIOS.RTVIDetailedNetworkStats {
        return RTVIDetailedNetworkStats(
            latest: self.latest.toRtvi(),
            worstVideoReceivePacketLoss: self.worstVideoReceivePacketLoss,
            worstVideoSendPacketLoss: self.worstVideoSendPacketLoss
        )
    }
}

extension Daily.LatestStatistics {
    func toRtvi() -> PipecatClientIOS.RTVILatestStatistics {
        return RTVILatestStatistics(
            receiveBitsPerSecond: self.receiveBitsPerSecond,
            sendBitsPerSecond: self.sendBitsPerSecond,
            timestamp: self.timestamp,
            videoRecvBitsPerSecond: self.videoRecvBitsPerSecond,
            videoSendBitsPerSecond: self.videoSendBitsPerSecond,
            videoRecvPacketLoss: self.videoRecvPacketLoss,
            videoSendPacketLoss: self.videoSendPacketLoss,
            totalRecvPacketLoss: self.totalRecvPacketLoss,
            totalSendPacketLoss: self.totalSendPacketLoss
        )
    }
}

extension Daily.NetworkConnectionStatusUpdate {
    func toRtvi() -> PipecatClientIOS.RTVINetworkConnectionStatusUpdate {
        // NetworkConnectionStatusUpdate is Codable, so we decode it to extract the values
        guard let jsonData = try? JSONEncoder().encode(self),
              let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
              let connectionString = json["connection"] as? String,
              let eventString = json["event"] as? String else {
            // Fallback: return default values if decoding fails
            return RTVINetworkConnectionStatusUpdate(
                connection: .signalling,
                event: .connected
            )
        }
        
        let connection: PipecatClientIOS.RTVINetworkConnectionType = {
            switch connectionString {
            case "signalling":
                return .signalling
            case "recvTransport":
                return .recvTransport
            case "sendTransport":
                return .sendTransport
            default:
                return .signalling
            }
        }()
        
        let event: PipecatClientIOS.RTVINetworkConnectionEventType = {
            switch eventString {
            case "connected":
                return .connected
            case "interrupted":
                return .interrupted
            default:
                return .connected
            }
        }()
        
        return RTVINetworkConnectionStatusUpdate(
            connection: connection,
            event: event
        )
    }
}
