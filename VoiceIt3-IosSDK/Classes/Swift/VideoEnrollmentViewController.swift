import UIKit
import AVFoundation

/// Video enrollment — captures face + voice and enrolls via API (3 enrollments required)
@objc(VIVideoEnrollmentViewController)
class VIVideoEnrollmentViewController: UIViewController {

    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var messageleftConstraint: NSLayoutConstraint!
    @IBOutlet weak var progressView: UIView! // SpinningView

    private var myNavController: VIMainNavigationController?
    private var myVoiceIt: VoiceItAPIThree!
    private let cameraManager = CameraSessionManager()
    private let audioManager = AudioRecordingManager()

    private var enrollmentCount = 0
    private let requiredEnrollments = 3
    private var continueRunning = true
    private var enrollmentStarted = false
    private var lookingIntoCam = false
    private var lookingIntoCamCounter = 0
    private var imageData: Data?
    private var originalConstraint: CGFloat = 0
    private var initialBrightness: CGFloat = 0

    // Camera circle
    private var cameraCenterPoint = CGPoint.zero
    private var backgroundWidthHeight: CGFloat = 0
    private var cameraBorderLayer = CALayer()
    private var progressCircle = CAShapeLayer()
    private var faceRectangleLayer = CALayer()

    override func viewDidLoad() {
        super.viewDidLoad()
        initialBrightness = UIScreen.main.brightness
        UIScreen.main.brightness = 1.0

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
        title = "Enrolling Video"

        setupCamera()
        setupAudioCallbacks()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        originalConstraint = messageleftConstraint.constant
        messageLabel.text = VoiceItResponseManager.getMessage("LOOK_INTO_CAM")
    }

    override func viewWillDisappear(_ animated: Bool) {
        UIScreen.main.brightness = initialBrightness
        super.viewWillDisappear(animated)
        cleanup()
    }

    // MARK: - Setup

    private func setupCamera() {
        cameraManager.setupSession(for: view)
        setupCameraCircle()

        cameraManager.onFaceDetected = { [weak self] face in
            guard let self, self.continueRunning else { return }
            VoiceItUtilities.showFaceRectangle(self.faceRectangleLayer, face: face)
            self.lookingIntoCam = true
            self.lookingIntoCamCounter += 1

            if self.lookingIntoCamCounter > 5 && !self.enrollmentStarted {
                self.enrollmentStarted = true
                self.startEnrollmentCapture()
            }
        }

        cameraManager.onFaceLost = { [weak self] in
            self?.lookingIntoCam = false
            self?.faceRectangleLayer.isHidden = true
        }

        cameraManager.onFrameCaptured = { [weak self] sampleBuffer in
            guard let self, self.enrollmentStarted, self.imageData == nil else { return }
            self.imageData = self.cameraManager.captureImageData(from: sampleBuffer)
        }

        cameraManager.start()
    }

    private func setupCameraCircle() {
        let rootLayer = view.layer
        backgroundWidthHeight = view.frame.size.height * 0.42
        let circleWidth: CGFloat = 0.064 * backgroundWidthHeight

        cameraCenterPoint = CGPoint(x: view.frame.size.width / 2, y: view.frame.size.height / 2 - 60)

        cameraBorderLayer.frame = CGRect(
            x: cameraCenterPoint.x - backgroundWidthHeight / 2,
            y: cameraCenterPoint.y - backgroundWidthHeight / 2,
            width: backgroundWidthHeight,
            height: backgroundWidthHeight
        )
        cameraBorderLayer.cornerRadius = circleWidth / 2
        cameraBorderLayer.masksToBounds = true
        cameraBorderLayer.backgroundColor = UIColor(red: 0.17, green: 0.21, blue: 0.27, alpha: 1.0).cgColor

        cameraManager.previewLayer?.frame = CGRect(x: 0, y: 0, width: backgroundWidthHeight, height: backgroundWidthHeight)
        if let preview = cameraManager.previewLayer {
            cameraBorderLayer.addSublayer(preview)
        }

        faceRectangleLayer = CALayer()
        VoiceItUtilities.setupFaceRectangle(faceRectangleLayer)
        cameraBorderLayer.addSublayer(faceRectangleLayer)
        rootLayer.addSublayer(cameraBorderLayer)

        progressCircle.path = UIBezierPath(
            arcCenter: cameraCenterPoint,
            radius: backgroundWidthHeight / 2,
            startAngle: -.pi / 2,
            endAngle: 2 * .pi - .pi / 2,
            clockwise: true
        ).cgPath
        progressCircle.fillColor = UIColor.clear.cgColor
        progressCircle.strokeColor = UIColor.clear.cgColor
        progressCircle.lineWidth = circleWidth * 2
        rootLayer.addSublayer(progressCircle)
    }

    private func setupAudioCallbacks() {
        audioManager.onRecordingFinished = { [weak self] audioPath in
            self?.submitEnrollment(audioPath: audioPath)
        }
        audioManager.onRecordingError = { [weak self] error in
            DispatchQueue.main.async {
                self?.messageLabel.text = error
            }
        }
    }

    // MARK: - Enrollment Flow

    private func startEnrollmentCapture() {
        let prompts = ["ENROLL_0", "ENROLL_1", "ENROLL_2"]
        let phrase = myNavController?.voicePrintPhrase ?? ""
        let promptKey = prompts[min(enrollmentCount, prompts.count - 1)]

        DispatchQueue.main.async { [weak self] in
            self?.messageLabel.text = VoiceItResponseManager.getMessage(promptKey, variable: phrase)
        }

        progressCircle.strokeColor = Theme.mainCGColor
        let animation = CABasicAnimation(keyPath: "strokeEnd")
        animation.fromValue = 0.0
        animation.toValue = 1.0
        animation.duration = 4.8
        progressCircle.add(animation, forKey: "drawCircleAnimation")

        // Start audio recording
        audioManager.startRecording(duration: 4.8)
    }

    private func submitEnrollment(audioPath: String) {
        guard continueRunning else { return }

        DispatchQueue.main.async { [weak self] in
            self?.messageLabel.text = VoiceItResponseManager.getMessage("WAITING")
            self?.progressView.isHidden = false
        }

        let userId = myNavController?.uniqueId ?? ""
        let contentLang = myNavController?.contentLanguage ?? "en-US"
        let phrase = myNavController?.voicePrintPhrase ?? ""
        let capturedImage = imageData ?? Data()

        myVoiceIt.createVideoEnrollment(userId, contentLanguage: contentLang, imageData: capturedImage, audioPath: audioPath, phrase: phrase) { [weak self] jsonResponse in
            guard let self, self.continueRunning else { return }

            VoiceItUtilities.deleteFile(audioPath)

            let json = VoiceItUtilities.jsonObject(from: jsonResponse ?? "") ?? [:]
            let responseCode = json["responseCode"] as? String ?? ""

            DispatchQueue.main.async {
                self.progressView.isHidden = true
                self.progressCircle.strokeColor = UIColor.clear.cgColor

                if responseCode == "SUCC" {
                    self.enrollmentCount += 1
                    self.messageLabel.text = VoiceItResponseManager.getMessage("ENROLL_SUCCESS")

                    if self.enrollmentCount >= self.requiredEnrollments {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            let storyboard = VoiceItUtilities.getVoiceItStoryBoard()
                            let finishVC = storyboard.instantiateViewController(withIdentifier: "enrollFinishedVC")
                            self.navigationController?.pushViewController(finishVC, animated: true)
                        }
                    } else {
                        // Reset for next enrollment
                        self.enrollmentStarted = false
                        self.lookingIntoCamCounter = 0
                        self.imageData = nil
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            self.messageLabel.text = VoiceItResponseManager.getMessage("LOOK_INTO_CAM")
                        }
                    }
                } else {
                    let message = VoiceItResponseManager.getMessage(responseCode)
                    self.messageLabel.text = message

                    if VoiceItUtilities.isBadResponseCode(responseCode) {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            self.exitWithError(jsonResponse ?? "")
                        }
                    } else {
                        self.enrollmentStarted = false
                        self.lookingIntoCamCounter = 0
                        self.imageData = nil
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            self.messageLabel.text = VoiceItResponseManager.getMessage("LOOK_INTO_CAM")
                        }
                    }
                }
            }
        }
    }

    // MARK: - Navigation

    @objc private func cancelClicked() {
        cleanup()
        myNavController?.dismiss(animated: true) { [weak self] in
            self?.myNavController?.userEnrollmentsCancelled?()
        }
    }

    private func exitWithError(_ response: String) {
        cleanup()
        myNavController?.dismiss(animated: true) { [weak self] in
            self?.myNavController?.userEnrollmentsCancelled?()
        }
    }

    private func cleanup() {
        continueRunning = false
        cameraManager.cleanup()
        audioManager.cleanup()
    }
}
