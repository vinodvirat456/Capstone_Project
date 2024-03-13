SELECT *FROM BANK_CHURN;
select * from customerinfo;

-- OBJECTIVE QUESTIONS


-- 1.What is the distribution of account balance across different regions?

SELECT
    GeographyLocation,
    COUNT(*) AS NumCustomers,
    sum(balance) as TotalBalance,
    AVG(Balance) AS AvgBalance,
    MIN(Balance) AS MinBalance,
    MAX(Balance) AS MaxBalance
FROM
    Bank_churn
JOIN
    customerinfo ON Bank_churn.CustomerId = customerinfo.CustomerId
GROUP BY
    GeographyLocation
ORDER BY
    GeographyLocation;
    
    
    
   -- 2.Identify the top 5 customers with the highest Estimated Salary in the last quarter of the year.
WITH CustomerTransactionCounts AS (  
  SELECT        
        c.CustomerId,
        c.Surname,
        sum(EstimatedSalary) AS EstimatedSalary
    FROM
        customerinfo c
   JOIN
        bank_churn bc ON bc.CustomerId = c.CustomerId
     WHERE
         EXTRACT(MONTH FROM BankDOJ) IN (10, 11, 12)  
   GROUP BY       
         c.CustomerId, c.Surname
 )
SELECT
   CustomerId,
   Surname,
    EstimatedSalary
 FROM
    CustomerTransactionCounts
ORDER BY
  EstimatedSalary DESC
 LIMIT 5;


   --  3.Calculate the average number of products used by customers who have a credit card.
   
   SELECT
    AVG(NumOfProducts) AS AvgProductsWithCreditCard
FROM Bank_churn
WHERE HasCrCard = 1;


-- --  4.Determine the churn rate by gender for the most recent year in the dataset. Filter data for the most recent year


WITH RecentYear AS (
    SELECT MAX(YEAR(BankDOJ)) AS MaxYear
    FROM customerinfo
)

SELECT
    GenderCategory,
    SUM(CASE WHEN Exited = 1 THEN 1 ELSE 0 END) AS ChurnedCustomers,
    COUNT(*) AS TotalCustomers,
    ROUND(SUM(CASE WHEN Exited = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS ChurnRate
FROM
    customerinfo ci
    join bank_churn bc on ci.CustomerId=bc.CustomerId
JOIN
    RecentYear ry ON YEAR(ci.BankDOJ) = ry.MaxYear
GROUP BY
    GenderCategory;



-- 5.Compare the average credit score of customers who have exited and those who remain.
SELECT
    ExitCategory,
    AVG(CreditScore) AS AvgCreditScore
FROM
    Bank_churn
GROUP BY
    ExitCategory;
    
-- 6.Which gender has a higher average estimated salary, and how does it relate to the number of active accounts? 
 WITH GenderSalaryActiveAccounts AS (
    SELECT
        GenderCategory,
        AVG(EstimatedSalary) AS AvgSalary
--         SUM(bc.IsActiveMember) AS NumActiveAccounts
    FROM
        customerinfo c
        JOIN bank_churn bc on c.CustomerId=bc.CustomerId
        WHERE bc.IsActiveMember=1
    GROUP BY
        GenderCategory
)

SELECT
    GenderCategory,
    AvgSalary
    FROM
    GenderSalaryActiveAccounts
ORDER BY
    AvgSalary DESC;

 -- 7.Segment the customers based on their credit score and identify the segment with the highest exit rate.
 
 WITH CreditScoreSegments AS (
    SELECT
        CASE
            WHEN CreditScore BETWEEN 800 AND 850 THEN 'Excellent'
            WHEN CreditScore BETWEEN 740 AND 799 THEN 'Very Good'
            WHEN CreditScore BETWEEN 670 AND 739 THEN 'Good'
            WHEN CreditScore BETWEEN 580 AND 669 THEN 'Fair'
            WHEN CreditScore BETWEEN 300 AND 579 THEN 'Poor'
            ELSE 'Unknown'  
        END AS CreditScoreSegment,
        COUNT(*) AS TotalCustomers,
        SUM(Exited) AS ChurnedCustomers,
        100 * SUM(Exited) / COUNT(*) AS ExitRate
    FROM Bank_churn
    GROUP BY CreditScoreSegment
)

SELECT
    CreditScoreSegment,
    TotalCustomers,
    ChurnedCustomers,
    ExitRate
FROM CreditScoreSegments
ORDER BY ExitRate DESC
LIMIT 1;

-- 8.Find out which geographic region has the highest number of active customers with a tenure greater than 5 years. (SQL)
 
 WITH ActiveCustomersByRegion AS (
    SELECT
        GeographyLocation,
        COUNT(*) AS ActiveCustomers
    FROM customerinfo
    JOIN
        Bank_churn ON customerinfo.CustomerId = Bank_churn.CustomerId
    WHERE 
        IsActiveMember = 1 AND Tenure > 5
    GROUP BY GeographyLocation
)

SELECT
    GeographyLocation,
    ActiveCustomers
FROM
    ActiveCustomersByRegion
ORDER BY
    ActiveCustomers DESC
LIMIT 1;


-- 9.What is the impact of having a credit card on customer churn, based on the available data?
WITH CreditCardChurn AS (
    SELECT
        HasCrCard,
        COUNT(*) AS TotalCustomers,
        SUM(Exited) AS ChurnedCustomers,
        100 * SUM(Exited) / COUNT(*) AS ChurnRate
    FROM
        Bank_churn
    GROUP BY
        HasCrCard
)

SELECT
    HasCrCard,
    TotalCustomers,
    ChurnedCustomers,
    ChurnRate
FROM
    CreditCardChurn;


-- 10.	For customers who have exited, what is the most common number of products they had used?

SELECT
    NumOfProducts,
    COUNT(*) AS NumCustomers
FROM Bank_churn
WHERE Exited = 1
GROUP BY NumOfProducts
ORDER BY NumCustomers DESC
LIMIT 1;


-- 11.Examine the trend of customer Joining over time and identify any seasonal patterns (yearly or monthly).
--  Prepare the data through SQL and then visualize it.
SELECT YEAR(c.BankDOJ) AS Years,COUNT(c.CustomerId) AS CustomersCount
FROM customerinfo c
JOIN bank_churn bc on c.customerID=bc.customerID
GROUP BY Years
ORDER BY Years asc;



-- 12.Analyze the relationship between the number of products and the account balance for customers who have exited.

SELECT
    NumOfProducts,
    AVG(Balance) AS AvgBalance,
    COUNT(*) AS NumCustomers
FROM Bank_churn
WHERE Exited = 1
GROUP BY NumOfProducts
ORDER BY NumOfProducts;


-- 15.Using SQL, write a query to find out the gender wise average income of male and female in each geography id.
--  Also rank the gender according to the average value. 

WITH GenderIncomeRank AS (
    SELECT
        GeographyID,
        GenderCategory,
        AVG(EstimatedSalary) AS AvgIncome,
        DENSE_RANK() OVER (PARTITION BY  GeographyID ORDER BY AVG(EstimatedSalary) DESC) AS GenderRank
    FROM
        customerinfo
    GROUP BY
        GeographyID, GenderCategory
)

SELECT
    GeographyID,
    GenderCategory,
    AvgIncome,
    GenderRank
FROM
    GenderIncomeRank
ORDER BY
    GeographyID, GenderRank;


    
-- 16. Using SQL, write a query to find out the average tenure of the people who have exited in each age bracket (18-30, 30-50, 50+).

SELECT
    CASE
        WHEN Age BETWEEN 18 AND 30 THEN '18-30'
        WHEN Age BETWEEN 30 AND 50 THEN '30-50'
        WHEN Age >= 50 THEN '50+'
        ELSE 'Unknown'  
    END AS AgeBracket,
    AVG(Tenure) AS AvgTenure
FROM customerinfo c
JOIN bank_churn bc  on bc.CustomerId=c.CustomerId
WHERE Exited = 1
GROUP BY AgeBracket
ORDER BY AgeBracket;


-- 17.Is there any direct correlation between salary and balance of the customers?
 -- And is it different for people who have exited or not?
 
 --  Correlation Coefficient for All Customers

SELECT 
    (COUNT(*) * SUM(EstimatedSalary * Balance) - SUM(EstimatedSalary) * SUM(Balance)) / 
    SQRT((COUNT(*) * SUM(EstimatedSalary * EstimatedSalary) - POW(SUM(EstimatedSalary), 2)) * 
    (COUNT(*) * SUM(Balance * Balance) - POW(SUM(Balance), 2))) AS Correlation_AllCustomers
FROM 
    Bank_churn bc
    join customerinfo c on c.CustomerId=bc.CustomerId;

--  Correlation Coefficient for Customers who have Exited
SELECT 
    (COUNT(*) * SUM(EstimatedSalary * Balance) - SUM(EstimatedSalary) * SUM(Balance)) / 
    SQRT((COUNT(*) * SUM(EstimatedSalary * EstimatedSalary) - POW(SUM(EstimatedSalary), 2)) * 
    (COUNT(*) * SUM(Balance * Balance) - POW(SUM(Balance), 2))) AS Correlation_ExitedCustomers
FROM 
    Bank_churn bc
    join customerinfo c on c.CustomerId=bc.CustomerId
WHERE 
    Exited = 1;

 
 -- 18.Is there any correlation between salary and Credit score of customers?
SELECT 
    (COUNT(*) * SUM(EstimatedSalary * CreditScore) - SUM(EstimatedSalary) * SUM(CreditScore)) / 
    SQRT((COUNT(*) * SUM(EstimatedSalary * EstimatedSalary) - POW(SUM(EstimatedSalary), 2)) * 
    (COUNT(*) * SUM(CreditScore * CreditScore) - POW(SUM(CreditScore), 2))) AS Correlation_Salary_CreditScore
FROM 
    customerinfo c
    join bank_churn bc on c.customerid=bc.CustomerId;


-- 19.Rank each bucket of credit score as per the number of customers who have churned the bank.

SELECT
    CASE
     WHEN CreditScore BETWEEN 800 AND 850 THEN 'Excellent'
            WHEN CreditScore BETWEEN 740 AND 799 THEN 'Very Good'
            WHEN CreditScore BETWEEN 670 AND 739 THEN 'Good'
            WHEN CreditScore BETWEEN 580 AND 669 THEN 'Fair'
            WHEN CreditScore BETWEEN 300 AND 579 THEN 'Poor'
            ELSE 'Unknown'
            END AS CreditScoreBucket,
     COUNT(*) AS NumChurnedCustomers,
      DENSE_RANK() OVER (ORDER BY COUNT(*) DESC) AS CreditRank
FROM
    Bank_churn
WHERE
    Exited = 1
GROUP BY
    CreditScoreBucket
ORDER BY
    CreditRank;
    
    
-- 20.According to the age buckets find the number of customers who have a credit card. 
-- Also retrieve those buckets who have lesser than average number of credit cards per bucket.


   SELECT
        CASE
            WHEN Age BETWEEN 18 AND 30 THEN '18-30'
            WHEN Age BETWEEN 30 AND 50 THEN '30-50'
            WHEN Age >= 50 THEN '50+'
            ELSE 'Unknown'  
        END AS AgeBucket,
        COUNT(*) AS NumofCustomers
        FROM customerinfo c
        
        JOIN bank_churn bc on c.CustomerId=bc.CustomerId
        WHERE  HasCrCard=1
        
       group by AgeBucket;
--        
--        
--
WITH CreditCardCounts AS (
    SELECT
      CASE
            WHEN Age BETWEEN 18 AND 30 THEN '18-30'
            WHEN Age BETWEEN 31 AND 50 THEN '31-50'
            WHEN Age >= 51 THEN '50+'
          ELSE 'Unknown'
        END AS AgeBucket,
        SUM(HasCrCard) AS CreditCardCount,
        COUNT(*) AS TotalCustomers
    FROM
        customerinfo c
        join bank_churn  bc on c.CustomerId=bc.CustomerId
    GROUP BY
        AgeBucket
),
AverageCreditCards AS (
    SELECT
        AVG(CreditCardCount) AS AvgCreditCards
    FROM
        CreditCardCounts
)
SELECT
    AgeBucket,
    CreditCardCount,
    TotalCustomers
FROM
    CreditCardCounts
WHERE
    CreditCardCount < (SELECT AvgCreditCards FROM AverageCreditCards);


        
-- 21.Rank the Locations as per the number of people who have churned the bank and average balance of the learners.
WITH LocationChurnStats AS (
    SELECT
        GeographyLocation,
        COUNT(*) AS NumChurnedCustomers,
        AVG(Balance) AS AvgBalance
    FROM
        customerinfo c
    JOIN
        Bank_churn bc ON c.CustomerId = bc.CustomerId
    WHERE
        Exited = 1
    GROUP BY
        GeographyLocation
)

SELECT
    GeographyLocation,
    NumChurnedCustomers,
    AvgBalance,
    RANK() OVER (ORDER BY NumChurnedCustomers DESC, AvgBalance DESC) AS LocationRank
FROM
    LocationChurnStats
ORDER BY
    LocationRank;
    
    
    ------ Data Analysis and Subjective Questions------
    
    -- 9.	Utilize SQL queries to segment customers based on demographics, account details, and transaction behaviors.

      --   1.Segmentation by Demographics:

SELECT
    GenderCategory,
    COUNT(*) AS CustomerCount
FROM
    customerinfo
GROUP BY
    GenderCategory;
    
    -- 2.Segmentation by Account Details:
    
    SELECT
    CreditCategory,
    AVG(Balance) AS AvgBalance
FROM
    Bank_churn
GROUP BY
    CreditCategory;
    
    
    -- 3.Segmentation by Transaction Behaviors:
    
    SELECT
    IsActiveMember,
    AVG(NumOfProducts) AS AvgProducts
FROM
    Bank_churn
GROUP BY
    IsActiveMember;
    
    
    

















