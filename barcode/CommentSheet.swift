//
//  CommentSheet.swift
//  barcode
//
//  Created by Burke Butler on 11/30/25.
//

import SwiftUI

struct CommentSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataStore: DataStore
    let post: FeedPost
    let currentUserId: UUID
    @State private var commentText = ""
    @FocusState private var isCommentFieldFocused: Bool

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Comments list
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        if post.comments.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "bubble.left.and.bubble.right")
                                    .font(.system(size: 48))
                                    .foregroundColor(.secondary)
                                    .padding(.top, 40)

                                Text("No comments yet")
                                    .font(.headline)
                                    .foregroundColor(.secondary)

                                Text("Be the first to comment!")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                        } else {
                            ForEach(post.comments) { comment in
                                if let user = dataStore.getUser(for: comment.userId) {
                                    CommentRow(comment: comment, user: user)
                                }
                            }
                        }
                    }
                    .padding()
                }

                Divider()

                // Comment input
                HStack(spacing: 12) {
                    if let currentUser = dataStore.getUser(for: currentUserId) {
                        // Avatar
                        if let avatarURL = currentUser.avatarURL {
                            AsyncImage(url: URL(string: avatarURL)) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 32, height: 32)
                                        .clipShape(Circle())
                                default:
                                    Circle()
                                        .fill(Color.blue.opacity(0.2))
                                        .frame(width: 32, height: 32)
                                        .overlay(
                                            Text(currentUser.displayName.prefix(1))
                                                .font(.system(size: 14, weight: .semibold))
                                                .foregroundColor(.blue)
                                        )
                                }
                            }
                        } else {
                            Circle()
                                .fill(Color.blue.opacity(0.2))
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Text(currentUser.displayName.prefix(1))
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.blue)
                                )
                        }
                    }

                    TextField("Add a comment...", text: $commentText, axis: .vertical)
                        .textFieldStyle(PlainTextFieldStyle())
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(.systemGray6))
                        .cornerRadius(20)
                        .focused($isCommentFieldFocused)

                    Button(action: postComment) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(commentText.isEmpty ? .gray : .blue)
                    }
                    .disabled(commentText.isEmpty)
                }
                .padding()
                .background(Color(.systemBackground))
            }
            .navigationTitle("Comments")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                isCommentFieldFocused = true
            }
        }
    }

    private func postComment() {
        guard !commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        dataStore.addComment(postId: post.id, userId: currentUserId, text: commentText)
        commentText = ""
    }
}

struct CommentRow: View {
    let comment: Comment
    let user: User

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Avatar
            if let avatarURL = user.avatarURL {
                AsyncImage(url: URL(string: avatarURL)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 36, height: 36)
                            .clipShape(Circle())
                    default:
                        Circle()
                            .fill(Color.blue.opacity(0.2))
                            .frame(width: 36, height: 36)
                            .overlay(
                                Text(user.displayName.prefix(1))
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.blue)
                            )
                    }
                }
            } else {
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 36, height: 36)
                    .overlay(
                        Text(user.displayName.prefix(1))
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.blue)
                    )
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(user.displayName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)

                    Spacer()

                    Text(comment.relativeTime)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }

                Text(comment.text)
                    .font(.system(size: 14))
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
