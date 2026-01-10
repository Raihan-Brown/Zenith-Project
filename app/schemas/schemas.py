from pydantic import BaseModel
from typing import Optional
from datetime import datetime

class UserBase(BaseModel):
    name: str
    nis: Optional[str] = None

class UserCreate(UserBase):
    password: str
    role: str = "USER"

class UserOut(UserBase):
    id: str
    points: int
    role: str
    class Config:
        from_attributes = True

class Token(BaseModel):
    access_token: str
    token_type: str

class WasteDetection(BaseModel):
    user_id: str
    waste_type: str
    confidence: float
    # image_url: Optional[str] = None # Jika ada integrasi storage

class FaceRecognitionRequest(BaseModel):
    user_id: str
    confidence: float
    camera_id: str

class QRGenerate(BaseModel):
    points: int

class LeaderboardOut(BaseModel):
    name: str
    points: int

    class Config:
        from_attributes = True

class QRReportOut(BaseModel):
    id: int
    qr_token: str
    points: int
    status: str
    created_at: datetime
    user_name: str # Menampilkan nama user yang menukar

    class Config:
        from_attributes = True