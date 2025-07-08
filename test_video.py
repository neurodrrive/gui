#!/usr/bin/env python3
"""
Test script to verify video file integrity and properties
"""
import cv2
import os
import sys

def test_video_file(video_path):
    """Test if video file exists and is readable"""
    print(f"🎬 Testing video file: {video_path}")
    
    # Check if file exists
    if not os.path.exists(video_path):
        print(f"❌ File does not exist: {video_path}")
        return False
    
    # Get file size
    file_size = os.path.getsize(video_path)
    print(f"📁 File size: {file_size:,} bytes ({file_size/1024/1024:.2f} MB)")
    
    # Try to open with OpenCV
    cap = cv2.VideoCapture(video_path)
    if not cap.isOpened():
        print("❌ Cannot open video file with OpenCV")
        return False
    
    # Get video properties
    fps = cap.get(cv2.CAP_PROP_FPS)
    width = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
    height = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
    frame_count = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
    duration = frame_count / fps if fps > 0 else 0
    
    print(f"🎥 Video properties:")
    print(f"   Resolution: {width}x{height}")
    print(f"   FPS: {fps:.2f}")
    print(f"   Frames: {frame_count}")
    print(f"   Duration: {duration:.2f} seconds")
    
    # Try to read first frame
    ret, frame = cap.read()
    if not ret:
        print("❌ Cannot read first frame")
        cap.release()
        return False
    
    print("✅ First frame read successfully")
    
    # Test reading a few more frames
    frames_read = 1
    for i in range(min(10, frame_count - 1)):
        ret, _ = cap.read()
        if ret:
            frames_read += 1
        else:
            break
    
    print(f"✅ Successfully read {frames_read} frames")
    
    cap.release()
    return True

def main():
    # Test common video paths
    test_paths = [
        "/models/traffic_signs_detection_3/output.avi",
        "/models/drowsiness_detection_f3/output.avi",
        "/models/lane_detection_3/output.avi",
        "output.avi"  # Current directory
    ]
    
    if len(sys.argv) > 1:
        # Test specific path provided as argument
        test_paths = [sys.argv[1]]
    
    print("🔍 Testing video files...\n")
    
    success_count = 0
    for path in test_paths:
        try:
            if test_video_file(path):
                success_count += 1
            print()
        except Exception as e:
            print(f"❌ Error testing {path}: {e}\n")
    
    print(f"📊 Summary: {success_count}/{len(test_paths)} videos tested successfully")
    
    if success_count == 0:
        print("\n💡 Tips:")
        print("1. Make sure the Python processing script completed successfully")
        print("2. Check the working directory is correct")
        print("3. Verify the video codec is supported (try XVID or MJPG)")

if __name__ == "__main__":
    main() 