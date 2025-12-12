//
//  RatingCard.swift
//  barcode
//
//  Created by Burke Butler on 11/18/25.
//

import SwiftUI

struct RatingCard: View {
    let rating: Rating

    var body: some View {
        VStack(spacing: 0) {
            // Photo section (if available)
            if let photoName = rating.photoNames.first {
                Image(photoName)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 200)
                    .clipped()
            } else {
                // Placeholder with category color
                Rectangle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [categoryColor.opacity(0.3), categoryColor.opacity(0.1)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 200)
                    .overlay(
                        Image(systemName: categoryIcon)
                            .font(.system(size: 48))
                            .foregroundColor(categoryColor.opacity(0.5))
                    )
            }

            // Content section
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(rating.drinkName)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.primary)

                    Spacer()

                    // Category badge
                    Text(rating.category.rawValue)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(categoryColor)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(categoryColor.opacity(0.15))
                        .cornerRadius(8)
                }

                HStack(spacing: 8) {
                    StarRatingView(rating: rating.stars, size: 16)

                    Text("•")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)

                    Text(rating.relativeTime)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }

                if !rating.notes.isEmpty {
                    Text(rating.notes)
                        .font(.system(size: 15))
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                        .lineSpacing(3)
                        .padding(.top, 2)
                }
            }
            .padding(14)
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
    }

    var categoryColor: Color {
        switch rating.category {
        case .beer:
            return .orange
        case .wine:
            return .purple
        case .cocktail:
            return .blue
        case .other:
            return .gray
        }
    }

    var categoryIcon: String {
        switch rating.category {
        case .beer:
            return "mug.fill"
        case .wine:
            return "wineglass.fill"
        case .cocktail:
            return "cup.and.saucer.fill"
        case .other:
            return "circle.fill"
        }
    }
}

