import cv2
import mediapipe as mp
import numpy as np
from fastapi import FastAPI, UploadFile, File
from fastapi.responses import HTMLResponse
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
import csv
from datetime import datetime
import os
import urllib3

# Disable insecure request warnings
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

app = FastAPI()

# Configure CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Mount static directories
app.mount('/static', StaticFiles(directory='static'), name='static')
app.mount('/class_audio', StaticFiles(directory='class_audio'), name='class_audio')

# Set CSV path
CSV_PATH = 'drowsiness_log.csv'

# Create CSV file if not exists
if not os.path.exists(CSV_PATH):
    with open(CSV_PATH, 'w', newline='') as file:
        writer = csv.writer(file)
        writer.writerow(['Date', 'Time', 'Status'])

# Initialize MediaPipe Face Mesh
mp_face_mesh = mp.solutions.face_mesh
face_mesh = mp_face_mesh.FaceMesh(static_image_mode=True, max_num_faces=1, refine_landmarks=True)

# Eye landmarks indices
LEFT_EYE_IDX = [33, 160, 158, 133, 153, 144]
RIGHT_EYE_IDX = [362, 385, 387, 263, 373, 380]

def log_drowsiness_status(drowsy):
    try:
        current_time = datetime.now()
        date = current_time.strftime('%Y-%m-%d')
        time_str = current_time.strftime('%H:%M:%S')
        status = 'Yes' if drowsy else 'No'
        
        with open(CSV_PATH, 'a', newline='') as file:
            writer = csv.writer(file)
            writer.writerow([date, time_str, status])
    except Exception as e:
        print(f"Error logging status: {e}")

def eye_aspect_ratio(eye):
    A = np.linalg.norm(eye[1] - eye[5])
    B = np.linalg.norm(eye[2] - eye[4])
    C = np.linalg.norm(eye[0] - eye[3])
    ear = (A + B) / (2.0 * C)
    return ear

EYE_AR_THRESH = 0.23

@app.get('/', response_class=HTMLResponse)
def index():
    try:
        with open('static/index.html', 'r', encoding='utf-8') as f:
            return f.read()
    except Exception as e:
        print(f"Error loading index page: {e}")
        return "Error loading page"

@app.get('/last_records')
def get_last_records():
    try:
        records = []
        if not os.path.exists(CSV_PATH):
            return []
            
        with open(CSV_PATH, 'r', newline='', encoding='utf-8') as file:
            reader = csv.DictReader(file)
            all_records = list(reader)
            
            if len(all_records) == 0:
                return []
            
            last_records = all_records[-5:] if len(all_records) >= 5 else all_records
            
            for record in last_records:
                records.append({
                    'date': record['Date'],
                    'time': record['Time'],
                    'status': record['Status']
                })
        return records
    except Exception as e:
        print(f"Error in get_last_records: {e}")
        return []

@app.post('/detect')
def detect_drowsiness(file: UploadFile = File(...)):
    try:
        image_bytes = file.file.read()
        npimg = np.frombuffer(image_bytes, np.uint8)
        frame = cv2.imdecode(npimg, cv2.IMREAD_COLOR)
        
        if frame is None:
            return {"error": "Could not decode image"}
            
        rgb_frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        results = face_mesh.process(rgb_frame)
        
        drowsy = False
        if results.multi_face_landmarks:
            for face_landmarks in results.multi_face_landmarks:
                landmarks = np.array([(lm.x * frame.shape[1], lm.y * frame.shape[0]) for lm in face_landmarks.landmark])
                leftEye = landmarks[LEFT_EYE_IDX]
                rightEye = landmarks[RIGHT_EYE_IDX]
                
                leftEAR = eye_aspect_ratio(leftEye)
                rightEAR = eye_aspect_ratio(rightEye)
                ear = (leftEAR + rightEAR) / 2.0
                
                if ear < EYE_AR_THRESH:
                    drowsy = True
    
        log_drowsiness_status(drowsy)
        return {"drowsy": drowsy}
        
    except Exception as e:
        return {"error": str(e)}

if __name__ == '__main__':
    # --- Automatic video processing for 'vid.mp4' ---
    video_path = 'vid.mp4'
    output_path = 'output.avi'  # Changed to AVI format for Qt compatibility on Linux
    if os.path.exists(video_path):
        print(f"\nProcessing {video_path} for drowsiness detection...")
        cap = cv2.VideoCapture(video_path)
        # Using MJPG codec which is widely compatible with Qt on Linux
        fourcc = cv2.VideoWriter_fourcc(*'MJPG')
        fps = cap.get(cv2.CAP_PROP_FPS)
        width = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
        height = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
        out = cv2.VideoWriter(output_path, fourcc, fps, (width, height))
        frame_idx = 0
        while cap.isOpened():
            ret, frame = cap.read()
            if not ret:
                break
            rgb_frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
            results = face_mesh.process(rgb_frame)
            drowsy = False
            if results.multi_face_landmarks:
                for face_landmarks in results.multi_face_landmarks:
                    landmarks = np.array([(lm.x * frame.shape[1], lm.y * frame.shape[0]) for lm in face_landmarks.landmark])
                    leftEye = landmarks[LEFT_EYE_IDX]
                    rightEye = landmarks[RIGHT_EYE_IDX]
                    leftEAR = eye_aspect_ratio(leftEye)
                    rightEAR = eye_aspect_ratio(rightEye)
                    ear = (leftEAR + rightEAR) / 2.0
                    if ear < EYE_AR_THRESH:
                        drowsy = True
            # Optionally, mark drowsy frames visually
            if drowsy:
                cv2.putText(frame, 'DROWSY', (50, 50), cv2.FONT_HERSHEY_SIMPLEX, 2, (0,0,255), 4)
            out.write(frame)
            frame_idx += 1
        cap.release()
        out.release()
        print(f"Done. Output saved as {output_path}")
    else:
        print(f"{video_path} not found. Skipping automatic video processing.")

    # --- Start FastAPI server after video processing ---
    import uvicorn
    print("\n=== Starting main server ===")
    print("Server will be available at: https://localhost:8000")
    print("CSV file path:", os.path.abspath(CSV_PATH))
    print("=== Server starting... ===\n")
    
    ssl_keyfile = 'key.pem'
    ssl_certfile = 'cert.pem'
    
    if os.path.exists(ssl_keyfile) and os.path.exists(ssl_certfile):
        print("SSL certificates found, starting with HTTPS")
        uvicorn.run(
            'main:app',
            host='localhost',
            port=8000,
            reload=True,
            ssl_keyfile=ssl_keyfile,
            ssl_certfile=ssl_certfile,
            log_level="debug"
        )
    else:
        print("SSL certificates not found. Server not started.")
