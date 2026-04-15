-- ==============================================================================
-- MBLP136 Veri Tabanı Dönem Sonu Projesi - Örnek Referans Çözüm
-- Senaryo: E-Ticaret Sipariş ve Stok Yönetimi
-- Özgün Eklemeler: KargoFirmalari tablosu ve MusteriTipi alanı
-- ==============================================================================

-- 1. DDL: TABLO OLUŞTURMA VE KISITLAMALAR (Constraints)
CREATE TABLE Kategoriler (
    KategoriID INT PRIMARY KEY IDENTITY(1,1), -- MySQL için AUTO_INCREMENT
    KategoriAdi VARCHAR(50) NOT NULL UNIQUE,
    Aciklama VARCHAR(255)
);

CREATE TABLE KargoFirmalari ( -- ÖZGÜN TABLO EKLENTİSİ
    KargoID INT PRIMARY KEY IDENTITY(1,1),
    FirmaAdi VARCHAR(50) NOT NULL,
    IletisimHatti VARCHAR(20)
);

CREATE TABLE Musteriler (
    MusteriID INT PRIMARY KEY IDENTITY(1,1),
    AdSoyad VARCHAR(100) NOT NULL,
    Email VARCHAR(100) UNIQUE NOT NULL,
    Telefon VARCHAR(15),
    MusteriTipi VARCHAR(20) DEFAULT 'Standart' CHECK (MusteriTipi IN ('Standart', 'VIP', 'Kurumsal')) -- ÖZGÜN ALAN EKLENTİSİ
);

CREATE TABLE Urunler (
    UrunID INT PRIMARY KEY IDENTITY(1,1),
    KategoriID INT,
    UrunAdi VARCHAR(100) NOT NULL,
    GuncelFiyat DECIMAL(10,2) NOT NULL CHECK (GuncelFiyat > 0),
    StokMiktari INT DEFAULT 0 CHECK (StokMiktari >= 0),
    FOREIGN KEY (KategoriID) REFERENCES Kategoriler(KategoriID)
);

CREATE TABLE Siparisler (
    SiparisID INT PRIMARY KEY IDENTITY(1,1),
    MusteriID INT,
    KargoID INT, -- ÖZGÜN YAPI ENTEGRASYONU
    SiparisTarihi DATETIME DEFAULT GETDATE(),
    ToplamTutar DECIMAL(12,2) DEFAULT 0.00,
    FOREIGN KEY (MusteriID) REFERENCES Musteriler(MusteriID),
    FOREIGN KEY (KargoID) REFERENCES KargoFirmalari(KargoID)
);

CREATE TABLE Siparis_Detay (
    DetayID INT PRIMARY KEY IDENTITY(1,1),
    SiparisID INT,
    UrunID INT,
    Adet INT NOT NULL CHECK (Adet > 0),
    BirimFiyat DECIMAL(10,2) NOT NULL CHECK (BirimFiyat > 0), -- ALTIN SORU: Fiyat geçmişi koruması
    FOREIGN KEY (SiparisID) REFERENCES Siparisler(SiparisID) ON DELETE CASCADE,
    FOREIGN KEY (UrunID) REFERENCES Urunler(UrunID)
);

-- ==============================================================================
-- 2. DML: VERİ EKLEME (Gerçekçi ve Tutarlı Veri Seti)
INSERT INTO Kategoriler (KategoriAdi, Aciklama) VALUES 
('Elektronik', 'Telefon, Bilgisayar ve Aksesuarlar'),
('Ofis Kırtasiye', 'Defter, Kalem, Dosya');

INSERT INTO KargoFirmalari (FirmaAdi, IletisimHatti) VALUES 
('Yurtiçi Kargo', '444 99 99'),
('MNG Kargo', '0850 222 06 06');

INSERT INTO Musteriler (AdSoyad, Email, Telefon, MusteriTipi) VALUES 
('Ahmet Yılmaz', 'ahmet.y@email.com', '5551112233', 'Standart'),
('Ayşe Kaya', 'ayse.k@email.com', '5329998877', 'VIP');

INSERT INTO Urunler (KategoriID, UrunAdi, GuncelFiyat, StokMiktari) VALUES 
(1, 'Kablosuz Mouse', 450.00, 50),
(1, 'Mekanik Klavye', 1250.00, 5), -- Kritik Stok
(2, 'A4 Fotokopi Kağıdı', 120.00, 200);

-- ==============================================================================
-- 3. ACID FARKINDALIĞI: TRANSACTION İLE SİPARİŞ OLUŞTURMA
BEGIN TRANSACTION;
    -- Sipariş başlığı oluşturuluyor
    INSERT INTO Siparisler (MusteriID, KargoID, SiparisTarihi, ToplamTutar) 
    VALUES (2, 1, '2023-10-25', 1700.00);
    
    -- Sipariş detayları ekleniyor (Ürün fiyatı o anki fiyattan sabitleniyor)
    INSERT INTO Siparis_Detay (SiparisID, UrunID, Adet, BirimFiyat) VALUES (1, 1, 1, 450.00);
    INSERT INTO Siparis_Detay (SiparisID, UrunID, Adet, BirimFiyat) VALUES (1, 2, 1, 1250.00);
    
    -- Stok düşümü yapılıyor
    UPDATE Urunler SET StokMiktari = StokMiktari - 1 WHERE UrunID IN (1, 2);
COMMIT;

-- ==============================================================================
-- 4. DQL: İLERİ DÜZEY SORGULAR (Raporlama)

-- Sorgu 1: Hangi müşteri bugüne kadar toplam kaç TL'lik alışveriş yapmıştır? (JOIN, GROUP BY, ORDER BY)
SELECT 
    m.AdSoyad, 
    m.MusteriTipi,
    COUNT(s.SiparisID) AS ToplamSiparisSayisi,
    SUM(s.ToplamTutar) AS ToplamHarcama
FROM Musteriler m
LEFT JOIN Siparisler s ON m.MusteriID = s.MusteriID
GROUP BY m.AdSoyad, m.MusteriTipi
ORDER BY ToplamHarcama DESC;

-- Sorgu 2: Stok miktarı kritik seviyenin (10) altına düşen ürünler ve kategorileri
SELECT 
    k.KategoriAdi,
    u.UrunAdi, 
    u.StokMiktari
FROM Urunler u
INNER JOIN Kategoriler k ON u.KategoriID = k.KategoriID
WHERE u.StokMiktari < 10;

-- Sorgu 3: Özgün Rapor - Kargo firmalarına göre dağıtılan toplam sipariş sayısı
SELECT 
    kf.FirmaAdi, 
    COUNT(s.SiparisID) AS TasinanPaketSayisi
FROM KargoFirmalari kf
INNER JOIN Siparisler s ON kf.KargoID = s.KargoID
GROUP BY kf.FirmaAdi;