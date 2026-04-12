import SwiftUI
import VoiceIt3_IosSDK

class VoiceItViewModel: ObservableObject {
    @Published var apiKey = ""
    @Published var apiToken = ""
    @Published var userId = ""
    @Published var phrase = "never forget tomorrow is a new day"
    @Published var contentLanguage = "en-US"
    @Published var showAlert = false
    @Published var alertMessage = ""

    private var voiceIt: VoiceItAPIThree?

    init() {
        let args = ProcessInfo.processInfo.arguments
        if let idx = args.firstIndex(of: "--apiKey"), idx + 1 < args.count {
            apiKey = args[idx + 1]
        }
        if let idx = args.firstIndex(of: "--apiToken"), idx + 1 < args.count {
            apiToken = args[idx + 1]
        }
        if let idx = args.firstIndex(of: "--userId"), idx + 1 < args.count {
            userId = args[idx + 1]
        }
    }

    private func initSDK() -> Bool {
        guard !apiKey.isEmpty, !apiToken.isEmpty else {
            alertMessage = "Please enter your API Key and API Token"
            showAlert = true
            return false
        }
        guard !userId.isEmpty else {
            alertMessage = "Please enter a User ID"
            showAlert = true
            return false
        }
        guard let vc = topViewController() else {
            alertMessage = "Cannot find view controller"
            showAlert = true
            return false
        }
        let styles = NSMutableDictionary(dictionary: [
            "kThemeColor": "#FBC132",
            "kIconStyle": "default"
        ])
        voiceIt = VoiceItAPIThree(vc, apiKey: apiKey, apiToken: apiToken, styles: styles)
        return true
    }

    private func topViewController() -> UIViewController? {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = scene.windows.first(where: { $0.isKeyWindow }),
              var top = window.rootViewController else { return nil }
        while let presented = top.presentedViewController {
            top = presented
        }
        return top
    }

    // MARK: - Enrollment

    func startVoiceEnrollment() {
        guard initSDK() else { return }
        voiceIt?.encapsulatedVoiceEnrollUser(userId, contentLanguage: contentLanguage, voicePrintPhrase: phrase,
            userEnrollmentsCancelled: { [weak self] in
                DispatchQueue.main.async { self?.showResult("Voice enrollment cancelled") }
            },
            userEnrollmentsPassed: { [weak self] _ in
                DispatchQueue.main.async { self?.showResult("Voice enrollment successful!") }
            })
    }

    func startFaceEnrollment() {
        guard initSDK() else { return }
        voiceIt?.encapsulatedFaceEnrollUser(userId,
            userEnrollmentsCancelled: { [weak self] in
                DispatchQueue.main.async { self?.showResult("Face enrollment cancelled") }
            },
            userEnrollmentsPassed: { [weak self] _ in
                DispatchQueue.main.async { self?.showResult("Face enrollment successful!") }
            })
    }

    func startVideoEnrollment() {
        guard initSDK() else { return }
        voiceIt?.encapsulatedVideoEnrollUser(userId, contentLanguage: contentLanguage, voicePrintPhrase: phrase,
            userEnrollmentsCancelled: { [weak self] in
                DispatchQueue.main.async { self?.showResult("Video enrollment cancelled") }
            },
            userEnrollmentsPassed: { [weak self] _ in
                DispatchQueue.main.async { self?.showResult("Video enrollment successful!") }
            })
    }

    // MARK: - Verification

    func startVoiceVerification() {
        guard initSDK() else { return }
        voiceIt?.encapsulatedVoiceVerification(userId, contentLanguage: contentLanguage, voicePrintPhrase: phrase,
            userVerificationCancelled: { [weak self] in
                DispatchQueue.main.async { self?.showResult("Voice verification cancelled") }
            },
            userVerificationSuccessful: { [weak self] confidence, _ in
                DispatchQueue.main.async { self?.showResult("Voice verified! Confidence: \(confidence)") }
            },
            userVerificationFailed: { [weak self] confidence, _ in
                DispatchQueue.main.async { self?.showResult("Voice verification failed. Confidence: \(confidence)") }
            })
    }

    func startFaceVerification() {
        guard initSDK() else { return }
        voiceIt?.encapsulatedFaceVerification(userId, contentLanguage: contentLanguage,
            userVerificationCancelled: { [weak self] in
                DispatchQueue.main.async { self?.showResult("Face verification cancelled") }
            },
            userVerificationSuccessful: { [weak self] confidence, _ in
                DispatchQueue.main.async { self?.showResult("Face verified! Confidence: \(confidence)") }
            },
            userVerificationFailed: { [weak self] confidence, _ in
                DispatchQueue.main.async { self?.showResult("Face verification failed. Confidence: \(confidence)") }
            })
    }

    func startVideoVerification() {
        guard initSDK() else { return }
        voiceIt?.encapsulatedVideoVerification(userId, contentLanguage: contentLanguage, voicePrintPhrase: phrase,
            userVerificationCancelled: { [weak self] in
                DispatchQueue.main.async { self?.showResult("Video verification cancelled") }
            },
            userVerificationSuccessful: { [weak self] faceConfidence, voiceConfidence, _ in
                DispatchQueue.main.async { self?.showResult("Video verified! Face: \(faceConfidence), Voice: \(voiceConfidence)") }
            },
            userVerificationFailed: { [weak self] faceConfidence, voiceConfidence, _ in
                DispatchQueue.main.async { self?.showResult("Video verification failed. Face: \(faceConfidence), Voice: \(voiceConfidence)") }
            })
    }

    private func showResult(_ msg: String) {
        alertMessage = msg
        showAlert = true
    }
}
