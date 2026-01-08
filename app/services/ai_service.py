import cv2
import face_recognition
import numpy as np
import requests
import time
import os
from collections import Counter
from app.core.config import settings

class AIEngine:
    def __init__(self):
        self.known_encodings = []
        self.known_ids = []
        self.known_names = []
        self.load_faces()

    def load_faces(self):
        """Memuat database wajah dari folder 'faces'"""
        if not os.path.exists("faces"):
            os.makedirs("faces")
            return
        
        for file in os.listdir("faces"):
            if file.endswith((".jpg", ".png")):
                # Format file: UUID_Nama.jpg
                img = face_recognition.load_image_file(f"faces/{file}")
                encs = face_recognition.face_encodings(img)
                if encs:
                    self.known_encodings.append(encs[0])
                    parts = file.split("_")
                    self.known_ids.append(parts[0])
                    self.known_names.append(parts[1].split(".")[0])
        print(f"AI Engine: {len(self.known_ids)} wajah dimuat.")

    def get_esp_snapshot(self):
        """Ambil 1 frame dari ESP32-CAM"""
        try:
            url = f"http://{settings.CAM_IP}/capture"
            r = requests.get(url, timeout=3)
            if r.status_code == 200:
                img_np = np.frombuffer(r.content, np.uint8)
                return cv2.imdecode(img_np, cv2.IMREAD_COLOR)
        except Exception as e:
            print(f"Camera Error: {e}")
        return None

    def face_majority_voting(self, shots=5):
        """Ambil 5 shot dan gunakan suara terbanyak"""
        votes = []
        for i in range(shots):
            frame = self.get_esp_snapshot()
            if frame is not None:
                rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
                encs = face_recognition.face_encodings(rgb)
                if encs:
                    matches = face_recognition.compare_faces(self.known_encodings, encs[0], tolerance=0.45)
                    if True in matches:
                        idx = matches.index(True)
                        votes.append((self.known_ids[idx], self.known_names[idx]))
            time.sleep(0.25) # Interval per shot

        if not votes: return None, None
        
        # Majority Voting
        counts = Counter([v[0] for v in votes])
        winner_id, count = counts.most_common(1)[0]
        
        # Ambil nama dari data voting pertama yang cocok dengan winner_id
        winner_name = next(v[1] for v in votes if v[0] == winner_id)
        return winner_id, winner_name

    def trash_detect_roboflow(self):
        """Deteksi sampah via Roboflow Hosted Inference"""
        frame = self.get_esp_snapshot()
        if frame is None: return None
        
        # Resize ke 320x320 untuk Roboflow
        resized = cv2.resize(frame, (320, 320))
        _, img_encoded = cv2.imencode(".jpg", resized)
        
        url = f"https://detect.roboflow.com/{settings.ROBOFLOW_MODEL}?api_key={settings.ROBOFLOW_API_KEY}"
        try:
            r = requests.post(url, files={"file": img_encoded.tobytes()}, timeout=10)
            data = r.json()
            preds = data.get("predictions", [])
            if not preds: return None
            
            # Ambil objek dengan confidence tertinggi
            best = max(preds, key=lambda x: x['confidence'])
            return {"type": best["class"], "confidence": best["confidence"]}
        except Exception as e:
            print(f"Roboflow Error: {e}")
            return None

ai_engine = AIEngine()