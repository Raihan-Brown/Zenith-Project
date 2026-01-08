from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
from app.database import get_db
from app.models import models
from app.core import security
from app.schemas import schemas

router = APIRouter(prefix="/auth", tags=["Auth"])

@router.post("/register", response_model=schemas.UserOut)
def register(user_in: schemas.UserCreate, db: Session = Depends(get_db)):
    if user_in.nis and db.query(models.User).filter(models.User.nis == user_in.nis).first():
        raise HTTPException(status_code=400, detail="NIS sudah digunakan")
    
    new_user = models.User(
        name=user_in.name,
        nis=user_in.nis,
        password_hash=security.get_password_hash(user_in.password),
        role=user_in.role
    )
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    return new_user

@router.post("/login", response_model=schemas.Token)
def login(form_data: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(get_db)):
    user = db.query(models.User).filter(models.User.nis == form_data.username).first()
    if not user or not security.verify_password(form_data.password, user.password_hash):
        raise HTTPException(status_code=401, detail="NIS atau password salah")
    
    token = security.create_access_token(subject=user.id)
    return {"access_token": token, "token_type": "bearer"}