//
//  barcodeApp.swift
//  barcode
//
//  Created by Burke Butler on 11/18/25.
//

import SwiftUI

@main
struct barcodeApp: App {
    @StateObject private var authManager = AuthManager()

    var body: some Scene {
        WindowGroup {
            if authManager.isCheckingAuth {
                // Show a loading view while checking authentication
                ZStack {
                    Color(.systemBackground)
                        .ignoresSafeArea()
                    VStack(spacing: 16) {
                        BarcodeLoader()
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 75)
                }
            } else if authManager.isAuthenticated {
                ContentView()
                    .environmentObject(authManager)
            } else {
                LoginView()
                    .environmentObject(authManager)
            }
        }
    }
}
