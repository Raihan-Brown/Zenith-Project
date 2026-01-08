import paho.mqtt.client as mqtt
import json
import threading
import uuid
from app.core.config import settings
from app.services.ai_engine import ai_engine
from app.database import SessionLocal
from app.models import models

# In-memory session store untuk mengikat User ID ke Device ID saat transaksi berlangsung
# Format: { device_id: { "user_id": "...", "session_id": "..." } }
active_sessions = {}

def on_message(client, userdata, msg):
    db = SessionLocal()
    try:
        payload = json.loads(msg.payload.decode())
        cmd = payload.get("cmd")
        device_id = payload.get("device_id", "unknown")
        response_topic = f"zenith/{device_id}/response"

        if cmd == "FACE_SCAN":
            print(f"MQTT: Memulai Face Scan Voting untuk {device_id}")
            u_id, u_name = ai_engine.face_majority_voting(shots=5)
            
            if u_id:
                session_id = str(uuid.uuid4())
                active_sessions[device_id] = {"user_id": u_id, "session_id": session_id}
                
                resp = {
                    "cmd": "FACE_SCAN_RESULT",
                    "status": "OK",
                    "user": u_name,
                    "session_id": session_id
                }
            else:
                resp = {"cmd": "FACE_SCAN_RESULT", "status": "ERROR", "message": "Face Not Recognized"}
            
            client.publish(response_topic, json.dumps(resp))

        elif cmd == "TRASH_SCAN":
            print(f"MQTT: Memulai Trash Scan untuk {device_id}")
            # Cek apakah ada user yang sudah teridentifikasi di device ini
            session_data = active_sessions.get(device_id)
            
            if not session_data:
                client.publish(response_topic, json.dumps({"cmd": "TRASH_SCAN_RESULT", "status": "ERROR", "message": "No Active Session"}))
                return

            trash_info = ai_engine.trash_detect_roboflow()
            
            if trash_info:
                # Ambil Poin dari DB
                category = db.query(models.WasteCategory).filter(models.WasteCategory.name == trash_info["type"]).first()
                points = category.points if category else 0
                
                # Update User Points & Simpan Log
                user = db.query(models.User).filter(models.User.id == session_data["user_id"]).first()
                if user:
                    user.points += points
                    
                    new_log = models.WasteLog(
                        device_id=device_id,
                        session_id=session_data["session_id"],
                        user_id=user.id,
                        trash_type=trash_info["type"],
                        confidence_score=trash_info["confidence"],
                        points_earned=points
                    )
                    db.add(new_log)
                    db.commit()
                    
                    resp = {
                        "cmd": "TRASH_SCAN_RESULT",
                        "status": "OK",
                        "trash": trash_info["type"],
                        "points": points,
                        "confidence": trash_info["confidence"],
                        "session_id": session_data["session_id"]
                    }
                    # Bersihkan session setelah transaksi selesai
                    del active_sessions[device_id]
                else:
                    resp = {"cmd": "TRASH_SCAN_RESULT", "status": "ERROR", "message": "User Data Missing"}
            else:
                resp = {"cmd": "TRASH_SCAN_RESULT", "status": "ERROR", "message": "Trash Not Identified"}
            
            client.publish(response_topic, json.dumps(resp))

    except Exception as e:
        print(f"MQTT Worker Error: {e}")
    finally:
        db.close()

def mqtt_worker():
    client = mqtt.Client()
    client.on_message = on_message
    client.connect(settings.MQTT_BROKER, settings.MQTT_PORT, 60)
    client.subscribe(settings.MQTT_CMD_TOPIC)
    print(f"📡 Zenith MQTT Background Worker Running on topic: {settings.MQTT_CMD_TOPIC}")
    client.loop_forever()

def init_mqtt_background():
    # Menjalankan MQTT di thread terpisah (Daemon agar mati saat app berhenti)
    t = threading.Thread(target=mqtt_worker, daemon=True)
    t.start()