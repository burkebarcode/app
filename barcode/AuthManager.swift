//
//  AuthManager.swift
//  barcode
//
//  Created by Burke Butler on 12/3/25.
//

import Foundation
import Combine

@MainActor
class AuthManager: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var currentUser: User?
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false

    private let apiService = APIService.shared
    private let tokenManager = TokenManager.shared

    init() {
        // Check if we have stored tokens
        Task {
            await checkAuthentication()
        }
    }

    private func checkAuthentication() async {
        // If we have tokens, fetch user info
        if tokenManager.isAuthenticated, let userId = tokenManager.userId {
            do {
                let userResponse = try await apiService.getUser(by: userId)
                self.currentUser = User(
                    id: UUID(uuidString: userResponse.id) ?? UUID(),
                    username: userResponse.handle,
                    displayName: userResponse.handle,
                    avatarURL: userResponse.avatarUrl
                )
                self.isAuthenticated = true
            } catch {
                // Token might be invalid, clear and require login
                print("Failed to fetch user on startup: \(error)")
                tokenManager.clearTokens()
                self.isAuthenticated = false
            }
        }
    }

    func signUp(email: String, handle: String, password: String) async {
        isLoading = true
        errorMessage = nil

        do {
            // Create user account
            let userResponse = try await apiService.signUp(email: email, handle: handle, password: password)

            // Automatically log in after signup
            let (_, userId) = try await apiService.login(email: email, password: password)

            // Fetch full user info
            let fullUserResponse = try await apiService.getUser(by: userId)

            // Create user object
            self.currentUser = User(
                id: UUID(uuidString: fullUserResponse.id) ?? UUID(),
                username: fullUserResponse.handle,
                displayName: fullUserResponse.handle,
                avatarURL: fullUserResponse.avatarUrl
            )

            self.isAuthenticated = true
        } catch {
            self.errorMessage = "Sign up failed: \(error.localizedDescription)"
        }

        isLoading = false
    }

    func signIn(email: String, password: String) async {
        isLoading = true
        errorMessage = nil

        do {
            // Login and get tokens
            let (_, userId) = try await apiService.login(email: email, password: password)

            // Fetch user info
            let userResponse = try await apiService.getUser(by: userId)

            self.currentUser = User(
                id: UUID(uuidString: userResponse.id) ?? UUID(),
                username: userResponse.handle,
                displayName: userResponse.handle,
                avatarURL: userResponse.avatarUrl
            )

            self.isAuthenticated = true
        } catch {
            self.errorMessage = "Login failed: \(error.localizedDescription)"
        }

        isLoading = false
    }

    func signOut() async {
        do {
            try await apiService.logout()
        } catch {
            print("Logout error: \(error)")
        }

        apiService.clearTokens()
        self.currentUser = nil
        self.isAuthenticated = false
    }
}

