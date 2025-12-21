//
//  ScoreSlider.swift
//  barcode
//
//  Precision slider for 0.0-10.0 decimal scoring
//

import SwiftUI

struct ScoreSlider: View {
    @Binding var score: Double
    @State private var showingNumericEntry = false
    @State private var entryText: String = ""
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        VStack(spacing: 16) {
            // Tappable score display
            Button(action: {
                entryText = String(format: "%.1f", score)
                showingNumericEntry = true
                isTextFieldFocused = true
            }) {
                VStack(spacing: 4) {
                    Text("Score")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)

                    if showingNumericEntry {
                        TextField("", text: $entryText)
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(.primary)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.center)
                            .focused($isTextFieldFocused)
                            .frame(height: 60)
                            .onChange(of: entryText) { newValue in
                                // Auto-apply valid scores
                                if let parsedScore = parseScore(newValue) {
                                    score = parsedScore
                                }
                            }
                            .onSubmit {
                                applyTextEntry()
                            }
                    } else {
                        Text(String(format: "%.1f", score))
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(.primary)
                    }

                    Text(scoreDescriptor(for: score))
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(PlainButtonStyle())

            // Precision slider
            VStack(spacing: 8) {
                Slider(value: $score, in: 0.0...10.0, step: 0.1)
                    .accentColor(.blue)
                    .onChange(of: score) { _ in
                        // Close numeric entry when sliding
                        if showingNumericEntry {
                            showingNumericEntry = false
                            isTextFieldFocused = false
                        }
                    }

                // Min/Max labels
                HStack {
                    Text("0.0")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)

                    Spacer()

                    Text("10.0")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 8)
        .onChange(of: isTextFieldFocused) { focused in
            if !focused && showingNumericEntry {
                applyTextEntry()
                showingNumericEntry = false
            }
        }
    }

    private func scoreDescriptor(for score: Double) -> String {
        switch score {
        case 9.0...10.0:
            return "Exceptional"
        case 8.0..<9.0:
            return "Excellent"
        case 7.0..<8.0:
            return "Good"
        case 6.0..<7.0:
            return "Above Average"
        case 5.0..<6.0:
            return "Average"
        case 4.0..<5.0:
            return "Below Average"
        case 2.0..<4.0:
            return "Poor"
        default:
            return "Very Poor"
        }
    }

    private func parseScore(_ text: String) -> Double? {
        guard !text.isEmpty else { return nil }

        // Try to parse as decimal
        if let value = Double(text) {
            // Handle >10 as /100 conversion
            if value > 10 {
                return min(value / 10.0, 10.0)
            }

            // Clamp to bounds
            return min(max(value, 0.0), 10.0)
        }

        return nil
    }

    private func applyTextEntry() {
        if let parsedScore = parseScore(entryText) {
            // Round to 1 decimal place
            score = round(parsedScore * 10) / 10
        }
        entryText = String(format: "%.1f", score)
    }
}

#Preview {
    @Previewable @State var score: Double = 7.5

    VStack {
        ScoreSlider(score: $score)
            .padding()

        Text("Current score: \(score, specifier: "%.1f")")
            .padding()
    }
}
