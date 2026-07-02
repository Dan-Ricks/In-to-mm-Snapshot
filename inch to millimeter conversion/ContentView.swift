//
//  ContentView.swift
//  In to mm Snapshot
//
//  Created by Dan on 6/20/26.
//

import SwiftUI
import UIKit
import Photos
import StoreKit

struct ContentView: View {
    @State private var inches: String = ""
    @State private var mm: String = ""
    @State private var description: String = ""
    @State private var photo: UIImage?
    @State private var showCamera = false
    @State private var isCapturing = false
    @State private var showSavedAlert = false

    @State private var tipProducts: [Product] = []
    @State private var isPurchasing = false
    @State private var showTipThanks = false

    @FocusState private var focusedField: Field?

    enum Field: Hashable {
        case inches
        case mm
        case description
    }

    private func updateMM() {
        guard let inchesVal = Double(inches) else {
            if mm != "" {
                mm = ""
            }
            return
        }
        let newMM = inchesVal * 25.4
        let formatted = String(format: "%.4f", newMM)
        if formatted != mm {
            mm = formatted
        }
    }

    private func updateInches() {
        guard let mmVal = Double(mm) else {
            if inches != "" {
                inches = ""
            }
            return
        }
        let newInches = mmVal / 25.4
        let formatted = String(format: "%.4f", newInches)
        if formatted != inches {
            inches = formatted
        }
    }

    /// Downsamples a UIImage to a maximum dimension to reduce memory usage.
    /// This prevents OOM kills from very high-resolution camera images.
    static func resizeImage(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let scale = min(maxDimension / max(image.size.width, image.size.height), 1.0)
        if scale >= 1 {
            return image
        }
        let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }

    private func saveToPhotos() {
        isCapturing = true
        // Small delay to hide the save button before capturing
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // Only generate and save the photo + data overlay image (image generator piece)
            if let overlayImage = self.createMeasurementOverlayImage() {
                PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
                    guard status == .authorized || status == .limited else { return }
                    PHPhotoLibrary.shared().performChanges({
                        PHAssetChangeRequest.creationRequestForAsset(from: overlayImage)
                    }) { success, error in
                        DispatchQueue.main.async {
                            if success {
                                self.showSavedAlert = true
                            } else {
                                print("Failed to save image: \(error?.localizedDescription ?? "unknown error")")
                            }
                        }
                    }
                }
            }

            isCapturing = false
        }
    }

    /// Creates a new image using the captured photo as base, with measurement data overlaid at the top
    /// in white text with a black border/outline for legibility.
    private func createMeasurementOverlayImage() -> UIImage? {
        guard let baseImage = photo, !inches.isEmpty || !mm.isEmpty || !description.isEmpty else {
            return nil
        }

        let size = baseImage.size
        let renderer = UIGraphicsImageRenderer(size: size)

        return renderer.image { context in
            // Draw the original photo
            baseImage.draw(in: CGRect(origin: .zero, size: size))

            // Dynamically sized fonts (will be reduced if text is too long)
            var baseFontSize = size.height * 0.065
            var numberFontSize = baseFontSize * 1.2
            var unitFontSize = baseFontSize
            var descFontSize = baseFontSize

            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .left

            func buildAttributedText() -> NSMutableAttributedString {
                paragraphStyle.lineSpacing = baseFontSize * 0.05

                let text = NSMutableAttributedString()

                // Description at the top (normal size)
                if !description.isEmpty {
                    let descFont = UIFont(name: "Arial-BoldMT", size: descFontSize) ?? UIFont.boldSystemFont(ofSize: descFontSize)
                    let descAttributes: [NSAttributedString.Key: Any] = [
                        .font: descFont,
                        .foregroundColor: UIColor.white,
                        .strokeColor: UIColor.black,
                        .strokeWidth: -4.0,
                        .paragraphStyle: paragraphStyle
                    ]
                    text.append(NSAttributedString(string: description, attributes: descAttributes))
                    text.append(NSAttributedString(string: "\n", attributes: descAttributes))
                }

                // Inches: number 20% larger, unit normal size
                if !inches.isEmpty {
                    let numFont = UIFont(name: "Arial-BoldMT", size: numberFontSize) ?? UIFont.boldSystemFont(ofSize: numberFontSize)
                    let unitFont = UIFont(name: "Arial-BoldMT", size: unitFontSize) ?? UIFont.boldSystemFont(ofSize: unitFontSize)

                    let numAttributes: [NSAttributedString.Key: Any] = [
                        .font: numFont,
                        .foregroundColor: UIColor.white,
                        .strokeColor: UIColor.black,
                        .strokeWidth: -4.0,
                        .paragraphStyle: paragraphStyle
                    ]
                    let unitAttributes: [NSAttributedString.Key: Any] = [
                        .font: unitFont,
                        .foregroundColor: UIColor.white,
                        .strokeColor: UIColor.black,
                        .strokeWidth: -4.0,
                        .paragraphStyle: paragraphStyle
                    ]

                    text.append(NSAttributedString(string: inches, attributes: numAttributes))
                    text.append(NSAttributedString(string: " in.", attributes: unitAttributes))
                    text.append(NSAttributedString(string: "\n", attributes: unitAttributes))
                }

                // mm: number 20% larger, unit normal size
                if !mm.isEmpty {
                    let numFont = UIFont(name: "Arial-BoldMT", size: numberFontSize) ?? UIFont.boldSystemFont(ofSize: numberFontSize)
                    let unitFont = UIFont(name: "Arial-BoldMT", size: unitFontSize) ?? UIFont.boldSystemFont(ofSize: unitFontSize)

                    let numAttributes: [NSAttributedString.Key: Any] = [
                        .font: numFont,
                        .foregroundColor: UIColor.white,
                        .strokeColor: UIColor.black,
                        .strokeWidth: -4.0,
                        .paragraphStyle: paragraphStyle
                    ]
                    let unitAttributes: [NSAttributedString.Key: Any] = [
                        .font: unitFont,
                        .foregroundColor: UIColor.white,
                        .strokeColor: UIColor.black,
                        .strokeWidth: -4.0,
                        .paragraphStyle: paragraphStyle
                    ]

                    text.append(NSAttributedString(string: mm, attributes: numAttributes))
                    text.append(NSAttributedString(string: " mm.", attributes: unitAttributes))
                }

                // Remove trailing newline
                if text.string.hasSuffix("\n") {
                    text.deleteCharacters(in: NSRange(location: text.length - 1, length: 1))
                }

                // Apply paragraph style to whole string
                if text.length > 0 {
                    let fullRange = NSRange(location: 0, length: text.length)
                    text.addAttribute(.paragraphStyle, value: paragraphStyle, range: fullRange)
                }

                return text
            }

            var text = buildAttributedText()

            // Dynamically reduce font sizes if the text block is too tall to fit all lines
            let maxAvailableHeight = size.height * 0.28
            let measurementWidth = size.width - (30 * 2)
            var measured = text.boundingRect(
                with: CGSize(width: measurementWidth, height: .greatestFiniteMagnitude),
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                context: nil
            )

            let minBaseFont: CGFloat = 14.0
            var attempts = 0
            while measured.height > maxAvailableHeight && baseFontSize > minBaseFont && attempts < 10 {
                attempts += 1
                let scale = (maxAvailableHeight / measured.height) * 0.92
                baseFontSize *= scale
                if baseFontSize < minBaseFont { baseFontSize = minBaseFont }
                numberFontSize = baseFontSize * 1.2
                unitFontSize = baseFontSize
                descFontSize = baseFontSize
                text = buildAttributedText()
                measured = text.boundingRect(
                    with: CGSize(width: measurementWidth, height: .greatestFiniteMagnitude),
                    options: [.usesLineFragmentOrigin, .usesFontLeading],
                    context: nil
                )
            }

            // Draw near the very top
            let padding: CGFloat = 30
            let maxTextWidth = size.width - (padding * 2)
            let textRect = CGRect(
                x: padding,
                y: padding,
                width: maxTextWidth,
                height: size.height * 0.28
            )

            text.draw(in: textRect)
        }
    }


    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                Text("In to mm Snapshot")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                    .padding(.top, 8)

                // Inches input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Inches (to 0.001\")")
                        .font(.headline)

                    TextField("e.g. 0.001", text: $inches)
                        .keyboardType(.decimalPad)
                        .font(.system(size: 48, weight: .semibold))
                        .textFieldStyle(.plain)
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.secondarySystemBackground))
                        )
                        .focused($focusedField, equals: .inches)
                        .onChange(of: inches) { _ in
                            if focusedField == .inches {
                                updateMM()
                            }
                        }
                }
                .padding(.horizontal)

                // mm input directly underneath - live bidirectional
                VStack(alignment: .leading, spacing: 8) {
                    Text("mm")
                        .font(.headline)

                    HStack {
                        TextField("0.0000", text: $mm)
                            .keyboardType(.decimalPad)
                            .font(.system(size: 48, weight: .semibold))
                            .textFieldStyle(.plain)
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.secondarySystemBackground))
                            )
                            .focused($focusedField, equals: .mm)
                            .onChange(of: mm) { _ in
                                if focusedField == .mm {
                                    updateInches()
                                }
                            }

                        Text("mm")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal)

                // Description input underneath both
                VStack(alignment: .leading, spacing: 8) {
                    Text("Description")
                        .font(.headline)

                    TextField("What is being measured?", text: $description)
                        .textFieldStyle(.roundedBorder)
                        .padding(.vertical, 4)
                        .focused($focusedField, equals: .description)
                }
                .padding(.horizontal)

                // Photo section at the bottom
                VStack(alignment: .leading, spacing: 8) {
                    Text("Photo of Measurement")
                        .font(.headline)

                    if let photo = photo {
                        Image(uiImage: photo)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 180)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                            )
                    } else {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.secondarySystemBackground))
                            .frame(height: 120)
                            .overlay(
                                Text("No photo taken yet")
                                    .foregroundStyle(.secondary)
                            )
                    }

                    Button {
                        showCamera = true
                    } label: {
                        Label(photo == nil ? "Take Photo" : "Retake Photo", systemImage: "camera.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.teal)
                }
                .padding(.horizontal)

                Spacer()

                if !isCapturing {
                    Button {
                        saveToPhotos()
                    } label: {
                        Label("Save to Photos", systemImage: "photo.on.rectangle")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }

                // Tip / Support section at bottom
                VStack(spacing: 8) {
                    Text("This app is 100% free with no ads or subscriptions.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    Text("If you find it useful, optional tips are greatly appreciated.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    if !tipProducts.isEmpty {
                        HStack(spacing: 8) {
                            ForEach(tipProducts) { product in
                                Button(product.displayPrice) {
                                    Task {
                                        await purchaseTip(product)
                                    }
                                }
                                .buttonStyle(.bordered)
                                .disabled(isPurchasing)
                            }
                        }
                    }

                    let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
                    Text("v\(version) • © Dan Ricks 2026")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .padding(.horizontal)
                .padding(.top, 8)
            }
            .padding()
            .contentShape(Rectangle())
            .onTapGesture {
                focusedField = nil
            }
            .navigationTitle("In to mm Snapshot")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showCamera, onDismiss: {
                focusedField = nil
            }) {
                ImagePicker(image: $photo)
            }
            .alert("Saved!", isPresented: $showSavedAlert) {
                Button("OK") { }
            } message: {
                Text("Screenshot has been saved to your Photos.")
            }
            .alert("Thank you!", isPresented: $showTipThanks) {
                Button("OK") { }
            } message: {
                Text("Your tip is greatly appreciated!")
            }
            .task {
                do {
                    tipProducts = try await Product.products(for: ["tip099", "tip199", "tip499"])
                } catch {
                    print("Failed to load tip products: \(error)")
                }
            }
        }
    }

    private func purchaseTip(_ product: Product) async {
        guard !isPurchasing else { return }
        isPurchasing = true
        defer { isPurchasing = false }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try verification.payloadValue
                await transaction.finish()
                showTipThanks = true
            case .userCancelled, .pending:
                break
            @unknown default:
                break
            }
        } catch {
            print("Purchase failed: \(error)")
        }
    }
}

#Preview {
    ContentView()
}

// MARK: - Camera Image Picker
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.presentationMode) var presentationMode

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        picker.allowsEditing = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                // Resize to prevent excessive memory usage (OOM kills)
                parent.image = ContentView.resizeImage(uiImage, maxDimension: 2048)
            }
            parent.presentationMode.wrappedValue.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}
