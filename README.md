# NeuroDrive Dashboard

A Qt/QML-based dashboard application for NeuroDrive.

## Features

- Driver verification with facial recognition
- Modern UI dashboard for vehicle monitoring

## Requirements

- Qt 6.8 or later
- C++17 compatible compiler
- CMake 3.16 or later

## Building the Application

### Install Dependencies

Ensure you have Qt 6.8 or later, CMake 3.16 or later, and a C++17 compatible compiler installed.

### Clone the Repository

```bash
git clone https://github.com/your-username/NeuroDrive.git
cd NeuroDrive
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

## Development Notes

- The application uses Qt Quick for the UI
- Network requests are handled via the NetworkService class
- Face verification API endpoint: https://localhost:5041/api/verify-driver

## Project Structure

- `main.cpp` - Application entry point
- `NetworkService.h/cpp` - Handles network requests
- `Main.qml` - Main application window
- `qml/pages/` - QML page components
- `img/` - Image resources 