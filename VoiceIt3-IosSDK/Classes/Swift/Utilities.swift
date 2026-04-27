import UIKit
import AVFoundation
import Network

/// Shared utility methods for the VoiceIt SDK
@objc public class VoiceItUtilities: NSObject {

    // MARK: - Network

    private static let monitor = NWPathMonitor()
    private static var isConnected = true

    @objc public static func startNetworkMonitoring() {
        monitor.pathUpdateHandler = { path in
            isConnected = (path.status == .satisfied)
        }
        monitor.start(queue: DispatchQueue(label: "io.voiceit.networkmonitor"))
    }

    @objc public static func checkNetwork() -> Bool {
        isConnected
    }

    // MARK: - Validation

    @objc public static func checkUserId(_ userId: String) -> Bool {
        !userId.isEmpty && userId.hasPrefix("usr_")
    }

    @objc public static func checkGroupId(_ groupId: String) -> Bool {
        !groupId.isEmpty && groupId.hasPrefix("grp_")
    }

    // MARK: - Colors

    @objc public static var greenColor: UIColor {
        UIColor(red: 39.0/255.0, green: 174.0/255.0, blue: 96.0/255.0, alpha: 1.0)
    }

    // MARK: - Storyboard

    @objc public static func getVoiceItStoryBoard() -> UIStoryboard {
        #if SWIFT_PACKAGE
        return UIStoryboard(name: "VoiceIt", bundle: .module)
        #else
        let podBundle = Bundle(for: VoiceItUtilities.self)
        if let bundleURL = podBundle.resourceURL?.appendingPathComponent("VoiceIt3-IosSDK.bundle"),
           let bundle = Bundle(url: bundleURL) {
            return UIStoryboard(name: "VoiceIt", bundle: bundle)
        }
        return UIStoryboard(name: "VoiceIt", bundle: podBundle)
        #endif
    }

    // MARK: - Audio

    @objc public static var recordingSettings: [String: Any] {
        [
            AVSampleRateKey: 48000.0,
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVLinearPCMBitDepthKey: 16,
            AVNumberOfChannelsKey: 1,
            AVLinearPCMIsBigEndianKey: false,
            AVLinearPCMIsFloatKey: false,
        ]
    }

    @objc public static func normalizedPowerLevel(from recorder: AVAudioRecorder) -> CGFloat {
        let decibels = recorder.averagePower(forChannel: 0)
        if decibels < -60.0 || decibels == 0.0 {
            return 0.0
        }
        let minDB: Float = -60.0
        let level = pow(10.0, 0.05 * decibels)
        let minLevel = pow(10.0, 0.05 * minDB)
        let normalized = (level - minLevel) / (1.0 - minLevel)
        return CGFloat(pow(normalized, 0.5))
    }

    // MARK: - Video / Image

    @objc public static func imageData(from videoURL: URL, atTime time: TimeInterval) -> Data? {
        let asset = AVURLAsset(url: videoURL)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.apertureMode = .encodedPixels

        guard let cgImage = try? generator.copyCGImage(at: CMTime(value: CMTimeValue(time), timescale: 60), actualTime: nil) else {
            return nil
        }
        let image = UIImage(cgImage: cgImage)
        return image.jpegData(compressionQuality: 0.5)
    }

    // MARK: - Temp Files

    @objc public static func pathForTemporaryFile(suffix: String) -> String {
        NSTemporaryDirectory() + "\(UUID().uuidString).\(suffix)"
    }

    @objc public static func deleteFile(_ path: String) {
        try? FileManager.default.removeItem(atPath: path)
    }

    // MARK: - JSON

    @objc public static func jsonObject(from string: String) -> [String: Any]? {
        guard let data = string.data(using: .utf8) else { return nil }
        return try? JSONSerialization.jsonObject(with: data) as? [String: Any]
    }

    // MARK: - String

    @objc public static func isStringSame(_ a: String, _ b: String) -> Bool {
        a.lowercased() == b.lowercased()
    }

    // MARK: - Face Rectangle

    @objc public static func setupFaceRectangle(_ layer: CALayer) {
        DispatchQueue.main.async {
            layer.zPosition = 1
            layer.borderColor = Theme.mainCGColor
            layer.borderWidth = 3.5
            layer.opacity = 0.5
            layer.isHidden = true
        }
    }

    @objc public static func showFaceRectangle(_ layer: CALayer, face: AVMetadataObject) {
        layer.isHidden = false
        layer.zPosition = 1
        let xPad: CGFloat = 2.5
        let yPad: CGFloat = -10.0
        let hPad: CGFloat = 20.0
        layer.frame = CGRect(
            x: face.bounds.origin.x + xPad,
            y: face.bounds.origin.y + yPad,
            width: face.bounds.size.width,
            height: face.bounds.size.height + hPad
        )
        layer.drawsAsynchronously = true
        layer.cornerRadius = 10.0
    }

    @objc public static func setBottomCorners(for button: UIButton) {
        let path = UIBezierPath(
            roundedRect: button.bounds,
            byRoundingCorners: [.bottomLeft, .bottomRight],
            cornerRadii: CGSize(width: 10, height: 10)
        )
        let mask = CAShapeLayer()
        mask.frame = button.bounds
        mask.path = path.cgPath
        button.layer.mask = mask
    }

    // MARK: - Response Codes

    @objc public static func isBadResponseCode(_ code: String) -> Bool {
        ["MISP", "UNFD", "DDNE", "IFAD", "IFVD", "GERR", "DAID", "UNAC", "CLNE", "ACLR", "FALI"].contains(code)
    }
}

// MARK: - UIColor Hex Extension

public extension UIColor {
    @objc convenience init(hexString: String) {
        var hex = hexString.trimmingCharacters(in: .alphanumerics.inverted)
        if hex.hasPrefix("#") { hex.removeFirst() }
        var rgbValue: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&rgbValue)
        self.init(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: 1.0
        )
    }
}
