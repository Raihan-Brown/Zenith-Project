from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    PROJECT_NAME: str = "Zenith Smart Waste Management"
    
    # MQTT Configuration
    MQTT_BROKER: str = "broker.hivemq.com"
    MQTT_PORT: int = 1883
    MQTT_CMD_TOPIC: str = "zenith/+/command"
    
    # AI Keys & Config
    SECRET_KEY: str = "ZENITH_SUPER_SECRET_2026"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 1440
    
    AI_SECRET_KEY: str = "ZENITH_AI_GATEWAY_TOKEN_042"
    ROBOFLOW_API_KEY: str = "Qk857OvyYnARtPkNyUOX"
    ROBOFLOW_MODEL: str = "deteksi-botol-dan-kaleng-uuytw/1"
    
    # Target ESP32-CAM (Snapshot Endpoint)
    CAM_IP: str = "172.27.2.160" 
    
    DATABASE_URL: str = "sqlite:///./zenith_v2.db"

    class Config:
        env_file = ".env"

settings = Settings()