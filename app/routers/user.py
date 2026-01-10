from fastapi import APIRouter, Depends
from ..models import models
from ..dependencies import get_current_user
from ..schemas import schemas
from typing import List

router = APIRouter(prefix="/users", tags=["User"])

@router.get("/me", response_model=schemas.UserOut)
def get_me(current_user: models.User = Depends(get_current_user)):
    return current_user

@router.get("/leaderboard", response_model=List[schemas.LeaderboardOut])
def get_leaderboard(db: Session = Depends(get_db)):
    # Mengambil 10 user dengan poin tertinggi
    top_users = db.query(models.User).order_by(models.User.points.desc()).limit(10).all()
    return top_users