//
//  ImageClassifier.swift
//  DogCatClassifier
//
//  Created by Tayseer Farooq on 11/06/25.
//

import Foundation
import CoreML
import Vision
import UIKit

extension Notification.Name {
    static let classificationDidComplete = Notification.Name("classificationDidComplete")
}

enum ClassificationError: Error {
    case modelLoadError
    case imageProcessingError
    case classificationError
    case invalidInput
    case modelNotFound
    case memoryError
    
    var localizedDescription: String {
        switch self {
        case .modelLoadError:
            return "Failed to load the classification model"
        case .imageProcessingError:
            return "Failed to process the input image"
        case .classificationError:
            return "Failed to classify the image"
        case .invalidInput:
            return "Invalid input image"
        case .modelNotFound:
            return "Model file not found in bundle"
        case .memoryError:
            return "Insufficient memory to process image"
        }
    }
}

struct ClassificationResult {
    let label: String
    let confidence: Double
}

@MainActor
class ImageClassifier {
    private var classificationRequest: VNCoreMLRequest?
    private let modelName = "MobileNetV2"
    private let maxImageDimension: CGFloat = 224 // MobileNetV2 expects 224x224 input
    
    init() throws {
        try setupModel()
    }
    
    private func setupModel() throws {
        // Check if model exists in bundle
        guard let modelURL = Bundle.main.url(forResource: modelName, withExtension: "mlmodelc") else {
            throw ClassificationError.modelNotFound
        }
        
        do {
            // Configure ML model with memory optimization
            let config = MLModelConfiguration()
            config.computeUnits = .all // Use all available compute units (CPU, Neural Engine, GPU)
            config.allowLowPrecisionAccumulationOnGPU = true // Enable memory optimization
            
            let model = try MLModel(contentsOf: modelURL, configuration: config)
            let visionModel = try VNCoreMLModel(for: model)
            
            classificationRequest = VNCoreMLRequest(model: visionModel) { [weak self] request, error in
                if let error = error {
                    print("Vision ML request error: \(error.localizedDescription)")
                    return
                }
                
                self?.processClassifications(for: request)
            }
            
            // Configure the request for optimal performance
            classificationRequest?.imageCropAndScaleOption = .centerCrop
            classificationRequest?.usesCPUOnly = false
            
        } catch {
            throw ClassificationError.modelLoadError
        }
    }
    
    private func optimizeImage(_ image: UIImage) -> UIImage? {
        // MobileNetV2 expects 224x224 input
        let targetSize = CGSize(width: 224, height: 224)
        
        UIGraphicsBeginImageContextWithOptions(targetSize, false, 1.0)
        defer { UIGraphicsEndImageContext() }
        
        // Calculate aspect ratio
        let aspectRatio = image.size.width / image.size.height
        var drawRect = CGRect(origin: .zero, size: targetSize)
        
        if aspectRatio > 1 {
            // Image is wider than tall
            drawRect.size.width = targetSize.height * aspectRatio
            drawRect.origin.x = (targetSize.width - drawRect.size.width) / 2
        } else {
            // Image is taller than wide
            drawRect.size.height = targetSize.width / aspectRatio
            drawRect.origin.y = (targetSize.height - drawRect.size.height) / 2
        }
        
        image.draw(in: drawRect)
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    private func processClassifications(for request: VNRequest) {
        guard let results = request.results as? [VNClassificationObservation] else {
            print("No classification results found")
            return
        }
        
        if let topResult = results.first {
            // Log the raw classification result
            print("Raw classification: \(topResult.identifier) with confidence: \(topResult.confidence)")
            
            // MobileNetV2 returns ImageNet class names, we'll map them to dog/cat
            let label = mapToDogOrCat(topResult.identifier)
            let confidence = Double(topResult.confidence)
            
            print("Mapped to: \(label) with confidence: \(confidence)")
            
            Task { @MainActor in
                NotificationCenter.default.post(
                    name: .classificationDidComplete,
                    object: nil,
                    userInfo: [
                        "label": label,
                        "confidence": confidence
                    ]
                )
            }
        }
    }
    
    private func mapToDogOrCat(_ imagenetClass: String) -> String {
        // Expanded list of dog breeds and terms
        let dogClasses = [
            "dog", "puppy", "hound", "retriever", "shepherd", "labrador", "bulldog", "beagle",
            "german shepherd", "golden retriever", "husky", "poodle", "chihuahua", "boxer",
            "doberman", "rottweiler", "dachshund", "shih tzu", "corgi", "collie", "terrier",
            "spaniel", "mastiff", "saint bernard", "great dane", "dalmatian", "samoyed",
            "akita", "shiba inu", "malamute", "chow chow", "pomeranian", "bichon frise"
        ]
        
        // Expanded list of cat breeds and terms
        let catClasses = [
            "cat", "kitten", "tabby", "siamese", "persian", "maine coon", "ragdoll",
            "british shorthair", "sphynx", "bengal", "abyssinian", "birman", "russian blue",
            "norwegian forest cat", "scottish fold", "american shorthair", "exotic shorthair",
            "burmese", "tonkinese", "balinese", "javanese", "oriental", "himalayan"
        ]
        
        let lowercasedClass = imagenetClass.lowercased()
        
        // Check for dog-related terms
        if dogClasses.contains(where: { lowercasedClass.contains($0) }) {
            return "Dog"
        }
        // Check for cat-related terms
        else if catClasses.contains(where: { lowercasedClass.contains($0) }) {
            return "Cat"
        }
        // If no match, return the original class name for debugging
        else {
            return "Unknown (\(imagenetClass))"
        }
    }
    
    func classifyImage(_ image: UIImage) async throws -> ClassificationResult {
        // Check memory pressure
        if ProcessInfo.processInfo.thermalState == .critical {
            throw ClassificationError.memoryError
        }
        
        guard let request = classificationRequest else {
            throw ClassificationError.modelLoadError
        }
        
        // Optimize image size for MobileNetV2
        guard let optimizedImage = optimizeImage(image),
              let cgImage = optimizedImage.cgImage else {
            throw ClassificationError.invalidInput
        }
        
        // Create a handler for the image
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        return try await withCheckedThrowingContinuation { continuation in
            var hasResumed = false
            var observer: NSObjectProtocol?
            
            // Create the observer
            observer = NotificationCenter.default.addObserver(
                forName: .classificationDidComplete,
                object: nil,
                queue: .main
            ) { notification in
                guard !hasResumed else { return }
                hasResumed = true
                
                if let observer = observer {
                    NotificationCenter.default.removeObserver(observer)
                }
                
                if let label = notification.userInfo?["label"] as? String,
                   let confidence = notification.userInfo?["confidence"] as? Double {
                    let result = ClassificationResult(label: label, confidence: confidence)
                    continuation.resume(returning: result)
                } else {
                    continuation.resume(throwing: ClassificationError.classificationError)
                }
            }
            
            // Set a timeout
            Task {
                try await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds timeout
                guard !hasResumed else { return }
                hasResumed = true
                
                if let observer = observer {
                    NotificationCenter.default.removeObserver(observer)
                }
                continuation.resume(throwing: ClassificationError.classificationError)
            }
            
            do {
                try handler.perform([request])
            } catch {
                guard !hasResumed else { return }
                hasResumed = true
                
                if let observer = observer {
                    NotificationCenter.default.removeObserver(observer)
                }
                continuation.resume(throwing: ClassificationError.imageProcessingError)
            }
        }
    }
    
    // Notification name for classification completion
    
    
}
