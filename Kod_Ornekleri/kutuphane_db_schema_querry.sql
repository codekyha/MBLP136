-- SQL Server Management Studio (SSMS) için veritabanı oluşturma betiği
-- Sistem tablolarını kontrol ederek 'Kutuphane' isimli bir veritabanı olup olmadığına bakar
IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'Kutuphane')
BEGIN
    -- Eğer veritabanı yoksa, fiziksel dosyaları oluşturur ve veritabanını başlatır
    CREATE DATABASE Kutuphane;
END
GO

-- Komutların bu noktadan itibaren 'Kutuphane' veritabanı üzerinde çalışmasını sağlar
USE Kutuphane;
GO

-- Kitap bilgilerinin depolanacağı ana tabloyu oluşturur
CREATE TABLE Kitaplar (
    -- ISBN: Uluslararası Standart Kitap Numarası. 
    -- PRIMARY KEY: Bu sütunu 'Birincil Anahtar' yapar; her kitap için benzersizdir ve boş bırakılamaz.
    -- NVARCHAR(20): 20 karaktere kadar değişken uzunluklu Unicode (her dilden karakter destekleyen) metin saklar.
    ISBN NVARCHAR(20) PRIMARY KEY,
    
    -- Baslik: Kitabın adı. 
    -- NOT NULL: Bu alanın boş geçilmesini engeller; her kitabın mutlaka bir ismi olmalıdır.
    Baslik NVARCHAR(255) NOT NULL,
    
    -- Yazar: Yazar ismi. Boş bırakılabilir (NULL).
    Yazar NVARCHAR(255),
    
    -- SayfaSayisi: Tamsayı (Integer) veri tipi.
    -- CONSTRAINT CHK_SayfaSayisi: Veri tutarlılığını sağlamak için bir 'Kontrol Kısıtlaması' ekler.
    -- CHECK (SayfaSayisi > 0): Matematiksel mantık çerçevesinde sayfa sayısının negatif veya sıfır olmamasını garanti eder.
    -- Formül: $$ \forall x \in \text{SayfaSayisi}, x > 0 $$
    SayfaSayisi INT CONSTRAINT CHK_SayfaSayisi CHECK (SayfaSayisi > 0),
    
    -- YayinTarihi: Kitabın basıldığı tarih bilgisini saklar (Yıl-Ay-Gün).
    YayinTarihi DATE,
    
    -- Fiyat: Ondalıklı sayı tipi. 
    -- DECIMAL(10, 2): Toplamda 10 basamak uzunluğunda, bunun 2 basamağı virgülden sonra olacak şekilde (Örn: 99999999.99) para birimi saklar.
    Fiyat DECIMAL(10, 2),
    
    -- EklenmeTarihi: Kaydın veritabanına girdiği tarih ve saat bilgisi.
    -- DEFAULT GETDATE(): Eğer kullanıcı bir tarih girmezse, sistem o anki tarihi otomatik olarak atar.
    EklenmeTarihi DATETIME DEFAULT GETDATE()
);
GO

-- Mevcut tabloya ilk veri girişini (DML - Data Manipulation Language) gerçekleştirir
-- Sadece ISBN ve Baslik sütunlarına veri gönderilir; diğerleri NULL veya DEFAULT değerlerini alır.
INSERT INTO Kitaplar (ISBN, Baslik) 
VALUES ('978-605', 'Veri Tabani Sistemleri');
GO

-- Kütüphaneye kayıtlı üyelerin kişisel ve iletişim verilerini saklamak için tablo oluşturur.
CREATE TABLE Uyeler (
    -- UyeID: Sistem tarafından otomatik atanan benzersiz kimlik numarası.
    -- IDENTITY(1,1): İlk kayıt 1'den başlar ve her yeni üyede 1 artar (Seed=1, Increment=1).
    -- PRIMARY KEY: Bu alanı 'Birincil Anahtar' yaparak indeksler; hızlı erişim sağlar ve boş bırakılamaz.
    UyeID INT IDENTITY(1,1) PRIMARY KEY,
    
    -- TCKimlikNo: Türkiye Cumhuriyeti Kimlik Numarası.
    -- NCHAR(11): 11 karakterlik sabit uzunluklu alan. Değişken olmadığı için bellek yönetimi daha öngörülebilirdir.
    -- UNIQUE: Aynı TC numarasıyla birden fazla üye kaydı açılmasını veritabanı seviyesinde engeller.
    -- NOT NULL: Bu alanın doldurulması zorunludur.
    TCKimlikNo NCHAR(11) UNIQUE NOT NULL,
    
    -- Ad ve Soyad: Üyenin isim bilgileri.
    -- NVARCHAR(100): 100 karaktere kadar Unicode (Türkçe karakter destekli) metin saklar.
    Ad NVARCHAR(100) NOT NULL,
    Soyad NVARCHAR(100) NOT NULL,
    
    -- Eposta: Üye ile iletişim kurulacak elektronik posta adresi.
    -- UNIQUE: Bir e-posta adresi sadece tek bir üyeye tanımlanabilir.
    Eposta NVARCHAR(255) UNIQUE,
    
    -- Telefon: İletişim numarası. Alan kodu ve format farklılıkları için NVARCHAR tercih edilmiştir.
    Telefon NVARCHAR(20),
    
    -- KayitTarihi: Üyenin sisteme ilk giriş yaptığı tarih.
    -- DATETIME: Tarih ve saat bilgisini birlikte tutar.
    -- DEFAULT GETDATE(): INSERT komutu sırasında tarih belirtilmezse, sunucunun o anki saatini otomatik yazar.
    KayitTarihi DATETIME DEFAULT GETDATE(),
    
    -- UyelikDurumu: Üyenin aktiflik/pasiflik statüsü.
    -- BIT: Bellekte çok az yer kaplayan veri tipi. 1 (Aktif) veya 0 (Pasif) değerlerini alır.
    -- DEFAULT 1: Yeni eklenen her üye varsayılan olarak 'Aktif' kabul edilir.
    UyelikDurumu BIT DEFAULT 1
);
GO

-- Kitaplar ve Uyeler arasındaki many-to-many (çoka-çok) ilişkiyi yöneten tablo
CREATE TABLE OduncIslemleri (
    -- IslemID: Her ödünç alma işlemi için benzersiz işlem numarası.
    IslemID INT IDENTITY(1,1) PRIMARY KEY,
    
    -- ISBN: Kitaplar tablosuna referans veren Yabancı Anahtar (Foreign Key).
    ISBN NVARCHAR(20),
    
    -- UyeID: Uyeler tablosuna referans veren Yabancı Anahtar (Foreign Key).
    UyeID INT,
    
    -- VerilisTarihi: Kitabın teslim edildiği an.
    VerilisTarihi DATETIME DEFAULT GETDATE(),
    
    -- TeslimTarihi: Kitap geri getirildiğinde doldurulacak alan (Başlangıçta NULL).
    TeslimTarihi DATETIME,
    
    -- SonTeslimTarihi: Hesaplanmış sütun (Computed Column). 
    -- Veriliş tarihine otomatik olarak 15 gün ekleyerek iade limitini belirler.
    SonTeslimTarihi AS DATEADD(day, 15, VerilisTarihi), 

    -- İlişkisel kısıtlamalar: Silme veya güncelleme durumunda veri bütünlüğünü korur.
    CONSTRAINT FK_Kitap FOREIGN KEY (ISBN) REFERENCES Kitaplar(ISBN),
    CONSTRAINT FK_Uye FOREIGN KEY (UyeID) REFERENCES Uyeler(UyeID)
);
GO