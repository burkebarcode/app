//
//  SignUpView.swift
//  barcode
//
//  Created by Burke Butler on 12/4/25.
//

import SwiftUI

struct SignUpView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authManager: AuthManager

    @State private var email: String = ""
    @State private var handle: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""

    var isValid: Bool {
        !email.isEmpty &&
        !handle.isEmpty &&
        password.count >= 8 &&
        password == confirmPassword
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "barcode.viewfinder")
                            .font(.system(size: 48))
                            .foregroundColor(.blue)

                        Text("Create Account")
                            .font(.system(size: 28, weight: .bold))

                        Text("Join the community")
                            .font(.system(size: 15))
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 40)
                    .padding(.bottom, 20)

                    // Form fields
                    VStack(spacing: 16) {
                        // Email
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Email")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)

                            TextField("your@email.com", text: $email)
                                .font(.system(size: 17))
                                .padding(14)
                                .background(Color(.systemGray6))
                                .cornerRadius(10)
                                .autocapitalization(.none)
                                .keyboardType(.emailAddress)
                                .disabled(authManager.isLoading)
                        }

                        // Handle
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Username")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)

                            TextField("username", text: $handle)
                                .font(.system(size: 17))
                                .padding(14)
                                .background(Color(.systemGray6))
                                .cornerRadius(10)
                                .autocapitalization(.none)
                                .disabled(authManager.isLoading)
                        }

                        // Password
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Password")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)

                            SecureField("At least 8 characters", text: $password)
                                .font(.system(size: 17))
                                .padding(14)
                                .background(Color(.systemGray6))
                                .cornerRadius(10)
                                .disabled(authManager.isLoading)
                        }

                        // Confirm Password
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Confirm Password")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)

                            SecureField("Confirm password", text: $confirmPassword)
                                .font(.system(size: 17))
                                .padding(14)
                                .background(Color(.systemGray6))
                                .cornerRadius(10)
                                .disabled(authManager.isLoading)

                            if !password.isEmpty && !confirmPassword.isEmpty && password != confirmPassword {
                                Text("Passwords don't match")
                                    .font(.system(size: 13))
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    .padding(.horizontal, 24)

                    // Error message
                    if let error = authManager.errorMessage {
                        Text(error)
                            .font(.system(size: 14))
                            .foregroundColor(.red)
                            .padding(.horizontal, 24)
                    }

                    // Sign up button
                    Button(action: {
                        Task {
                            await authManager.signUp(email: email, handle: handle, password: password)
                            if authManager.isAuthenticated {
                                dismiss()
                            }
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
                            Text("Sign Up")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(isValid ? Color.blue : Color.gray)
                                .cornerRadius(12)
                        }
                    }
                    .disabled(!isValid || authManager.isLoading)
                    .padding(.horizontal, 24)
                    .padding(.top, 8)

                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(authManager.isLoading)
                }
            }
        }
    }
}
