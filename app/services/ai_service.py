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
        self.known_nis = []
        self.known_names = []
        # Folder untuk melihat hasil jepretan kamera saat testing
        self.debug_folder = "debug"
        if not os.path.exists(self.debug_folder):
            os.makedirs(self.debug_folder)
            
        self.load_faces()

    def load_faces(self):
        """Memuat dataset wajah dari folder faces/ dengan format: NIS_Nama_X.jpg"""
        if not os.path.exists("faces"):
            os.makedirs("faces")
            print("AI Engine: Folder faces dibuat. Silakan masukkan foto dataset.")
            return
        
        for file in os.listdir("faces"):
            if file.lower().endswith((".jpg", ".png", ".jpeg")):
                try:
                    img = face_recognition.load_image_file(f"faces/{file}")
                    encs = face_recognition.face_encodings(img)
                    if encs:
                        self.known_encodings.append(encs[0])
                        # Mengambil NIS dari nama file (bagian sebelum underscore pertama)
                        parts = file.split("_")
                        self.known_nis.append(parts[0])
                        self.known_names.append(parts[1] if len(parts) > 1 else "Unknown")
                except Exception as e:
                    print(f"Gagal memuat wajah {file}: {e}")
        print(f"AI Engine: {len(self.known_nis)} wajah berhasil didaftarkan ke sistem.")

    def get_esp_snapshot(self, prefix="snap"):
        """Mengambil satu frame gambar dari ESP32-CAM via HTTP Capture"""
        try:
            # Menggunakan timestamp unik agar gambar tidak diambil dari cache
            r = requests.get(f"http://{settings.CAM_IP}/capture?t={int(time.time())}", timeout=5)
            if r.status_code == 200:
                img_np = np.frombuffer(r.content, np.uint8)
                frame = cv2.imdecode(img_np, cv2.IMREAD_COLOR)
                
                # Simpan ke folder debug untuk verifikasi manual saat testing
                debug_path = os.path.join(self.debug_folder, f"{prefix}_latest.jpg")
                cv2.imwrite(debug_path, frame)
                
                return frame
            else:
                print(f"📸 Kamera Error: Status {r.status_code}")
        except Exception as e:
            print(f"📸 Kamera Error (Koneksi): {e}")
            return None

    def face_majority_voting(self, shots=3):
        """Logika Majority Voting: Mengambil beberapa snapshot untuk akurasi tinggi"""
        votes = []
        print(f"📸 AI: Memulai proses identifikasi wajah ({shots} pengambilan)...")
        
        for i in range(shots):
            frame = self.get_esp_snapshot(prefix=f"face_{i}")
            if frame is not None:
                rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
                encs = face_recognition.face_encodings(rgb)
                if encs:
                    # Menggunakan toleransi 0.45 agar lebih ketat dan akurat
                    matches = face_recognition.compare_faces(self.known_encodings, encs[0], tolerance=0.45)
                    if True in matches:
                        idx = matches.index(True)
                        votes.append((self.known_nis[idx], self.known_names[idx]))
            time.sleep(0.2) 

        if not votes: 
            print("❌ AI: Wajah tidak terdeteksi atau tidak dikenali.")
            return None, None
        
        # Mencari hasil yang paling sering muncul (Majority Vote)
        counts = Counter([v[0] for v in votes])
        winner_nis, win_count = counts.most_common(1)[0]
        winner_name = next(v[1] for v in votes if v[0] == winner_nis)
        
        print(f"✅ AI: Identitas terkonfirmasi sebagai {winner_name} ({win_count}/{shots} match)")
        return winner_nis, winner_name

    def trash_detect_roboflow(self):
        """Deteksi sampah menggunakan API Roboflow dengan threshold rendah untuk fleksibilitas"""
        frame = self.get_esp_snapshot(prefix="trash")
        if frame is None:
            return None
        
        # Optimasi ukuran gambar sebelum dikirim ke cloud agar lebih ringan
        resized = cv2.resize(frame, (320, 320))
        _, encoded = cv2.imencode(".jpg", resized)
        
        # Konfigurasi URL Roboflow dengan confidence threshold 20%
        url = (
            f"https://detect.roboflow.com/{settings.ROBOFLOW_MODEL}"
            f"?api_key={settings.ROBOFLOW_API_KEY}"
            f"&confidence=0.2" 
        )
        
        try:
            r = requests.post(url, files={"file": encoded.tobytes()}, timeout=10)
            data = r.json()
            preds = data.get("predictions", [])
            
            if not preds:
                print("♻️ AI: Roboflow tidak menemukan objek yang cocok di dalam kotak.")
                return None
            
            # Mengambil prediksi dengan tingkat kepercayaan (confidence) tertinggi
            best = max(preds, key=lambda x: x['confidence'])
            print(f"♻️ AI: Terdeteksi {best['class']} (Confidence: {best['confidence']:.2f})")
            
            return {"type": best["class"], "confidence": best["confidence"]}
        except Exception as e:
            print(f"❌ Roboflow API Error: {e}")
            return None

ai_engine = AIEngine()