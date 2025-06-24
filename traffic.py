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
logger = logging.getLogger(_name_)

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
    fourcc = cv2.VideoWriter_fourcc(*'mp4v')
    fps = cap.get(cv2.CAP_PROP_FPS) or 25
    width = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
    height = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
    out = cv2.VideoWriter(output_path, fourcc, fps, (width, height))
    while True:
        ret, frame = cap.read()
        if not ret:
            break
        results = model(frame, conf=0.85, iou=0.85)
        for result in results:
            for box in result.boxes:
                x1, y1, x2, y2 = map(int, box.xyxy[0])
                cls = int(box.cls[0])
                conf = float(box.conf[0])
                class_name = result.names[cls]
                cv2.rectangle(frame, (x1, y1), (x2, y2), (0, 255, 0), 2)
                label = f"{class_name}: {conf:.2f}"
                cv2.putText(frame, label, (x1, y1 - 10), cv2.FONT_HERSHEY_SIMPLEX, 0.5, (0, 255, 0), 2)
        out.write(frame)
    cap.release()
    out.release()
    logger.info(f"Detection complete. Saved to {output_path}")
    return True

if _name_ == '_main_':
    ssl_keyfile = 'key.pem'
    ssl_certfile = 'cert.pem'
    video_filename = 'vid.mp4'  # Change this if you want a different video
    process_video(video_filename)
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