import paho.mqtt.client as mqtt
import json
import threading
import uuid
from app.core.config import settings
from app.services.ai_service import ai_engine
from app.database import SessionLocal
from app.models import models

# Store session aktif per device
active_sessions = {}

def on_message(client, userdata, msg):
    db = SessionLocal()
    raw_payload = msg.payload.decode().strip()
    
    # Log pesan masuk biar kita tau isinya apa
    print(f"📩 Pesan masuk di {msg.topic}: '{raw_payload}'")
    
    if not raw_payload:
        print("⚠️ Pesan kosong diabaikan.")
        db.close()
        return

    try:
        # Mencoba parse JSON
        payload = json.loads(raw_payload)
        cmd = payload.get("cmd")
        device_id = payload.get("device_id", "unknown")
        response_topic = f"zenith/{device_id}/response"

        if cmd == "FACE_SCAN":
            print(f"📸 Menjalankan Face Voting untuk {device_id}...")
            u_nis, u_name = ai_engine.face_majority_voting(shots=5)
            
            if u_nis:
                user = db.query(models.User).filter(models.User.nis == u_nis).first()
                if user:
                    session_id = str(uuid.uuid4())
                    active_sessions[device_id] = {"user_id": user.id, "session_id": session_id}
                    resp = {
                        "cmd": "FACE_SCAN_RESULT", 
                        "status": "OK", 
                        "user": user.name, 
                        "session_id": session_id
                    }
                else:
                    resp = {"cmd": "FACE_SCAN_RESULT", "status": "ERROR", "message": "NIS terdaftar di AI tapi tidak di DB"}
            else:
                resp = {"cmd": "FACE_SCAN_RESULT", "status": "ERROR", "message": "Wajah tidak dikenal"}
            
            client.publish(response_topic, json.dumps(resp))
            print(f"📤 Respon dikirim ke {response_topic}")

        elif cmd == "TRASH_SCAN":
            print(f"♻️ Menjalankan Trash Scan untuk {device_id}...")
            session = active_sessions.get(device_id)
            if not session:
                client.publish(response_topic, json.dumps({"status": "ERROR", "message": "Sesi tidak ditemukan"}))
                return

            trash = ai_engine.trash_detect_roboflow()
            if trash:
                category = db.query(models.WasteCategory).filter(models.WasteCategory.name == trash["type"]).first()
                points = category.points if category else 0
                
                user = db.query(models.User).filter(models.User.id == session["user_id"]).first()
                if user:
                    user.points += points
                    log = models.WasteLog(
                        device_id=device_id,
                        session_id=session["session_id"],
                        user_id=user.id,
                        trash_type=trash["type"],
                        confidence_score=trash["confidence"],
                        points_earned=points
                    )
                    db.add(log)
                    db.commit()
                    
                    resp = {
                        "cmd": "TRASH_SCAN_RESULT",
                        "status": "OK",
                        "trash": trash["type"],
                        "points": points,
                        "confidence": trash["confidence"]
                    }
                    del active_sessions[device_id] 
                else:
                    resp = {"status": "ERROR", "message": "User ID hilang"}
            else:
                resp = {"cmd": "TRASH_SCAN_RESULT", "status": "ERROR", "message": "Sampah tidak teridentifikasi"}
            
            client.publish(response_topic, json.dumps(resp))
            print(f"📤 Respon dikirim ke {response_topic}")

    except json.JSONDecodeError:
        print(f"❌ Error: Pesan bukan JSON valid! Isi pesan: '{raw_payload}'")
    except Exception as e:
        print(f"❌ MQTT Error: {e}")
    finally:
        db.close()

def mqtt_worker():
    client = mqtt.Client()
    client.on_message = on_message
    client.connect(settings.MQTT_BROKER, settings.MQTT_PORT, 60)
    client.subscribe(settings.MQTT_CMD_TOPIC)
    print(f"📡 Zenith MQTT Worker aktif di {settings.MQTT_CMD_TOPIC}")
    client.loop_forever()

def init_mqtt_background():
    t = threading.Thread(target=mqtt_worker, daemon=True)
    t.start()