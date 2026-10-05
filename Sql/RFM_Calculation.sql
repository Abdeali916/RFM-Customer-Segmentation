SELECT COUNT(*) AS TotalRows
FROM OnlineRetail;

SELECT MAX(InvoiceDate) AS LatestPurchaseDate
FROM OnlineRetail;

-- Calculate Recency, Frequency, and Monetary value for each customer

WITH AnalysisDate AS (
    SELECT DATEADD(DAY, 1, CAST(MAX(InvoiceDate) AS DATE)) AS AnalysisDate
    FROM OnlineRetail
)

SELECT
    CustomerID,
    DATEDIFF(DAY, MAX(InvoiceDate), AnalysisDate) AS Recency,
    COUNT(DISTINCT InvoiceNo) AS Frequency,
    SUM(Revenue) AS Monetary
FROM OnlineRetail
CROSS JOIN AnalysisDate
GROUP BY CustomerID, AnalysisDate
ORDER BY CustomerID;

-- Create a customer-level RFM table

WITH AnalysisDate AS (
    SELECT DATEADD(DAY, 1, CAST(MAX(InvoiceDate) AS DATE)) AS AnalysisDate
    FROM OnlineRetail
)

SELECT
    CustomerID,
    DATEDIFF(DAY, MAX(InvoiceDate), AnalysisDate) AS Recency,
    COUNT(DISTINCT InvoiceNo) AS Frequency,
    SUM(Revenue) AS Monetary
INTO Customer_RFM
FROM OnlineRetail
CROSS JOIN AnalysisDate
GROUP BY CustomerID, AnalysisDate;

-- Check the newly created customer-level RFM table

SELECT TOP 10 *
FROM Customer_RFM
ORDER BY CustomerID;

-- Count the number of customers in the RFM table

SELECT COUNT(*) AS TotalCustomers
FROM Customer_RFM;

-- Assign 1-5 scores to Recency, Frequency, and Monetary value

SELECT
    CustomerID,
    Recency,
    Frequency,
    Monetary,

    -- Lower Recency is better, so reverse the NTILE score
    6 - NTILE(5) OVER (ORDER BY Recency) AS R_Score,

    -- Higher Frequency is better
    NTILE(5) OVER (ORDER BY Frequency) AS F_Score,

    -- Higher Monetary value is better
    NTILE(5) OVER (ORDER BY Monetary) AS M_Score

FROM Customer_RFM;


-- Create a table containing RFM metrics and their 1-5 scores

WITH RFM_Scores AS (
    SELECT
        CustomerID,
        Recency,
        Frequency,
        Monetary,
        6 - NTILE(5) OVER (ORDER BY Recency) AS R_Score,
        NTILE(5) OVER (ORDER BY Frequency) AS F_Score,
        NTILE(5) OVER (ORDER BY Monetary) AS M_Score
    FROM Customer_RFM
)

SELECT
    CustomerID,
    Recency,
    Frequency,
    Monetary,
    R_Score,
    F_Score,
    M_Score,

    -- Combine the three scores into one RFM score such as 555 or 344
    CONCAT(R_Score, F_Score, M_Score) AS RFM_Score

INTO Customer_RFM_Scored
FROM RFM_Scores;

-- Check the customer RFM scoring table

SELECT TOP 20 *
FROM Customer_RFM_Scored
ORDER BY CustomerID;


-- Segment customers based on their RFM scores

SELECT
    CustomerID,
    Recency,
    Frequency,
    Monetary,
    R_Score,
    F_Score,
    M_Score,
    RFM_Score,
    CASE
        WHEN R_Score >= 4 AND F_Score >= 4 AND M_Score >= 4
            THEN 'Most Loyal Customers'
        WHEN R_Score >= 3 AND F_Score >= 3 AND M_Score >= 3
            THEN 'Loyal Customers'
        WHEN R_Score >= 4 AND F_Score <= 3
            THEN 'Potential Loyalists'
        WHEN R_Score <= 2 AND F_Score >= 3 AND M_Score >= 3
            THEN 'At Risk'
        WHEN R_Score <= 2 AND F_Score <= 2 AND M_Score <= 2
            THEN 'Lost Customers'
        ELSE 'Others'
    END AS Customer_Segment
FROM Customer_RFM_Scored;

-- Create the final RFM table with customer segments

WITH CustomerSegments AS (
    SELECT
        CustomerID,
        Recency,
        Frequency,
        Monetary,
        R_Score,
        F_Score,
        M_Score,
        RFM_Score,
        CASE
            WHEN R_Score >= 4 AND F_Score >= 4 AND M_Score >= 4
                THEN 'Most Loyal Customers'
            WHEN R_Score >= 3 AND F_Score >= 3 AND M_Score >= 3
                THEN 'Loyal Customers'
            WHEN R_Score >= 4 AND F_Score <= 3
                THEN 'Potential Loyalists'
            WHEN R_Score <= 2 AND F_Score >= 3 AND M_Score >= 3
                THEN 'At Risk'
            WHEN R_Score <= 2 AND F_Score <= 2 AND M_Score <= 2
                THEN 'Lost Customers'
            ELSE 'Others'
        END AS Customer_Segment
    FROM Customer_RFM_Scored
)

SELECT *
INTO Customer_RFM_Final
FROM CustomerSegments;

-- Check the final RFM table

SELECT TOP 20 *
FROM Customer_RFM_Final
ORDER BY CustomerID;

-- Count customers in each RFM segment

SELECT
    Customer_Segment,
    COUNT(*) AS Customer_Count
FROM Customer_RFM_Final
GROUP BY Customer_Segment
ORDER BY Customer_Count DESC;