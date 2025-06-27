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

## Raspberry Pi 4 Optimization

If you're running this application on a Raspberry Pi 4, you may experience longer processing times. Here are the optimizations implemented:

### Performance Optimizations Applied:
1. **Video Resolution Scaling**: Videos larger than 640px width are automatically scaled down
2. **Frame Rate Limiting**: Processing is limited to 15 FPS maximum for better performance
3. **Frame Skipping**: Only every 3rd frame is processed for AI detection to reduce CPU load
4. **Progress Reporting**: Better feedback during long processing operations

### Expected Performance:
- **Video Processing Time**: 2-5 minutes for a 30-second video (depending on complexity)
- **UI Responsiveness**: The interface remains responsive during processing
- **Memory Usage**: Optimized to use less RAM through reduced resolution and frame skipping

### Recommended Settings for Raspberry Pi:
1. **Increase GPU Memory Split**: 
   ```bash
   sudo raspi-config
   # Navigate to Advanced Options > Memory Split > Set to 128 or 256
   ```

2. **Enable Camera and Hardware Acceleration**:
   ```bash
   sudo raspi-config
   # Enable Camera and GPU memory split
   ```

3. **Use High-Speed SD Card**: Class 10 or better for faster file I/O

4. **Ensure Adequate Cooling**: AI processing can heat up the Pi significantly

### Troubleshooting:

#### "Not Responding" Dialog:
- This is normal during initial video processing
- Wait for the processing to complete (check terminal for progress)
- The UI will become responsive once processing finishes

#### Video Not Loading:
- Check that the Python script completed successfully
- Look for `output.avi` file in the model directory
- Video loading may take 10-30 seconds after processing completes

#### Long Processing Times:
- Normal for Raspberry Pi 4 - AI models are computationally intensive
- Consider using smaller input videos for testing
- Monitor system temperature to avoid thermal throttling
