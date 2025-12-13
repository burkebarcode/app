//
//  SocialFeedCard.swift
//  barcode
//
//  Created by Burke Butler on 11/30/25.
//

import SwiftUI

struct SocialFeedCard: View {
    let post: FeedPost
    let user: User
    let venue: Venue?
    @EnvironmentObject var dataStore: DataStore
    @State private var showComments = false

    // TODO: Replace with actual current user ID from auth system
    let currentUserId = UUID()

    var isLiked: Bool {
        post.likedBy.contains(currentUserId)
    }

    var body: some View {
        VStack(spacing: 12) {
            // User header
            HStack(spacing: 12) {
                // Avatar
                if let avatarURL = user.avatarURL {
                    AsyncImage(url: URL(string: avatarURL)) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 40, height: 40)
                                .clipShape(Circle())
                        default:
                            Circle()
                                .fill(Color.blue.opacity(0.2))
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Text(user.displayName.prefix(1))
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.blue)
                                )
                        }
                    }
                } else {
                    Circle()
                        .fill(Color.blue.opacity(0.2))
                        .frame(width: 40, height: 40)
                        .overlay(
                            Text(user.displayName.prefix(1))
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.blue)
                        )
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(user.displayName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.primary)

                    if let venue = venue {
                        HStack(spacing: 4) {
                            Image(systemName: "mappin.circle.fill")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)

                            Text(venue.name)
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Spacer()

                Text(post.relativeTime)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }

            // Drink photo (if available)
            if let photoURL = post.photoURL {
                AsyncImage(url: URL(string: photoURL)) { phase in
                    switch phase {
                    case .empty:
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 280)
                            .cornerRadius(12)
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(maxWidth: .infinity)
                            .frame(height: 280)
                            .clipped()
                            .cornerRadius(12)
                    case .failure:
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 280)
                            .cornerRadius(12)
                    @unknown default:
                        EmptyView()
                    }
                }
            }

            // Drink details
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(post.drinkName)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)

                    Spacer()

                    // Category badge
                    Text(post.category.rawValue)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(categoryColor)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(categoryColor.opacity(0.15))
                        .cornerRadius(8)
                }

                // Star rating
                if let stars = post.stars {
                    StarRatingView(rating: stars, size: 16)
                }

                // Notes
                if let notes = post.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.system(size: 15))
                        .foregroundColor(.secondary)
                        .lineSpacing(3)
                }
            }

            // Action buttons
            HStack(spacing: 24) {
                Button(action: {
                    dataStore.toggleLike(postId: post.id, userId: currentUserId)
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: isLiked ? "heart.fill" : "heart")
                            .font(.system(size: 18))
                        if post.likeCount > 0 {
                            Text("\(post.likeCount)")
                                .font(.system(size: 14, weight: .medium))
                        }
                    }
                    .foregroundColor(isLiked ? .red : .secondary)
                }

                Button(action: {
                    showComments = true
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "bubble.right")
                            .font(.system(size: 18))
                        if post.commentCount > 0 {
                            Text("\(post.commentCount)")
                                .font(.system(size: 14, weight: .medium))
                        }
                    }
                    .foregroundColor(.secondary)
                }

                Spacer()

                Button(action: {}) {
                    Image(systemName: "bookmark")
                        .font(.system(size: 18))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.top, 4)
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
        .sheet(isPresented: $showComments) {
            CommentSheet(post: post, currentUserId: currentUserId)
        }
    }

    var categoryColor: Color {
        switch post.category {
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
}

#Preview {
    SocialFeedCard(
        post: FeedPost(
            userId: UUID(),
            venueId: UUID(),
            drinkName: "Old Fashioned",
            category: .cocktail,
            stars: 5,
            notes: "Absolutely incredible! The bartender really knew what they were doing.",
            photoURL: "https://images.unsplash.com/photo-1514362545857-3bc16c4c7d1b?w=800"
        ),
        user: User(username: "john_doe", displayName: "John Doe"),
        venue: Venue(name: "The Speakeasy", type: .bar, city: "New York")
    )
    .padding()
}
