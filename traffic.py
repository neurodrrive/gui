from fastapi import FastAPI
from fastapi.responses import HTMLResponse
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
import cv2
from ultralytics import YOLO
import os
import logging
import uvicorn

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI()
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.mount("/static", StaticFiles(directory="static"), name="static")
app.mount("/class_audio", StaticFiles(directory="class_audio"), name="class_audio")

# Load YOLO model
try:
    model = YOLO('model_v2.pt')
    logger.info("Model loaded successfully")
except Exception as e:
    logger.error(f"Failed to load model: {e}")
    raise

@app.get("/", response_class=HTMLResponse)
async def get_index():
    try:
        with open("static/index.html", "r") as f:
            return f.read()
    except Exception as e:
        logger.error(f"Failed to read index.html: {e}")
        raise

def process_video(input_filename):
    input_path = os.path.join(os.getcwd(), input_filename)
    output_path = os.path.join(os.getcwd(), 'output.avi')
    if not os.path.exists(input_path):
        logger.error(f"{input_filename} not found in project root.")
        return False
    
    cap = cv2.VideoCapture(input_path)
    if not cap.isOpened():
        logger.error("Could not open input video")
        return False
    
    # Get video properties
    fps = cap.get(cv2.CAP_PROP_FPS) or 25
    width = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
    height = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
    total_frames = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
    
    # Reduce resolution for Raspberry Pi performance
    # Scale down if resolution is too high
    if width > 640:
        scale_factor = 640 / width
        width = 640
        height = int(height * scale_factor)
        logger.info(f"Scaling down video to {width}x{height} for better performance")
    
    # Reduce FPS for Raspberry Pi performance
    target_fps = min(fps, 15)  # Limit to 15 FPS max
    logger.info(f"Processing at {target_fps} FPS (original: {fps})")
    
    # Use XVID codec for better compatibility with Qt
    fourcc = cv2.VideoWriter_fourcc(*'XVID')
    out = cv2.VideoWriter(output_path, fourcc, target_fps, (width, height))
    
    if not out.isOpened():
        logger.warning("Could not open video writer with XVID, trying MJPG...")
        fourcc = cv2.VideoWriter_fourcc(*'MJPG')
        out = cv2.VideoWriter(output_path, fourcc, target_fps, (width, height))
        
    if not out.isOpened():
        logger.error("Could not open video writer")
        return False
    
    frame_count = 0
    processed_frames = 0
    
    logger.info(f"Starting video processing: {total_frames} frames")
    
    while True:
        ret, frame = cap.read()
        if not ret:
            break
        
        frame_count += 1
        
        # Skip frames for performance on Raspberry Pi
        if fps > target_fps and frame_count % int(fps / target_fps) != 0:
            continue
            
        # Resize frame if needed
        if frame.shape[1] != width or frame.shape[0] != height:
            frame = cv2.resize(frame, (width, height))
        
        # Process every Nth frame for detection to improve performance
        if processed_frames % 3 == 0:  # Process every 3rd frame
            results = model(frame, conf=0.85, iou=0.85)
            detections = []
            
            for result in results:
                for box in result.boxes:
                    x1, y1, x2, y2 = map(int, box.xyxy[0])
                    cls = int(box.cls[0])
                    conf = float(box.conf[0])
                    class_name = result.names[cls]
                    detections.append((x1, y1, x2, y2, class_name, conf))
        
        # Draw detections from last processing
        if 'detections' in locals():
            for x1, y1, x2, y2, class_name, conf in detections:
                cv2.rectangle(frame, (x1, y1), (x2, y2), (0, 255, 0), 2)
                label = f"{class_name}: {conf:.2f}"
                cv2.putText(frame, label, (x1, y1 - 10), cv2.FONT_HERSHEY_SIMPLEX, 0.5, (0, 255, 0), 2)
        
        out.write(frame)
        processed_frames += 1
        
        # Progress reporting
        if processed_frames % 30 == 0:  # Every 30 frames
            progress = (frame_count / total_frames) * 100
            logger.info(f"Progress: {progress:.1f}% ({processed_frames} frames processed)")
    
    cap.release()
    out.release()
    logger.info(f"Detection complete. Processed {processed_frames} frames. Saved to {output_path}")
    return True

if __name__ == '__main__':
    import sys
    
    # If running from ProcessManager, just process video and exit
    if len(sys.argv) == 1:
        video_filename = 'vid.mp4'  # Change this if you want a different video
        success = process_video(video_filename)
        if success:
            logger.info("Video processing completed successfully")
            exit(0)
        else:
            logger.error("Video processing failed")
            exit(1)
    
    # Only start web server if explicitly requested with --server argument
    if len(sys.argv) > 1 and sys.argv[1] == '--server':
        ssl_keyfile = 'key.pem'
        ssl_certfile = 'cert.pem'
        if not (os.path.exists(ssl_keyfile) and os.path.exists(ssl_certfile)):
            logger.error("SSL certificates not found. Generate using:")
            logger.error("openssl req -x509 -newkey rsa:4096 -nodes -out cert.pem -keyout key.pem -days 365 -subj '/CN=localhost'")
            exit(1)
        logger.info("Starting server with SSL on https://localhost:8000")
        uvicorn.run(
            "main:app",
            host="0.0.0.0",
            port=8000,
            ssl_keyfile=ssl_keyfile,
            ssl_certfile=ssl_certfile,
            log_level="info"
        ) 