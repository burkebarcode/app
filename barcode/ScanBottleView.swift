//
//  ScanBottleView.swift
//  barcode
//
//  Created by Claude Code on 12/24/25.
//

import SwiftUI
import AVFoundation
import Vision

struct ScanBottleView: View {
    @StateObject private var cameraManager = CameraManager()
    @StateObject private var ocrProcessor = OCRProcessor()
    @EnvironmentObject var coordinator: AppCoordinator

    @State private var parsedInfo: OCRProcessor.ParsedBottleInfo?
    @State private var isSearching = false
    @State private var showMatchResults = false
    @State private var scanResponse: ScanBottleResponse?
    @State private var errorMessage: String?
    @State private var isProcessingOCR = false
    @State private var showDetectionSheet = false

    var body: some View {
        ZStack {
            // Camera preview
            if cameraManager.isAuthorized && cameraManager.setupComplete {
                CameraPreviewView(previewLayer: cameraManager.getPreviewLayer())
                    .edgesIgnoringSafeArea(.all)
            } else if cameraManager.error != nil {
                VStack(spacing: 20) {
                    Image(systemName: "camera.fill.badge.ellipsis")
                        .font(.system(size: 60))
                        .foregroundColor(.red)

                    Text(cameraManager.error?.errorDescription ?? "Camera error")
                        .multilineTextAlignment(.center)
                        .padding()

                    Button("Open Settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
            } else {
                ZStack {
                    Color.black.edgesIgnoringSafeArea(.all)

                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))

                        Text("Setting up camera...")
                            .foregroundColor(.white)
                    }
                }
            }

            VStack {
                Spacer()

                // Detection bottom sheet
                if let info = parsedInfo, showDetectionSheet {
                    DetectionBottomSheet(
                        detectedInfo: info,
                        confidence: estimateConfidence(info: info),
                        onLogBeverage: {
                            showDetectionSheet = false
                            coordinator.shouldOpenAddRating = true
                        },
                        onViewMatches: {
                            showDetectionSheet = false
                            performSearch()
                        }
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                // Capture button (only when not showing detection sheet)
                if !showDetectionSheet {
                    Button(action: capturePhoto) {
                        VStack(spacing: 8) {
                            Image(systemName: "camera.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.white)
                            Text("Capture Label")
                                .font(.callout)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                        }
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(20)
                        .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 4)
                    }
                    .disabled(isSearching || isProcessingOCR || !cameraManager.setupComplete)
                    .padding(.bottom, 50)
                }
            }

            // Processing overlay
            if isProcessingOCR {
                Color.black.opacity(0.7)
                    .edgesIgnoringSafeArea(.all)

                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))

                    Text("Processing label...")
                        .font(.headline)
                        .foregroundColor(.white)
                }
            }

            // Loading overlay
            if isSearching {
                Color.black.opacity(0.7)
                    .edgesIgnoringSafeArea(.all)

                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))

                    Text("Searching...")
                        .font(.headline)
                        .foregroundColor(.white)
                }
            }

            // Error message
            if let error = errorMessage {
                VStack {
                    Spacer()

                    Text(error)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.red.opacity(0.8))
                        .cornerRadius(12)
                        .padding()
                        .onTapGesture {
                            errorMessage = nil
                        }

                    Spacer().frame(height: 150)
                }
            }
        }
        .sheet(isPresented: $showMatchResults) {
            if let response = scanResponse {
                ScanResultsView(response: response)
            }
        }
        .onAppear {
            // Reset detection state when view appears
            showDetectionSheet = false
            parsedInfo = nil
            errorMessage = nil

            setupCamera()
        }
        .onDisappear {
            cameraManager.stopSession()
        }
        .onChange(of: cameraManager.isAuthorized) { authorized in
            if authorized && !cameraManager.setupComplete {
                print("📷 Camera authorized, setting up...")
                cameraManager.setupCamera()
                cameraManager.startSession()
                print("✅ Camera session started")
            }
        }
    }

    private func setupCamera() {
        print("🎥 Setting up camera...")
        cameraManager.checkAuthorization()

        // If already authorized, setup and start session
        if cameraManager.isAuthorized {
            if !cameraManager.setupComplete {
                print("📷 Camera authorized, initial setup...")
                cameraManager.setupCamera()
            } else {
                print("📷 Camera already setup, restarting session...")
            }
            cameraManager.startSession()
            print("✅ Camera session started")
        } else {
            print("⏳ Waiting for camera authorization...")
        }
        // onChange handler will setup when authorization completes for first time
    }

    private func capturePhoto() {
        print("📸 Capturing photo...")
        isProcessingOCR = true
        errorMessage = nil
        parsedInfo = nil

        // Capture current frame
        guard let pixelBuffer = cameraManager.captureCurrentFrame() else {
            errorMessage = "Failed to capture image"
            isProcessingOCR = false
            print("❌ Failed to capture pixel buffer")
            return
        }

        print("🔍 Processing OCR...")

        // Process OCR on captured frame
        ocrProcessor.processFrame(pixelBuffer) { parsed in
            DispatchQueue.main.async {
                isProcessingOCR = false

                if let parsed = parsed {
                    print("OCR detected: \(parsed.rawText)")
                    self.parsedInfo = parsed
                    withAnimation(.easeOut(duration: 0.3)) {
                        self.showDetectionSheet = true
                    }
                } else {
                    print("No text detected")
                    errorMessage = "No text detected. Try moving closer to the label."
                }
            }
        }
    }

    private func performSearch() {
        guard let info = parsedInfo else {
            errorMessage = "No text detected. Please capture the label first."
            return
        }

        print("🔍 Performing search with text: \(info.rawText)")
        isSearching = true
        errorMessage = nil

        Task {
            do {
                let response = try await APIService.shared.scanBottle(
                    rawText: info.rawText,
                    tokens: info.tokens,
                    brandGuess: info.brandGuess,
                    nameGuess: info.nameGuess,
                    vintageGuess: info.vintageGuess,
                    includePhoto: false
                )

                await MainActor.run {
                    print("Search successful, found \(response.candidates.count) candidates")
                    isSearching = false
                    scanResponse = response
                    showMatchResults = true
                }
            } catch let error as APIError {
                await MainActor.run {
                    isSearching = false
                    let errorMsg: String
                    switch error {
                    case .invalidURL:
                        errorMsg = "Invalid request URL"
                    case .invalidResponse:
                        errorMsg = "Invalid server response"
                    case .httpError(let code):
                        errorMsg = "Server error (code \(code))"
                    case .decodingError:
                        errorMsg = "Failed to decode server response"
                    case .networkError(let err):
                        errorMsg = "Network error: \(err.localizedDescription)"
                    }
                    print("Search failed: \(errorMsg)")
                    errorMessage = errorMsg
                }
            } catch {
                await MainActor.run {
                    isSearching = false
                    let errorMsg = "Search failed: \(error.localizedDescription)"
                    print("\(errorMsg)")
                    errorMessage = errorMsg
                }
            }
        }
    }

    private func estimateConfidence(info: OCRProcessor.ParsedBottleInfo) -> Double {
        // Estimate confidence based on detected fields
        var confidence: Double = 0.0

        if info.nameGuess != nil {
            confidence += 0.4
        }
        if info.brandGuess != nil {
            confidence += 0.3
        }
        if info.vintageGuess != nil {
            confidence += 0.2
        }
        if !info.tokens.isEmpty {
            confidence += 0.1
        }

        return min(confidence, 1.0)
    }
}

// MARK: - Camera Preview View

struct CameraPreviewView: UIViewRepresentable {
    let previewLayer: AVCaptureVideoPreviewLayer

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .black

        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        DispatchQueue.main.async {
            if previewLayer.frame != uiView.bounds {
                previewLayer.frame = uiView.bounds
            }
        }
    }
}

#Preview {
    ScanBottleView()
}
