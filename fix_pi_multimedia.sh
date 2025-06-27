#!/bin/bash
# Fix multimedia issues on Raspberry Pi for NeuroDrive

echo "🔧 Fixing Raspberry Pi multimedia issues for NeuroDrive..."

# Install necessary multimedia packages
echo "📦 Installing multimedia packages..."
sudo apt update
sudo apt install -y \
    gstreamer1.0-tools \
    gstreamer1.0-plugins-base \
    gstreamer1.0-plugins-good \
    gstreamer1.0-plugins-bad \
    gstreamer1.0-plugins-ugly \
    gstreamer1.0-libav \
    libgstreamer1.0-dev \
    libgstreamer-plugins-base1.0-dev \
    qtmultimedia5-dev \
    qml-module-qtmultimedia \
    pulseaudio \
    alsa-utils

# Configure GPU memory
echo "🎮 Configuring GPU memory split..."
if ! grep -q "gpu_mem=128" /boot/config.txt; then
    echo "gpu_mem=128" | sudo tee -a /boot/config.txt
    echo "Added GPU memory configuration"
else
    echo "GPU memory already configured"
fi

# Enable camera if available
echo "📷 Enabling camera support..."
if ! grep -q "start_x=1" /boot/config.txt; then
    echo "start_x=1" | sudo tee -a /boot/config.txt
    echo "Camera support enabled"
fi

# Configure audio
echo "🔊 Starting audio services..."
pulseaudio --start --log-target=syslog 2>/dev/null || echo "PulseAudio already running"

# Set environment variables for multimedia
echo "🌍 Setting multimedia environment variables..."
cat > /tmp/multimedia_env << EOF
export QT_MULTIMEDIA_PREFERRED_PLUGINS=gstreamer
export GST_DEBUG=2
export QT_GSTREAMER_USE_PLAYBIN_VOLUME=1
export QT_GSTREAMER_WINDOW_VIDEOSINK=xvimagesink
EOF

echo "Environment variables created in /tmp/multimedia_env"
echo "Source this file before running the application:"
echo "source /tmp/multimedia_env"

# Test GStreamer
echo "🧪 Testing GStreamer installation..."
if command -v gst-launch-1.0 &> /dev/null; then
    echo "✅ GStreamer is installed"
    gst-inspect-1.0 --version
else
    echo "❌ GStreamer not found"
fi

# Test video playback capability
echo "🎬 Testing video playback capability..."
if gst-launch-1.0 videotestsrc num-buffers=10 ! videoconvert ! autovideosink 2>/dev/null; then
    echo "✅ Video playback test passed"
else
    echo "⚠️  Video playback test failed - check display configuration"
fi

echo ""
echo "🎉 Multimedia setup complete!"
echo ""
echo "📋 Next steps:"
echo "1. Reboot your Raspberry Pi: sudo reboot"
echo "2. Source the environment: source /tmp/multimedia_env"
echo "3. Run your application"
echo ""
echo "💡 If video still doesn't work, try:"
echo "   export QT_QPA_PLATFORM=xcb"
echo "   export DISPLAY=:0" 