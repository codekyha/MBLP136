# MBLP136 – Veri Tabanı Ders Notları ve Uygulamaları

![Database](https://img.shields.io/badge/Database-SQL_Server_%7C_MySQL-blue?style=for-the-badge&logo=microsoft-sql-server)
![LaTeX](https://img.shields.io/badge/TypeSetting-LaTeX-008080?style=for-the-badge&logo=latex)
![Docker](https://img.shields.io/badge/Validation-Docker-2496ED?style=for-the-badge&logo=docker)

Bu depo, **İstanbul Okan Üniversitesi Meslek Yüksekokulu** bünyesinde yürütülen **MBLP136 – Veri Tabanı** dersine ait tüm akademik materyalleri, SQL uygulama scriptlerini ve ders notlarının oluşturulmasında kullanılan LaTeX kaynak kodlarını içermektedir.

## 📚 Ders Hakkında

Bu ders, bir işletmenin veri ihtiyacını karşılayacak sistemlerin sıfırdan tasarlanması, normalize edilmesi ve modern SQL lehçeleri (T-SQL/MySQL) kullanılarak yönetilmesi üzerine kurgulanmıştır. Mühendislik disipliniyle veri modelleme yetkinliği kazandırmayı amaçlar.

* **Eğitmen:** Dr. Öğr. Üyesi Hasan Oğuz
* **Kurum:** İstanbul Okan Üniversitesi

---

## 📁 Depo İçeriği

Dizin yapısı akademik takip ve kodun yeniden üretilebilirliği (reproducibility) üzerine organize edilmiştir:

| Dizin | İçerik Açıklaması |
| :--- | :--- |
| `/Notlar` | Haftalık ders slaytları ve konu özetlerini içeren PDF dosyaları. |
| `/LaTeX_Source` | Notların dizgisinde kullanılan `.tex` dosyaları ve TikZ tabanlı ER diyagram çizimleri. |
| `/Kod_Ornekleri` | DDL, DML, JOIN yapıları ve kısıtlamaları (Constraints) içeren SQL scriptleri. |
| `/Lab_Foyleri` | Uygulamalı laboratuvar görevleri ve adım adım çözüm anahtarları. |
| `/Proje` | "E-Ticaret Sipariş ve Stok Yönetim Sistemi" dönem sonu proje yönergesi ve teknik isterler. |

---

## 🛠 Kullanılan Teknolojiler ve Araçlar

* **Veri Tabanı Motorları:** Microsoft SQL Server (T-SQL), MySQL.
* **Yönetim Arayüzleri:** SQL Server Management Studio (SSMS), phpMyAdmin.
* **Dizgi ve Raporlama:** LaTeX (Akademik dokümantasyon ve matematiksel formülasyonlar için).
* **Doğrulama (Validation):** Proje teslimlerinin standartize edilmesi için Docker ortamı.

---

## 🚀 14 Haftalık Yol Haritası

| Hafta | Konu Başlığı | Odak Noktası |
| :--- | :--- | :--- |
| 1-2 | Giriş ve Mimari | ANSI-SPARC üç seviyeli mimari ve veri soyutlama. |
| 3-4 | Veri Modelleri | Varlık-İlişki (ER) modeli ve kavramsal tasarım. |
| 5 | İlişkisel Model | Tablo yapıları, Primary Key ve Foreign Key mantığı. |
| 6 | Kısıtlamalar | Referansal bütünlük ve `CASCADE` mekanizmaları. |
| 7 | SQL Giriş | DDL komutları (`CREATE`, `ALTER`, `DROP`) ve veri tipleri. |
| 8-9 | Normalizasyon | 1NF, 2NF ve 3NF kuralları; anomali önleme. |
| 10-11 | DML ve Sorgular | `SELECT`, `INSERT`, `UPDATE`, `DELETE` ve veri filtreleme. |
| 12 | Join İşlemleri | İlişkisel cebir; Inner, Left ve Cross Join yapıları. |
| 13 | Transaction | ACID prensipleri (Atomicity, Consistency, Isolation, Durability). |
| 14 | Uygulama & Proje | Docker tabanlı sistem doğrulamaları ve proje sunumları. |

---

## 📝 Kurulum ve Çalıştırma

### SQL Scriptlerinin Uygulanması
1. Yerel ortamınızda **SQL Server Express** veya **XAMPP** kurulumunun aktif olduğundan emin olun.
2. `/Kod_Ornekleri` dizinindeki ilgili `.sql` dosyasını SSMS veya SQL arayüzünüzde açın.
3. Scripti `Execute` ederek veri tabanı şemasını ve örnek verileri oluşturun.

### LaTeX Kaynaklarının Derlenmesi
Ders notlarını yeniden derlemek için:
```bash
pdflatex main.tex
# veya XeLaTeX kullanıyorsanız
xelatex main.tex
