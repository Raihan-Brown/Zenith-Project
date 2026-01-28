import os
import sys

# Tambahkan path project ke system path biar bisa import app.*
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from sqlalchemy.orm import Session
from app.database import SessionLocal
from app.models import models
from app.core import security

def seed_admin_user():
    """
    Script khusus untuk membuat akun SUPER ADMIN secara manual.
    """
    db: Session = SessionLocal()
    
    # --- KONFIGURASI AKUN ADMIN ---
    # Ganti sesuai selera, tapi ingat ini buat login nanti
    ADMIN_NIS = "admin"           # Bisa pakai string 'admin' atau angka unik '00000'
    ADMIN_NAME = "Administrator Zenith"
    # ADMIN_EMAIL = "admin@zenith.com"
    ADMIN_PASSWORD = "admin123"
    ADMIN_ROLE = "admin"          # WAJIB 'admin' (kecil semua) sesuai logic Flutter
    # ------------------------------

    print("🚀 Sedang membuat akun Admin...")

    try:
        # 1. Cek apakah admin dengan NIS ini sudah ada?
        existing_user = db.query(models.User).filter(models.User.nis == ADMIN_NIS).first()

        if existing_user:
            print(f"⚠️ User dengan NIS '{ADMIN_NIS}' sudah ada.")
            print("🔄 Mengupdate password dan role untuk memastikan akses Admin...")
            
            # Update paksa jadi admin & reset password
            existing_user.role = ADMIN_ROLE
            existing_user.password_hash = security.get_password_hash(ADMIN_PASSWORD)
            # existing_user.email = ADMIN_EMAIL # Update email juga
            
            db.commit()
            print("✅ Berhasil update user yang ada menjadi ADMIN.")
            
        else:
            # 2. Kalau belum ada, buat baru
            new_admin = models.User(
                nis=ADMIN_NIS,
                name=ADMIN_NAME,
                # email=ADMIN_EMAIL,
                password_hash=security.get_password_hash(ADMIN_PASSWORD),
                role=ADMIN_ROLE,    # <--- INI KUNCINYA
                points=99999        # Kasih poin banyak biar keliatan sultan
                # Tambahkan field lain jika model kamu mewajibkannya (misal: profile_photo_url=None)
            )
            
            db.add(new_admin)
            db.commit()
            print(f"✅ Berhasil membuat akun ADMIN baru.")

        print("-" * 30)
        print("🎉 KREDENSIAL LOGIN:")
        print(f"👤 NIS/Username : {ADMIN_NIS}")
        print(f"🔑 Password     : {ADMIN_PASSWORD}")
        print(f"🛡️ Role         : {ADMIN_ROLE}")
        print("-" * 30)

    except Exception as e:
        print(f"❌ Terjadi Error: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    seed_admin_user()