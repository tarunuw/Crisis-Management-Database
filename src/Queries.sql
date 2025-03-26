-- Arnav Mohan's Queries
-- Query 1: Identifies the Top 3 Crises with the Highest Resource Allocations
-- Uses a temporary table to aggregate funding and filter results

-- Step 1: Create Temporary Table
DROP TABLE IF EXISTS #CrisisFundingSummary;
CREATE TABLE #CrisisFundingSummary (
    CrisisID INT,
    CrisisName VARCHAR(255),
    TotalFundAllocated DECIMAL(18,2),
    TotalOrgsInvolved INT
);

-- Step 2: Insert Aggregated Data into Temporary Table
INSERT INTO #CrisisFundingSummary (CrisisID, CrisisName, TotalFundAllocated, TotalOrgsInvolved)
SELECT 
    C.CrisisID,
    C.CrisisName,
    SUM(RA.FundAmount) AS TotalFundAllocated,
    COUNT(DISTINCT RA.OrgID) AS TotalOrgsInvolved
FROM CrisisEvents C
JOIN ResourceAllocations RA ON C.CrisisID = RA.CrisisID
GROUP BY C.CrisisID, C.CrisisName;

-- Step 3: Retrieve the Top 3 Crises with the Highest Resource Allocation
SELECT TOP 3 *
FROM #CrisisFundingSummary
ORDER BY TotalFundAllocated DESC, TotalOrgsInvolved DESC;



-- Managerial Insight: This query helps find which crises received the highest funding and had the most organizational involvement.
-- Decision-makers can analyze if the funds were appropriately distributed and if highly funded crises have corresponding impact.

-- Query 2: Advanced Stored Procedure to Retrieve Crisis Response Summary with Performance Indicators and Financial Data
CREATE PROCEDURE GetCrisisResponseSummary
    @CrisisID INT
AS
BEGIN
    WITH ResponseSummary AS (
        SELECT C.CrisisName, H.OrgName, R.ActivityDescription, R.ImplementationDate, R.ResponseUrgency,
               DATEDIFF(DAY, C.StartDate, R.ImplementationDate) AS DaysToRespond,
               COUNT(R.ResponseID) OVER (PARTITION BY R.OrgID) AS TotalResponsesByOrg,
               (SELECT SUM(FundAmount) FROM ResourceAllocations RA WHERE RA.OrgID = H.OrgID AND RA.CrisisID = C.CrisisID) AS TotalFundsAllocated
        FROM ResponseActivities R
        JOIN HumanitarianOrganizations H ON R.OrgID = H.OrgID
        JOIN CrisisEvents C ON R.CrisisID = C.CrisisID
        WHERE R.CrisisID = @CrisisID
    )
    SELECT RS.*, COALESCE(T.TotalFundsAllocated, 0) AS TotalFundsAllocated
    FROM ResponseSummary RS
    LEFT JOIN (
        SELECT RA.OrgID, SUM(RA.FundAmount) AS TotalFundsAllocated
        FROM ResourceAllocations RA
        WHERE RA.CrisisID = @CrisisID
        GROUP BY RA.OrgID
    ) T ON RS.OrgName = (SELECT OrgName FROM HumanitarianOrganizations WHERE OrgID = T.OrgID)
    ORDER BY DaysToRespond ASC, ResponseUrgency DESC;
END;

-- Managerial Insight: This stored procedure crisis allows decision-makers to find which organizations are efficiently utilizing funds alongside their response effectiveness by incorporating financial data.


-- Tarun Tamilselvan's Queries:

-- Query 1: Identifies Top 3 Most Severe Crises with Largest Affected Population (Using CTE and Rank)
-- Uses a CTE and RANK() to provide better prioritization of crises.

WITH CrisisImpact AS (
    SELECT C.CrisisID, C.CrisisName, C.Severity, A.RegionName, SUM(A.TotalAffected) AS TotalPopulationAffected,
           RANK() OVER (ORDER BY C.Severity DESC, SUM(A.TotalAffected) DESC) AS CrisisRank
    FROM CrisisEvents C
    JOIN AffectedArea AA ON C.CrisisID = AA.CrisisID
    JOIN AffectedRegions A ON AA.RegionID = A.RegionID
    GROUP BY C.CrisisID, C.CrisisName, C.Severity, A.RegionName
)
SELECT *
FROM CrisisImpact
WHERE CrisisRank <= 3;

-- Managerial Insight: By using RANK(), this query ensures that if multiple crises have the same severity and population affected, they are ranked accordingly without exclusions.

-- Query 2: Stored Procedure to Retrieve Latest Recovery Progress
CREATE PROCEDURE GetLatestRecoveryProgress
    @CrisisID INT
AS
BEGIN
    SELECT 
        C.CrisisName,
        T.DateRecorded,
        T.StatusUpdate,
        T.RecoveryProgress
    FROM TemporalData T
    JOIN CrisisEvents C ON T.CrisisID = C.CrisisID
    WHERE T.CrisisID = @CrisisID
    AND T.DateRecorded = (
        SELECT MAX(DateRecorded) 
        FROM TemporalData 
        WHERE CrisisID = @CrisisID
    )
    ORDER BY T.DateRecorded DESC;
END;

-- Managerial Insight: This stored procedure helps managers track the most recent updates on crisis recovery efforts. It ensures that decision-makers are acting based on the latest information rather than outdated status reports.

