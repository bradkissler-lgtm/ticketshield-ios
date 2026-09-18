import SwiftUI
import PhotosUI
import UIKit

struct AddSpotFlowView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppPreferences.self) private var preferences

    var onSave: (SpotDraft) -> Void

    @State private var step: Step = .capture
    @State private var pickerItem: PhotosPickerItem?
    @State private var showCamera = false
    @State private var isReading = false
    @State private var statusMessage: String?
    @State private var capturedImage: UIImage?
    @State private var suggestion = SuggestedSchedule.empty
    @State private var cameraUnavailable = false

    private enum Step {
        case capture
        case confirm
    }

    var body: some View {
        NavigationStack {
            Group {
                switch step {
                case .capture:
                    captureStep
                case .confirm:
                    ConfirmScheduleView(
                        title: "Confirm schedule",
                        draft: SpotDraft.from(suggestion: suggestion, defaultLead: preferences.defaultLeadTimeMinutes),
                        previewImage: capturedImage,
                        foundDays: suggestion.foundDays,
                        foundTime: suggestion.foundTime,
                        onSave: onSave
                    )
                }
            }
            .navigationTitle(step == .capture ? "Add spot" : "Confirm")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .sheet(isPresented: $showCamera) {
                CameraPicker(image: Binding(
                    get: { capturedImage },
                    set: { newImage in
                        capturedImage = newImage
                        if let newImage {
                            Task { await read(newImage) }
                        }
                    }
                ))
                .ignoresSafeArea()
            }
            .alert("Camera unavailable", isPresented: $cameraUnavailable) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("This device or simulator has no camera. Choose a photo of the sign instead.")
            }
        }
    }

    private var captureStep: some View {
        VStack(spacing: 24) {
            Text("Photograph the curb or street-cleaning sign. Text is read on this iPhone — the photo is not uploaded.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
                .padding(.top, 24)

            if isReading {
                ProgressView("Reading the sign…")
                    .padding(.top, 12)
            }

            if let statusMessage {
                Text(statusMessage)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Spacer()

            VStack(spacing: 12) {
                Button {
                    if UIImagePickerController.isSourceTypeAvailable(.camera) {
                        showCamera = true
                    } else {
                        cameraUnavailable = true
                    }
                } label: {
                    Label("Take photo", systemImage: "camera.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)

                PhotosPicker(selection: $pickerItem, matching: .images, photoLibrary: .shared()) {
                    Label("Choose photo", systemImage: "photo.on.rectangle")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.bordered)
                .onChange(of: pickerItem) { _, item in
                    guard let item else { return }
                    Task { await loadPicker(item) }
                }

                Button("Enter schedule without a photo") {
                    suggestion = .empty
                    capturedImage = nil
                    step = .confirm
                }
                .font(.footnote)
                .padding(.top, 4)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 28)
        }
    }

    private func loadPicker(_ item: PhotosPickerItem) async {
        isReading = true
        statusMessage = nil
        defer { isReading = false }
        do {
            guard let data = try await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data)
            else {
                statusMessage = "That photo couldn’t be opened. Try another."
                return
            }
            capturedImage = image
            await read(image)
        } catch {
            statusMessage = error.localizedDescription
        }
    }

    private func read(_ image: UIImage) async {
        isReading = true
        statusMessage = nil
        defer { isReading = false }
        do {
            let text = try await OCRService.recognizeText(in: image)
            if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                suggestion = .empty
                statusMessage = OCRService.OCRError.noText.errorDescription
            } else {
                suggestion = SignScheduleParser.parse(text)
            }
            step = .confirm
        } catch {
            suggestion = .empty
            statusMessage = error.localizedDescription
            step = .confirm
        }
    }
}

struct CameraPicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        picker.allowsEditing = false
        picker.cameraCaptureMode = .photo
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPicker

        init(parent: CameraPicker) {
            self.parent = parent
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            parent.image = info[.originalImage] as? UIImage
            parent.dismiss()
        }
    }
}
