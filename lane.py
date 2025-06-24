import cv2
import numpy as np
import time
import os

VIDEO_SOURCE = 'Lane_detect.mp4'
OUTPUT_VIDEO = 'output.avi'  # Using AVI format for Qt compatibility on Linux
DEBUG = True
SMOOTHING_FRAMES = 5
CANNY_THRESHOLDS = (50, 150)
GAUSSIAN_KERNEL = (5, 5)
HOUGH_PARAMS = dict(rho=1, theta=np.pi / 180, threshold=30, minLineLength=40, maxLineGap=50)

prev_left_fits = []
prev_right_fits = []

def region_of_interest(img, vertices):
    mask = np.zeros_like(img)
    cv2.fillPoly(mask, vertices, 255)
    return cv2.bitwise_and(img, mask)

def extrapolate_line(fit, y_bottom, y_top):
    if fit is None:
        return None
    m, b = fit
    x_bottom = int(m * y_bottom + b)
    x_top = int(m * y_top + b)
    return [(x_bottom, y_bottom), (x_top, y_top)]

def fit_average(fit_list, new_fit):
    if new_fit is not None:
        fit_list.append(new_fit)
    if len(fit_list) > SMOOTHING_FRAMES:
        fit_list.pop(0)
    return np.mean(fit_list, axis=0) if fit_list else None

def separate_lines(lines, img_shape):
    left_points, right_points = [], []
    height, width = img_shape[:2]
    mid_x = width // 2

    if lines is None:
        return None, None

    for line in lines:
        for x1, y1, x2, y2 in line:
            slope = (y2 - y1) / (x2 - x1 + 1e-6)
            if abs(slope) < 0.5:
                continue
            if slope < 0 and x1 < mid_x and x2 < mid_x:
                left_points.extend([(x1, y1), (x2, y2)])
            elif slope > 0 and x1 > mid_x and x2 > mid_x:
                right_points.extend([(x1, y1), (x2, y2)])

    def fit_line(points):
        if len(points) < 2:
            return None
        x_coords, y_coords = zip(*points)
        return np.polyfit(y_coords, x_coords, 1)

    return fit_line(left_points), fit_line(right_points)

def process_frame(frame):
    height, width = frame.shape[:2]
    roi_top = height // 2 + 50

    gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
    blur = cv2.GaussianBlur(gray, GAUSSIAN_KERNEL, 0)
    edges = cv2.Canny(blur, *CANNY_THRESHOLDS)

    roi_vertices = np.array([[
        (0, height),
        (width // 2 - 50, roi_top),
        (width // 2 + 50, roi_top),
        (width, height)
    ]], dtype=np.int32)
    cropped_edges = region_of_interest(edges, roi_vertices)

    lines = cv2.HoughLinesP(cropped_edges, **HOUGH_PARAMS)
    left_fit, right_fit = separate_lines(lines, frame.shape)

    smoothed_left_fit = fit_average(prev_left_fits, left_fit)
    smoothed_right_fit = fit_average(prev_right_fits, right_fit)

    line_img = np.zeros_like(frame)
    if DEBUG and lines is not None:
        for line in lines[:30]:
            x1, y1, x2, y2 = line[0]
            cv2.line(line_img, (x1, y1), (x2, y2), (0, 0, 255), 1)

    for fit, color in zip([smoothed_left_fit, smoothed_right_fit], [(0, 255, 0), (0, 255, 0)]):
        pts = extrapolate_line(fit, height, roi_top)
        if pts:
            cv2.line(line_img, pts[0], pts[1], color, 5)

    result = cv2.addWeighted(frame, 0.8, line_img, 1.0, 0)

    left_pts = extrapolate_line(smoothed_left_fit, height, roi_top)
    right_pts = extrapolate_line(smoothed_right_fit, height, roi_top)
    if left_pts and right_pts:
        polygon = np.array([left_pts[0], left_pts[1], right_pts[1], right_pts[0]], dtype=np.int32)
        overlay = result.copy()
        cv2.fillPoly(overlay, [polygon.reshape((-1, 1, 2))], (60, 200, 60))
        result = cv2.addWeighted(overlay, 0.3, result, 0.7, 0)

    return result

def main():
    cap = cv2.VideoCapture(VIDEO_SOURCE)
    if not cap.isOpened():
        print("❌ Error: Could not open video source.")
        return

    # Get original video info
    original_width = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
    original_height = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
    fps = cap.get(cv2.CAP_PROP_FPS)
    output_size = (600, 600)

    # Output video setup - Using XVID codec which is widely compatible with Qt on Linux
    fourcc = cv2.VideoWriter_fourcc(*'XVID')
    out = cv2.VideoWriter(OUTPUT_VIDEO, fourcc, fps, output_size)
    
    if not out.isOpened():
        print("Warning: Could not open video writer with XVID, trying MJPG...")
        fourcc = cv2.VideoWriter_fourcc(*'MJPG')
        out = cv2.VideoWriter(OUTPUT_VIDEO, fourcc, fps, output_size)
        
    if not out.isOpened():
        print("Error: Could not open video writer")
        return

    while True:
        ret, frame = cap.read()
        if not ret:
            break

        frame = cv2.resize(frame, output_size)
        processed = process_frame(frame)

        out.write(processed)  # Save frame

    cap.release()
    out.release()
    cv2.destroyAllWindows()
    print(f"✅ Output saved to: {os.path.abspath(OUTPUT_VIDEO)}")

if __name__ == "__main__":
    main()