-- ============================================================
--         🌍 EGYPT TOURISM - DATABASE SCHEMA
-- ============================================================
-- SECTION 1: CORE TABLES
-- ============================================================

-- جدول المستخدمين (سائح / مرشد / أدمن)
CREATE TABLE Users (
    Id          INT PRIMARY KEY IDENTITY(1,1),
    FullName    NVARCHAR(100)   NOT NULL,
    Email       NVARCHAR(150)   NOT NULL UNIQUE,
    PasswordHash NVARCHAR(255)  NOT NULL,
    Phone       NVARCHAR(20),
    Role        NVARCHAR(20)    NOT NULL CHECK (Role IN ('Tourist', 'Guide', 'Admin')),
    CreatedAt   DATETIME        DEFAULT GETDATE(),
    IsActive    BIT             DEFAULT 1
);

-- جدول الأماكن السياحية
CREATE TABLE Destinations (
    Id          INT PRIMARY KEY IDENTITY(1,1),
    Name        NVARCHAR(100)   NOT NULL,
    Region      NVARCHAR(100)   NOT NULL,   -- القاهرة / الأقصر / أسوان / شرم / الإسكندرية
    Description NVARCHAR(MAX),
    ImageUrl    NVARCHAR(500),
    IsActive    BIT             DEFAULT 1
);

-- ============================================================
-- 🧭 SECTION 2: GUIDE TABLES
-- ============================================================

-- جدول المرشدين (مرتبط بـ Users)
CREATE TABLE Guides (
    Id              INT PRIMARY KEY IDENTITY(1,1),
    UserId          INT             NOT NULL UNIQUE,    -- FK → Users
    LicenseNumber   NVARCHAR(50)    NOT NULL UNIQUE,    -- رقم الترخيص الرسمي
    NationalId      NVARCHAR(50)    NOT NULL,
    ProfileImageUrl NVARCHAR(500),
    IdImageUrl      NVARCHAR(500),
    Bio             NVARCHAR(MAX),
    Status          NVARCHAR(20)    DEFAULT 'Pending'   -- Pending / Approved / Rejected
                    CHECK (Status IN ('Pending', 'Approved', 'Rejected')),
    RejectionReason NVARCHAR(500),                      -- سبب الرفض من الأدمن
    ApprovedAt      DATETIME,
    CreatedAt       DATETIME        DEFAULT GETDATE(),

    CONSTRAINT FK_Guides_Users FOREIGN KEY (UserId) REFERENCES Users(Id)
);

-- جدول لغات المرشد (علاقة Many-to-Many)
CREATE TABLE GuideLanguages (
    Id          INT PRIMARY KEY IDENTITY(1,1),
    GuideId     INT             NOT NULL,
    Language    NVARCHAR(50)    NOT NULL,   -- English / French / Spanish / Arabic ...

    CONSTRAINT FK_GuideLanguages_Guides FOREIGN KEY (GuideId) REFERENCES Guides(Id)
);

-- جدول مناطق عمل المرشد
CREATE TABLE GuideRegions (
    Id          INT PRIMARY KEY IDENTITY(1,1),
    GuideId     INT             NOT NULL,
    DestinationId INT           NOT NULL,   -- FK → Destinations

    CONSTRAINT FK_GuideRegions_Guides       FOREIGN KEY (GuideId)       REFERENCES Guides(Id),
    CONSTRAINT FK_GuideRegions_Destinations FOREIGN KEY (DestinationId) REFERENCES Destinations(Id)
);


-- ============================================================
-- 🎫 SECTION 3: TRIP BOOKING (حجز الرحلة)
-- ============================================================

CREATE TABLE TripBookings (
    Id              INT PRIMARY KEY IDENTITY(1,1),
    TouristId       INT             NOT NULL,    -- FK → Users (Role = Tourist)
    DestinationId   INT             NOT NULL,    -- FK → Destinations
    TripType        NVARCHAR(50)    NOT NULL CHECK (TripType IN ('Historical', 'Entertainment', 'Religious', 'Nature')),
    StartDate       DATE            NOT NULL,
    EndDate         DATE            NOT NULL,
    NumOfPeople     INT             NOT NULL,
    Notes           NVARCHAR(MAX),
    Status          NVARCHAR(20)    DEFAULT 'Pending'
                    CHECK (Status IN ('Pending', 'Confirmed', 'Cancelled', 'Completed')),
    CreatedAt       DATETIME        DEFAULT GETDATE(),

    CONSTRAINT FK_TripBookings_Tourist      FOREIGN KEY (TouristId)     REFERENCES Users(Id),
    CONSTRAINT FK_TripBookings_Destination  FOREIGN KEY (DestinationId) REFERENCES Destinations(Id)
);


-- ============================================================
-- 🧭 SECTION 4: GUIDE BOOKING — ⭐ القلب بتاع البروجيكت
--
--    الجداول اللي بتخدم حجز المرشد مباشرةً:
--    ✅ Users          → عشان نعرف السائح
--    ✅ Guides         → عشان نعرف المرشد وحالته (Approved)
--    ✅ Destinations   → عشان نعرف الوجهة
--    ✅ GuideLanguages → عشان السائح يفلتر بالغة
--    ✅ GuideRegions   → عشان السائح يفلتر بالمنطقة
-- ============================================================

CREATE TABLE GuideBookings (
    Id              INT PRIMARY KEY IDENTITY(1,1),
    TouristId       INT             NOT NULL,    -- FK → Users (Role = Tourist)
    GuideId         INT             NOT NULL,    -- FK → Guides
    DestinationId   INT             NOT NULL,    -- FK → Destinations
    BookingDate     DATE            NOT NULL,    -- يوم بداية الرحلة
    DurationDays    INT             NOT NULL,    -- عدد الأيام
    NumOfPeople     INT             NOT NULL,
    Notes           NVARCHAR(MAX),
    Status          NVARCHAR(20)    DEFAULT 'Pending'
                    CHECK (Status IN ('Pending', 'Confirmed', 'Rejected', 'Completed', 'Cancelled')),
    GuideResponse   NVARCHAR(500),              -- رد المرشد لو رفض
    CreatedAt       DATETIME        DEFAULT GETDATE(),
    UpdatedAt       DATETIME,

    CONSTRAINT FK_GuideBookings_Tourist     FOREIGN KEY (TouristId)     REFERENCES Users(Id),
    CONSTRAINT FK_GuideBookings_Guide       FOREIGN KEY (GuideId)       REFERENCES Guides(Id),
    CONSTRAINT FK_GuideBookings_Destination FOREIGN KEY (DestinationId) REFERENCES Destinations(Id)
);


-- ============================================================
-- ⭐ SECTION 5: REVIEWS (التقييمات)
--    متاحة بس بعد اكتمال الرحلة (Status = Completed)
-- ============================================================

CREATE TABLE Reviews (
    Id              INT PRIMARY KEY IDENTITY(1,1),
    TouristId       INT             NOT NULL,
    GuideId         INT             NOT NULL,
    GuideBookingId  INT             NOT NULL UNIQUE,   -- حجز واحد = تقييم واحد
    Rating          TINYINT         NOT NULL CHECK (Rating BETWEEN 1 AND 5),
    Comment         NVARCHAR(MAX),
    CreatedAt       DATETIME        DEFAULT GETDATE(),

    CONSTRAINT FK_Reviews_Tourist       FOREIGN KEY (TouristId)      REFERENCES Users(Id),
    CONSTRAINT FK_Reviews_Guide         FOREIGN KEY (GuideId)         REFERENCES Guides(Id),
    CONSTRAINT FK_Reviews_GuideBooking  FOREIGN KEY (GuideBookingId)  REFERENCES GuideBookings(Id)
);


-- ============================================================
-- 📊 SECTION 6: INDEXES (لتسريع الاستعلامات)
-- ============================================================

CREATE INDEX IX_Guides_Status           ON Guides(Status);
CREATE INDEX IX_GuideBookings_TouristId ON GuideBookings(TouristId);
CREATE INDEX IX_GuideBookings_GuideId   ON GuideBookings(GuideId);
CREATE INDEX IX_GuideBookings_Status    ON GuideBookings(Status);
CREATE INDEX IX_TripBookings_TouristId  ON TripBookings(TouristId);
CREATE INDEX IX_Reviews_GuideId         ON Reviews(GuideId);


-- ============================================================
-- 🌱 SECTION 7: SEED DATA (بيانات أولية للتجربة)
-- ============================================================

-- Admin user
INSERT INTO Users (FullName, Email, PasswordHash, Phone, Role)
VALUES ('Admin Egypt Tourism', 'admin@egypttourism.com', 'HASHED_PASSWORD', '01000000000', 'Admin');

-- Destinations
INSERT INTO Destinations (Name, Region, Description) VALUES
('الأهرامات',        'القاهرة',      'أعظم عجائب الدنيا السبع'),
('معبد الكرنك',      'الأقصر',       'أضخم معبد في العالم القديم'),
('أبو سمبل',         'أسوان',        'معبد رمسيس الثاني الشهير'),
('شرم الشيخ',        'سيناء',        'المدينة الساحلية الجميلة'),
('الإسكندرية',       'الإسكندرية',   'عروس البحر المتوسط');
