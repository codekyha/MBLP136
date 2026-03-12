-- 1. Veritabanı Ortamı
IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'SporSalonuDB')
BEGIN
    CREATE DATABASE SporSalonuDB;
END
GO

USE SporSalonuDB;
GO

-- 2. Çalışanlar Tablosu: Eğitmenler ve personel
CREATE TABLE Calisanlar (
    CalisanID INT IDENTITY(1,1) PRIMARY KEY,
    Ad NVARCHAR(100) NOT NULL,
    Soyad NVARCHAR(100) NOT NULL,
    Gorev NVARCHAR(50), -- Örn: Fitness Eğitmeni, Resepsiyon
    Maas DECIMAL(10, 2) CHECK (Maas > 0),
    IseBaslamaTarihi DATE DEFAULT GETDATE()
);

-- 3. Üyelik Tipleri: Paket yönetimi (Normalizasyon için ayrı tablo)
CREATE TABLE UyelikTipleri (
    TipID INT IDENTITY(1,1) PRIMARY KEY,
    TipAd NVARCHAR(50) NOT NULL, -- Örn: Gold, Silver, Standart
    AylikUcret DECIMAL(10, 2) NOT NULL,
    SureAy INT DEFAULT 1 -- Paketin kaç ay sürdüğü
);

-- 4. Üyeler Tablosu
CREATE TABLE Uyeler (
    UyeID INT IDENTITY(1,1) PRIMARY KEY,
    Ad NVARCHAR(100) NOT NULL,
    Soyad NVARCHAR(100) NOT NULL,
    TCNo NCHAR(11) UNIQUE NOT NULL,
    DogumTarihi DATE,
    TipID INT, -- Foreign Key: Üyelik Tipi
    KayitTarihi DATE DEFAULT GETDATE(),
    Durum BIT DEFAULT 1, -- 1: Aktif, 0: Pasif (Üyeliği dondurmuş)
    CONSTRAINT FK_UyeTip FOREIGN KEY (TipID) REFERENCES UyelikTipleri(TipID)
);

-- 5. Giriş-Çıkış Kayıtları: Hareket Verisi
CREATE TABLE GirisCikisLog (
    LogID BIGINT IDENTITY(1,1) PRIMARY KEY, -- Çok fazla kayıt olacağı için BIGINT
    UyeID INT,
    GirisZamani DATETIME DEFAULT GETDATE(),
    CikisZamani DATETIME, -- Üye çıkarken güncellenecek
    
    -- Fiziksel Kısıtlama: Çıkış zamanı girişten önce olamaz
    CONSTRAINT CHK_Zaman CHECK (CikisZamani > GirisZamani),
    CONSTRAINT FK_LogUye FOREIGN KEY (UyeID) REFERENCES Uyeler(UyeID)
);

-- 6. Çalışan Giriş-Çıkış Kayıtları (Personel Devam Takip Sistemi)
CREATE TABLE CalisanGirisCikisLog (
    -- LogID: Personel trafiği yoğun olabileceği için ölçeklenebilir BIGINT seçilmiştir.
    LogID BIGINT IDENTITY(1,1) PRIMARY KEY,
    
    -- CalisanID: Calisanlar tablosuna referans veren Foreign Key.
    CalisanID INT NOT NULL,
    
    -- GirisZamani: Vardiya başlangıç zaman damgası.
    GirisZamani DATETIME DEFAULT GETDATE(),
    
    -- CikisZamani: Vardiya bitiş zamanı (Çıkış yapılana kadar NULL kalır).
    CikisZamani DATETIME,
    
    -- Nedensellik Kısıtlaması (Causality Constraint):
    -- Çıkış zamanı giriş zamanından önce olamaz.
    -- Formül: $$ T_{bitis} > T_{baslangic} $$
    CONSTRAINT CHK_CalisanZaman CHECK (CikisZamani > GirisZamani),
    
    -- Referansal Bütünlük: Silinmiş bir personelin log kaydı sistemde kalamaz.
    CONSTRAINT FK_LogCalisan FOREIGN KEY (CalisanID) REFERENCES Calisanlar(CalisanID)
);
GO

USE SporSalonuDB;
GO

CREATE VIEW View_GenelHareketTakibi AS
-- 1. Üyelerin Giriş-Çıkış Verileri
SELECT 
    'Üye' AS KisiTipi,
    U.UyeID AS KayitID,
    U.Ad + ' ' + U.Soyad AS AdSoyad,
    UT.TipAd AS GorevVeyaPaket,
    L.GirisZamani,
    L.CikisZamani,
    -- Süre Hesaplama (Dakika cinsinden)
    DATEDIFF(MINUTE, L.GirisZamani, L.CikisZamani) AS KalinanSureDakika,
    -- Süre Formatlama (Saat:Dakika)
    CAST(DATEDIFF(MINUTE, L.GirisZamani, L.CikisZamani) / 60 AS VARCHAR(5)) + ':' + 
    RIGHT('0' + CAST(DATEDIFF(MINUTE, L.GirisZamani, L.CikisZamani) % 60 AS VARCHAR(2)), 2) AS KalinanSureFormatli
FROM Uyeler U
JOIN UyelikTipleri UT ON U.TipID = UT.TipID
JOIN GirisCikisLog L ON U.UyeID = L.UyeID

UNION ALL

-- 2. Çalışanların Giriş-Çıkış Verileri
SELECT 
    'Çalışan' AS KisiTipi,
    C.CalisanID AS KayitID,
    C.Ad + ' ' + C.Soyad AS AdSoyad,
    C.Gorev AS GorevVeyaPaket,
    CL.GirisZamani,
    CL.CikisZamani,
    -- Süre Hesaplama (Dakika cinsinden)
    DATEDIFF(MINUTE, CL.GirisZamani, CL.CikisZamani) AS KalinanSureDakika,
    -- Süre Formatlama (Saat:Dakika)
    CAST(DATEDIFF(MINUTE, CL.GirisZamani, CL.CikisZamani) / 60 AS VARCHAR(5)) + ':' + 
    RIGHT('0' + CAST(DATEDIFF(MINUTE, CL.GirisZamani, CL.CikisZamani) % 60 AS VARCHAR(2)), 2) AS KalinanSureFormatli
FROM Calisanlar C
JOIN CalisanGirisCikisLog CL ON C.CalisanID = CL.CalisanID;
GO