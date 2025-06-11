//
//  ContentView.swift
//  DogCatClassifier
//
//  Created by Tayseer Farooq on 11/06/25.
//

import SwiftUI
import PhotosUI
import AVFoundation

struct ContentView: View {
    @State private var selectedImage: UIImage?
    @State private var classificationResult: String?
    @State private var confidence: Double?
    @State private var isShowingImagePicker = false
    @State private var isShowingCamera = false
    @State private var showPermissionAlert = false
    @State private var isProcessing = false
    @State private var errorMessage: String?
    @State private var showError = false
    
    private let imageClassifier: ImageClassifier
    
    init() {
        do {
            imageClassifier = try ImageClassifier()
        } catch {
            fatalError("Failed to initialize ImageClassifier: \(error.localizedDescription)")
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Image Display Area
                ZStack {
                    if let image = selectedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity, maxHeight: 400)
                            .cornerRadius(12)
                            .shadow(radius: 5)
                            .transition(.scale.combined(with: .opacity))
                    } else {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.2))
                            .frame(maxWidth: .infinity, maxHeight: 400)
                            .overlay(
                                Image(systemName: "photo")
                                    .font(.system(size: 50))
                                    .foregroundColor(.gray)
                            )
                    }
                }
                .padding(.horizontal)
                
                // Classification Result
                if let result = classificationResult {
                    VStack(spacing: 8) {
                        Text(result)
                            .font(.title2)
                            .bold()
                        
                        if let confidence = confidence {
                            Text("Confidence: \(Int(confidence * 100))%")
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.blue.opacity(0.1))
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                
                // Action Buttons
                HStack(spacing: 20) {
                    Button(action: {
                        checkCameraPermission()
                    }) {
                        Label("Camera", systemImage: "camera")
                            .font(.headline)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    
                    Button(action: {
                        isShowingImagePicker = true
                    }) {
                        Label("Photo Library", systemImage: "photo.on.rectangle")
                            .font(.headline)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
                
                if isProcessing {
                    ProgressView()
                        .scaleEffect(1.5)
                        .padding()
                }
            }
            .navigationTitle("Dog vs Cat Classifier")
            .sheet(isPresented: $isShowingImagePicker) {
                ImagePicker(image: $selectedImage)
            }
            .sheet(isPresented: $isShowingCamera) {
                CameraView(image: $selectedImage)
            }
            .alert("Camera Access Required", isPresented: $showPermissionAlert) {
                Button("Settings", role: .none) {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Please allow camera access in Settings to use this feature.")
            }
            .alert("Classification Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "An unknown error occurred")
            }
            .onChange(of: selectedImage) { newImage in
                if let image = newImage {
                    classifyImage(image)
                }
            }
        }
    }
    
    private func checkCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            isShowingCamera = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted {
                    DispatchQueue.main.async {
                        isShowingCamera = true
                    }
                }
            }
        case .denied, .restricted:
            showPermissionAlert = true
        @unknown default:
            break
        }
    }
    
    private func classifyImage(_ image: UIImage) {
        isProcessing = true
        errorMessage = nil
        
        Task {
            do {
                let result = try await imageClassifier.classifyImage(image)
                await MainActor.run {
                    classificationResult = result.label
                    confidence = result.confidence
                    isProcessing = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                    isProcessing = false
                }
            }
        }
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
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
            parent.presentationMode.wrappedValue.dismiss()
            
            guard let provider = results.first?.itemProvider else { return }
            
            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { image, _ in
                    DispatchQueue.main.async {
                        self.parent.image = image as? UIImage
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
