import AVFoundation
import UIKit

/// Manages AVCaptureSession for face/video biometric capture
/// Extracts shared camera logic used by Face/Video Enrollment and Verification VCs
class CameraSessionManager: NSObject, AVCaptureMetadataOutputObjectsDelegate, AVCaptureVideoDataOutputSampleBufferDelegate {

    let captureSession = AVCaptureSession()
    var previewLayer: AVCaptureVideoPreviewLayer?
    var videoDataOutput: AVCaptureVideoDataOutput?
    var metadataOutput: AVCaptureMetadataOutput?

    // Video writing
    var assetWriter: AVAssetWriter?
    var assetWriterInput: AVAssetWriterInput?
    var pixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor?
    var isWriting = false

    // Face detection
    var onFaceDetected: ((AVMetadataObject) -> Void)?
    var onFaceLost: (() -> Void)?
    var onFrameCaptured: ((CMSampleBuffer) -> Void)?

    // State
    private let sessionQueue = DispatchQueue(label: "io.voiceit.camera.session")
    private(set) var isFrontCamera = true
    private(set) var isRunning = false

    // MARK: - Setup

    func setupSession(for view: UIView) {
        captureSession.sessionPreset = .high

        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let input = try? AVCaptureDeviceInput(device: camera) else { return }

        if captureSession.canAddInput(input) {
            captureSession.addInput(input)
        }

        // Video data output for frame capture
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: sessionQueue)
        videoOutput.alwaysDiscardsLateVideoFrames = true
        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        }
        self.videoDataOutput = videoOutput

        // Metadata output for face detection
        let metadata = AVCaptureMetadataOutput()
        if captureSession.canAddOutput(metadata) {
            captureSession.addOutput(metadata)
            metadata.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            if metadata.availableMetadataObjectTypes.contains(.face) {
                metadata.metadataObjectTypes = [.face]
            }
        }
        self.metadataOutput = metadata

        // Preview layer
        let preview = AVCaptureVideoPreviewLayer(session: captureSession)
        preview.videoGravity = .resizeAspectFill
        preview.frame = view.bounds
        view.layer.addSublayer(preview)
        self.previewLayer = preview
    }

    // MARK: - Start / Stop

    func start() {
        sessionQueue.async { [weak self] in
            self?.captureSession.startRunning()
            self?.isRunning = true
        }
    }

    func stop() {
        sessionQueue.async { [weak self] in
            self?.captureSession.stopRunning()
            self?.isRunning = false
        }
    }

    // MARK: - Video Writing

    func startWriting(to url: URL) {
        guard let writer = try? AVAssetWriter(url: url, fileType: .mp4) else { return }

        let settings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: 480,
            AVVideoHeightKey: 640,
        ]
        let writerInput = AVAssetWriterInput(mediaType: .video, outputSettings: settings)
        writerInput.expectsMediaDataInRealTime = true

        let adaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: writerInput,
            sourcePixelBufferAttributes: [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
            ]
        )

        writer.add(writerInput)
        writer.startWriting()
        writer.startSession(atSourceTime: .zero)

        self.assetWriter = writer
        self.assetWriterInput = writerInput
        self.pixelBufferAdaptor = adaptor
        self.isWriting = true
    }

    func stopWriting(completion: @escaping (URL?) -> Void) {
        isWriting = false
        guard let writer = assetWriter else {
            completion(nil)
            return
        }
        assetWriterInput?.markAsFinished()
        writer.finishWriting {
            completion(writer.outputURL)
        }
    }

    // MARK: - Image Capture

    func captureImageData(from sampleBuffer: CMSampleBuffer) -> Data? {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return nil }
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext()
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return nil }
        return UIImage(cgImage: cgImage).jpegData(compressionQuality: 0.5)
    }

    // MARK: - Delegates

    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if let face = metadataObjects.first(where: { $0.type == .face }),
           let transformed = previewLayer?.transformedMetadataObject(for: face) {
            onFaceDetected?(transformed)
        } else {
            onFaceLost?()
        }
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        onFrameCaptured?(sampleBuffer)

        if isWriting, let adaptor = pixelBufferAdaptor,
           let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer),
           assetWriterInput?.isReadyForMoreMediaData == true {
            let time = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
            adaptor.append(pixelBuffer, withPresentationTime: time)
        }
    }

    // MARK: - Cleanup

    func cleanup() {
        stop()
        previewLayer?.removeFromSuperlayer()
        previewLayer = nil
        assetWriter = nil
        assetWriterInput = nil
        pixelBufferAdaptor = nil
    }
}
