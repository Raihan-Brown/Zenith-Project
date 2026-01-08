import secrets
from datetime import datetime, timedelta
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
    
    if not qr or qr.expired_at < datetime.utcnow():
        if qr:
            qr.status = "EXPIRED"
            db.commit()
        raise HTTPException(status_code=400, detail="QR tidak valid atau sudah expired")
    
    # Eksekusi pemotongan poin
    user = db.query(models.User).filter(models.User.id == qr.user_id).first()
    if user.points < qr.points:
        qr.status = "FAILED"
        db.commit()
        raise HTTPException(status_code=400, detail="Poin user tidak cukup saat pemindaian")
    
    user.points -= qr.points
    qr.status = "COMPLETED"
    db.commit()
    
    return {"status": "success", "user": user.name, "points_redeemed": qr.points}