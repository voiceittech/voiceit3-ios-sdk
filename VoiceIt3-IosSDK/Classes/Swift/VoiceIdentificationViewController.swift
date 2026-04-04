import UIKit
import AVFoundation

/// Voice identification — records voice and identifies from a group via API
@objc(VIVoiceIdentificationViewController)
class VIVoiceIdentificationViewController: UIViewController {

    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var verificationBox: UIView!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var progressView: UIView! // SpinningView
    @IBOutlet weak var waveformView: UIView! // SCSiriWaveformView

    @objc var groupToIdentifyGroupId: String = ""
    @objc var thePhrase: String = ""
    @objc var contentLanguage: String = ""
    @objc var voiceItMaster: NSObject?
    @objc var failsAllowed: Int = 3
    @objc var userIdentificationCancelled: (() -> Void)?
    @objc var userIdentificationSuccessful: ((Float, String, String) -> Void)?
    @objc var userIdentificationFailed: ((Float, String) -> Void)?

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
        messageLabel.text = VoiceItResponseManager.getMessage("IDENTIFY", variable: thePhrase)
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
            self?.processIdentification(audioPath: path)
        }
    }

    private func startRecording() {
        guard continueRunning else { return }
        messageLabel.text = VoiceItResponseManager.getMessage("IDENTIFY", variable: thePhrase)
        audioManager.startRecording(duration: 4.8)
    }

    private func processIdentification(audioPath: String) {
        guard continueRunning else { return }

        DispatchQueue.main.async { [weak self] in
            self?.messageLabel.text = VoiceItResponseManager.getMessage("WAITING")
            self?.progressView.isHidden = false
        }

        guard let voiceIt = voiceItMaster as? VoiceItAPIThree else { return }

        voiceIt.voiceIdentification(groupToIdentifyGroupId, contentLanguage: contentLanguage, audioPath: audioPath, phrase: thePhrase) { [weak self] jsonResponse in
            guard let self, self.continueRunning else { return }

            VoiceItUtilities.deleteFile(audioPath)

            let json = VoiceItUtilities.jsonObject(from: jsonResponse ?? "") ?? [:]
            let responseCode = json["responseCode"] as? String ?? ""
            let confidence = (json["voiceConfidence"] as? NSNumber)?.floatValue ?? 0
            let userId = json["userId"] as? String ?? ""

            DispatchQueue.main.async {
                self.progressView.isHidden = true

                if responseCode == "SUCC" {
                    self.messageLabel.text = VoiceItResponseManager.getMessage("SUCCESS_IDENTIFIED")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        self.dismiss(animated: true) {
                            self.userIdentificationSuccessful?(confidence, userId, jsonResponse ?? "")
                        }
                    }
                } else {
                    self.failCounter += 1
                    self.messageLabel.text = VoiceItResponseManager.getMessage(responseCode)

                    if VoiceItUtilities.isBadResponseCode(responseCode) || self.failCounter >= self.failsAllowed {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            self.dismiss(animated: true) {
                                self.userIdentificationFailed?(confidence, jsonResponse ?? "")
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
            self?.userIdentificationCancelled?()
        }
    }
}
