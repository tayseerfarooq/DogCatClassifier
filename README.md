# DogCatClassifier - iOS App 

## Project Overview
DogCatClassifier is an iOS application that uses machine learning to classify images as either dogs or cats. The app features a modern SwiftUI interface, camera integration, and real-time image classification using Core ML and Vision frameworks. Not to forget, this is complete vibe coding with lots of learning.

## Development Journey

### Project Inception
The project was conceived and developed through a collaborative process using various AI tools:
- **Claude (Anthropic)**: Used for initial project ideation and architecture planning
- **ChatGPT**: Assisted with specific coding questions and debugging
- **Cursor**: Primary IDE for code development and implementation
- **Xcode**: Final compilation and testing environment

### Development Process
1. **Initial Setup**
   - Created project structure using Xcode
   - Set up SwiftUI-based interface
   - Configured Core ML integration

2. **Core Components**
   - `ContentView.swift`: Main UI implementation
   - `ImageClassifier.swift`: ML model integration
   - `CameraView.swift`: Camera functionality
   - `Info.plist`: Privacy and permission configurations

3. **Key Features**
   - Real-time image classification
   - Camera and photo library integration
   - Clean, modern UI design
   - Error handling and user feedback
   - State management using SwiftUI

## Technical Implementation

### Architecture
The app follows a clean architecture pattern with:
- **Presentation Layer**: SwiftUI views
- **Business Logic**: ImageClassifier class
- **Data Layer**: Core ML model integration

### Key Components

#### ImageClassifier
- Handles image processing and classification
- Uses MobileNetV2 model for predictions
- Implements confidence thresholding
- Provides detailed classification results

#### Camera Integration
- Supports both camera and photo library
- Handles device compatibility
- Implements proper error handling

#### UI Components
- Modern SwiftUI interface
- Responsive design
- User-friendly feedback system

## Challenges and Solutions

### 1. Model Accuracy
**Challenge**: Initial classification accuracy was low
**Solution**: 
- Implemented expanded class mapping
- Added confidence thresholding
- Improved image preprocessing

### 2. Camera Compatibility
**Challenge**: Camera issues on certain devices
**Solution**:
- Added device compatibility checks
- Implemented fallback options
- Enhanced error handling

### 3. Build Issues
**Challenge**: Multiple Info.plist processing errors
**Solution**:
- Fixed project configuration
- Corrected Info.plist path settings
- Removed duplicate entries

### 4. Code Structure
**Challenge**: Function placement and scope issues
**Solution**:
- Reorganized code structure
- Fixed function scoping
- Improved error handling

## Future Improvements

### 1. Model Enhancement
- Train custom model with more dog/cat breeds
- Implement transfer learning
- Add breed-specific classification

### 2. Performance Optimization
- Implement image caching
- Optimize memory usage
- Add background processing

### 3. UI/UX Improvements
- Add animations
- Implement dark mode
- Add more user feedback

### 4. Additional Features
- Save classification history
- Share results
- Add favorite classifications

## Setup Instructions

1. **Prerequisites**
   - Xcode 14.0 or later
   - iOS 15.0 or later
   - Swift 5.5 or later

2. **Installation**
   ```bash
   git clone [repository-url]
   cd DogCatClassifier
   open DogCatClassifier.xcodeproj
   ```

3. **Configuration**
   - Add MobileNetV2.mlmodel to the project
   - Configure Info.plist with required permissions
   - Set deployment target in project settings

4. **Building**
   - Clean build folder
   - Build and run on target device

## Project Structure
DogCatClassifier/
├── DogCatClassifier/
│ ├── ContentView.swift
│ ├── ImageClassifier.swift
│ ├── CameraView.swift
│ └── Info.plist
├── Models/
│ └── MobileNetV2.mlmodel
└── DogCatClassifier.xcodeproj/


## Screenshots

![IMG_3168](https://github.com/user-attachments/assets/1b89a707-1f25-444e-97e5-79c3d8b8feca)



## Development Log

### Key Milestones
1. Project initialization
2. UI implementation
3. ML model integration
4. Camera functionality
5. Error handling
6. Performance optimization

### Notable Issues
1. Model accuracy improvements
2. Camera compatibility fixes
3. Build configuration resolution
4. Code structure optimization

## Contributing
Feel free to contribute to this project by:
1. Forking the repository
2. Creating a feature branch
3. Submitting a pull request

## Acknowledgments
- Claude (Anthropic) for project ideation
- ChatGPT for coding assistance
- Cursor for development environment
- Apple for Core ML and Vision frameworks
