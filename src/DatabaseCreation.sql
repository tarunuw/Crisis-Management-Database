-- Arnav Mohan, Tarun Tamilselvan
-- Create Database
CREATE DATABASE CrisisManagement;
GO
USE CrisisManagement;
GO


DROP TABLE IF EXISTS TemporalData;
DROP TABLE IF EXISTS ResponseActivities;
DROP TABLE IF EXISTS AffectedArea;
DROP TABLE IF EXISTS ResourceAllocations;
DROP TABLE IF EXISTS HumanitarianOrganizations;
DROP TABLE IF EXISTS AffectedRegions;
DROP TABLE IF EXISTS CrisisEvents;

-- 1) Create Tables (Without Foreign Keys First)

-- CrisisEvents Table - Arnav
CREATE TABLE CrisisEvents (
    CrisisID INT IDENTITY(1,1),
    CrisisName VARCHAR(255) NOT NULL,
    Nature VARCHAR(100) NOT NULL,
    Severity INT NOT NULL CHECK (Severity BETWEEN 1 AND 10), 
    StartDate DATE NOT NULL,
    EndDate DATE NULL CHECK (EndDate >= StartDate), -- CHECK Constraint: EndDate must be after StartDate
    CONSTRAINT pk_crisis PRIMARY KEY (CrisisID)
);
GO

-- AffectedRegions Table - Arnav
CREATE TABLE AffectedRegions (
    RegionID INT IDENTITY(1,1),
    RegionName VARCHAR(255) NOT NULL,
    Country VARCHAR(100) NOT NULL,
    PopulationAffected INT NOT NULL CHECK (PopulationAffected >= 0),
    CONSTRAINT pk_region PRIMARY KEY (RegionID)
);
GO

-- HumanitarianOrganizations Table - Arnav
CREATE TABLE HumanitarianOrganizations (
    OrgID INT IDENTITY(1,1),
    OrgName VARCHAR(255) NOT NULL,
    Type VARCHAR(100) NOT NULL,
    ContactInfo VARCHAR(255) NOT NULL,
    AreasOfOperation TEXT NULL,
    CONSTRAINT pk_org PRIMARY KEY (OrgID)
);
GO

-- ResourceAllocations Table - Tarun
CREATE TABLE ResourceAllocations (
    AllocationID INT IDENTITY(1,1),
    CrisisID INT NOT NULL,
    OrgID INT NOT NULL,
    FundAmount DECIMAL(18,2) NOT NULL CHECK (FundAmount >= 0),
    SupplyDetails TEXT NULL,
    AllocationDate DATE NOT NULL DEFAULT GETDATE(),
    CONSTRAINT pk_allocation PRIMARY KEY (AllocationID) 
);
GO

-- AffectedArea Table - Tarun
CREATE TABLE AffectedArea (
    AffectedAreaID INT IDENTITY(1,1),
    RegionID INT NOT NULL,
    CrisisID INT NOT NULL,
    TotalAffected INT NOT NULL CHECK (TotalAffected >= 0),
    VulnerableGroups TEXT NULL,
    NeedsAssessment TEXT NULL,
    ImpactLevel AS (TotalAffected / 1000) , -- Impact based on affected population
    CONSTRAINT pk_affected_area PRIMARY KEY (AffectedAreaID)
);
GO

-- ResponseActivities Table - Arnav
CREATE TABLE ResponseActivities (
    ResponseID INT IDENTITY(1,1),
    CrisisID INT NOT NULL,
    OrgID INT NOT NULL,
    ActivityDescription TEXT NOT NULL,
    ImplementationDate DATE NOT NULL,
    ResponseUrgency AS (
        CASE 
            WHEN DATEDIFF(DAY, (SELECT StartDate FROM CrisisEvents WHERE CrisisID = ResponseActivities.CrisisID), GETDATE()) <= 7 THEN 'High'
            WHEN DATEDIFF(DAY, (SELECT StartDate FROM CrisisEvents WHERE CrisisID = ResponseActivities.CrisisID), GETDATE()) BETWEEN 8 AND 30 THEN 'Medium'
            ELSE 'Low'
        END
    ) , -- Assigns urgency based on crisis date
    CONSTRAINT pk_response PRIMARY KEY (ResponseID) 
);
GO

-- TemporalData Table - Tarun
CREATE TABLE TemporalData (
    TemporalID INT IDENTITY(1,1),
    CrisisID INT NOT NULL,
    DateRecorded DATE NOT NULL DEFAULT GETDATE(), -- Uses today's date if not provided
    StatusUpdate TEXT NOT NULL,
    RecoveryProgress TEXT NULL,
    CONSTRAINT pk_temporal PRIMARY KEY (TemporalID) 
);
GO

-- 2) Add Referential Integrity (Foreign Keys)

-- ResourceAllocations Table
ALTER TABLE ResourceAllocations 
ADD CONSTRAINT fk_resource_crisis FOREIGN KEY (CrisisID) REFERENCES CrisisEvents(CrisisID) 
ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE ResourceAllocations 
ADD CONSTRAINT fk_resource_org FOREIGN KEY (OrgID) REFERENCES HumanitarianOrganizations(OrgID) 
ON DELETE CASCADE ON UPDATE CASCADE;

-- AffectedArea Table
ALTER TABLE AffectedArea 
ADD CONSTRAINT fk_affected_area_region FOREIGN KEY (RegionID) REFERENCES AffectedRegions(RegionID) 
ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE AffectedArea 
ADD CONSTRAINT fk_affected_area_crisis FOREIGN KEY (CrisisID) REFERENCES CrisisEvents(CrisisID) 
ON DELETE CASCADE ON UPDATE CASCADE;

-- ResponseActivities Table
ALTER TABLE ResponseActivities 
ADD CONSTRAINT fk_response_crisis FOREIGN KEY (CrisisID) REFERENCES CrisisEvents(CrisisID) 
ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE ResponseActivities 
ADD CONSTRAINT fk_response_org FOREIGN KEY (OrgID) REFERENCES HumanitarianOrganizations(OrgID) 
ON DELETE CASCADE ON UPDATE CASCADE;

-- TemporalData Table
ALTER TABLE TemporalData 
ADD CONSTRAINT fk_temporal_crisis FOREIGN KEY (CrisisID) REFERENCES CrisisEvents(CrisisID) 
ON DELETE CASCADE ON UPDATE CASCADE;
GO

-- 3) Add General Constraints

-- Severity must be between 1 and 10
ALTER TABLE CrisisEvents 
ADD CONSTRAINT chk_severity CHECK (Severity BETWEEN 1 AND 10);

-- FundAmount must be a positive value
ALTER TABLE ResourceAllocations 
ADD CONSTRAINT chk_fund_amount CHECK (FundAmount >= 0);

-- PopulationAffected must be a positive value
ALTER TABLE AffectedRegions 
ADD CONSTRAINT chk_population_affected CHECK (PopulationAffected >= 0);

-- TotalAffected must be a positive value
ALTER TABLE AffectedArea 
ADD CONSTRAINT chk_total_affected CHECK (TotalAffected >= 0);

-- Check ResponseUrgency is either 'High', 'Medium', 'Low'
ALTER TABLE ResponseActivities 
ADD CONSTRAINT chk_response_urgency CHECK (ResponseUrgency IN ('High', 'Medium', 'Low'));
GO

-- Bulk insert into CrisisEvents
BULK INSERT CrisisEvents
FROM 'C:\Users\aarnn\Downloads\CrisisEvents.csv'
WITH (
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    TABLOCK
);
GO

-- Bulk insert into AffectedRegions
BULK INSERT AffectedRegions
FROM 'C:\Users\aarnn\Downloads\AffectedRegions.csv'
WITH (
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    BATCHSIZE = 1000
);
GO

-- Bulk insert into HumanitarianOrganizations
BULK INSERT HumanitarianOrganizations
FROM 'C:\Users\aarnn\Downloads\HumanitarianOrganizations.csv'
WITH (
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    BATCHSIZE = 1000
);
GO

-- Bulk insert into ResourceAllocations
BULK INSERT ResourceAllocations
FROM 'C:\Users\aarnn\Downloads\ResourceAllocations.csv'
WITH (
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    BATCHSIZE = 1000
);
GO

-- Bulk insert into AffectedArea
BULK INSERT AffectedArea
FROM 'C:\Users\aarnn\Downloads\AffectedArea.csv'
WITH (
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    BATCHSIZE = 1000
);
GO

-- Bulk insert into ResponseActivities
BULK INSERT ResponseActivities
FROM 'C:\Users\aarnn\Downloads\ResponseActivities.csv'
WITH (
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    BATCHSIZE = 1000
);
GO

-- Bulk insert into TemporalData
BULK INSERT TemporalData
FROM 'C:\Users\aarnn\Downloads\TemporalData.csv'
WITH (
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    BATCHSIZE = 1000
);
GO
