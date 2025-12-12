//
//  CocktailRatingForm.swift
//  barcode
//
//  Created by Burke Butler on 11/30/25.
//

import SwiftUI

struct CocktailRatingForm: View {
    @Binding var cocktailName: String
    @Binding var cocktailDetails: CocktailDetails
    @Binding var rating: Int
    @Binding var notes: String

    var body: some View {
        VStack(spacing: 24) {
            // MARK: - Cocktail Name
            VStack(alignment: .leading, spacing: 8) {
                Text("Cocktail Name")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)

                TextField("e.g. Old Fashioned", text: $cocktailName)
                    .font(.system(size: 16))
                    .padding(14)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .autocorrectionDisabled()
            }

            // MARK: - Cocktail Details Section
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Cocktail Details")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)

                    Spacer()

                    Image(systemName: "cup.and.saucer.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.blue)
                }

                // Base Spirit selector
                VStack(alignment: .leading, spacing: 10) {
                    Text("Base Spirit")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.secondary)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(BaseSpirit.allCases, id: \.self) { spirit in
                                BaseSpiritPill(
                                    spirit: spirit,
                                    isSelected: cocktailDetails.baseSpirit == spirit,
                                    onTap: {
                                        cocktailDetails.baseSpirit = spirit
                                    }
                                )
                            }
                        }
                    }
                }

                // Cocktail Family
                VStack(alignment: .leading, spacing: 10) {
                    Text("Cocktail Family")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.secondary)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(CocktailFamily.allCases, id: \.self) { family in
                                CocktailFamilyPill(
                                    family: family,
                                    isSelected: cocktailDetails.cocktailFamily == family,
                                    onTap: {
                                        cocktailDetails.cocktailFamily = family
                                    }
                                )
                            }
                        }
                    }
                }

                // Preparation Style
                VStack(alignment: .leading, spacing: 10) {
                    Text("Preparation")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.secondary)

                    HStack(spacing: 8) {
                        ForEach(PreparationStyle.allCases, id: \.self) { style in
                            PreparationButton(
                                style: style,
                                isSelected: cocktailDetails.preparationStyle == style,
                                onTap: { cocktailDetails.preparationStyle = style }
                            )
                        }
                    }
                }
            }
            .padding(16)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)

            // MARK: - Presentation Section
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Presentation")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)

                    Spacer()

                    Image(systemName: "wineglass")
                        .font(.system(size: 20))
                        .foregroundColor(.blue)
                }

                // Glass Type
                VStack(alignment: .leading, spacing: 10) {
                    Text("Glassware")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.secondary)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(GlassType.allCases, id: \.self) { glass in
                                GlassTypePill(
                                    glass: glass,
                                    isSelected: cocktailDetails.glassType == glass,
                                    onTap: { cocktailDetails.glassType = glass }
                                )
                            }
                        }
                    }
                }

                // Garnish
                VStack(alignment: .leading, spacing: 10) {
                    Text("Garnish (optional)")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.secondary)

                    TextField("e.g. Orange peel, cherry", text: Binding(
                        get: { cocktailDetails.garnish ?? "" },
                        set: { cocktailDetails.garnish = $0.isEmpty ? nil : $0 }
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
                HStack {
                    Text("Tasting Profile")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)

                    Spacer()

                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 18))
                        .foregroundColor(.blue)
                }

                // Sweetness
                VStack(alignment: .leading, spacing: 10) {
                    Text("Sweetness")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.secondary)

                    HStack(spacing: 8) {
                        ForEach(BalanceLevel.allCases, id: \.self) { level in
                            BalanceLevelButton(
                                label: level.rawValue,
                                isSelected: cocktailDetails.sweetness == level,
                                onTap: { cocktailDetails.sweetness = level }
                            )
                        }
                    }
                }

                // Booziness
                VStack(alignment: .leading, spacing: 10) {
                    Text("Booziness")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.secondary)

                    HStack(spacing: 8) {
                        ForEach(BalanceLevel.allCases, id: \.self) { level in
                            BalanceLevelButton(
                                label: level.rawValue,
                                isSelected: cocktailDetails.booziness == level,
                                onTap: { cocktailDetails.booziness = level }
                            )
                        }
                    }
                }

                // Balance
                VStack(alignment: .leading, spacing: 10) {
                    Text("Balance")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.secondary)

                    HStack(spacing: 8) {
                        ForEach(BalanceLevel.allCases, id: \.self) { level in
                            BalanceLevelButton(
                                label: level.rawValue,
                                isSelected: cocktailDetails.balance == level,
                                onTap: { cocktailDetails.balance = level }
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

                // Recipe Notes
                VStack(alignment: .leading, spacing: 10) {
                    Text("Recipe Notes (optional)")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.secondary)

                    ZStack(alignment: .topLeading) {
                        if (cocktailDetails.recipeNotes ?? "").isEmpty {
                            Text("What was special or unique about this version?")
                                .foregroundColor(Color(.placeholderText))
                                .padding(.top, 8)
                                .padding(.leading, 5)
                        }

                        TextEditor(text: Binding(
                            get: { cocktailDetails.recipeNotes ?? "" },
                            set: { cocktailDetails.recipeNotes = $0.isEmpty ? nil : $0 }
                        ))
                        .frame(minHeight: 80)
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                    }
                    .padding(12)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                }

                Divider()

                // General Tasting Notes
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
                            .frame(minHeight: 80)
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

struct BaseSpiritPill: View {
    let spirit: BaseSpirit
    let isSelected: Bool
    let onTap: () -> Void

    var spiritColor: Color {
        switch spirit {
        case .gin: return Color(red: 0.5, green: 0.7, blue: 0.8)
        case .rum: return Color(red: 0.8, green: 0.6, blue: 0.4)
        case .tequila: return Color(red: 0.9, green: 0.8, blue: 0.5)
        case .whiskey: return Color(red: 0.7, green: 0.5, blue: 0.3)
        case .vodka: return Color(red: 0.8, green: 0.8, blue: 0.9)
        case .mezcal: return Color(red: 0.6, green: 0.6, blue: 0.6)
        case .bourbon: return Color(red: 0.6, green: 0.3, blue: 0.2)
        case .scotch: return Color(red: 0.7, green: 0.6, blue: 0.4)
        case .brandy: return Color(red: 0.8, green: 0.5, blue: 0.3)
        case .cognac: return Color(red: 0.7, green: 0.4, blue: 0.2)
        case .other: return .gray
        }
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Circle()
                    .fill(spiritColor)
                    .frame(width: 12, height: 12)

                Text(spirit.rawValue)
                    .font(.system(size: 14, weight: isSelected ? .bold : .semibold))
                    .foregroundColor(isSelected ? .primary : .secondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(isSelected ? Color.blue.opacity(0.15) : Color(.systemGray6))
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct CocktailFamilyPill: View {
    let family: CocktailFamily
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(family.rawValue)
                .font(.system(size: 14, weight: isSelected ? .bold : .semibold))
                .foregroundColor(isSelected ? .primary : .secondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(isSelected ? Color.blue.opacity(0.15) : Color(.systemGray6))
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct PreparationButton: View {
    let style: PreparationStyle
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(style.rawValue)
                .font(.system(size: 14, weight: isSelected ? .bold : .semibold))
                .foregroundColor(isSelected ? .white : .secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(isSelected ? Color.blue : Color(.systemGray6))
                .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct GlassTypePill: View {
    let glass: GlassType
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(glass.rawValue)
                .font(.system(size: 14, weight: isSelected ? .bold : .semibold))
                .foregroundColor(isSelected ? .primary : .secondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(isSelected ? Color.blue.opacity(0.15) : Color(.systemGray6))
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct BalanceLevelButton: View {
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
                .background(isSelected ? Color.blue : Color(.systemGray6))
                .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
