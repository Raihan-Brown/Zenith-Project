import uuid
from sqlalchemy import Column, String, Integer, ForeignKey, DateTime, Float
from sqlalchemy.orm import relationship
from datetime import datetime
from app.database import Base

class User(Base):
    __tablename__ = "users"
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    name = Column(String, nullable=False)
    nis = Column(String, unique=True, index=True, nullable=True)
    password_hash = Column(String, nullable=False)
    role = Column(String, default="USER") # USER | ADMIN
    points = Column(Integer, default=0)
    created_at = Column(DateTime, default=datetime.utcnow)

class WasteCategory(Base):
    __tablename__ = "waste_categories"
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, unique=True, index=True) # e.g., 'botol', 'kaleng'
    points = Column(Integer, default=0)

class WasteLog(Base):
    __tablename__ = "waste_logs"
    id = Column(Integer, primary_key=True, index=True)
    device_id = Column(String)      # ID Alat (Audit)
    session_id = Column(String)     # ID Sesi Transaksi (Audit)
    user_id = Column(String, ForeignKey("users.id"))
    trash_type = Column(String)     # Label Sampah (Audit)
    confidence_score = Column(Float) # Skor AI (Audit)
    points_earned = Column(Integer)
    timestamp = Column(DateTime, default=datetime.utcnow)

class QRTransaction(Base):
    __tablename__ = "qr_transactions"
    id = Column(Integer, primary_key=True, index=True)
    qr_token = Column(String, unique=True, index=True)
    user_id = Column(String, ForeignKey("users.id"))
    points = Column(Integer)
    status = Column(String, default="PENDING")
    created_at = Column(DateTime, default=datetime.utcnow)
    expired_at = Column(DateTime)
    # Tambahkan baris ini:
    scanned_by_admin_id = Column(String, ForeignKey("users.id"), nullable=True) 

    # Tambahkan relationship agar mudah mengambil data user/admin (opsional)
    user = relationship("User", foreign_keys=[user_id])
    admin = relationship("User", foreign_keys=[scanned_by_admin_id])