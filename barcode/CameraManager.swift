//
//  CameraManager.swift
//  barcode
//
//  Created by Claude Code on 12/24/25.
//

import AVFoundation
import Combine
import UIKit

class CameraManager: NSObject, ObservableObject {
    @Published var isAuthorized = false
    @Published var setupComplete = false
    @Published var error: CameraError?

    private let session = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let sessionQueue = DispatchQueue(label: "camera.session.queue")

    var previewLayer: AVCaptureVideoPreviewLayer?
    var frameHandler: ((CVPixelBuffer) -> Void)?

    enum CameraError: Error, LocalizedError {
        case unauthorized
        case setupFailed
        case deviceNotAvailable

        var errorDescription: String? {
            switch self {
            case .unauthorized:
                return "Camera access denied. Please enable camera access in Settings."
            case .setupFailed:
                return "Failed to setup camera"
            case .deviceNotAvailable:
                return "Camera not available"
            }
        }
    }

    override init() {
        super.init()
    }

    func checkAuthorization() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            isAuthorized = true
        case .notDetermined:
            sessionQueue.suspend()
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                self?.isAuthorized = granted
                self?.sessionQueue.resume()
            }
        default:
            isAuthorized = false
            error = .unauthorized
        }
    }

    func setupCamera() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }

            do {
                try self.configureSession()
                DispatchQueue.main.async {
                    self.setupComplete = true
                }
            } catch {
                DispatchQueue.main.async {
                    self.error = .setupFailed
                }
            }
        }
    }

    private func configureSession() throws {
        session.beginConfiguration()
        session.sessionPreset = .high

        // Add video input
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            session.commitConfiguration()
            throw CameraError.deviceNotAvailable
        }

        let videoInput = try AVCaptureDeviceInput(device: camera)
        if session.canAddInput(videoInput) {
            session.addInput(videoInput)
        } else {
            session.commitConfiguration()
            throw CameraError.setupFailed
        }

        // Add video output
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "camera.frame.queue"))
        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]

        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
        } else {
            session.commitConfiguration()
            throw CameraError.setupFailed
        }

        // Configure video orientation
        if let connection = videoOutput.connection(with: .video) {
            connection.videoOrientation = .portrait
        }

        session.commitConfiguration()
    }

    func startSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            if !self.session.isRunning {
                self.session.startRunning()
            }
        }
    }

    func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            if self.session.isRunning {
                self.session.stopRunning()
            }
        }
    }

    func getPreviewLayer() -> AVCaptureVideoPreviewLayer {
        if let existing = previewLayer {
            return existing
        }

        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        previewLayer = layer
        return layer
    }

    private var latestPixelBuffer: CVPixelBuffer?
    private let bufferQueue = DispatchQueue(label: "camera.buffer.queue")

    func captureCurrentFrame() -> CVPixelBuffer? {
        var buffer: CVPixelBuffer?
        bufferQueue.sync {
            buffer = latestPixelBuffer
        }
        return buffer
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }

        // Store latest frame for manual capture
        bufferQueue.async { [weak self] in
            self?.latestPixelBuffer = pixelBuffer
        }

        // Also call frame handler if set (for continuous processing)
        frameHandler?(pixelBuffer)
    }
}
