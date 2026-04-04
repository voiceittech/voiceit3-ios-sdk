import UIKit
import AVFoundation

/// Voice enrollment — records 3 voice samples and enrolls via API
@objc(VIVoiceEnrollmentViewController)
class VIVoiceEnrollmentViewController: UIViewController {

    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var messageleftConstraint: NSLayoutConstraint!
    @IBOutlet weak var progressView: UIView! // SpinningView
    @IBOutlet weak var waveformView: UIView! // SCSiriWaveformView

    private var myNavController: VIMainNavigationController?
    private var myVoiceIt: VoiceItAPIThree!
    private let audioManager = AudioRecordingManager()

    private var enrollmentCount = 0
    private let requiredEnrollments = 3
    private var continueRunning = true
    private var originalConstraint: CGFloat = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.hidesBackButton = true
        myNavController = navigationController as? VIMainNavigationController
        myVoiceIt = myNavController?.myVoiceIt as? VoiceItAPIThree

        let cancelButton = UIBarButtonItem(
            title: VoiceItResponseManager.getMessage("CANCEL"),
            style: .plain, target: self, action: #selector(cancelClicked)
        )
        cancelButton.tintColor = UIColor(hexString: "#FFFFFF")
        navigationItem.leftBarButtonItem = cancelButton

        messageLabel.textColor = .white
        title = "Enrolling Voice"

        setupAudioCallbacks()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        originalConstraint = messageleftConstraint.constant
        startEnrollmentCycle()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        continueRunning = false
        audioManager.cleanup()
    }

    // MARK: - Audio Setup

    private func setupAudioCallbacks() {
        audioManager.onPowerLevelUpdate = { [weak self] level in
            if let waveform = self?.waveformView as? WaveformView {
                waveform.update(withLevel: level)
            }
        }

        audioManager.onRecordingFinished = { [weak self] path in
            self?.processEnrollment(audioPath: path)
        }

        audioManager.onRecordingError = { [weak self] error in
            DispatchQueue.main.async {
                self?.messageLabel.text = error
            }
        }
    }

    // MARK: - Enrollment Flow

    private func startEnrollmentCycle() {
        guard continueRunning else { return }

        let prompts = ["ENROLL_0", "ENROLL_1", "ENROLL_2"]
        let phrase = myNavController?.voicePrintPhrase ?? ""
        let promptKey = prompts[min(enrollmentCount, prompts.count - 1)]

        DispatchQueue.main.async { [weak self] in
            self?.messageLabel.text = VoiceItResponseManager.getMessage(promptKey, variable: phrase)
        }

        // Delay before starting recording
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            guard self?.continueRunning == true else { return }
            self?.audioManager.startRecording(duration: 4.8)
        }
    }

    private func processEnrollment(audioPath: String) {
        guard continueRunning else { return }

        DispatchQueue.main.async { [weak self] in
            self?.messageLabel.text = VoiceItResponseManager.getMessage("WAITING")
            self?.progressView.isHidden = false
        }

        let userId = myNavController?.uniqueId ?? ""
        let contentLang = myNavController?.contentLanguage ?? "en-US"
        let phrase = myNavController?.voicePrintPhrase ?? ""

        myVoiceIt.createVoiceEnrollment(userId, contentLanguage: contentLang, audioPath: audioPath, phrase: phrase) { [weak self] jsonResponse in
            guard let self, self.continueRunning else { return }

            VoiceItUtilities.deleteFile(audioPath)

            let json = VoiceItUtilities.jsonObject(from: jsonResponse ?? "") ?? [:]
            let responseCode = json["responseCode"] as? String ?? ""

            DispatchQueue.main.async {
                self.progressView.isHidden = true

                if responseCode == "SUCC" {
                    self.enrollmentCount += 1
                    self.messageLabel.text = VoiceItResponseManager.getMessage("ENROLL_SUCCESS")

                    if self.enrollmentCount >= self.requiredEnrollments {
                        // All enrollments done
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            let storyboard = VoiceItUtilities.getVoiceItStoryBoard()
                            let finishVC = storyboard.instantiateViewController(withIdentifier: "enrollFinishedVC")
                            self.navigationController?.pushViewController(finishVC, animated: true)
                        }
                    } else {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            self.startEnrollmentCycle()
                        }
                    }
                } else {
                    // Handle error
                    let message = VoiceItResponseManager.getMessage(responseCode)
                    self.messageLabel.text = message

                    if VoiceItUtilities.isBadResponseCode(responseCode) {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            self.exitWithError(jsonResponse ?? "")
                        }
                    } else {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            self.startEnrollmentCycle()
                        }
                    }
                }
            }
        }
    }

    // MARK: - Navigation

    @objc private func cancelClicked() {
        continueRunning = false
        audioManager.cleanup()
        myNavController?.dismiss(animated: true) { [weak self] in
            self?.myNavController?.userEnrollmentsCancelled?()
        }
    }

    private func exitWithError(_ response: String) {
        continueRunning = false
        audioManager.cleanup()
        myNavController?.dismiss(animated: true) { [weak self] in
            self?.myNavController?.userEnrollmentsCancelled?()
        }
    }
}
