from fastapi import APIRouter, Depends
from ..models import models
from ..dependencies import get_current_user
from ..schemas import schemas

router = APIRouter(prefix="/users", tags=["User"])

@router.get("/me", response_model=schemas.UserOut)
def get_me(current_user: models.User = Depends(get_current_user)):
    return current_user