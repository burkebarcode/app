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
        HStack(spacing: 14) {
            // Left thumbnail - photo if available, otherwise category gradient
            if let firstMedia = rating.media?.first {
                let _ = print("RatingCard: media exists, url=\(firstMedia.url), fullUrl=\(firstMedia.fullUrl)")
                AsyncImage(url: URL(string: firstMedia.url)) { phase in
                    switch phase {
                    case .success(let image):
                        let _ = print("RatingCard: AsyncImage SUCCESS for url=\(firstMedia.url)")
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 64, height: 64)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    case .failure(let error):
                        let _ = print("RatingCard: AsyncImage FAILED for url=\(firstMedia.url), error=\(error)")
                        categoryGradientThumbnail
                    case .empty:
                        let _ = print("RatingCard: AsyncImage EMPTY for url=\(firstMedia.url)")
                        categoryGradientThumbnail
                    @unknown default:
                        categoryGradientThumbnail
                    }
                }
            } else {
                let _ = print("RatingCard: NO media for rating \(rating.drinkName)")
                categoryGradientThumbnail
            }

            // Content area
            VStack(alignment: .leading, spacing: 6) {
                // Line 1: Drink name (bold, primary)
                Text(rating.drinkName)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)

                // Line 2: Secondary identity (brewery/style/venue depending on drink type)
                if let secondaryText = secondaryIdentity {
                    Text(secondaryText)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                // Rating + sentiment
                HStack(spacing: 6) {
                    if let stars = rating.stars {
                        StarRatingView(rating: stars, size: 14)

                        Text("\(stars).0")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)

                        if let sentiment = sentiment(for: stars) {
                            Text("•")
                                .font(.system(size: 11))
                                .foregroundColor(Color(.tertiaryLabel))

                            Text(sentiment)
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.top, 2)

                // Metadata row (venue + time)
                HStack(spacing: 4) {
                    Text(rating.relativeTime)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Category badge (subtle)
            Text(rating.category.rawValue.prefix(1).uppercased())
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(categoryColor)
                .frame(width: 24, height: 24)
                .background(categoryColor.opacity(0.12))
                .cornerRadius(6)
        }
        .padding(14)
        .background(Color(.systemBackground))
        .cornerRadius(14)
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
    }

    // Secondary identity text based on drink category
    var secondaryIdentity: String? {
        switch rating.category {
        case .beer:
            if let brewery = rating.beerDetails?.brewery {
                if let style = rating.beerDetails?.style {
                    return "\(brewery) · \(style.rawValue)"
                }
                return brewery
            }
            return rating.beerDetails?.style?.rawValue

        case .wine:
            var parts: [String] = []
            if let style = rating.wineDetails?.style {
                parts.append(style.rawValue)
            }
            if let region = rating.wineDetails?.region {
                parts.append(region)
            }
            return parts.isEmpty ? nil : parts.joined(separator: " · ")

        case .cocktail:
            var parts: [String] = []
            if let spirit = rating.cocktailDetails?.baseSpirit {
                parts.append(spirit.rawValue)
            }
            if let family = rating.cocktailDetails?.cocktailFamily {
                parts.append(family.rawValue)
            }
            return parts.isEmpty ? nil : parts.joined(separator: " · ")

        case .other:
            return nil
        }
    }

    // Simple sentiment for personality
    func sentiment(for stars: Int) -> String? {
        switch stars {
        case 1: return "Meh"
        case 2: return "Okay"
        case 3: return "Solid"
        case 4: return "Great"
        case 5: return "Amazing"
        default: return nil
        }
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

    var categoryGradientThumbnail: some View {
        ZStack {
            // Gradient background keyed to drink type
            LinearGradient(
                gradient: Gradient(colors: [categoryColor.opacity(0.6), categoryColor.opacity(0.3)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Drink type icon
            Image(systemName: categoryIcon)
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(.white)
        }
        .frame(width: 64, height: 64)
        .cornerRadius(12)
    }
}
