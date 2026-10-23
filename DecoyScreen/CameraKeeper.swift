import AVFoundation
import Observation
import UIKit

/// iOS only lets an app put its own content on the outer screen while the
/// inner one is in use if it has a camera session running (that's what
/// `CameraCaptureAccessory` is for). This keeps the smallest session it can:
/// the rear camera at the lowest quality and frame rate, frames thrown away,
/// nothing recorded or saved. The camera indicator stays on while it runs.
@MainActor
@Observable
final class CameraKeeper {
    enum State: Equatable {
        case idle
        case starting
        case running
        /// You said no to camera access.
        case denied
        /// No camera at all, as in the simulator.
        case noCamera
        case failed
    }

    private(set) var state: State = .idle

    @ObservationIgnored private let box = SessionBox()

    func start() async {
        guard state != .running, state != .starting else { return }
        state = .starting

        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            break
        case .notDetermined:
            guard await AVCaptureDevice.requestAccess(for: .video) else {
                state = .denied
                return
            }
        default:
            state = .denied
            return
        }

        let result = await box.start()
        state = switch result {
        case .running: .running
        case .noCamera: .noCamera
        case .failed: .failed
        }
    }

    func stop() {
        guard state == .running || state == .starting else { return }
        state = .idle
        Task { await box.stop() }
    }

    func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

/// Owns the capture session off the main thread.
private actor SessionBox {
    enum Result { case running, noCamera, failed }

    private var session: AVCaptureSession?

    func start() -> Result {
        if let session {
            if !session.isRunning { session.startRunning() }
            return session.isRunning ? .running : .failed
        }
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
                ?? AVCaptureDevice.default(for: .video) else {
            return .noCamera
        }
        let session = AVCaptureSession()
        session.beginConfiguration()
        if session.canSetSessionPreset(.low) { session.sessionPreset = .low }
        guard let input = try? AVCaptureDeviceInput(device: device), session.canAddInput(input) else {
            session.commitConfiguration()
            return .failed
        }
        session.addInput(input)
        // Frames go nowhere; the output only exists so the session counts as capturing.
        let output = AVCaptureVideoDataOutput()
        output.alwaysDiscardsLateVideoFrames = true
        if session.canAddOutput(output) { session.addOutput(output) }
        session.commitConfiguration()
        Self.slowDown(device)
        session.startRunning()
        self.session = session
        return session.isRunning ? .running : .failed
    }

    func stop() {
        session?.stopRunning()
    }

    /// Fewer frames, less battery.
    private static func slowDown(_ device: AVCaptureDevice) {
        let fps: Double = 5
        guard device.activeFormat.videoSupportedFrameRateRanges.contains(where: { $0.minFrameRate <= fps }),
              (try? device.lockForConfiguration()) != nil else { return }
        let frame = CMTime(value: 1, timescale: CMTimeScale(fps))
        device.activeVideoMinFrameDuration = frame
        device.activeVideoMaxFrameDuration = frame
        device.unlockForConfiguration()
    }
}
