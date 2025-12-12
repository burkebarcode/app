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
            if authManager.isAuthenticated {
                ContentView()
                    .environmentObject(authManager)
            } else {
                LoginView()
                    .environmentObject(authManager)
            }
        }
    }
}
