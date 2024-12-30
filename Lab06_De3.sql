CREATE DATABASE DE3 
-- 1. 
CREATE TABLE DOCGIA (
    MaDG CHAR(5) PRIMARY KEY,
    HoTen VARCHAR(30),
    NgaySinh SMALLDATETIME,
    DiaChi VARCHAR(30),
    SoDT VARCHAR(15)
);

CREATE TABLE SACH (
    MaSach CHAR(5) PRIMARY KEY,
    TenSach VARCHAR(25),
    TheLoai VARCHAR(25),
    NhaXuatBan VARCHAR(30)
);

CREATE TABLE PHIEUTHUE (
    MaPT CHAR(5) PRIMARY KEY,
    MaDG CHAR(5),
    NgayThue SMALLDATETIME,
    NgayTra SMALLDATETIME,
    SoSachThue INT,
    FOREIGN KEY (MaDG) REFERENCES DOCGIA(MaDG)
);

CREATE TABLE CHITIET_PT (
    MaPT CHAR(5),
    MaSach CHAR(5),
    PRIMARY KEY (MaPT, MaSach),
    FOREIGN KEY (MaPT) REFERENCES PHIEUTHUE(MaPT),
    FOREIGN KEY (MaSach) REFERENCES SACH(MaSach)
);

-- 2. 
-- 2.1. 
GO
CREATE TRIGGER TR_KiemTraThoiGianThue
ON PHIEUTHUE
AFTER INSERT, UPDATE
AS
BEGIN
    IF EXISTS (
        SELECT 1
        FROM INSERTED
        WHERE DATEDIFF(DAY, NgayThue, NgayTra) > 10
    )
    BEGIN
        ROLLBACK;
        THROW 50001, 'Thoi gian thue sach khong duoc vuot qua 10 ngay.', 1;
    END
END;
GO
-- 2.2.
GO
CREATE TRIGGER TR_KiemTraSoSachThue
ON PHIEUTHUE
AFTER INSERT, UPDATE
AS
BEGIN
    IF EXISTS (
        SELECT 1
        FROM PHIEUTHUE PT
        JOIN (
            SELECT MaPT, COUNT(*) AS TongSoSach
            FROM CHITIET_PT
            GROUP BY MaPT
        ) AS CT ON PT.MaPT = CT.MaPT
        WHERE PT.SoSachThue <> CT.TongSoSach
    )
    BEGIN
        ROLLBACK;
        THROW 50002, 'So sach thue khong khop voi tong so sach trong chi tiet phieu thue.', 1;
    END
END;
GO
-- 3. 
-- 3.1.
SELECT DISTINCT DG.MaDG, DG.HoTen
FROM DOCGIA DG
JOIN PHIEUTHUE PT ON DG.MaDG = PT.MaDG
JOIN CHITIET_PT CT ON PT.MaPT = CT.MaPT
JOIN SACH S ON CT.MaSach = S.MaSach
WHERE S.TheLoai = 'Tin hoc' AND YEAR(PT.NgayThue) = 2007;

-- 3.2.
WITH TheLoai_Thue AS (
    SELECT DG.MaDG, DG.HoTen, S.TheLoai, COUNT(DISTINCT S.TheLoai) AS SoTheLoai
    FROM DOCGIA DG
    JOIN PHIEUTHUE PT ON DG.MaDG = PT.MaDG
    JOIN CHITIET_PT CT ON PT.MaPT = CT.MaPT
    JOIN SACH S ON CT.MaSach = S.MaSach
    GROUP BY DG.MaDG, DG.HoTen, S.TheLoai
),
MaxTheLoai AS (
    SELECT MaDG, MAX(SoTheLoai) AS MaxSoTheLoai
    FROM TheLoai_Thue
    GROUP BY MaDG
)
SELECT TL.MaDG, TL.HoTen
FROM TheLoai_Thue TL
JOIN MaxTheLoai MT ON TL.MaDG = MT.MaDG AND TL.SoTheLoai = MT.MaxSoTheLoai;

-- 3.3.
WITH Sach_Thue AS (
    SELECT S.TheLoai, S.TenSach, COUNT(*) AS SoLanThue
    FROM SACH S
    JOIN CHITIET_PT CT ON S.MaSach = CT.MaSach
    GROUP BY S.TheLoai, S.TenSach
),
MaxThue_TheLoai AS (
    SELECT TheLoai, MAX(SoLanThue) AS MaxThue
    FROM Sach_Thue
    GROUP BY TheLoai
)
SELECT ST.TheLoai, ST.TenSach
FROM Sach_Thue ST
JOIN MaxThue_TheLoai MT ON ST.TheLoai = MT.TheLoai AND ST.SoLanThue = MT.MaxThue;
