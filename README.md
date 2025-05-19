# NeuroDrive Dashboard

A modern Qt/QML-based dashboard application for NeuroDrive with dark mode support.

## Features

- Secure driver verification with facial recognition API integration
- Modern UI dashboard with dark/light mode support
- Front camera monitoring with:
  - Traffic Sign Recognition
  - Lane Detection
  - Combined Drowsiness & Traffic Sign analysis
- Cabin camera monitoring with:
  - Distraction Monitoring
  - Drowsiness Detection
- Settings panel with theme customization
- Responsive interface optimized for vehicle displays

## Screenshots

### Login Screen
![Login Screen](img/screens/1.png)

### Main Dashboard
![Dashboard](img/screens/2.png)

### Front Camera
![Front Camera](img/screens/3.png)

### Cabin Camera
![Cabin Camera](img/screens/4.png)

### Settings
![Settings](img/screens/5.png)

## Requirements

- Qt 6.8 or later
- C++17 compatible compiler
- CMake 3.16 or later
- Network connectivity for driver verification API

## Building the Application

### Install Dependencies

Ensure you have Qt 6.8 or later, CMake 3.16 or later, and a C++17 compatible compiler installed.

### Clone the Repository

```bash
git clone https://github.com/youssef47048/NueroDrive/NeuroDrive.git
cd NeuroDrive_13_5_2025
```

### Build the Application

```bash
mkdir build
cd build
cmake ..
make -j4
```

### Run the Application

```bash
./appNeuroDrive_13_5_2025
```

## Usage

1. On startup, the application displays a login screen
2. Click the login button to verify the driver through facial recognition
3. Upon successful verification, the main dashboard is displayed
4. Use the dashboard buttons to navigate to different features:
   - Front Camera: Access traffic sign recognition and lane detection
   - Cabin Camera: Access driver monitoring features
   - Settings: Customize application appearance (dark/light mode)

## Development Notes

- The application uses Qt Quick for the UI
- Network requests are handled via the NetworkService class
- Face verification API endpoint for local: https://localhost:5041/api/verify-driver
- Face verification API endpoint: https://neurodrive.runasp.net/api/verify-driver
- Dark mode is implemented using dynamic property binding for colors

## Project Structure

- `main.cpp` - Application entry point
- `NetworkService.h/cpp` - Handles API requests and image processing
- `Main.qml` - Main application window with dashboard layout
- `qml/pages/` - QML page components (Login, Dashboard)
- `qml/components/` - Reusable UI components (FeatureButton, etc.)
- `img/` - Image resources
