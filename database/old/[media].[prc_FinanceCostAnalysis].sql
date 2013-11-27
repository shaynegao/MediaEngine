

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

    @GroupType CHAR(1) -- C:City D:Dept *:Detail


AS
  SET NOCOUNT ON

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
        One          decimal(18, 2) default(0),
        One_Y        decimal(18, 2) default(0),
        Two          decimal(18, 2) default(0),
        Two_Y        decimal(18, 2) default(0),
        Three        decimal(18, 2) default(0),
        Three_Y      decimal(18, 2) default(0),
        Four         decimal(18, 2) default(0),
        Four_Y       decimal(18, 2) default(0),
        Five         decimal(18, 2) default(0),
        Five_Y       decimal(18, 2) default(0),
        Six          decimal(18, 2) default(0),
        Six_Y        decimal(18, 2) default(0),
        Seven        decimal(18, 2) default(0),
        Seven_Y      decimal(18, 2) default(0),
        Eight        decimal(18, 2) default(0),
        Eight_Y      decimal(18, 2) default(0),
        Nine         decimal(18, 2) default(0),
        Nine_Y       decimal(18, 2) default(0),
        Ten          decimal(18, 2) default(0),
        Ten_Y        decimal(18, 2) default(0),
        Eleven       decimal(18, 2) default(0),
        Eleven_Y     decimal(18, 2) default(0),
        Twelve       decimal(18, 2) default(0),
        Twelve_Y     decimal(18, 2) default(0),
        Closed_TOT   decimal(18, 2) default(0),
        Year_Total   decimal(18, 2) default(0),
        Year_ExcludeForecast_Total decimal(18, 2) default(0)
      )

    IF @SelectDeptID IS NOT NULL
    BEGIN
        INSERT INTO #dept ( DeptID )
        SELECT D1.DeptID
        FROM [basic].[tbb_Department] D1
        JOIN basic.tbb_Department D2 ON D1.DeptNo LIKE  D2.DeptNo + '%'
        WHERE D2.DeptID = @SelectDeptID
    END

    -- prepare month
    INSERT INTO #month ( MonthID ,StartDate )
    SELECT 1, DATEADD(year, @SelectedYear - 1900, 0) UNION
    SELECT 2, DATEADD(MONTH, 1, DATEADD(year, @SelectedYear - 1900, 0)) UNION
    SELECT 3, DATEADD(MONTH, 2, DATEADD(year, @SelectedYear - 1900, 0)) UNION
    SELECT 4, DATEADD(MONTH, 3, DATEADD(year, @SelectedYear - 1900, 0)) UNION
    SELECT 5, DATEADD(MONTH, 4, DATEADD(year, @SelectedYear - 1900, 0)) UNION
    SELECT 6, DATEADD(MONTH, 5, DATEADD(year, @SelectedYear - 1900, 0)) UNION
    SELECT 7, DATEADD(MONTH, 6, DATEADD(year, @SelectedYear - 1900, 0)) UNION
    SELECT 8, DATEADD(MONTH, 7, DATEADD(year, @SelectedYear - 1900, 0)) UNION
    SELECT 9, DATEADD(MONTH, 8, DATEADD(year, @SelectedYear - 1900, 0)) UNION
    SELECT 10, DATEADD(MONTH, 9, DATEADD(year, @SelectedYear - 1900, 0)) UNION
    SELECT 11, DATEADD(MONTH, 10, DATEADD(year, @SelectedYear - 1900, 0)) UNION
    SELECT 12, DATEADD(MONTH, 11, DATEADD(year, @SelectedYear - 1900, 0))

    UPDATE #month SET EndDate = DATEADD(DAY, -1, DATEADD(MONTH, 1, StartDate)), AllDays = DAY(DATEADD(DAY, -1, DATEADD(MONTH, 1, StartDate)))

  -- SELECT * FROM #month
    INSERT INTO #contract ( ContractID )
    SELECT C.ContractID FROM media.tbb_Contract C
    JOIN media.tbb_Building B ON C.ItemID = B.BuildingID
    WHERE ISNULL(@SelectedSignCompanyID, C.SignCompanyID) = C.SignCompanyID
      AND (@SelectedPayCompanyID IS NULL OR (CASE WHEN @IsEqualPayCompanyID = 1 THEN C.PayCompanyID ELSE NULLIF(@SelectedPayCompanyID, C.PayCompanyID) END = @SelectedPayCompanyID ))
          AND (@SelectedCheckAccountID IS NULL OR (CASE WHEN @IsEqualCheckAccountID = 1 THEN C.CheckAccountID ELSE NULLIF(@SelectedCheckAccountID, C.CheckAccountID) END = @SelectedCheckAccountID ))
          AND (@SelectedDisplayType IS NULL OR (CASE WHEN @IsEqualDisplayType = 1 THEN C.DisplayType ELSE NULLIF(@SelectedDisplayType, C.DisplayType) END = @SelectedDisplayType ))
          AND (@SelectedCity IS NULL OR (CASE WHEN @IsEqualCity = 1 THEN B.CityID ELSE NULLIF(@SelectedCity, B.CityID) END = @SelectedCity ))
          AND (@SelectedBuildingType1 IS NULL OR (CASE WHEN @IsEqualBuildingType1 = 1 THEN B.BuildingType_1 ELSE NULLIF(@SelectedBuildingType1, B.BuildingType_1) END = @SelectedBuildingType1 ))
          AND (@SelectedBuildingLevel IS NULL OR (CASE WHEN @IsEqualBuildingLevel = 1 THEN B.BuildingLevel ELSE NULLIF(@SelectedBuildingLevel, B.BuildingLevel) END = @SelectedBuildingLevel ))
          AND (@SelectDeptID IS NULL OR C.DeptID IN (SELECT DeptID FROM  #dept))

  -- SELECT * FROM #contract

        INSERT INTO #t_res
            ( contract_id ,
              One , Two , Three , Four , Five , Six , Seven , Eight , Nine , Ten , Eleven , Twelve, Year_Total, Year_ExcludeForecast_Total)
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
            SUM(CASE WHEN CA.AmortizeMonth = 12 THEN AmortizeAmount END),
            SUM(AmortizeAmount), SUM(AmortizeAmount)

        FROM  media.tbs_CostAmortize CA
        WHERE CA.IsClose = 1
         AND CA.AmortizeType IN ('正常','预摊')
         AND CA.AmortizeYear = @SelectedYear
         GROUP BY CA.ContractID

    DECLARE @MaxSettled INT, @FromMonth INT
    SELECT @MaxSettled = MAX(CA.AmortizeMonth)
    FROM media.tbs_CostAmortize CA
    WHERE CA.IsClose = 1
        AND CA.AmortizeYear = @SelectedYear

    SET @FromMonth = ISNULL(@MaxSettled, 0) + 1
    PRINT @FromMonth

    IF @FromMonth <= 12
    BEGIN
      DELETE #month WHERE MonthID < @FromMonth

      SELECT
    C.ContractID,
    M.MonthID,
    C.RentAmount / (DATEDIFF(d, C.PerformBeginDate, C.PerformEndDate) + 1) * [media].[GetRangeDays](M.StartDate, M.EndDate, C.PerformBeginDate, C.PerformEndDate) AS [Normal],
    CASE WHEN C.DealStatus in (6, 10)  -- 续签,冻结不需要考虑预摊
    THEN 0
    ELSE (C.RentAmount / (DATEDIFF(d, C.PerformBeginDate, C.PerformEndDate) + 1) * CASE WHEN M.EndDate > C.PerformEndDate THEN DAY(M.EndDate) - [media].[GetRangeDays](M.StartDate, M.EndDate, C.PerformBeginDate, C.PerformEndDate) ELSE 0 END) END AS [Forecast]
    INTO #unclosed
    FROM media.tbb_Contract C, #month M
    WHERE C.DealStatus NOT IN (-1, 9) -- 终止

    INSERT INTO #t_res
    ( contract_id ,
      One , One_Y , Two , Two_Y , Three , Three_Y , Four , Four_Y , Five , Five_Y , Six , Six_Y ,
      Seven , Seven_Y , Eight , Eight_Y , Nine , Nine_Y , Ten , Ten_Y , Eleven , Eleven_Y , Twelve , Twelve_Y ,
      Year_Total, Year_ExcludeForecast_Total)

    SELECT ContractID
      , SUM(CASE WHEN MonthID = 1  THEN [Normal] ELSE 0 END)
        , SUM(CASE WHEN MonthID = 1  THEN [Forecast] ELSE 0 END)
        , SUM(CASE WHEN MonthID = 2  THEN [Normal] ELSE 0 END)
        , SUM(CASE WHEN MonthID = 2  THEN [Forecast] ELSE 0 END)
        , SUM(CASE WHEN MonthID = 3  THEN [Normal] ELSE 0 END)
        , SUM(CASE WHEN MonthID = 3  THEN [Forecast] ELSE 0 END)
        , SUM(CASE WHEN MonthID = 4  THEN [Normal] ELSE 0 END)
        , SUM(CASE WHEN MonthID = 4  THEN [Forecast] ELSE 0 END)
        , SUM(CASE WHEN MonthID = 5  THEN [Normal] ELSE 0 END)
        , SUM(CASE WHEN MonthID = 5  THEN [Forecast] ELSE 0 END)
        , SUM(CASE WHEN MonthID = 6  THEN [Normal] ELSE 0 END)
        , SUM(CASE WHEN MonthID = 6  THEN [Forecast] ELSE 0 END)
        , SUM(CASE WHEN MonthID = 7  THEN [Normal] ELSE 0 END)
        , SUM(CASE WHEN MonthID = 7  THEN [Forecast] ELSE 0 END)
        , SUM(CASE WHEN MonthID = 8  THEN [Normal] ELSE 0 END)
        , SUM(CASE WHEN MonthID = 8  THEN [Forecast] ELSE 0 END)
        , SUM(CASE WHEN MonthID = 9  THEN [Normal] ELSE 0 END)
        , SUM(CASE WHEN MonthID = 9  THEN [Forecast] ELSE 0 END)
        , SUM(CASE WHEN MonthID = 10 THEN [Normal] ELSE 0 END)
        , SUM(CASE WHEN MonthID = 10 THEN [Forecast] ELSE 0 END)
        , SUM(CASE WHEN MonthID = 11 THEN [Normal] ELSE 0 END)
        , SUM(CASE WHEN MonthID = 11 THEN [Forecast] ELSE 0 END)
        , SUM(CASE WHEN MonthID = 12 THEN [Normal] ELSE 0 END)
        , SUM(CASE WHEN MonthID = 12 THEN [Forecast] ELSE 0 END)
        , SUM(ISNULL([Normal], 0) + ISNULL([Forecast], 0))
        , SUM(ISNULL([Normal], 0))
     FROM #unclosed
    GROUP BY ContractID

    END


    IF @GroupType = 'C'
    BEGIN

      SELECT B.CityName AS GroupName, C.DisplayType,

      sum(One ) as One ,
      sum(One_Y ) as One_Y ,
      sum(Two ) as Two ,
      sum(Two_Y ) as Two_Y ,
      sum(Three ) as Three ,
      sum(Three_Y ) as Three_Y ,
      sum(Four ) as Four ,
      sum(Four_Y ) as Four_Y ,
      sum(Five ) as Five ,
      sum(Five_Y ) as Five_Y ,
      sum(Six ) as Six ,
      sum(Six_Y ) as Six_Y ,
      sum(Seven ) as Seven ,
      sum(Seven_Y ) as Seven_Y ,
      sum(Eight ) as Eight ,
      sum(Eight_Y ) as Eight_Y ,
      sum(Nine ) as Nine ,
      sum(Nine_Y ) as Nine_Y ,
      sum(Ten ) as Ten ,
      sum(Ten_Y ) as Ten_Y ,
      sum(Eleven ) as Eleven ,
      sum(Eleven_Y ) as Eleven_Y ,
      sum(Twelve ) as Twelve ,
      sum(Twelve_Y) as Twelve_Y,
      sum(Year_Total) as Year_Total,
      sum(Year_ExcludeForecast_Total)  as Year_ExcludeForecast_Total

      FROM #t_res T
      JOIN media.tbb_Contract C ON C.ContractID = T.contract_id
      JOIN media.tbb_Building B ON C.ItemID = B.BuildingID
      GROUP BY B.CityName, C.DisplayType


    END
    ELSE
    IF @GroupType = 'D'
  BEGIN

      SELECT C.DeptName AS GroupName, C.DisplayType,
        sum(One ) as One ,
      sum(One_Y ) as One_Y ,
      sum(Two ) as Two ,
      sum(Two_Y ) as Two_Y ,
      sum(Three ) as Three ,
      sum(Three_Y ) as Three_Y ,
      sum(Four ) as Four ,
      sum(Four_Y ) as Four_Y ,
      sum(Five ) as Five ,
      sum(Five_Y ) as Five_Y ,
      sum(Six ) as Six ,
      sum(Six_Y ) as Six_Y ,
      sum(Seven ) as Seven ,
      sum(Seven_Y ) as Seven_Y ,
      sum(Eight ) as Eight ,
      sum(Eight_Y ) as Eight_Y ,
      sum(Nine ) as Nine ,
      sum(Nine_Y ) as Nine_Y ,
      sum(Ten ) as Ten ,
      sum(Ten_Y ) as Ten_Y ,
      sum(Eleven ) as Eleven ,
      sum(Eleven_Y ) as Eleven_Y ,
      sum(Twelve ) as Twelve ,
      sum(Twelve_Y) as Twelve_Y,
        sum(Year_Total) as Year_Total,
      sum(Year_ExcludeForecast_Total)  as Year_ExcludeForecast_Total

       FROM #t_res T
      JOIN media.tbb_Contract C ON C.ContractID = T.contract_id
      GROUP BY C.DeptName, C.DisplayType
    END
    ELSE
    BEGIN
      SELECT * FROM #t_res
    END


    DROP TABLE #dept, #month, #contract, #t_res
    IF OBJECT_ID('tempdb..#unclosed') IS NOT NULL
    BEGIN
      DROP TABLE #unclosed
    END



GO


