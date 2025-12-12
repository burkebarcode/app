//
//  BeerRatingForm.swift
//  barcode
//
//  Created by Burke Butler on 11/30/25.
//

import SwiftUI

struct BeerRatingForm: View {
    @Binding var beerName: String
    @Binding var beerDetails: BeerDetails
    @Binding var rating: Int
    @Binding var notes: String

    var body: some View {
        VStack(spacing: 24) {
            // MARK: - Beer Name
            VStack(alignment: .leading, spacing: 8) {
                Text("Beer Name")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)

                TextField("Beer name or label", text: $beerName)
                    .font(.system(size: 16))
                    .padding(14)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .autocorrectionDisabled()
            }

            // MARK: - Beer Details Section
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Beer Details")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)

                    Spacer()

                    Image(systemName: "mug.fill")
                        .font(.system(size: 20))
                        .foregroundColor(Color(red: 0.9, green: 0.6, blue: 0.2))
                }

                // Style selector
                VStack(alignment: .leading, spacing: 10) {
                    Text("Style")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.secondary)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(BeerStyle.allCases, id: \.self) { style in
                                BeerStylePill(
                                    style: style,
                                    isSelected: beerDetails.style == style,
                                    onTap: {
                                        beerDetails.style = style
                                    }
                                )
                            }
                        }
                    }
                }

                // Brewery
                VStack(alignment: .leading, spacing: 10) {
                    Text("Brewery")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.secondary)

                    TextField("e.g. Sierra Nevada", text: Binding(
                        get: { beerDetails.brewery ?? "" },
                        set: { beerDetails.brewery = $0.isEmpty ? nil : $0 }
                    ))
                    .font(.system(size: 16))
                    .padding(12)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .autocorrectionDisabled()
                }

                // ABV and IBU
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("ABV %")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.secondary)

                        TextField("e.g. 6.5", text: Binding(
                            get: { beerDetails.abv ?? "" },
                            set: { beerDetails.abv = $0.isEmpty ? nil : $0 }
                        ))
                        .font(.system(size: 16))
                        .padding(12)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .keyboardType(.decimalPad)
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("IBU")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.secondary)

                        TextField("e.g. 45", text: Binding(
                            get: { beerDetails.ibu ?? "" },
                            set: { beerDetails.ibu = $0.isEmpty ? nil : $0 }
                        ))
                        .font(.system(size: 16))
                        .padding(12)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .keyboardType(.numberPad)
                    }
                }
            }
            .padding(16)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)

            // MARK: - Serving Section
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Serving")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)

                    Spacer()

                    Image(systemName: "takeoutbag.and.cup.and.straw.fill")
                        .font(.system(size: 18))
                        .foregroundColor(Color(red: 0.9, green: 0.6, blue: 0.2))
                }

                HStack(spacing: 10) {
                    ForEach(ServingType.allCases, id: \.self) { type in
                        ServingTypePill(
                            type: type,
                            isSelected: beerDetails.servingType == type,
                            onTap: { beerDetails.servingType = type }
                        )
                    }
                }
            }
            .padding(16)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)

            // MARK: - Flavor Profile Section
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Flavor Profile")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)

                    Spacer()

                    Image(systemName: "drop.fill")
                        .font(.system(size: 18))
                        .foregroundColor(Color(red: 0.9, green: 0.6, blue: 0.2))
                }

                // Bitterness
                VStack(alignment: .leading, spacing: 10) {
                    Text("Bitterness")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.secondary)

                    HStack(spacing: 8) {
                        ForEach(FlavorLevel.allCases, id: \.self) { level in
                            FlavorLevelButton(
                                label: level.rawValue,
                                isSelected: beerDetails.bitterness == level,
                                onTap: { beerDetails.bitterness = level }
                            )
                        }
                    }
                }

                // Hoppiness
                VStack(alignment: .leading, spacing: 10) {
                    Text("Hoppiness")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.secondary)

                    HStack(spacing: 8) {
                        ForEach(FlavorLevel.allCases, id: \.self) { level in
                            FlavorLevelButton(
                                label: level.rawValue,
                                isSelected: beerDetails.hoppiness == level,
                                onTap: { beerDetails.hoppiness = level }
                            )
                        }
                    }
                }

                // Maltiness
                VStack(alignment: .leading, spacing: 10) {
                    Text("Maltiness")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.secondary)

                    HStack(spacing: 8) {
                        ForEach(FlavorLevel.allCases, id: \.self) { level in
                            FlavorLevelButton(
                                label: level.rawValue,
                                isSelected: beerDetails.maltiness == level,
                                onTap: { beerDetails.maltiness = level }
                            )
                        }
                    }
                }

                // Mouthfeel
                VStack(alignment: .leading, spacing: 10) {
                    Text("Mouthfeel")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.secondary)

                    HStack(spacing: 8) {
                        ForEach(Mouthfeel.allCases, id: \.self) { feel in
                            FlavorLevelButton(
                                label: feel.rawValue,
                                isSelected: beerDetails.mouthfeel == feel,
                                onTap: { beerDetails.mouthfeel = feel }
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
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)

                // Rating
                VStack(alignment: .leading, spacing: 10) {
                    Text("Rating")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.secondary)

                    HStack {
                        Spacer()
                        StarRatingView(
                            rating: rating,
                            size: 36,
                            interactive: true,
                            onRatingChanged: { newRating in
                                rating = newRating
                            }
                        )
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }

                Divider()

                // Tasting Notes
                VStack(alignment: .leading, spacing: 10) {
                    Text("Tasting Notes (optional)")
                        .font(.system(size: 15, weight: .semibold))
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

struct BeerStylePill: View {
    let style: BeerStyle
    let isSelected: Bool
    let onTap: () -> Void

    var styleColor: Color {
        switch style {
        case .ipa: return Color(red: 0.4, green: 0.7, blue: 0.3)
        case .pale_ale: return Color(red: 0.9, green: 0.7, blue: 0.3)
        case .lager: return Color(red: 1.0, green: 0.9, blue: 0.5)
        case .pilsner: return Color(red: 0.95, green: 0.85, blue: 0.4)
        case .stout: return Color(red: 0.2, green: 0.1, blue: 0.1)
        case .porter: return Color(red: 0.3, green: 0.2, blue: 0.1)
        case .sour: return Color(red: 0.9, green: 0.5, blue: 0.6)
        case .wheat: return Color(red: 0.9, green: 0.8, blue: 0.5)
        case .amber: return Color(red: 0.8, green: 0.4, blue: 0.2)
        case .brown: return Color(red: 0.5, green: 0.3, blue: 0.2)
        case .saison: return Color(red: 0.95, green: 0.9, blue: 0.6)
        case .belgian: return Color(red: 0.8, green: 0.6, blue: 0.3)
        case .other: return .gray
        }
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Circle()
                    .fill(styleColor)
                    .frame(width: 12, height: 12)

                Text(style.rawValue)
                    .font(.system(size: 14, weight: isSelected ? .bold : .semibold))
                    .foregroundColor(isSelected ? .primary : .secondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(isSelected ? Color.orange.opacity(0.15) : Color(.systemGray6))
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? Color.orange : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ServingTypePill: View {
    let type: ServingType
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(type.rawValue)
                .font(.system(size: 15, weight: isSelected ? .bold : .medium))
                .foregroundColor(isSelected ? .white : .secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(isSelected ? Color.orange : Color(.systemGray6))
                .cornerRadius(10)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct FlavorLevelButton: View {
    let label: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(label)
                .font(.system(size: 14, weight: isSelected ? .bold : .semibold))
                .foregroundColor(isSelected ? .white : .secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(isSelected ? Color.orange : Color(.systemGray6))
                .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
