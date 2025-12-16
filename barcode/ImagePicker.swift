//
//  ImagePicker.swift
//  barcode
//
//  Photo picker with compression for post uploads
//

import SwiftUI
import PhotosUI
import UIKit

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImages: [UIImage]
    var maxSelection: Int = 5

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = maxSelection
        config.preferredAssetRepresentationMode = .current

        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)

            guard !results.isEmpty else { return }

            var images: [UIImage] = []
            let group = DispatchGroup()

            for result in results {
                group.enter()
                result.itemProvider.loadObject(ofClass: UIImage.self) { (object, error) in
                    defer { group.leave() }

                    if let image = object as? UIImage {
                        images.append(image)
                    }
                }
            }

            group.notify(queue: .main) {
                self.parent.selectedImages = images
            }
        }
    }
}

// MARK: - Image Compression Utilities

extension UIImage {
    /// Compress image for upload
    /// - Parameters:
    ///   - maxDimension: Maximum dimension (width or height) in pixels
    ///   - quality: JPEG compression quality (0.0 - 1.0)
    /// - Returns: Compressed JPEG data
    func compressForUpload(maxDimension: CGFloat = 2048, quality: CGFloat = 0.8) -> Data? {
        // Resize if needed
        let resized = self.resized(toMaxDimension: maxDimension)

        // Convert to JPEG with quality
        return resized.jpegData(compressionQuality: quality)
    }

    /// Create thumbnail
    /// - Parameter size: Target size (will maintain aspect ratio)
    /// - Returns: Compressed thumbnail data
    func createThumbnail(size: CGFloat = 320, quality: CGFloat = 0.75) -> Data? {
        let resized = self.resized(toMaxDimension: size)
        return resized.jpegData(compressionQuality: quality)
    }

    /// Resize image to fit within max dimension while maintaining aspect ratio
    private func resized(toMaxDimension maxDimension: CGFloat) -> UIImage {
        let size = self.size

        // If already smaller, return original
        if size.width <= maxDimension && size.height <= maxDimension {
            return self
        }

        // Calculate new size maintaining aspect ratio
        let ratio = size.width / size.height
        var newSize: CGSize

        if size.width > size.height {
            newSize = CGSize(width: maxDimension, height: maxDimension / ratio)
        } else {
            newSize = CGSize(width: maxDimension * ratio, height: maxDimension)
        }

        // Render resized image
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }

    /// Get image dimensions
    var dimensions: (width: Int, height: Int) {
        return (Int(size.width), Int(size.height))
    }
}

// MARK: - SwiftUI Photo Picker (Modern Alternative)

@available(iOS 16.0, *)
struct ModernPhotoPicker: View {
    @Binding var selectedImages: [UIImage]
    @State private var selectedItems: [PhotosPickerItem] = []
    var maxSelection: Int = 5

    var body: some View {
        PhotosPicker(
            selection: $selectedItems,
            maxSelectionCount: maxSelection,
            matching: .images
        ) {
            Label("Select Photos", systemImage: "photo.on.rectangle.angled")
        }
        .onChange(of: selectedItems) { newItems in
            Task {
                var images: [UIImage] = []

                for item in newItems {
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        images.append(image)
                    }
                }

                await MainActor.run {
                    selectedImages = images
                }
            }
        }
    }
}
