

-- =============================================
-- Author:      gaoweiwei
-- Create date: 2013/11/26
-- Description: 成本分析报表
-- =============================================

CREATE PROCEDURE [media].[prc_FinanceCostAnalysis]
    @SelectedYear INT ,

    @SelectedSignCompanyID INT = NULL,
    @IsEqualPayCompanyID BIT,
    @SelectedPayCompanyID INT = NULL,
    @IsEqualCheckAccountID BIT,
    @SelectedCheckAccountID INT = NULL ,
    @IsEqualDisplayType BIT,
    @SelectedDisplayType VARCHAR(10) = NULL,
    @IsEqualCity BIT,
    @SelectedCity INT = NULL,
    @IsEqualBuildingType1 BIT,
    @SelectedBuildingType1 INT = NULL,
    @IsEqualBuildingLevel BIT,
    @SelectedBuildingLevel VARCHAR(20) = NULL,
    @SelectDeptID INT = NULL ,

    @GroupType INT


AS
    DECLARE @ReportDate DATETIME
    DECLARE @BackupID INT

    SELECT @ReportDate = CAST(@SelectedYear AS CHAR(4)) + '1231'
    SET @BackupID = report.fn_GetBackupID(@ReportDate);

    CREATE TABLE #dept
    (
        DeptID INT
    )

    CREATE TABLE #contract
    (
        ContractID INT
    )

    CREATE TABLE #month
    (
        MonthID    INT ,
        StartDate   DATETIME,
        EndDate     DATETIME,
        AllDays     INT
    )

    CREATE TABLE #t_res(
        contract_id  int,
        One          decimal(18, 2),
        One_Y        decimal(18, 2),
        Two          decimal(18, 2),
        Two_Y        decimal(18, 2),
        Three        decimal(18, 2),
        Three_Y      decimal(18, 2),
        Four         decimal(18, 2),
        Four_Y       decimal(18, 2),
        Five         decimal(18, 2),
        Five_Y       decimal(18, 2),
        Six          decimal(18, 2),
        Six_Y        decimal(18, 2),
        Seven        decimal(18, 2),
        Seven_Y      decimal(18, 2),
        Eight        decimal(18, 2),
        Eight_Y      decimal(18, 2),
        Nine         decimal(18, 2),
        Nine_Y       decimal(18, 2),
        Ten          decimal(18, 2),
        Ten_Y        decimal(18, 2),
        Eleven       decimal(18, 2),
        Eleven_Y     decimal(18, 2),
        Twelve       decimal(18, 2),
        Twelve_Y     decimal(18, 2)
      )

    IF @SelectDeptID IS NOT NULL
    BEGIN
        INSERT INTO #dept ( DeptID )
        SELECT D1.DeptID
        FROM [basic].[tbb_Department] D1
        JOIN basic.tbb_Department D2 ON D1.DeptNo LIKE  D2.DeptNo + '%'
        WHERE D2.DeptID = @SelectDeptID
    END

    IF @BackupID IS NULL OR @BackupID <= 0
        BEGIN
            RETURN -1;
        END


    -- prepare month
    INSERT INTO #month ( MonthID ,StartDate )
    SELECT 1, DATEADD(year, @SelectedYear - 1900, 0) UNION
    SELECT 2, DATEADD(MONTH, 1, DATEADD(year, @SelectedYear - 1900, 0))
    SELECT 3, DATEADD(MONTH, 2, DATEADD(year, @SelectedYear - 1900, 0))
    SELECT 4, DATEADD(MONTH, 3, DATEADD(year, @SelectedYear - 1900, 0))
    SELECT 5, DATEADD(MONTH, 4, DATEADD(year, @SelectedYear - 1900, 0))
    SELECT 6, DATEADD(MONTH, 5, DATEADD(year, @SelectedYear - 1900, 0))
    SELECT 7, DATEADD(MONTH, 6, DATEADD(year, @SelectedYear - 1900, 0))
    SELECT 8, DATEADD(MONTH, 7, DATEADD(year, @SelectedYear - 1900, 0))
    SELECT 9, DATEADD(MONTH, 8, DATEADD(year, @SelectedYear - 1900, 0))
    SELECT 10, DATEADD(MONTH, 9, DATEADD(year, @SelectedYear - 1900, 0))
    SELECT 11, DATEADD(MONTH, 10, DATEADD(year, @SelectedYear - 1900, 0))
    SELECT 12, DATEADD(MONTH, 11, DATEADD(year, @SelectedYear - 1900, 0))

    UPDATE #month SET EndDate = DATEADD(DAY, -1, DATEADD(MONTH, 1, StartDate)), AllDays = DAY(DATEADD(DAY, -1, DATEADD(MONTH, 1, StartDate)))

    INSERT INTO #contract ( ContractID )
    SELECT C.ContractID FROM report.tbd_Contract C
    JOIN report.tbd_Building B ON C.BackupID = B.BackupID AND C.ItemID = B.BuildingID
    WHERE C.BackupID = @BackupID
        AND ISNULL(@SelectedSignCompanyID, C.SignCompanyID) = C.SignCompanyID
        AND (@SelectedPayCompanyID IS NULL OR (CASE WHEN @IsEqualPayCompanyID = 1 THEN C.PayCompanyID ELSE NULLIF(@SelectedPayCompanyID, C.PayCompanyID) END = @SelectedPayCompanyID ))
        AND (@SelectedCheckAccountID IS NULL OR (CASE WHEN @IsEqualCheckAccountID = 1 THEN C.CheckAccountID ELSE NULLIF(@SelectedCheckAccountID, C.CheckAccountID) END = @SelectedCheckAccountID ))
        AND (@SelectedDisplayType IS NULL OR (CASE WHEN @IsEqualDisplayType = 1 THEN C.DisplayTypeCode ELSE NULLIF(@SelectedDisplayType, C.DisplayTypeCode) END = @SelectedDisplayType ))
        AND (@SelectedCity IS NULL OR (CASE WHEN @IsEqualCity = 1 THEN B.CityID ELSE NULLIF(@SelectedCity, B.CityID) END = @SelectedCity ))
        AND (@SelectedBuildingType1 IS NULL OR (CASE WHEN @IsEqualBuildingType1 = 1 THEN B.BuildingType_1 ELSE NULLIF(@SelectedBuildingType1, B.BuildingType_1) END = @SelectedBuildingType1 ))
        AND (@SelectedBuildingLevel IS NULL OR (CASE WHEN @IsEqualBuildingLevel = 1 THEN B.BuildingLevel ELSE NULLIF(@SelectedBuildingLevel, B.BuildingLevel) END = @SelectedBuildingLevel ))
        AND (@SelectDeptID IS NULL OR C.DeptID IN (SELECT DeptID FROM  #dept))


        INSERT INTO #t_res
            ( contract_id ,
              One ,
              Two ,
              Three ,
              Four ,
              Five ,
              Six ,
              Seven ,
              Eight ,
              Nine ,
              Ten ,
              Eleven ,
              Twelve
            )
             SELECT  CA.ContractID ,
            SUM(CASE WHEN CA.AmortizeMonth = 1 THEN AmortizeAmount END),
            SUM(CASE WHEN CA.AmortizeMonth = 2 THEN AmortizeAmount END),
            SUM(CASE WHEN CA.AmortizeMonth = 3 THEN AmortizeAmount END),
            SUM(CASE WHEN CA.AmortizeMonth = 4 THEN AmortizeAmount END),
            SUM(CASE WHEN CA.AmortizeMonth = 5 THEN AmortizeAmount END),
            SUM(CASE WHEN CA.AmortizeMonth = 6 THEN AmortizeAmount END),
            SUM(CASE WHEN CA.AmortizeMonth = 7 THEN AmortizeAmount END),
            SUM(CASE WHEN CA.AmortizeMonth = 8 THEN AmortizeAmount END),
            SUM(CASE WHEN CA.AmortizeMonth = 9 THEN AmortizeAmount END),
            SUM(CASE WHEN CA.AmortizeMonth = 10 THEN AmortizeAmount END),
            SUM(CASE WHEN CA.AmortizeMonth = 11 THEN AmortizeAmount END),
            SUM(CASE WHEN CA.AmortizeMonth = 12 THEN AmortizeAmount END)
        FROM  report.tbs_CostAmortize CA
        WHERE CA.BackupID = @BackupID
         AND CA.IsClose = 1
         AND CA.AmortizeType IN ('正常','预摊')
         AND CA.AmortizeYear = @SelectedYear
         GROUP BY CA.ContractID

    DECLARE @MaxSettled INT, @FromMonth INT
    SELECT @MaxSettled = MAX(CA.AmortizeMonth)
    FROM report.tbs_CostAmortize CA
    WHERE CA.BackupID = @BackupID
        AND CA.IsClose = 1
        AND CA.AmortizeYear = @SelectedYear

    SET @FromMonth = ISNULL(@MaxSettled, 0) + 1
    PRINT @FromMonth



        SELECT
    C.ContractID,
    M.MonthID,
    C.RentAmount / (DATEDIFF(d, C.PerformBeginDate, C.PerformEndDate) + 1) * [dbo].[GetRangeDays](M.StartDate, M.EndDate, C.PerformBeginDate, C.PerformEndDate) AS [Normal],
    CASE WHEN C.DealStatus in (123) THEN 0 ELSE (C.RentAmount / (DATEDIFF(d, C.PerformBeginDate, C.PerformEndDate) + 1) * CASE WHEN M.EndDate > C.PerformEndDate THEN DAY(M.EndDate) - [dbo].[GetRangeDays](M.StartDate, M.EndDate, C.PerformBeginDate, C.PerformEndDate) ELSE 0 END) END AS [Forecast]
    INTO #unclosed
    FROM report.tbd_Contract C, #month M
    WHERE C.DealStatus NOT IN (1,2,3)
--AND C.state NOT IN ('EA033004','EA033005','EA033006')





        INSERT INTO #t_res
        ( contract_id ,
          One ,
          One_Y ,
          Two ,
          Two_Y ,
          Three ,
          Three_Y ,
          Four ,
          Four_Y ,
          Five ,
          Five_Y ,
          Six ,
          Six_Y ,
          Seven ,
          Seven_Y ,
          Eight ,
          Eight_Y ,
          Nine ,
          Nine_Y ,
          Ten ,
          Ten_Y ,
          Eleven ,
          Eleven_Y ,
          Twelve ,
          Twelve_Y
        )

        SELECT ContractID
        , CASE WHEN MonthID = 1 AND 1 >= @FromMonth THEN [Normal] ELSE 0 END
        , CASE WHEN MonthID = 1 AND 1 >= @FromMonth THEN [Forecast] ELSE 0 END
        , CASE WHEN MonthID = 2 AND 2 >= @FromMonth THEN [Normal] ELSE 0 END
        , CASE WHEN MonthID = 2 AND 2 >= @FromMonth THEN [Forecast] ELSE 0 END
        , CASE WHEN MonthID = 3 AND 3 >= @FromMonth THEN [Normal] ELSE 0 END
        , CASE WHEN MonthID = 3 AND 3 >= @FromMonth THEN [Forecast] ELSE 0 END
        , CASE WHEN MonthID = 4 AND 4 >= @FromMonth THEN [Normal] ELSE 0 END
        , CASE WHEN MonthID = 4 AND 4 >= @FromMonth THEN [Forecast] ELSE 0 END
        , CASE WHEN MonthID = 5 AND 5 >= @FromMonth THEN [Normal] ELSE 0 END
        , CASE WHEN MonthID = 5 AND 5 >= @FromMonth THEN [Forecast] ELSE 0 END
        , CASE WHEN MonthID = 6 AND 6 >= @FromMonth THEN [Normal] ELSE 0 END
        , CASE WHEN MonthID = 6 AND 6 >= @FromMonth THEN [Forecast] ELSE 0 END
        , CASE WHEN MonthID = 7 AND 7 >= @FromMonth THEN [Normal] ELSE 0 END
        , CASE WHEN MonthID = 7 AND 7 >= @FromMonth THEN [Forecast] ELSE 0 END
        , CASE WHEN MonthID = 8 AND 8 >= @FromMonth THEN [Normal] ELSE 0 END
        , CASE WHEN MonthID = 8 AND 8 >= @FromMonth THEN [Forecast] ELSE 0 END
        , CASE WHEN MonthID = 9 AND 9 >= @FromMonth THEN [Normal] ELSE 0 END
        , CASE WHEN MonthID = 9 AND 9 >= @FromMonth THEN [Forecast] ELSE 0 END
        , CASE WHEN MonthID = 10 AND 10 >= @FromMonth THEN [Normal] ELSE 0 END
        , CASE WHEN MonthID = 10 AND 10 >= @FromMonth THEN [Forecast] ELSE 0 END
        , CASE WHEN MonthID = 11 AND 11 >= @FromMonth THEN [Normal] ELSE 0 END
        , CASE WHEN MonthID = 11 AND 11 >= @FromMonth THEN [Forecast] ELSE 0 END
        , CASE WHEN MonthID = 12 AND 12 >= @FromMonth THEN [Normal] ELSE 0 END
        , CASE WHEN MonthID = 12 AND 12 >= @FromMonth THEN [Forecast] ELSE 0 END
         FROM #unclosed
        GROUP BY ContractID



    --- SELECT * FROM   #contract

    DROP TABLE #dept, #month, #contract, #unclosed


GO


