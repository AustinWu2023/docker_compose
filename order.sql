USE orders;

CREATE TABLE ReturnedSalesReport (
    ID int NOT NULL,
    ReportType varchar(20) ,
    Commint varchar(20) ,
    CreateDateTime datetime DEFAULT now(),
    PRIMARY KEY (ID)
);


CREATE PROCEDURE `Test.Insertdata` (
	IN pId int,
    IN pReportType VARCHAR(20),
    IN pCommint varchar(20) 
)
BEGIN
	INSERT INTO `orders`.`returnedsalesreport`
    (`ID`, `ReportType`, `Commint` )
    VALUES
    (   pId,
        pReportType,
        pCommint
    );
END

