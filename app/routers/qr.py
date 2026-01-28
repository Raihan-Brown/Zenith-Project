import secrets
from datetime import datetime, timedelta
from typing import List
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from ..database import get_db
from ..models import models
from ..schemas import schemas
from ..dependencies import get_current_user, admin_required

router = APIRouter(prefix="/qr", tags=["QR Transaction"])

@router.post("/generate")
def generate_qr(
    payload: schemas.QRGenerate, 
    db: Session = Depends(get_db), 
    user: models.User = Depends(get_current_user)
):
    if user.points < payload.points:
        raise HTTPException(status_code=400, detail="Poin tidak mencukupi")
    
    # Buat token unik
    token = secrets.token_urlsafe(32)
    new_qr = models.QRTransaction(
        qr_token=token,
        user_id=user.id,
        points=payload.points,
        expired_at=datetime.utcnow() + timedelta(seconds=60) # Expired 60 detik
    )
    db.add(new_qr)
    db.commit()
    
    return {"qr_token": token, "expires_in": 60}

@router.post("/scan")
def scan_qr(
    payload: dict, 
    db: Session = Depends(get_db), 
    admin: models.User = Depends(admin_required)
):
    qr_token = payload.get("qr_token")
    qr = db.query(models.QRTransaction).filter(
        models.QRTransaction.qr_token == qr_token,
        models.QRTransaction.status == "PENDING"
    ).first()
    
    # ... (validasi expired tetap sama) ...
    
    user = db.query(models.User).filter(models.User.id == qr.user_id).first()
    if user.points < qr.points:
        qr.status = "FAILED"
        db.commit()
        raise HTTPException(status_code=400, detail="Poin user tidak cukup")
    
    # PROSES TRANSFER & PENCATATAN ADMIN
    user.points -= qr.points
    admin.points += qr.points
    
    qr.status = "COMPLETED"
    qr.scanned_by_admin_id = admin.id # Simpan siapa admin yang nge-scan
    db.commit()
    
    return {"status": "success", "user": user.name, "points_redeemed": qr.points}

@router.get("/reports", response_model=List[schemas.QRReportOut])
def get_admin_reports(
    db: Session = Depends(get_db), 
    admin: models.User = Depends(admin_required)
):
    # Mengambil daftar transaksi sukses yang diproses oleh admin ini
    transactions = db.query(models.QRTransaction).filter(
        models.QRTransaction.scanned_by_admin_id == admin.id,
        models.QRTransaction.status == "COMPLETED"
    ).order_by(models.QRTransaction.created_at.desc()).all()
    
    # Mapping manual untuk memasukkan nama user ke dalam response
    results = []
    for tx in transactions:
        results.append({
            "id": tx.id,
            "qr_token": tx.qr_token,
            "points": tx.points,
            "status": tx.status,
            "created_at": tx.created_at,
            "user_name": tx.user.name if tx.user else "Unknown"
        })
    return results