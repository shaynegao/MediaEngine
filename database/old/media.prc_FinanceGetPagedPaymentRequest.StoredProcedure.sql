IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[media].[prc_FinanceGetPagedPaymentRequest]') AND type in (N'P', N'PC'))
DROP PROCEDURE [media].[prc_FinanceGetPagedPaymentRequest]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[media].[prc_FinanceGetPagedPaymentRequest]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'




CREATE procedure [media].[prc_FinanceGetPagedPaymentRequest] (
	 @FilterMPPID				int = null,
     @FilterDeveloperName      VARCHAR(30) = null,
     @FilterOperatorName       VARCHAR(30) = null,
     @FilterVendorID         bigint = null,
     @FilterApplyMethod      int = null,
     @FilterScheduleStatus        int = null,
     @FilterDeptID           int = null,
     @FilterExpectDateMin  date = null,
     @FilterExpectDateMax  date = null,
     @FilterApplyDateMin   date = null,
     @FilterApplyDateMax   date = null,
     @FilterPayPeriodBeginMin date = null,
     @FilterPayPeriodBeginMax date = null,
     @FilterPayPeriodEndMin date = null,
     @FilterPayPeriodEndMax date = null,
     @FilterDisplayType    varchar(50) = null,
     @FilterContractCode   varchar(50) = ''%'',
     @FilterFeeType        varchar(20) = null,
     @FilterBuildingID     bigint = null,
     @FilterPayCompanyID   INT = NULL,
     @UserID               bigint,
     @SearchMode           varchar(20),
     @PageSize             int,
     @PageIndex            int,
     @TotalCount           int output
 ) as
begin
    set nocount on

    DECLARE @FilterOperatorID BIGINT

    -- Parameter Adjust

    if @FilterDisplayType = ''''
        set @FilterDisplayType = null
    if  @FilterContractCode is null or @FilterContractCode = ''''
        set @FilterContractCode = ''%''


    -- Dept 

    CREATE TABLE #dept (DeptID  INT)
            
    if LOWER(@SearchMode) = ''my''
        BEGIN
            set @FilterOperatorID = @UserID

            INSERT INTO #dept (DeptID)
			SELECT U.DeptID
			FROM basic.tbb_User U 
			WHERE U.UserID = @UserID
        END 
    else    
    IF LOWER(@SearchMode) = ''mydept''
        BEGIN
            INSERT INTO #dept (DeptID)
            SELECT DISTINCT D1.DeptID FROM basic.tbb_Department D 
                JOIN basic.tbb_User U ON D.DeptID = U.DeptID
                JOIN basic.tbb_Department D1 ON D1.DeptNo LIKE D.DeptNo + ''%''
            WHERE U.UserID = @UserID
        END
    else
    IF LOWER(@SearchMode) = ''finance''
        BEGIN
            INSERT INTO #dept (DeptID)
            SELECT DISTINCT DeptID FROM  basic.VW_UserDept WHERE UserID = @UserID
        END 
        
    IF LOWER(@SearchMode) = ''all''
        BEGIN
            INSERT INTO #dept (DeptID)
            SELECT DISTINCT DeptID FROM basic.tbb_Department
        END 

    IF ISNULL(@FilterDeptID, 0) <> 0
    BEGIN
    
        DELETE D
        FROM #dept D
        WHERE D.DeptID NOT IN (
            SELECT D2.DeptID FROM basic.tbb_Department D1
            JOIN basic.tbb_Department D2 ON D2.DeptNo LIKE D1.DeptNo + ''%''
            WHERE D1.DeptID = @FilterDeptID
        )
    
    END

    declare @sql        nvarchar(max)
    declare @sqlFilter  nvarchar(1000)
    declare @sqlP       nvarchar(200)

    select @sql = '''', @sqlFilter = '''', @sqlP = ''''


    if ISNULL(@FilterMPPID, 0) <> 0
    BEGIN
        set @sqlFilter = @sqlFilter + '' and PA.ApplyBatchID = @FilterMPPID ''
    end 

    if ISNULL(@FilterDeveloperName, '''') <> ''''
    BEGIN
        SET @FilterDeveloperName = ''%'' + @FilterDeveloperName + ''%''
        set @sqlFilter = @sqlFilter + '' and C.DeveloperName like @FilterDeveloperName ''
    end 
    if ISNULL(@FilterOperatorName, '''') <> ''''
    BEGIN
        SET @FilterOperatorName = ''%'' + @FilterOperatorName + ''%''
        set @sqlFilter = @sqlFilter + '' and C.OperatorName like  @FilterOperatorName ''
    end 
    if @FilterOperatorID is not null
    begin
        set @sqlFilter = @sqlFilter + '' and C.OperatorID = @FilterOperatorID ''
    end 

    if @FilterBuildingID is not null
    begin
        -- set @sqlFilter = @sqlFilter + '' and C.ItemID = @FilterBuildingID ''
        set @sqlFilter = @sqlFilter + '' and C.ContractID in (select ContractID from media.tbr_Contract_Building where ValidStatus = 0 AND BuildingID = @FilterBuildingID ) ''
    end 
    
    if @FilterContractCode <> ''%''
    begin
        set @sqlFilter = @sqlFilter + '' and C.ContractCode like @FilterContractCode ''
    end 

    if @FilterDisplayType is not null
    begin
        set @sqlFilter = @sqlFilter + '' and C.DisplayType = @FilterDisplayType ''
    end 

    if @FilterPayCompanyID is not null
    begin
        set @sqlFilter = @sqlFilter + '' and C.PayCompanyID = @FilterPayCompanyID ''
    end 

    --if (LOWER(@SearchMode) = ''mydept'' OR LOWER(@SearchMode) = ''finance'' OR LOWER(@SearchMode) = ''all'')
    --begin
        set @sqlFilter = @sqlFilter + '' and C.DeptID IN (SELECT DeptID FROM #dept) ''
    --end 

    if @FilterVendorID is not null
    begin
        set @sqlFilter = @sqlFilter + '' and PP.VendorID = @FilterVendorID ''
    end 
    if @FilterFeeType is not null
    begin
        set @sqlFilter = @sqlFilter + '' and PP.FeeType = @FilterFeeType ''
    end 

    if @FilterScheduleStatus is not null
    begin
        set @sqlFilter = @sqlFilter + '' and (((@FilterScheduleStatus & Power(2, 0)) > 0 and PA.AuditStatus = 0)
            OR ((@FilterScheduleStatus & Power(2, 1)) > 0 and PA.AuditStatus = 1)
            OR ((@FilterScheduleStatus & Power(2, 2)) > 0 and PA.AuditStatus = 2)
            OR ((@FilterScheduleStatus & Power(2, 3)) > 0 and PA.AuditStatus in (3,4,5))
            ) ''
    end 

    if @FilterExpectDateMin is not null
    begin
        set @sqlFilter = @sqlFilter + '' and PP.PlanPayDate >= @FilterExpectDateMin ''
    end

    if @FilterExpectDateMax is not null
    begin
        set @sqlFilter = @sqlFilter + '' and PP.PlanPayDate <= @FilterExpectDateMax ''
    end


    if @FilterPayPeriodBeginMin is not null
    begin
        set @sqlFilter = @sqlFilter + '' and PP.FeeBeginDate >= @FilterPayPeriodBeginMin ''
    end

    if @FilterPayPeriodBeginMax is not null
    begin
        set @sqlFilter = @sqlFilter + '' and PP.FeeBeginDate <= @FilterPayPeriodBeginMax ''
    end
    
    if @FilterPayPeriodEndMin is not null
    begin
        set @sqlFilter = @sqlFilter + '' and PP.FeeEndDate >= @FilterPayPeriodEndMin ''
    end

    if @FilterPayPeriodEndMax is not null
    begin
        set @sqlFilter = @sqlFilter + '' and PP.FeeEndDate <= @FilterPayPeriodEndMax ''
    end
    
    if @FilterApplyDateMin is not null
    begin
        set @sqlP = @sqlP + '' and PA1.ApplyDate >= @FilterApplyDateMin ''
    end

    if @FilterApplyDateMax is not null
    begin
        set @sqlP = @sqlP + '' and PA1.ApplyDate <= @FilterApplyDateMax ''
    end

    if @FilterApplyMethod is not null
    begin
        set @sqlP = @sqlP + '' and PA1.ApplyType = @FilterApplyMethod ''
    end

    if len(@sqlP) <> 0
    begin
        set @sqlFilter = @sqlFilter + '' and PA.PayBillID in (select PayBillID from media.tbb_PayApply PA1 where 1 = 1 '' +  @sqlP + '')''
    end

    create table #t
    (
        rn  int identity(1,1) PRIMARY KEY,
        ID bigint,
        PlanPayID bigint,
        ContractCode varchar(100),
        BuildingName  varchar(100),
        OperatorName varchar(100),
        DeptName varchar(100),
        PayCompanyId int,
        VendorID bigint,
        FeeType  varchar(100),
        PayAmount decimal(10,2),
        ExpectDate date,
        PayPeriodBegin date,
        PayPeriodEnd date,
        ContractStatus int,
        PayeeBankName varchar(100),
        PayeeName varchar(100),
        PayeeAccountNumber varchar(100),
        Memo  varchar(800),
        ScheduleStatus int,
        ScheduleApplyDate date,
        ScheduleApplyType INT,
        ScheduleAuditDate datetime,
        ActualPayMethod VARCHAR(50),
        PayFrequency    VARCHAR(50),
        MatchAccountText  VARCHAR(50),
        SignedLocationCount  INT, 
        UsableCount INT 
    )   

    set @sql = @sql + ''
insert into #t (
ID , PlanPayID, ContractCode, BuildingName , OperatorName , DeptName, PayCompanyId, VendorID , FeeType, PayAmount, ExpectDate, PayPeriodBegin, PayPeriodEnd, ContractStatus, PayeeBankName , PayeeName , PayeeAccountNumber, Memo , ScheduleStatus, ScheduleApplyDate, ScheduleApplyType, ScheduleAuditDate, ActualPayMethod, PayFrequency, MatchAccountText, SignedLocationCount, UsableCount )
select
    PA.PayBillID , PA.PlanPayID , C.ContractCode , C.ItemName , C.OperatorName , C.DeptName , C.PayCompanyId , PP.VendorID,  PP.FeeType , PA.PayAmount , PP.PlanPayDate , PP.FeeBeginDate , PP.FeeEndDate , C.DealStatus , AX.AccountBank , AX.AccountName , AX.AccountNumber , PP.Memo , PA.AuditStatus , PA.ApplyDate , PA.ApplyType , PA.AuditTime , PA.PayKind , PP.PayWay , C.CheckAccount , C.SignedLocationCount , C.SignedLocationCount - C.PresentOwnsCount - C.PresentUsingCount
    from media.tbb_PayPlan PP
    join media.tbb_Contract C on PP.ContractID = C.ContractID
    join media.tbb_PayApply PA on PA.PlanPayID = PP.PlanPayID
    left join media.tbi_PayAccount AX on AX.PayBillID = PA.PayBillID
    where
        (C.DealStatus = 3 OR C.DealStatus = 10) -- 执行中或续签
        AND C.IsSignFinished = 1
        AND PP.ValidStatus = 0
            ''

    set @sql = @sql + @sqlFilter
    set @sql = @sql + '' ORDER BY PA.PayBillID DESC  ''

    print @sql
    EXECUTE sp_executesql
    @sql
    , N''@FilterMPPID int, @FilterPayCompanyID int, @FilterDeveloperName varchar(30), @FilterOperatorName varchar(30), @FilterOperatorID bigint, @FilterVendorID bigint, @FilterApplyMethod int, @FilterScheduleStatus int, @FilterDeptID int, @FilterExpectDateMin date, @FilterExpectDateMax date, @FilterApplyDateMin date, @FilterApplyDateMax date, @FilterPayPeriodBeginMin date, @FilterPayPeriodBeginMax date, @FilterPayPeriodEndMin date, @FilterPayPeriodEndMax date, @FilterDisplayType varchar(50), @FilterContractCode varchar(50), @FilterFeeType
 varchar(20), @FilterBuildingID bigint, @SearchMode varchar(20)''
	, @FilterMPPID = @FilterMPPID
    , @FilterDeveloperName = @FilterDeveloperName
    , @FilterOperatorName = @FilterOperatorName
    , @FilterOperatorID = @FilterOperatorID
    , @FilterVendorID = @FilterVendorID
    , @FilterApplyMethod = @FilterApplyMethod
    , @FilterScheduleStatus = @FilterScheduleStatus
    , @FilterDeptID = @FilterDeptID
    , @FilterExpectDateMin = @FilterExpectDateMin
    , @FilterExpectDateMax = @FilterExpectDateMax
    , @FilterApplyDateMin = @FilterApplyDateMin
    , @FilterApplyDateMax = @FilterApplyDateMax
    , @FilterPayPeriodBeginMin = @FilterPayPeriodBeginMin
    , @FilterPayPeriodBeginMax = @FilterPayPeriodBeginMax
    , @FilterPayPeriodEndMin = @FilterPayPeriodEndMin
    , @FilterPayPeriodEndMax = @FilterPayPeriodEndMax
    , @FilterDisplayType = @FilterDisplayType
    , @FilterContractCode = @FilterContractCode
    , @FilterFeeType = @FilterFeeType
    , @FilterBuildingID = @FilterBuildingID
    , @SearchMode = @SearchMode
    , @FilterPayCompanyID = @FilterPayCompanyID
        
    select @TotalCount = COUNT(*) from #t

    SELECT  T.rn ,
            T.ID ,
            T.PlanPayID ,
            T.ContractCode ,
            T.BuildingName ,
            T.OperatorName ,
            T.DeptName ,
            T.PayCompanyId ,
            T.VendorID ,
            T.FeeType ,
            T.PayAmount ,
            T.ExpectDate ,
            T.PayPeriodBegin ,
            T.PayPeriodEnd ,
            T.ContractStatus ,
            T.PayeeBankName ,
            T.PayeeName ,
            T.PayeeAccountNumber ,
            T.Memo ,
            T.ScheduleStatus ,
            T.ScheduleApplyDate ,
            T.ScheduleApplyType ,
            T.ScheduleAuditDate ,
            T.ActualPayMethod ,
            T.PayFrequency ,
            T.MatchAccountText ,
            T.SignedLocationCount ,
            T.UsableCount,
            V.VendorName
    FROM   #t T 
    LEFT join media.tbb_Vendor V on V.VendorID  = T.VendorID
    WHERE  T.rn > ( @PageIndex - 1 ) * @PageSize 
           AND T.rn <= @PageSize * @PageIndex 
    ORDER BY T.rn
    
    drop table #dept, #t   
        
    set nocount off  

end














' 
END
GO
