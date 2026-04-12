import UIKit
import AVFoundation

/// Video verification — captures face + voice and verifies via API
@objc(VIVideoVerificationViewController)
class VIVideoVerificationViewController: UIViewController {

    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var verificationBox: UIView!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var progressView: UIView! // SpinningView

    @objc var userToVerifyUserId: String = ""
    @objc var thePhrase: String = ""
    @objc var contentLanguage: String = ""
    @objc var voiceItMaster: NSObject?
    @objc var failsAllowed: Int = 3
    @objc var userVerificationCancelled: (() -> Void)?
    @objc var userVerificationSuccessful: ((Float, Float, String) -> Void)?
    @objc var userVerificationFailed: ((Float, Float, String) -> Void)?

    private let cameraManager = CameraSessionManager()
    private let audioManager = AudioRecordingManager()
    private var continueRunning = true
    private var verificationStarted = false
    private var lookingIntoCamCounter = 0
    private var failCounter = 0
    private var imageData: Data?
    private var initialBrightness: CGFloat = 0

    private var cameraCenterPoint = CGPoint.zero
    private var backgroundWidthHeight: CGFloat = 0
    private var cameraBorderLayer = CALayer()
    private var progressCircle = CAShapeLayer()
    private var faceRectangleLayer = CALayer()

    override func viewDidLoad() {
        super.viewDidLoad()
        initialBrightness = UIScreen.main.brightness
        UIScreen.main.brightness = 1.0

        view.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        progressView.isHidden = true

        VoiceItUtilities.setBottomCorners(for: cancelButton)
        cancelButton.backgroundColor = Theme.mainUIColor
        cancelButton.setTitle(VoiceItResponseManager.getMessage("CANCEL"), for: .normal)

        setupCamera()
        setupAudioCallbacks()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        messageLabel.text = VoiceItResponseManager.getMessage("LOOK_INTO_CAM")
    }

    override func viewWillDisappear(_ animated: Bool) {
        UIScreen.main.brightness = initialBrightness
        super.viewWillDisappear(animated)
        cleanup()
    }

    private func setupCamera() {
        let container = verificationBox ?? view!
        cameraManager.setupSession(for: container)
        setupCameraCircle(in: container)

        cameraManager.onFaceDetected = { [weak self] face in
            guard let self, self.continueRunning else { return }
            VoiceItUtilities.showFaceRectangle(self.faceRectangleLayer, face: face)
            self.lookingIntoCamCounter += 1

            if self.lookingIntoCamCounter > 5 && !self.verificationStarted {
                self.verificationStarted = true
                self.startVerificationCapture()
            }
        }

        cameraManager.onFaceLost = { [weak self] in
            self?.faceRectangleLayer.isHidden = true
        }

        cameraManager.onFrameCaptured = { [weak self] sampleBuffer in
            guard let self, self.verificationStarted, self.imageData == nil else { return }
            self.imageData = self.cameraManager.captureImageData(from: sampleBuffer)
        }

        cameraManager.start()
    }

    private func setupCameraCircle(in container: UIView) {
        backgroundWidthHeight = container.frame.size.width * 0.85
        let circleWidth: CGFloat = 0.064 * backgroundWidthHeight
        cameraCenterPoint = CGPoint(x: container.frame.size.width / 2, y: container.frame.size.height / 2 - 30)

        cameraBorderLayer.frame = CGRect(
            x: cameraCenterPoint.x - backgroundWidthHeight / 2,
            y: cameraCenterPoint.y - backgroundWidthHeight / 2,
            width: backgroundWidthHeight, height: backgroundWidthHeight
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
        container.layer.addSublayer(cameraBorderLayer)

        progressCircle.path = UIBezierPath(
            arcCenter: cameraCenterPoint, radius: backgroundWidthHeight / 2,
            startAngle: -.pi / 2, endAngle: 2 * .pi - .pi / 2, clockwise: true
        ).cgPath
        progressCircle.fillColor = UIColor.clear.cgColor
        progressCircle.strokeColor = UIColor.clear.cgColor
        progressCircle.lineWidth = circleWidth + 8
        container.layer.addSublayer(progressCircle)
    }

    private func setupAudioCallbacks() {
        audioManager.onRecordingFinished = { [weak self] audioPath in
            self?.submitVerification(audioPath: audioPath)
        }
    }

    private func startVerificationCapture() {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.messageLabel.text = VoiceItResponseManager.getMessage("VERIFY", variable: self.thePhrase)
        }

        progressCircle.strokeColor = Theme.mainCGColor
        let animation = CABasicAnimation(keyPath: "strokeEnd")
        animation.fromValue = 0.0
        animation.toValue = 1.0
        animation.duration = 4.8
        progressCircle.add(animation, forKey: "drawCircleAnimation")

        audioManager.startRecording(duration: 4.8)
    }

    private func submitVerification(audioPath: String) {
        guard continueRunning else { return }

        DispatchQueue.main.async { [weak self] in
            self?.messageLabel.text = VoiceItResponseManager.getMessage("WAITING")
            self?.progressView.isHidden = false
        }

        guard let voiceIt = voiceItMaster as? VoiceItAPIThree else { return }
        let capturedImage = imageData ?? Data()

        voiceIt.videoVerification(userToVerifyUserId, contentLanguage: contentLanguage, imageData: capturedImage, audioPath: audioPath, phrase: thePhrase) { [weak self] jsonResponse in
            guard let self, self.continueRunning else { return }

            VoiceItUtilities.deleteFile(audioPath)

            let json = VoiceItUtilities.jsonObject(from: jsonResponse ?? "") ?? [:]
            let responseCode = json["responseCode"] as? String ?? ""
            let faceConf = (json["faceConfidence"] as? NSNumber)?.floatValue ?? 0
            let voiceConf = (json["voiceConfidence"] as? NSNumber)?.floatValue ?? 0

            DispatchQueue.main.async {
                self.progressView.isHidden = true
                self.progressCircle.strokeColor = UIColor.clear.cgColor

                if responseCode == "SUCC" {
                    self.messageLabel.text = VoiceItResponseManager.getMessage("SUCCESS")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        self.dismiss(animated: true) {
                            self.userVerificationSuccessful?(faceConf, voiceConf, jsonResponse ?? "")
                        }
                    }
                } else {
                    self.failCounter += 1
                    self.messageLabel.text = VoiceItResponseManager.getMessage(responseCode)

                    if VoiceItUtilities.isBadResponseCode(responseCode) || self.failCounter >= self.failsAllowed {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            self.dismiss(animated: true) {
                                self.userVerificationFailed?(faceConf, voiceConf, jsonResponse ?? "")
                            }
                        }
                    } else {
                        self.verificationStarted = false
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

    @IBAction func cancelClicked(_ sender: Any) {
        cleanup()
        dismiss(animated: true) { [weak self] in
            self?.userVerificationCancelled?()
        }
    }

    private func cleanup() {
        continueRunning = false
        cameraManager.cleanup()
        audioManager.cleanup()
    }
}
