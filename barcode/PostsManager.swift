//
//  PostsManager.swift
//  barcode
//
//  Created by Claude on 12/4/25.
//

import Foundation
import Combine

@MainActor
class PostsManager: ObservableObject {
    @Published var posts: [PostResponse] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let apiService = APIService.shared

    func fetchPosts() async {
        isLoading = true
        errorMessage = nil

        do {
            let fetchedPosts = try await apiService.getPosts()
            self.posts = fetchedPosts
        } catch {
            self.errorMessage = "Failed to load posts: \(error.localizedDescription)"
            print("Error fetching posts: \(error)")
        }

        isLoading = false
    }

    func createPost(
        venueId: String? = nil,
        drinkName: String,
        drinkCategory: String,
        stars: Int? = nil,
        score: Double? = nil,
        notes: String? = nil,
        beerDetails: BeerDetailsRequest? = nil,
        wineDetails: WineDetailsRequest? = nil,
        cocktailDetails: CocktailDetailsRequest? = nil,
        venueDetails: VenueDetailsRequest? = nil
    ) async -> Bool {
        isLoading = true
        errorMessage = nil

        do {
            let newPost = try await apiService.createPost(
                venueId: venueId,
                drinkName: drinkName,
                drinkCategory: drinkCategory,
                stars: stars,
                score: score,
                notes: notes,
                beerDetails: beerDetails,
                wineDetails: wineDetails,
                cocktailDetails: cocktailDetails,
                venueDetails: venueDetails
            )

            // Add to the beginning of the list
            self.posts.insert(newPost, at: 0)
            isLoading = false
            return true
        } catch {
            self.errorMessage = "Failed to create post: \(error.localizedDescription)"
            print("Error creating post: \(error)")
            isLoading = false
            return false
        }
    }

    func updatePost(
        postId: String,
        drinkName: String,
        stars: Int? = nil,
        score: Double? = nil,
        notes: String? = nil,
        beerDetails: BeerDetailsRequest? = nil,
        wineDetails: WineDetailsRequest? = nil,
        cocktailDetails: CocktailDetailsRequest? = nil
    ) async -> Bool {
        isLoading = true
        errorMessage = nil

        do {
            let updatedPost = try await apiService.updatePost(
                postId: postId,
                drinkName: drinkName,
                stars: stars,
                score: score,
                notes: notes,
                beerDetails: beerDetails,
                wineDetails: wineDetails,
                cocktailDetails: cocktailDetails
            )

            // Update the post in the list
            if let index = posts.firstIndex(where: { $0.id == postId }) {
                posts[index] = updatedPost
            }

            isLoading = false
            return true
        } catch {
            self.errorMessage = "Failed to update post: \(error.localizedDescription)"
            print("Error updating post: \(error)")
            isLoading = false
            return false
        }
    }

    func deletePost(postId: String) async -> Bool {
        isLoading = true
        errorMessage = nil

        do {
            try await apiService.deletePost(postId: postId)

            // Remove from the list
            posts.removeAll(where: { $0.id == postId })

            isLoading = false
            return true
        } catch {
            self.errorMessage = "Failed to delete post: \(error.localizedDescription)"
            print("Error deleting post: \(error)")
            isLoading = false
            return false
        }
    }
}
