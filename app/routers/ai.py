from fastapi import APIRouter, Depends, HTTPException, Header
from sqlalchemy.orm import Session
from app.database import get_db
from app.models import models
from app.schemas import schemas
from app.core.config import settings

router = APIRouter(prefix="/ai", tags=["AI Integration"])

@router.post("/waste-detected")
def handle_waste(
    payload: schemas.WasteDetection, 
    db: Session = Depends(get_db),
    x_ai_secret: str = Header(None)
):
    if x_ai_secret != settings.AI_SECRET_KEY:
        raise HTTPException(status_code=403, detail="Invalid AI Secret Key")
    
    user = db.query(models.User).filter(models.User.id == payload.user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User tidak ditemukan")
    
    category = db.query(models.WasteCategory).filter(
        models.WasteCategory.name == payload.waste_type
    ).first()
    
    if not category:
        raise HTTPException(status_code=400, detail="Kategori sampah tidak terdaftar")
    
    user.points += category.points
    new_log = models.WasteLog(
        user_id=user.id,
        waste_category_id=category.id,
        points_earned=category.points
    )
    db.add(new_log)
    db.commit()
    
    return {"status": "success", "points_added": category.points, "current_total": user.points}