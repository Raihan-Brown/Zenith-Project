from fastapi import FastAPI
from app.database import engine, Base, SessionLocal
from app.models import models
from app.services.mqtt_handler import init_mqtt_background
from app.core.config import settings
from app.routers import auth, user, qr, ai

# Inisialisasi Database
Base.metadata.create_all(bind=engine)

app = FastAPI(title=settings.PROJECT_NAME)

@app.on_event("startup")
def startup_event():
    # 1. Pastikan kategori sampah dasar tersedia di DB
    db = SessionLocal()
    try:
        if not db.query(models.WasteCategory).first():
            initial_categories = [
                models.WasteCategory(name="botol", points=300),
                models.WasteCategory(name="kaleng", points=500)
            ]
            db.add_all(initial_categories)
            db.commit()
            print("DB: Kategori sampah awal di-seed.")
    finally:
        db.close()

    # 2. Jalankan MQTT Listener di Background Thread
    init_mqtt_background()

# Include Routers
app.include_router(auth.router)
app.include_router(user.router)
app.include_router(qr.router)
app.include_router(ai.router)

@app.get("/")
def root():
    return {
        "status": "Zenith Backend Online",
        "mqtt": "Background Service Running",
        "ai": "Face Majority Voting Enabled"
    }

@app.get("/health")
def health_check():
    return {"status": "ok"}