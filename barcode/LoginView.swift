//
//  LoginView.swift
//  barcode
//
//  Created by Burke Butler on 12/3/25.
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var showingSignUp = false

    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Logo/Title
                VStack(spacing: 12) {
                    Image(systemName: "barcode.viewfinder")
                        .font(.system(size: 64))
                        .foregroundColor(.primary)

                    Text("barcode")
                        .font(.system(size: 36, weight: .light))
                        .foregroundColor(.primary)
                }
                .padding(.bottom, 80)

                // Email field
                TextField("Email", text: $email)
                    .font(.system(size: 17))
                    .padding(16)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
                    .disabled(authManager.isLoading)
                    .padding(.horizontal, 40)
                    .padding(.bottom, 12)

                // Password field
                SecureField("Password", text: $password)
                    .font(.system(size: 17))
                    .padding(16)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .disabled(authManager.isLoading)
                    .padding(.horizontal, 40)
                    .padding(.bottom, 24)

                // Error message
                if let error = authManager.errorMessage {
                    Text(error)
                        .font(.system(size: 14))
                        .foregroundColor(.red)
                        .padding(.horizontal, 40)
                        .padding(.bottom, 12)
                }

                // Sign in button
                Button(action: {
                    Task {
                        await authManager.signIn(email: email, password: password)
                    }
                }) {
                    if authManager.isLoading {
                        ProgressView()
                            .tint(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.blue)
                            .cornerRadius(12)
                    } else {
                        Text("Sign In")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                }
                .disabled(authManager.isLoading)
                .padding(.horizontal, 40)

                // Sign up link
                Button(action: {
                    showingSignUp = true
                }) {
                    Text("Don't have an account? Sign up")
                        .font(.system(size: 15))
                        .foregroundColor(.secondary)
                }
                .padding(.top, 20)
                .disabled(authManager.isLoading)

                Spacer()
                Spacer()
            }
        }
        .sheet(isPresented: $showingSignUp) {
            SignUpView()
        }
    }
}
