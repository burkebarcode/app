//
//  DetectionBottomSheet.swift
//  barcode
//
//  Created by Claude Code on 12/25/25.
//

import SwiftUI

struct DetectionBottomSheet: View {
    let detectedInfo: OCRProcessor.ParsedBottleInfo
    let confidence: Double
    let onLogBeverage: () -> Void
    let onViewMatches: () -> Void

    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var coordinator: AppCoordinator

    var body: some View {
        VStack(spacing: 0) {
            // Drag handle
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.secondary.opacity(0.3))
                .frame(width: 36, height: 5)
                .padding(.top, 8)
                .padding(.bottom, 16)

            VStack(spacing: 20) {
                // Status line
                HStack(spacing: 8) {
                    Image(systemName: statusIcon)
                        .foregroundColor(confidenceColor)
                        .font(.system(size: 16, weight: .semibold))

                    Text(statusText)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(confidenceColor)

                    Spacer()
                }

                // Detected beverage info
                VStack(alignment: .leading, spacing: 8) {
                    // Name (large, bold)
                    if let name = detectedInfo.nameGuess {
                        Text(name)
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.primary)
                            .lineLimit(2)
                    }

                    // Brand (smaller, secondary)
                    if let brand = detectedInfo.brandGuess {
                        Text(brand)
                            .font(.system(size: 17))
                            .foregroundColor(.secondary)
                    }

                    // Vintage chip
                    if let vintage = detectedInfo.vintageGuess {
                        HStack(spacing: 4) {
                            Text(vintage)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color(.tertiarySystemFill))
                                .cornerRadius(8)

                            Spacer()
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Confidence indicator
                HStack(spacing: 6) {
                    Circle()
                        .fill(confidenceColor)
                        .frame(width: 8, height: 8)

                    Text(confidenceText)
                        .font(.footnote)
                        .foregroundColor(.secondary)

                    Spacer()
                }
                .padding(.top, 4)

                // Primary actions
                VStack(spacing: 12) {
                    // Primary: Log this beverage
                    Button(action: {
                        // Pre-fill the add rating sheet with detected info
                        coordinator.prefilledDrinkName = titleCased(detectedInfo.nameGuess)
                        coordinator.prefilledCategory = .wine // Default to wine for now
                        coordinator.prefilledVarietal = extractVarietal(from: detectedInfo)
                        coordinator.prefilledWineStyle = extractWineStyle(from: detectedInfo)
                        coordinator.prefilledVintage = detectedInfo.vintageGuess
                        coordinator.prefilledRegion = extractRegion(from: detectedInfo)
                        onLogBeverage()
                    }) {
                        Text("Log this beverage")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.blue)
                            .cornerRadius(14)
                    }

                    // Secondary: View matches
                    Button(action: onViewMatches) {
                        Text("View matches")
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                }
                .padding(.top, 8)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
        .background(
            BottomSheetBackground()
        )
    }

    // MARK: - Computed Properties

    private var statusIcon: String {
        if confidence >= 0.8 {
            return "checkmark.circle.fill"
        } else {
            return "exclamationmark.triangle.fill"
        }
    }

    private var statusText: String {
        if confidence >= 0.8 {
            return "Bottle recognized"
        } else {
            return "Possible match found"
        }
    }

    private var confidenceColor: Color {
        if confidence >= 0.7 {
            return Color(red: 0.2, green: 0.78, blue: 0.35) // Soft green
        } else if confidence >= 0.4 {
            return Color(red: 1.0, green: 0.75, blue: 0.2) // Soft amber
        } else {
            return Color(red: 0.95, green: 0.45, blue: 0.45) // Muted red
        }
    }

    private var confidenceText: String {
        let percentage = Int(confidence * 100)
        if confidence >= 0.7 {
            return "High confidence • \(percentage)%"
        } else if confidence >= 0.4 {
            return "Medium confidence • \(percentage)%"
        } else {
            return "Low confidence • \(percentage)%"
        }
    }

    // MARK: - Helper Functions

    private func titleCased(_ text: String?) -> String? {
        guard let text = text else { return nil }

        // Split into words and capitalize each
        return text.split(separator: " ")
            .map { word in
                let lowercased = word.lowercased()
                // Keep certain words lowercase (articles, prepositions)
                let lowercaseWords = ["a", "an", "the", "and", "or", "but", "of", "in", "on", "at", "to", "for", "with", "by"]

                if lowercaseWords.contains(lowercased) {
                    return lowercased
                } else {
                    return word.prefix(1).uppercased() + word.dropFirst().lowercased()
                }
            }
            .joined(separator: " ")
            .split(separator: " ")
            .enumerated()
            .map { index, word in
                // Always capitalize first word
                if index == 0 {
                    return word.prefix(1).uppercased() + word.dropFirst().lowercased()
                } else {
                    return String(word)
                }
            }
            .joined(separator: " ")
    }

    private func extractRegion(from info: OCRProcessor.ParsedBottleInfo) -> String? {
        // Common wine regions to look for
        let commonRegions = [
            "Napa", "Napa Valley", "Sonoma", "Paso Robles", "Bordeaux", "Burgundy",
            "Champagne", "Tuscany", "Piedmont", "Rioja", "Barolo", "Chianti",
            "Mendoza", "Marlborough", "Willamette Valley", "Russian River",
            "Central Coast", "Santa Barbara", "Walla Walla", "Columbia Valley"
        ]

        let lowerText = info.rawText.lowercased()

        for region in commonRegions.sorted(by: { $0.count > $1.count }) { // Check longer names first
            if lowerText.contains(region.lowercased()) {
                return region
            }
        }

        return nil
    }

    private func extractVarietal(from info: OCRProcessor.ParsedBottleInfo) -> String? {
        // Common varietals to look for in tokens
        let commonVarietals = [
            "Cabernet Sauvignon", "Cabernet", "Merlot", "Pinot Noir", "Syrah", "Shiraz",
            "Malbec", "Zinfandel", "Chardonnay", "Sauvignon Blanc", "Pinot Grigio",
            "Pinot Gris", "Riesling", "Moscato", "Blend"
        ]

        let lowerText = info.rawText.lowercased()

        for varietal in commonVarietals {
            if lowerText.contains(varietal.lowercased()) {
                return varietal
            }
        }

        return nil
    }

    private func extractWineStyle(from info: OCRProcessor.ParsedBottleInfo) -> WineStyle? {
        let lowerText = info.rawText.lowercased()
        let tokens = info.tokens.map { $0.lowercased() }

        // Check for wine style indicators
        if tokens.contains("red") || lowerText.contains("red wine") {
            return .red
        } else if tokens.contains("white") || lowerText.contains("white wine") {
            return .white
        } else if tokens.contains("rosé") || tokens.contains("rose") || lowerText.contains("rosé") {
            return .rose
        } else if tokens.contains("sparkling") || lowerText.contains("champagne") || lowerText.contains("prosecco") {
            return .sparkling
        }

        // Default based on varietal if known
        if let varietal = extractVarietal(from: info) {
            let redVarietals = ["Cabernet Sauvignon", "Cabernet", "Merlot", "Pinot Noir", "Syrah", "Shiraz", "Malbec", "Zinfandel"]
            let whiteVarietals = ["Chardonnay", "Sauvignon Blanc", "Pinot Grigio", "Pinot Gris", "Riesling", "Moscato"]

            if redVarietals.contains(varietal) {
                return .red
            } else if whiteVarietals.contains(varietal) {
                return .white
            }
        }

        // Default to red if we can't determine
        return .red
    }
}

// MARK: - Bottom Sheet Background

struct BottomSheetBackground: View {
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ZStack {
            // Frosted glass effect
            if colorScheme == .dark {
                Color.black.opacity(0.7)
            } else {
                Color.white.opacity(0.9)
            }

            // Blur
            Rectangle()
                .fill(.ultraThinMaterial)
        }
        .cornerRadius(28, corners: [.topLeft, .topRight])
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: -2)
        .ignoresSafeArea(edges: .bottom)
    }
}

// Note: RoundedCorner extension is defined in MapVenueSearchView.swift

#Preview {
    ZStack {
        Color.gray.ignoresSafeArea()

        VStack {
            Spacer()

            DetectionBottomSheet(
                detectedInfo: OCRProcessor.ParsedBottleInfo(
                    rawText: "Caymus Cabernet Sauvignon 2019",
                    tokens: ["caymus", "cabernet", "sauvignon", "2019"],
                    brandGuess: "Caymus Vineyards",
                    nameGuess: "Cabernet Sauvignon",
                    vintageGuess: "2019"
                ),
                confidence: 0.92,
                onLogBeverage: {},
                onViewMatches: {}
            )
        }
    }
}
