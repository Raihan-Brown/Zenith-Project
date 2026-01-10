import os
from sqlalchemy.orm import Session
from app.database import SessionLocal, engine
from app.models import models
from app.core import security

def seed_users_from_faces():
    """
    Skrip otomatis untuk mendaftarkan user ke database berdasarkan foto di folder faces/
    Format file wajib: NIS_Nama_Nomor.jpg (Contoh: 2310631170042_Raihan_1.jpg)
    """
    db: Session = SessionLocal()
    faces_folder = "faces"

    if not os.path.exists(faces_folder):
        print(f"❌ Folder '{faces_folder}' tidak ditemukan!")
        return

    print("🚀 Memulai sinkronisasi Foto Faces ke Database...")
    
    # Ambil semua file gambar di folder faces
    valid_extensions = ('.jpg', '.png', '.jpeg')
    files = [f for f in os.listdir(faces_folder) if f.lower().endswith(valid_extensions)]
    
    added_count = 0
    skipped_count = 0
    error_count = 0

    # Gunakan password yang sangat sederhana untuk testing
    # Jika masih error, masalahnya ada di instalasi library bcrypt Anda
    DEFAULT_PASSWORD = "pw123"

    for file_name in files:
        try:
            # Ambil NIS dan Nama dari file_name (NIS_Nama_No.jpg)
            parts = file_name.split("_")
            if len(parts) < 2:
                continue
            
            nis = str(parts[0]).strip()
            name = str(parts[1]).strip()
            
            # Cek apakah NIS sudah ada di database supaya tidak duplikat
            existing_user = db.query(models.User).filter(models.User.nis == nis).first()
            
            if not existing_user:
                # Pastikan password adalah string murni dan dibersihkan dari karakter aneh
                # Kita konversi ke str() dan strip() lagi untuk keamanan ekstra
                clean_password = str(DEFAULT_PASSWORD).strip()
                
                # Truncate paksa ke 72 byte (limit maksimal bcrypt)
                final_password = clean_password[:72]
                
                # Cek jika NIS atau Name kosong (mencegah error database)
                if not nis or not name:
                    print(f"⚠️ Melewati {file_name}: Data tidak lengkap.")
                    continue

                new_user = models.User(
                    name=name,
                    nis=nis,
                    password_hash=security.get_password_hash(final_password),
                    role="USER",
                    points=0
                )
                db.add(new_user)
                db.commit()
                print(f"✅ Berhasil mendaftarkan: {name} (NIS: {nis})")
                added_count += 1
            else:
                skipped_count += 1
        except Exception as e:
            db.rollback()
            # Tampilkan detail error untuk debugging
            error_msg = str(e)
            if "72 bytes" in error_msg:
                print(f"❌ Error Bcrypt pada {file_name}: Sistem mendeteksi password terlalu panjang ({len(DEFAULT_PASSWORD)} char).")
                print("   Saran: Jalankan 'pip install --upgrade bcrypt passlib' di terminal Anda.")
            else:
                print(f"❌ Gagal memproses {file_name}: {error_msg}")
            error_count += 1

    db.close()
    print("-" * 30)
    print(f"🏁 Selesai!")
    print(f"➕ User baru ditambahkan: {added_count}")
    print(f"⏭️ User sudah ada (diabaikan): {skipped_count}")
    if error_count > 0:
        print(f"⚠️ Total file gagal: {error_count}")

if __name__ == "__main__":
    seed_users_from_faces()