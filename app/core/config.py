from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    PROJECT_NAME: str = "Zenith Smart Waste"
    
    # MQTT Configuration
    MQTT_BROKER: str = "broker.hivemq.com"
    MQTT_PORT: int = 1883
    MQTT_CMD_TOPIC: str = "zenith/command"
    
    # AI Keys & Config
    AI_SECRET_KEY: str = "ZENITH_AI_GATEWAY_TOKEN_042"
    ROBOFLOW_API_KEY: str = "Qk857OvyYnARtPkNyUOX"
    ROBOFLOW_MODEL: str = "deteksi-botol-dan-kaleng-uuytw/1"
    
    # Hardware Endpoint (ESP32-CAM IP)
    # Di produksi, IP ini bisa dinamis per device_id jika disimpan di DB
    CAM_IP: str = "10.68.38.86" 
    
    # Database
    DATABASE_URL: str = "sqlite:///./zenith_final.db"

    class Config:
        env_file = ".env"

settings = Settings()