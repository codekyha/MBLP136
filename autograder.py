import os
import subprocess
import time
import glob

# ================= AYARLAR =================
SQL_KLASORU = "./ogrenci_projeleri"
RAPOR_DOSYASI = "degerlendirme_raporu.txt"
DOCKER_CONTAINER_NAME = "mblp136_test_db"
MYSQL_ROOT_PASSWORD = "root"
# ===========================================

def run_command(command, check=False):
    """Terminal komutlarını çalıştırır ve çıktıyı döndürür."""
    result = subprocess.run(command, shell=True, capture_output=True, text=True)
    if check and result.returncode != 0:
        return False, result.stderr
    return True, result.stdout

def start_mysql_container():
    """Geçici bir MySQL konteyneri başlatır."""
    print("[*] Geçici Test Veritabanı (Docker MySQL) başlatılıyor...")
    # Varsa eski konteyneri temizle
    run_command(f"docker rm -f {DOCKER_CONTAINER_NAME}")
    
    # Yeni konteyner başlat
    run_command(f"docker run --name {DOCKER_CONTAINER_NAME} -e MYSQL_ROOT_PASSWORD={MYSQL_ROOT_PASSWORD} -d mysql:8.0")
    
    # Veritabanının hazır olmasını bekle (Ping atarak kontrol eder)
    for _ in range(30):
        success, _ = run_command(f"docker exec {DOCKER_CONTAINER_NAME} mysqladmin ping -h localhost -u root --password={MYSQL_ROOT_PASSWORD}")
        if success:
            print("[+] Veritabanı teste hazır.\n")
            return True
        time.sleep(1)
    return False

def stop_mysql_container():
    """Test bittikten sonra konteyneri siler."""
    print("\n[*] Testler bitti. Docker konteyneri temizleniyor...")
    run_command(f"docker rm -f {DOCKER_CONTAINER_NAME}")

def test_student_sql(sql_file):
    """Öğrencinin SQL dosyasını test eder ve puanlar."""
    student_name = os.path.basename(sql_file)
    print(f"--- Test Ediliyor: {student_name} ---")
    
    score = 0
    feedback = []

    # 1. SQL Dosyasını Konteynere Kopyala ve Çalıştır
    run_command(f"docker cp \"{sql_file}\" {DOCKER_CONTAINER_NAME}:/test.sql")
    
    # Veritabanını sıfırla ve SQL'i içeri aktar
    run_command(f"docker exec {DOCKER_CONTAINER_NAME} mysql -u root -p{MYSQL_ROOT_PASSWORD} -e 'DROP DATABASE IF EXISTS testdb; CREATE DATABASE testdb;'")
    success, err = run_command(f"docker exec {DOCKER_CONTAINER_NAME} mysql -u root -p{MYSQL_ROOT_PASSWORD} testdb < /test.sql", check=True)
    
    if not success:
        feedback.append("❌ HATA: SQL scripti çalışırken syntax (sözdizimi) hatası verdi veya tablolar oluşturulamadı.")
        feedback.append(f"   Detay: {err.strip()[:200]}...") # Hatanın ilk 200 karakteri
        return score, feedback
    else:
        score += 30
        feedback.append("✅ SQL dosyası hatasız çalıştı ve DB oluşturuldu. (+30 Puan)")

    # 2. Tablo Sayısı Kontrolü (En az 5 tablo olmalı)
    _, out = run_command(f"docker exec {DOCKER_CONTAINER_NAME} mysql -u root -p{MYSQL_ROOT_PASSWORD} -N -B -e 'SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = \"testdb\";'")
    try:
        table_count = int(out.strip())
        if table_count >= 5:
            score += 20
            feedback.append(f"✅ Tablo Sayısı: {table_count} (İstenen minimum sayı sağlandı). (+20 Puan)")
        else:
            score += 10
            feedback.append(f"⚠️ Tablo Sayısı: {table_count} (5'ten az tablo var!). (+10 Puan)")
    except:
        feedback.append("❌ Tablo sayısı okunamadı.")

    # 3. İçerik (Veri) Kontrolü (Tablolarda data var mı?)
    _, tables_out = run_command(f"docker exec {DOCKER_CONTAINER_NAME} mysql -u root -p{MYSQL_ROOT_PASSWORD} -N -B -e 'SHOW TABLES FROM testdb;'")
    tables = tables_out.strip().split('\n')
    
    empty_tables = 0
    for table in tables:
        if table:
            _, row_count_out = run_command(f"docker exec {DOCKER_CONTAINER_NAME} mysql -u root -p{MYSQL_ROOT_PASSWORD} -N -B -e 'SELECT COUNT(*) FROM testdb.{table};'")
            if int(row_count_out.strip()) == 0:
                empty_tables += 1

    if empty_tables == 0 and len(tables) > 0:
        score += 15
        feedback.append("✅ Tüm tablolara başarılı bir şekilde örnek veri (INSERT) eklenmiş. (+15 Puan)")
    else:
        feedback.append(f"⚠️ İÇERİK EKSİK: {empty_tables} tabloda hiç veri yok. (Puan verilmedi)")

    # 4. Dosya İçi Statik Analiz (Özgünlük ve İleri Sorgular)
    with open(sql_file, 'r', encoding='utf-8', errors='ignore') as f:
        content = f.read().upper()
        
        # JOIN kullanımı
        if "JOIN" in content:
            score += 10
            feedback.append("✅ JOIN yapısı kullanılmış. (+10 Puan)")
        else:
            feedback.append("❌ JOIN yapısı bulunamadı.")
            
        # GROUP BY kullanımı
        if "GROUP BY" in content:
            score += 10
            feedback.append("✅ GROUP BY yapısı kullanılmış. (+10 Puan)")
        else:
            feedback.append("❌ GROUP BY yapısı bulunamadı.")

        # ACID / Kısıtlayıcılar
        constraints = sum(1 for word in ["CHECK", "UNIQUE", "DEFAULT", "NOT NULL"] if word in content)
        if constraints >= 2:
            score += 15
            feedback.append("✅ En az 2 farklı kısıtlayıcı (Constraint) kullanılmış. (+15 Puan)")
        else:
            feedback.append("⚠️ Yeterli kısıtlayıcı (Constraint) bulunamadı.")

    feedback.append(f"🏆 OTOMATİK TEKNİK PUAN: {score}/100")
    feedback.append("-" * 40)
    return score, feedback

def main():
    print("=== MBLP136 Veri Tabanı Otomatik Notlandırma Sistemi ===")
    sql_files = glob.glob(os.path.join(SQL_KLASORU, "*.sql"))
    
    if not sql_files:
        print(f"HATA: '{SQL_KLASORU}' klasöründe hiç .sql dosyası bulunamadı!")
        return

    print(f"Toplam {len(sql_files)} proje bulundu.\n")
    
    if not start_mysql_container():
        print("HATA: Docker MySQL başlatılamadı. Docker'ın açık olduğundan emin olun.")
        return

    with open(RAPOR_DOSYASI, 'w', encoding='utf-8') as f_report:
        f_report.write("MBLP136 DÖNEM SONU PROJESİ DEĞERLENDİRME RAPORU\n")
        f_report.write("="*50 + "\n\n")

        for sql_file in sql_files:
            score, feedback = test_student_sql(sql_file)
            
            # Rapora yazdır
            f_report.write(f"Öğrenci Dosyası: {os.path.basename(sql_file)}\n")
            for line in feedback:
                f_report.write(line + "\n")
                print(line)
            f_report.write("\n")

    stop_mysql_container()
    print(f"\n[!] Tüm testler tamamlandı. Rapor '{RAPOR_DOSYASI}' dosyasına kaydedildi.")

if __name__ == "__main__":
    main()