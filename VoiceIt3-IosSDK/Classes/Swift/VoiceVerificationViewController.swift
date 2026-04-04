import UIKit
import AVFoundation

/// Voice verification — records voice and verifies via API
@objc(VIVoiceVerificationViewController)
class VIVoiceVerificationViewController: UIViewController {

    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var verificationBox: UIView!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var progressView: UIView! // SpinningView
    @IBOutlet weak var waveformView: UIView! // SCSiriWaveformView

    // Set by the encapsulated method launcher
    @objc var userToVerifyUserId: String = ""
    @objc var thePhrase: String = ""
    @objc var contentLanguage: String = ""
    @objc var voiceItMaster: NSObject?
    @objc var failsAllowed: Int = 3
    @objc var userVerificationCancelled: (() -> Void)?
    @objc var userVerificationSuccessful: ((Float, String) -> Void)?
    @objc var userVerificationFailed: ((Float, String) -> Void)?

    private let audioManager = AudioRecordingManager()
    private var continueRunning = true
    private var failCounter = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        progressView.isHidden = true

        VoiceItUtilities.setBottomCorners(for: cancelButton)
        cancelButton.backgroundColor = Theme.mainUIColor
        cancelButton.setTitle(VoiceItResponseManager.getMessage("CANCEL"), for: .normal)

        setupAudioCallbacks()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        messageLabel.text = VoiceItResponseManager.getMessage("VERIFY", variable: thePhrase)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.startRecording()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        continueRunning = false
        audioManager.cleanup()
    }

    private func setupAudioCallbacks() {
        audioManager.onPowerLevelUpdate = { [weak self] level in
            if let waveform = self?.waveformView as? WaveformView {
                waveform.update(withLevel: level)
            }
        }
        audioManager.onRecordingFinished = { [weak self] path in
            self?.processVerification(audioPath: path)
        }
    }

    private func startRecording() {
        guard continueRunning else { return }
        messageLabel.text = VoiceItResponseManager.getMessage("VERIFY", variable: thePhrase)
        audioManager.startRecording(duration: 4.8)
    }

    private func processVerification(audioPath: String) {
        guard continueRunning else { return }

        DispatchQueue.main.async { [weak self] in
            self?.messageLabel.text = VoiceItResponseManager.getMessage("WAITING")
            self?.progressView.isHidden = false
        }

        guard let voiceIt = voiceItMaster as? VoiceItAPIThree else { return }

        voiceIt.voiceVerification(userToVerifyUserId, contentLanguage: contentLanguage, audioPath: audioPath, phrase: thePhrase) { [weak self] jsonResponse in
            guard let self, self.continueRunning else { return }

            VoiceItUtilities.deleteFile(audioPath)

            let json = VoiceItUtilities.jsonObject(from: jsonResponse ?? "") ?? [:]
            let responseCode = json["responseCode"] as? String ?? ""
            let confidence = (json["voiceConfidence"] as? NSNumber)?.floatValue ?? 0

            DispatchQueue.main.async {
                self.progressView.isHidden = true

                if responseCode == "SUCC" {
                    self.messageLabel.text = VoiceItResponseManager.getMessage("SUCCESS")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        self.dismiss(animated: true) {
                            self.userVerificationSuccessful?(confidence, jsonResponse ?? "")
                        }
                    }
                } else {
                    self.failCounter += 1
                    let message = VoiceItResponseManager.getMessage(responseCode)
                    self.messageLabel.text = message

                    if VoiceItUtilities.isBadResponseCode(responseCode) || self.failCounter >= self.failsAllowed {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            self.dismiss(animated: true) {
                                self.userVerificationFailed?(confidence, jsonResponse ?? "")
                            }
                        }
                    } else {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            self.startRecording()
                        }
                    }
                }
            }
        }
    }

    @IBAction func cancelClicked(_ sender: Any) {
        continueRunning = false
        audioManager.cleanup()
        dismiss(animated: true) { [weak self] in
            self?.userVerificationCancelled?()
        }
    }
}
