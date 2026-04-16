-- ==============================================================================
-- MBLP136 Veri Tabanı Dönem Sonu Projesi - Örnek Referans Çözüm
-- Senaryo: E-Ticaret Sipariş ve Stok Yönetimi
-- Özgün Eklemeler: KargoFirmalari tablosu ve MusteriTipi alanı
-- ==============================================================================

-- ==============================================================================
-- 0. VERİ TABANI KONTROLÜ VE OLUŞTURMA (Database Check & Create)
-- Yeni bir veri tabanı oluşturabilmek için öncelikle sistemin ana veri tabanı 
-- olan 'master' dizinine geçiş yapmalıyız.
-- ==============================================================================
USE master;
GO

-- 'project' adında bir veritabanı yoksa yeni oluşturur.
-- Bu blok, kodun her çalıştırıldığında hata vermesini önleyen bir güvenlik kontrolüdür.
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = N'project')
BEGIN
    PRINT 'Veri tabanı bulunamadı. "project" adında yeni bir veri tabanı oluşturuluyor...';
    CREATE DATABASE [project];
END
ELSE
BEGIN
    PRINT '"project" veri tabanı zaten mevcut. İşlemlere bu veri tabanında devam ediliyor...';
END
GO

-- Veri tabanı oluştuktan sonra, tabloların bu db içine yazılması için 'USE' ile içine giriyoruz.
USE [project];
GO

-- ==============================================================================
-- 1. DDL: TABLO OLUŞTURMA VE KISITLAMALAR (Data Definition Language)
-- Bu bölümde tablolar oluşturulurken Veri Bütünlüğünü (Data Integrity) korumak 
-- amacıyla PK, FK, UNIQUE, CHECK ve DEFAULT kısıtlayıcıları kullanılmıştır.
-- ==============================================================================

CREATE TABLE Kategoriler (
    -- IDENTITY(1,1): ID değerinin 1'den başlayarak otomatik olarak 1'er artmasını sağlar.
    KategoriID INT PRIMARY KEY IDENTITY(1,1), 
    -- UNIQUE: Aynı kategori adından birden fazla eklenmesini engeller.
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
    -- DEFAULT: Değer girilmezse otomatik 'Standart' atar.
    -- CHECK: Sadece belirtilen 3 tipte müşteri kaydına izin vererek veri standardını korur.
    MusteriTipi VARCHAR(20) DEFAULT 'Standart' CHECK (MusteriTipi IN ('Standart', 'VIP', 'Kurumsal')) 
);

CREATE TABLE Urunler (
    UrunID INT PRIMARY KEY IDENTITY(1,1),
    KategoriID INT,
    UrunAdi VARCHAR(100) NOT NULL,
    -- DECIMAL(10,2): Toplam 10 basamaklı, virgülden sonra 2 basamağı olan küsuratlı sayı.
    -- CHECK (GuncelFiyat > 0): Ücretsiz veya eksi fiyatlı ürün girilmesini mantıksal olarak engeller.
    GuncelFiyat DECIMAL(10,2) NOT NULL CHECK (GuncelFiyat > 0),
    StokMiktari INT DEFAULT 0 CHECK (StokMiktari >= 0),
    -- FOREIGN KEY: Bu tablodaki KategoriID'nin, Kategoriler tablosundaki ID ile eşleşmesini zorunlu kılar.
    FOREIGN KEY (KategoriID) REFERENCES Kategoriler(KategoriID)
);

CREATE TABLE Siparisler (
    SiparisID INT PRIMARY KEY IDENTITY(1,1),
    MusteriID INT,
    KargoID INT,
    -- GETDATE(): Siparişin eklendiği anki sistem tarih ve saatini otomatik olarak kaydeder.
    SiparisTarihi DATETIME DEFAULT GETDATE(),
    ToplamTutar DECIMAL(12,2) DEFAULT 0.00,
    FOREIGN KEY (MusteriID) REFERENCES Musteriler(MusteriID),
    FOREIGN KEY (KargoID) REFERENCES KargoFirmalari(KargoID)
);

-- Bu tablo, "Siparişler" ve "Ürünler" arasındaki Çoka-Çok (N:M) ilişkiyi çözen Kesişim Tablosudur.
CREATE TABLE Siparis_Detay (
    DetayID INT PRIMARY KEY IDENTITY(1,1),
    SiparisID INT,
    UrunID INT,
    Adet INT NOT NULL CHECK (Adet > 0),
    -- ALTIN SORU ÇÖZÜMÜ: Ürünün o anki fiyatı buraya kopyalanır. 
    -- Urunler tablosunda zam yapılsa bile eski siparişin fiyatı buradan okunacağı için fatura tutarı bozulmaz.
    BirimFiyat DECIMAL(10,2) NOT NULL CHECK (BirimFiyat > 0), 
    -- ON DELETE CASCADE: Eğer bir sipariş iptal edilip Siparisler tablosundan silinirse, 
    -- o siparişe ait olan bu detay satırları da otomatik olarak silinir (Yetim kayıt kalmaz).
    FOREIGN KEY (SiparisID) REFERENCES Siparisler(SiparisID) ON DELETE CASCADE,
    FOREIGN KEY (UrunID) REFERENCES Urunler(UrunID)
);

-- ==============================================================================
-- 2. DML: VERİ EKLEME (Data Manipulation Language)
-- Referans Bütünlüğü (Referential Integrity) gereği; önce bağımsız (Parent) 
-- tablolara, daha sonra Yabancı Anahtar (FK) içeren bağımlı (Child) tablolara veri eklenir.
-- ==============================================================================

-- 2.1. Önce Bağımsız Tablolar Dolduruluyor
INSERT INTO Kategoriler (KategoriAdi, Aciklama) VALUES 
('Elektronik', 'Telefon, Bilgisayar ve Aksesuarlar'),
('Ofis Kırtasiye', 'Defter, Kalem, Dosya');

INSERT INTO KargoFirmalari (FirmaAdi, IletisimHatti) VALUES 
('Yurtiçi Kargo', '444 99 99'),
('MNG Kargo', '0850 222 06 06');

INSERT INTO Musteriler (AdSoyad, Email, Telefon, MusteriTipi) VALUES 
('Ahmet Yılmaz', 'ahmet.y@email.com', '5551112233', 'Standart'),
('Ayşe Kaya', 'ayse.k@email.com', '5329998877', 'VIP');

-- 2.2. Sonra Bağımlı Tablolar Dolduruluyor (KategoriID referans alınarak)
INSERT INTO Urunler (KategoriID, UrunAdi, GuncelFiyat, StokMiktari) VALUES 
(1, 'Kablosuz Mouse', 450.00, 50),
(1, 'Mekanik Klavye', 1250.00, 5), -- Kritik Stok örneği için düşük tutuldu
(2, 'A4 Fotokopi Kağıdı', 120.00, 200);

-- ==============================================================================
-- 3. ACID FARKINDALIĞI: TRANSACTION İLE SİPARİŞ OLUŞTURMA
-- Atomicity (Atomiklik) ilkesi gereği; sipariş başlığı ekleme, detay ekleme ve 
-- stok düşme işlemleri tek bir paket (Transaction) haline getirilir. 
-- İşlemlerden biri hata verirse hiçbiri veri tabanına yazılmaz (Rollback).
-- ==============================================================================

BEGIN TRANSACTION;
    -- 1. Aşama: Sipariş başlığı oluşturuluyor
    INSERT INTO Siparisler (MusteriID, KargoID, SiparisTarihi, ToplamTutar) 
    VALUES (2, 1, '2023-10-25', 1700.00);
    
    -- 2. Aşama: Sipariş içerikleri ekleniyor. 
    -- Dikkat: Fiyatlar Urunler tablosundan o anki değeriyle alınıp statik olarak yazılıyor.
    INSERT INTO Siparis_Detay (SiparisID, UrunID, Adet, BirimFiyat) VALUES (1, 1, 1, 450.00);
    INSERT INTO Siparis_Detay (SiparisID, UrunID, Adet, BirimFiyat) VALUES (1, 2, 1, 1250.00);
    
    -- 3. Aşama: Satılan ürünlerin stokları güncelleniyor.
    UPDATE Urunler SET StokMiktari = StokMiktari - 1 WHERE UrunID IN (1, 2);
    
-- Tüm aşamalar hatasız geçerse veriler kalıcı olarak DB'ye yazılır.
COMMIT;

-- ==============================================================================
-- 4. DQL: İLERİ DÜZEY SORGULAR (Data Query Language - Raporlama)
-- Bu bölümde JOIN işlemleri ve Aggregation (Kümeleme) fonksiyonları kullanılmıştır.
-- ==============================================================================

-- Sorgu 1: Hangi müşteri bugüne kadar toplam kaç TL'lik alışveriş yapmıştır? 
-- Neden LEFT JOIN? Eğer bir müşteri sisteme kayıtlı olup henüz hiç sipariş vermediyse 
-- INNER JOIN onu listeden çıkarır. LEFT JOIN ise 0 siparişle dahi müşteriyi gösterir.
SELECT 
    m.AdSoyad, 
    m.MusteriTipi,
    COUNT(s.SiparisID) AS ToplamSiparisSayisi, -- Sipariş adedini sayar
    SUM(s.ToplamTutar) AS ToplamHarcama        -- Sipariş tutarlarını toplar
FROM Musteriler m
LEFT JOIN Siparisler s ON m.MusteriID = s.MusteriID
GROUP BY m.AdSoyad, m.MusteriTipi              -- Ad ve Tipe göre gruplayarak tek satıra indirger
ORDER BY ToplamHarcama DESC;                   -- En çok harcama yapandan (DESC) aza doğru sıralar

-- Sorgu 2: Stok miktarı kritik seviyenin (10) altına düşen ürünler ve kategorileri
-- Sadece eşleşen verileri getirmesi yeterli olduğu için INNER JOIN kullanılmıştır.
SELECT 
    k.KategoriAdi,
    u.UrunAdi, 
    u.StokMiktari
FROM Urunler u
INNER JOIN Kategoriler k ON u.KategoriID = k.KategoriID
WHERE u.StokMiktari < 10;                      -- Sadece stoku 10'dan küçük olanları filtreler

-- Sorgu 3: Özgün Rapor - Kargo firmalarına göre dağıtılan toplam sipariş sayısı
-- İş süreçlerini analiz etmek için sisteme eklenen özgün tablonun (KargoFirmalari) raporudur.
SELECT 
    kf.FirmaAdi, 
    COUNT(s.SiparisID) AS TasinanPaketSayisi
FROM KargoFirmalari kf
INNER JOIN Siparisler s ON kf.KargoID = s.KargoID
GROUP BY kf.FirmaAdi;                          -- Kargo firması bazında gruplama yapar
