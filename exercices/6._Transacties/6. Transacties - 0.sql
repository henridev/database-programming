-- First drop + create a new database
USE MASTER;
SET NOCOUNT ON;
DROP DATABASE IF EXISTS [Transactions_Db];

CREATE DATABASE [Transactions_Db];




-- Then, create a new test table with dummy data
USE [Transactions_Db];
SET NOCOUNT ON;
GO

CREATE TABLE TestIsolationLevels (
EmpID INT NOT NULL,
EmpName VARCHAR(100),
EmpSalary MONEY,
CONSTRAINT pk_EmpID PRIMARY KEY(EmpID) )
GO

-- Insert Test Data
INSERT INTO TestIsolationLevels 
VALUES 
(2322, 'Dave Smith', 35000),
(2900, 'John West', 22000),
(2219, 'Melinda Carlisle', 40000),
(2950, 'Adam Johns', 18000) 
GO