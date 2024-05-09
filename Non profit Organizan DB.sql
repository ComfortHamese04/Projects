--CREATE THE DATABASE

CREATE DATABASE NonProfitDB;
GO

-- Enable mixed-mode authentication

EXEC sp_configure 'show advanced options', 1
RECONFIGURE
GO
EXEC sp_configure 'mixed authentication mode', 1
RECONFIGURE
GO

-- Create a user account
USE NonProfitDB
GO
CREATE LOGIN [nonprofituser] WITH PASSWORD='password123'
GO
CREATE USER [nonprofituser] FOR LOGIN [nonprofituser]
GO
EXEC sp_addrolemember 'db_datareader', 'nonprofituser'
GO
EXEC sp_addrolemember 'db_datawriter', 'nonprofituser'
GO

--CREATE THE TABLES AND COLUMNS

GO
CREATE TABLE Donor (
  Donor_ID INT PRIMARY KEY,
  First_Name NVARCHAR(50) NOT NULL,
  Last_Name NVARCHAR(50) NOT NULL,
  Email NVARCHAR(50) NOT NULL,
  Phone_Number NVARCHAR(20) NOT NULL,
  Address NVARCHAR(50) NOT NULL
);

CREATE TABLE Campaign (
  Campaign_ID INT PRIMARY KEY,
  Campaign_Name NVARCHAR(50) NOT NULL,
  Cmpaign_Description NVARCHAR(500) NOT NULL,
  Start_Date DATE NOT NULL,
  End_Date DATE NOT NULL
);

CREATE TABLE Donation (
  Donation_ID INT PRIMARY KEY, 
  Amount DECIMAL(10, 2) NOT NULL,
  Date_of_Payment DATE NOT NULL,
  Donor_ID INT NOT NULL,
  Campaign_ID INT NOT NULL,
  CONSTRAINT FK_Donation_Donor FOREIGN KEY (Donor_ID) REFERENCES Donor(Donor_ID),
  CONSTRAINT FK_Donation_Campaign FOREIGN KEY (Campaign_ID) REFERENCES Campaign(Campaign_ID)
);

CREATE TABLE Campaign_Donor (
  Campaign_Donor_ID INT PRIMARY KEY,
  Donor_ID INT NOT NULL,
  Campaign_ID INT NOT NULL,
  CONSTRAINT FK_Campaign_Donor_Donor FOREIGN KEY (Donor_ID) REFERENCES Donor(Donor_ID),
  CONSTRAINT FK_Campaign_Donor_Campaign FOREIGN KEY (Campaign_ID) REFERENCES Campaign(Campaign_ID)
);
GO

--ADD SAMPLE DATA TO THE TABLES
GO
INSERT INTO Donor (Donor_ID, First_Name, Last_Name, Email, Phone_Number, Address)
VALUES (1, 'Rob', 'Jacobs', 'robjacobs@gamil.com', '071-1234-457', 'Pretoria'),
       (2, 'Nancy', 'Smith', 'nancysmith@gmail.com', '082-5678-789', 'Johannesburg'),
       (3, 'Natahan', 'Ralph', 'Natahnralph@gmail.com', '066-9012-563', 'Durban');

INSERT INTO Campaign (Campaign_ID, Campaign_Name, Cmpaign_Description, Start_Date, End_Date)
VALUES (1, 'Education for All', 'Helping provide education to underprivileged children', '2023-01-01', '2023-12-31'),
       (2, 'Clean Water Initiative', 'Providing access to clean water in developing countries', '2023-02-01', '2023-11-30');

INSERT INTO Donation (Donation_ID, Amount, Date_of_Payment, Donor_ID, Campaign_ID)
VALUES (1, 100.00, '2023-01-15', 1, 1),
       (2, 50.00, '2023-03-01', 2, 1),
       (3, 200.00, '2023-02-15', 3, 2),
       (4, 25.00, '2023-04-01', 1, 2);

INSERT INTO Campaign_Donor (Campaign_Donor_ID, Donor_ID, Campaign_ID)
VALUES (1, 1, 1),
       (2, 2, 1),
       (3, 3,1)
GO
--  Create a view that shows all the donations made by a particular donor.
GO
CREATE VIEW AllDonationsByDonor

AS
SELECT Donation.Donation_ID, Donation.Amount, Donation.Date_of_Payment, Campaign.Campaign_Name
FROM Donation
JOIN Campaign ON Donation.Campaign_ID = Campaign.Campaign_ID
WHERE Donation.Donor_ID=Donor_ID
GO
--  Create a stored procedure that adds a new donor to the database.
GO
CREATE PROCEDURE AddNewDonor
@First_Name VARCHAR(50),
@Last_Name VARCHAR(50),
@Email VARCHAR(50),
@Phone_Number VARCHAR(20),
@Location VARCHAR(50)
AS
BEGIN
SET NOCOUNT ON;

INSERT INTO Donor (First_Name, Last_Name, Email, Phone_Number, Address)
VALUES (@First_Name, @Last_Name, @Email, @Phone_Number, @Location)
END
GO
--  Create a trigger that updates the Campaign_Donor table whenever a new donation is made.
GO
CREATE TRIGGER UpdateCampaignDonor
ON Donation
AFTER INSERT
AS
BEGIN
SET NOCOUNT ON;

INSERT INTO Campaign_Donor (Campaign_ID, Donor_ID)
SELECT i.Campaign_ID, i.Donor_ID
FROM inserted i
END
GO
--  Create a function that calculates the total amount donated by a particular donor.
GO
CREATE FUNCTION TotalDonationsByDonor (@Donor_ID INT)
RETURNS DECIMAL(10,2)
AS
BEGIN
DECLARE @Total DECIMAL(10,2)

SELECT @Total = SUM(Amount)
FROM Donation
WHERE Donor_ID = @Donor_ID
RETURN @Total
END
GO
-- Create a cursor that loops through all the donors and sends them an email thanking them for their contributions.
GO
DECLARE @Donor_ID INT
DECLARE @First_Name VARCHAR(50)
DECLARE @Last_Name VARCHAR(50)
DECLARE @Email VARCHAR(50)
DECLARE @Message VARCHAR(500)

DECLARE Donor_Cursor CURSOR FOR
(SELECT Donor_ID=@Donor_ID, First_Name=@First_Name, Last_Name=Last_Name, Email=@Email
FROM Donor)

OPEN Donor_Cursor

FETCH NEXT FROM Donor_Cursor INTO @Donor_ID, @First_Name, @Last_Name, @Email

WHILE @@FETCH_STATUS = 0
BEGIN
SET @Message = 'Dear ' + @First_Name + ' ' + @Last_Name + ', thank you for your generous donation to our campaign. Your support makes a real difference!'

FETCH NEXT FROM Donor_Cursor INTO @Donor_ID, @First_Name, @Last_Name, @Email
END

CLOSE Donor_Cursor
DEALLOCATE Donor_Cursor
GO
--Create a stored procedure that allows a user to delete a donation from the database
GO
CREATE PROCEDURE DeleteDonation
    @Donation_ID int
AS
BEGIN
    DELETE FROM Donation
    WHERE Donation_ID = @Donation_ID;
END;
GO

--view that shows all the information about a particular campaign, including the total amount donated and the number of donors
GO
CREATE VIEW CampaignDetails
AS
SELECT c.Campaign_ID, c.Campaign_Name, c.Cmpaign_Description, c.Start_Date, c.End_Date,
       COUNT(cd.Donor_ID) AS Num_Donors, SUM(dn.Amount) AS Total_Donations
FROM Campaign c
LEFT JOIN Campaign_Donor cd ON c.Campaign_ID = cd.Campaign_ID
LEFT JOIN Donation dn ON c.Campaign_ID = dn.Campaign_ID
GROUP BY c.Campaign_ID, c.Campaign_Name, c.Cmpaign_Description, c.Start_Date, c.End_Date;

GO


