//
//  TokenManager.swift
//  barcode
//
//  Created by Burke Butler on 12/4/25.
//

import Foundation

class TokenManager {
    static let shared = TokenManager()

    private let accessTokenKey = "access_token"
    private let refreshTokenKey = "refresh_token"
    private let tokenExpiryKey = "token_expiry"
    private let userIdKey = "user_id"

    private init() {}

    // MARK: - Token Storage

    var accessToken: String? {
        get { UserDefaults.standard.string(forKey: accessTokenKey) }
        set { UserDefaults.standard.set(newValue, forKey: accessTokenKey) }
    }

    var refreshToken: String? {
        get { UserDefaults.standard.string(forKey: refreshTokenKey) }
        set { UserDefaults.standard.set(newValue, forKey: refreshTokenKey) }
    }

    var tokenExpiry: Date? {
        get { UserDefaults.standard.object(forKey: tokenExpiryKey) as? Date }
        set { UserDefaults.standard.set(newValue, forKey: tokenExpiryKey) }
    }

    var userId: String? {
        get { UserDefaults.standard.string(forKey: userIdKey) }
        set { UserDefaults.standard.set(newValue, forKey: userIdKey) }
    }

    // MARK: - Token Management

    func saveTokens(accessToken: String, refreshToken: String, expiresIn: Int64, userId: String) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.userId = userId
        self.tokenExpiry = Date().addingTimeInterval(TimeInterval(expiresIn))
    }

    func clearTokens() {
        self.accessToken = nil
        self.refreshToken = nil
        self.tokenExpiry = nil
        self.userId = nil
    }

    var isAuthenticated: Bool {
        return accessToken != nil && refreshToken != nil
    }

    var isTokenExpired: Bool {
        guard let expiry = tokenExpiry else { return true }
        // Consider token expired 5 minutes before actual expiry
        return Date().addingTimeInterval(5 * 60) >= expiry
    }

    func shouldRefreshToken() -> Bool {
        return isAuthenticated && isTokenExpired
    }
}
