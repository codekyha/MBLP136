-- 1. Veritabanı Ortamının Hazırlanması
-- Sistem tablolarını kontrol ederek 'FiloTakip' adında bir veritabanı olup olmadığını doğrular.
-- Idempotent (tekrar edilebilir) bir yapı oluşturmak için IF NOT EXISTS kontrolü kritiktir.
IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'FiloTakip')
BEGIN
    CREATE DATABASE FiloTakip; -- Bellekte ve diskte veritabanı alanını rezerve eder.
END
GO

-- Komutların yürütme bağlamını (context) yeni oluşturulan veritabanına taşır.
USE FiloTakip;
GO

-- 2. Araçlar Tablosu: Sistemin Ana Varlığı (Entity)
CREATE TABLE Araclar (
    -- Plaka: Doğal anahtar (Natural Key). Her araç için dünyada benzersizdir.
    Plaka NVARCHAR(15) PRIMARY KEY, 
    
    -- NOT NULL kısıtlaması, zorunlu alanları belirler.
    Marka NVARCHAR(50) NOT NULL,
    Model NVARCHAR(50) NOT NULL,
    
    -- CHECK Kısıtlaması: Mantıksal veri kontrolü. 
    -- Veri girişini $Yil > 1950$ koşuluyla sınırlar, hatalı girişi fiziksel seviyede engeller.
    Yil INT CHECK (Yil > 1950), 
    
    -- SasiNo: İkinci bir tekil anahtardır. UNIQUE kısıtlaması ile mükerrer kayıt önlenir.
    SasiNo NVARCHAR(17) UNIQUE NOT NULL, 
    
    -- Hassas veri (Para birimi) için DECIMAL kullanımı: 10 basamak toplam, 2 basamak ondalık.
    GunlukKira DECIMAL(10, 2) NOT NULL,
    
    -- Durum: BIT tipi (0 veya 1). Boole mantığıyla aracın müsaitlik durumunu tutar.
    -- DEFAULT 1: Kayıt anında araç varsayılan olarak 'Müsait' kabul edilir.
    Durum BIT DEFAULT 1 
);

-- 3. Aksesuarlar Tablosu
CREATE TABLE Aksesuarlar (
    -- IDENTITY(1,1): Otomatik artan sayısal anahtar (Surrogate Key). 
    AksesuarID INT IDENTITY(1,1) PRIMARY KEY,
    AksesuarAdi NVARCHAR(100) NOT NULL
);

-- 4. Araç-Aksesuar Eşleşmesi (Çoka-Çok İlişki Çözümü - Junction Table)
-- Normalizasyon kuralları gereği M:N (Many-to-Many) ilişkiler doğrudan kurulamaz.
-- Bir aracın çok aksesuarı, bir aksesuar tipinin çok aracı olabilir.
CREATE TABLE AracAksesuar (
    Plaka NVARCHAR(15),
    AksesuarID INT,
    
    -- Composite Primary Key: Plaka ve AksesuarID ikilisi birlikte satırı tekilleştirir.
    -- Bu sayede aynı araçta aynı aksesuardan sadece bir adet tanımlanması garanti edilir.
    PRIMARY KEY (Plaka, AksesuarID), 
    
    -- Referansal Bütünlük (Foreign Keys):
    -- Bu sütunlardaki veriler mutlaka ana tablolarda mevcut olmak zorundadır.
    CONSTRAINT FK_AracAksesuar_Plaka FOREIGN KEY (Plaka) REFERENCES Araclar(Plaka),
    CONSTRAINT FK_AracAksesuar_Aksesuar FOREIGN KEY (AksesuarID) REFERENCES Aksesuarlar(AksesuarID)
);

-- 5. Müşteriler Tablosu
CREATE TABLE Musteriler (
    MusteriID INT IDENTITY(1,1) PRIMARY KEY,
    Ad NVARCHAR(100) NOT NULL,
    Soyad NVARCHAR(100) NOT NULL,
    
    -- EhliyetNo: Yasal zorunluluk gereği her müşteri için benzersizdir.
    EhliyetNo NVARCHAR(20) UNIQUE NOT NULL, 
    Telefon NVARCHAR(20)
);

-- 6. Kiralama İşlemleri (İşlemsel / Hareket Tablosu)
-- Bu tablo sistemin "Zaman Serisi" verisini ve ilişkisel köprülerini barındırır.
CREATE TABLE Kiralamalar (
    KiralamaID INT IDENTITY(1,1) PRIMARY KEY,
    Plaka NVARCHAR(15), -- Hangi araç?
    MusteriID INT,      -- Kim kiraladı?
    
    -- GETDATE(): Sunucu sistem saatini baz alarak otomatik tarih ataması yapar.
    AlisTarihi DATETIME DEFAULT GETDATE(),
    
    -- IadeTarihi: Araç henüz dönmediyse NULL kalabilir. 
    -- Bu alanın NULL olması "Aktif Kiralama" anlamına gelir.
    IadeTarihi DATETIME, 
    
    -- Foreign Key kısıtlamaları: Silme veya güncelleme durumunda veri bütünlüğünü korur.
    CONSTRAINT FK_Kiralama_Arac FOREIGN KEY (Plaka) REFERENCES Araclar(Plaka),
    CONSTRAINT FK_Kiralama_Musteri FOREIGN KEY (MusteriID) REFERENCES Musteriler(MusteriID)
);