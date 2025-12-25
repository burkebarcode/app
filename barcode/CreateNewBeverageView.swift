//
//  CreateNewBeverageView.swift
//  barcode
//
//  Created by Claude Code on 12/25/25.
//

import SwiftUI

struct CreateNewBeverageView: View {
    let detectedInfo: ScanQuery

    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var coordinator: AppCoordinator

    @State private var name: String
    @State private var brand: String
    @State private var vintage: String
    @State private var category: String = "wine"
    @State private var isCreating = false

    init(detectedInfo: ScanQuery) {
        self.detectedInfo = detectedInfo
        _name = State(initialValue: detectedInfo.name ?? "")
        _brand = State(initialValue: detectedInfo.brand ?? "")
        _vintage = State(initialValue: detectedInfo.vintage ?? "")
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)

                        Text("Create new beverage")
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("We didn't find an exact match, but we filled in what we detected.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top, 20)

                    // Form fields
                    VStack(spacing: 20) {
                        // Category picker
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Category")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)

                            Picker("Category", selection: $category) {
                                Text("Wine").tag("wine")
                                Text("Beer").tag("beer")
                                Text("Cocktail").tag("cocktail")
                            }
                            .pickerStyle(.segmented)
                        }

                        // Name field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Name")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)

                            TextField("e.g., Cabernet Sauvignon", text: $name)
                                .textFieldStyle(RoundedTextFieldStyle())
                        }

                        // Brand field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Brand")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)

                            TextField("e.g., Caymus Vineyards", text: $brand)
                                .textFieldStyle(RoundedTextFieldStyle())
                        }

                        // Vintage field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Vintage (optional)")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)

                            TextField("e.g., 2019", text: $vintage)
                                .textFieldStyle(RoundedTextFieldStyle())
                                .keyboardType(.numberPad)
                        }
                    }
                    .padding(.horizontal)

                    // Primary action
                    Button(action: createAndLogBeverage) {
                        if isCreating {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                        } else {
                            Text("Create & log beverage")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                        }
                    }
                    .background(isFormValid ? Color.blue : Color.gray)
                    .cornerRadius(14)
                    .disabled(!isFormValid || isCreating)
                    .padding(.horizontal)
                    .padding(.top, 8)

                    // Cancel button
                    Button(action: { dismiss() }) {
                        Text("Cancel")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .disabled(isCreating)

                    Spacer(minLength: 40)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.secondary)
                    }
                    .disabled(isCreating)
                }
            }
        }
    }

    private var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private func createAndLogBeverage() {
        isCreating = true

        // TODO: Call API to create new beverage
        // For now, just dismiss and open the add rating sheet
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isCreating = false
            dismiss()
            coordinator.shouldOpenAddRating = true
        }
    }
}

// MARK: - Rounded Text Field Style

struct RoundedTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
    }
}

#Preview {
    CreateNewBeverageView(
        detectedInfo: ScanQuery(
            rawText: "Caymus Cabernet 2019",
            brand: "Caymus",
            name: "Cabernet Sauvignon",
            vintage: "2019"
        )
    )
    .environmentObject(AppCoordinator())
}
