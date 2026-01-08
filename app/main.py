from fastapi import FastAPI
from app.database import engine, Base, SessionLocal
from app.models import models
from app.services.mqtt_handler import init_mqtt_background
from app.core.config import settings

# Inisialisasi Tabel Database
Base.metadata.create_all(bind=engine)

app = FastAPI(title=settings.PROJECT_NAME)

@app.on_event("startup")
def startup_event():
    # 1. Pastikan kategori sampah awal ada di DB
    db = SessionLocal()
    try:
        if not db.query(models.WasteCategory).first():
            initial_cats = [
                models.WasteCategory(name="botol", points=300),
                models.WasteCategory(name="kaleng", points=500)
            ]
            db.add_all(initial_cats)
            db.commit()
            print("DB: Initial waste categories seeded.")
    finally:
        db.close()

    # 2. Jalankan MQTT Listener di Background Thread
    init_mqtt_background()

@app.get("/")
def root():
    return {
        "app": settings.PROJECT_NAME,
        "status": "Online",
        "mqtt_status": "Background Thread Running"
    }

@app.get("/health")
def health_check():
    return {"status": "ok"}