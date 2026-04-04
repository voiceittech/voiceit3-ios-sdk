import AVFoundation

/// Manages audio recording for voice biometric capture
/// Extracts shared audio logic used by Voice/Video Enrollment and Verification VCs
class AudioRecordingManager: NSObject, AVAudioRecorderDelegate {

    private var audioRecorder: AVAudioRecorder?
    private var recordingTimer: Timer?

    var onRecordingFinished: ((String) -> Void)?
    var onPowerLevelUpdate: ((CGFloat) -> Void)?
    var onRecordingError: ((String) -> Void)?

    private(set) var isRecording = false
    private var outputPath: String = ""

    // MARK: - Recording

    func startRecording(duration: TimeInterval = 4.8) {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try session.setActive(true)
        } catch {
            onRecordingError?("Failed to configure audio session: \(error.localizedDescription)")
            return
        }

        outputPath = VoiceItUtilities.pathForTemporaryFile(suffix: "wav")
        let url = URL(fileURLWithPath: outputPath)

        do {
            audioRecorder = try AVAudioRecorder(url: url, settings: VoiceItUtilities.recordingSettings)
            audioRecorder?.delegate = self
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.record(forDuration: duration)
            isRecording = true

            // Start power level monitoring
            recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
                guard let self, let recorder = self.audioRecorder else { return }
                recorder.updateMeters()
                let level = VoiceItUtilities.normalizedPowerLevel(from: recorder)
                self.onPowerLevelUpdate?(level)
            }
        } catch {
            onRecordingError?("Failed to start recording: \(error.localizedDescription)")
        }
    }

    func stopRecording() {
        recordingTimer?.invalidate()
        recordingTimer = nil
        audioRecorder?.stop()
        isRecording = false
    }

    // MARK: - AVAudioRecorderDelegate

    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        recordingTimer?.invalidate()
        recordingTimer = nil
        isRecording = false

        if flag {
            onRecordingFinished?(outputPath)
        } else {
            onRecordingError?("Recording failed")
        }
    }

    // MARK: - Cleanup

    func cleanup() {
        stopRecording()
        if !outputPath.isEmpty {
            VoiceItUtilities.deleteFile(outputPath)
        }
        audioRecorder = nil
    }

    /// Current normalized power level (0.0 - 1.0)
    var currentPowerLevel: CGFloat {
        guard let recorder = audioRecorder else { return 0 }
        recorder.updateMeters()
        return VoiceItUtilities.normalizedPowerLevel(from: recorder)
    }
}
