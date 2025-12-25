//
//  WineRatingForm.swift
//  barcode
//
//  Created by Burke Butler on 11/30/25.
//

import SwiftUI

struct WineRatingForm: View {
    @Binding var wineName: String
    @Binding var wineDetails: WineDetails
    @Binding var score: Double
    @Binding var notes: String

    // Common wine varietals
    let commonVarietals = [
        "Cabernet Sauvignon", "Merlot", "Pinot Noir", "Syrah/Shiraz", "Malbec",
        "Chardonnay", "Sauvignon Blanc", "Pinot Grigio", "Riesling", "Moscato"
    ]

    // Common wine regions
    let commonRegions = [
        "Napa Valley", "Sonoma", "Bordeaux", "Burgundy", "Tuscany",
        "Rioja", "Mendoza", "Barossa Valley", "Willamette Valley"
    ]

    var body: some View {
        VStack(spacing: 24) {
            // MARK: - Wine Name
            VStack(alignment: .leading, spacing: 8) {
                Text("Wine Name")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)

                TextField("Wine name or label", text: $wineName)
                    .font(.system(size: 16))
                    .padding(14)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .autocorrectionDisabled()
            }

            // MARK: - Wine Details Section
            VStack(alignment: .leading, spacing: 16) {
                Text("Wine Details")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)

                // Style selector
                VStack(alignment: .leading, spacing: 10) {
                    Text("Style")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.secondary)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(WineStyle.allCases, id: \.self) { style in
                                WineStylePill(
                                    style: style,
                                    isSelected: wineDetails.style == style,
                                    onTap: {
                                        wineDetails.style = style
                                    }
                                )
                            }
                        }
                    }
                }

                // Varietal
                VStack(alignment: .leading, spacing: 10) {
                    Text("Varietal")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.secondary)

                    TextField("e.g. Cabernet Sauvignon", text: Binding(
                        get: { wineDetails.varietal ?? "" },
                        set: { wineDetails.varietal = $0.isEmpty ? nil : $0 }
                    ))
                    .font(.system(size: 16))
                    .padding(12)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .autocorrectionDisabled()
                }

                // Region and Vintage
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Region")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.secondary)

                        TextField("e.g. Napa Valley", text: Binding(
                            get: { wineDetails.region ?? "" },
                            set: { wineDetails.region = $0.isEmpty ? nil : $0 }
                        ))
                        .font(.system(size: 16))
                        .padding(12)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .autocorrectionDisabled()
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Vintage")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.secondary)

                        TextField("Year", text: Binding(
                            get: { wineDetails.vintage ?? "" },
                            set: { wineDetails.vintage = $0.isEmpty ? nil : $0 }
                        ))
                        .font(.system(size: 16))
                        .padding(12)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .keyboardType(.numberPad)
                        .frame(width: 90)
                    }
                }

                // Winery
                VStack(alignment: .leading, spacing: 10) {
                    Text("Winery / Producer (optional)")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.secondary)

                    TextField("Producer name", text: Binding(
                        get: { wineDetails.winery ?? "" },
                        set: { wineDetails.winery = $0.isEmpty ? nil : $0 }
                    ))
                    .font(.system(size: 16))
                    .padding(12)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .autocorrectionDisabled()
                }
            }
            .padding(16)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)

            // MARK: - Tasting Profile Section
            VStack(alignment: .leading, spacing: 16) {
                Text("Tasting Profile")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)

                // Sweetness
                VStack(alignment: .leading, spacing: 10) {
                    Text("Sweetness")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.secondary)

                    HStack(spacing: 8) {
                        ForEach(SweetnessLevel.allCases, id: \.self) { level in
                            TastingLevelButton(
                                label: level.rawValue,
                                isSelected: wineDetails.sweetness == level,
                                onTap: { wineDetails.sweetness = level }
                            )
                        }
                    }
                }

                // Body
                VStack(alignment: .leading, spacing: 10) {
                    Text("Body")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.secondary)

                    HStack(spacing: 8) {
                        ForEach(WineBody.allCases, id: \.self) { body in
                            TastingLevelButton(
                                label: body.rawValue,
                                isSelected: wineDetails.body == body,
                                onTap: { wineDetails.body = body }
                            )
                        }
                    }
                }

                // Tannin
                VStack(alignment: .leading, spacing: 10) {
                    Text("Tannin")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.secondary)

                    HStack(spacing: 8) {
                        ForEach(TastingLevel.allCases, id: \.self) { level in
                            TastingLevelButton(
                                label: level.rawValue,
                                isSelected: wineDetails.tannin == level,
                                onTap: { wineDetails.tannin = level }
                            )
                        }
                    }
                }

                // Acidity
                VStack(alignment: .leading, spacing: 10) {
                    Text("Acidity")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.secondary)

                    HStack(spacing: 8) {
                        ForEach(TastingLevel.allCases, id: \.self) { level in
                            TastingLevelButton(
                                label: level.rawValue,
                                isSelected: wineDetails.acidity == level,
                                onTap: { wineDetails.acidity = level }
                            )
                        }
                    }
                }
            }
            .padding(16)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)

            // MARK: - Overall Impression Section
            VStack(alignment: .leading, spacing: 16) {
                Text("Overall Impression")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)

                // Score
                ScoreSlider(score: $score)

                Divider()

                // Tasting Notes
                VStack(alignment: .leading, spacing: 10) {
                    Text("Tasting Notes (optional)")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.secondary)

                    ZStack(alignment: .topLeading) {
                        if notes.isEmpty {
                            Text("Describe flavors, aromas, finish...")
                                .foregroundColor(Color(.placeholderText))
                                .padding(.top, 8)
                                .padding(.leading, 5)
                        }

                        TextEditor(text: $notes)
                            .frame(minHeight: 100)
                            .scrollContentBackground(.hidden)
                            .background(Color.clear)
                    }
                    .padding(12)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                }
            }
            .padding(16)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
        }
    }
}

// MARK: - Supporting Components

struct WineStylePill: View {
    let style: WineStyle
    let isSelected: Bool
    let onTap: () -> Void

    var styleColor: Color {
        switch style {
        case .red: return Color(red: 0.5, green: 0.1, blue: 0.1)
        case .white: return Color(red: 0.9, green: 0.85, blue: 0.4)
        case .rose: return Color(red: 0.9, green: 0.5, blue: 0.6)
        case .orange: return Color.orange
        case .sparkling: return Color(red: 0.95, green: 0.95, blue: 0.7)
        case .dessert: return Color(red: 0.6, green: 0.4, blue: 0.2)
        }
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Circle()
                    .fill(styleColor)
                    .frame(width: 12, height: 12)

                Text(style.rawValue)
                    .font(.system(size: 14, weight: isSelected ? .semibold : .medium))
                    .foregroundColor(isSelected ? .primary : .secondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(isSelected ? Color.purple.opacity(0.12) : Color(.systemGray6))
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? Color.purple : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct TastingLevelButton: View {
    let label: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(label)
                .font(.system(size: 14, weight: isSelected ? .semibold : .medium))
                .foregroundColor(isSelected ? .white : .secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(isSelected ? Color.purple : Color(.systemGray6))
                .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
