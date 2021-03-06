IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[media].[prc_FinanceGetPagedPayable]') AND type in (N'P', N'PC'))
DROP PROCEDURE [media].[prc_FinanceGetPagedPayable]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[media].[prc_FinanceGetPagedPayable]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'




CREATE  procedure [media].[prc_FinanceGetPagedPayable] (
     @FilterDeveloperName      VARCHAR(30) = null,
     @FilterOperatorName       VARCHAR(30) = null,
     @FilterVendorID         bigint = null,
     @FilterApplyMethod      int = null,
     @FilterIsApplied        int = null,
     @FilterPayStatus        int = null,
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

    create table #t
    (
        rn  int identity(1,1),
        PlanPayID bigint,
        ContractID bigint,
        ContractCode varchar(100),
        BuildingName  varchar(100),
        OperatorName varchar(100),
        DeveloperName varchar(100),
        DeptName varchar(100),
        PayCompanyId   int,
        VendorID bigint,
        FeeType  varchar(100),
        PayAmount decimal(10,2),
        PaidAmount decimal(10,2),
        ExpectDate date,
        PayPeriodBegin date,
        PayPeriodEnd date,
        ContractStatus int,
        Memo  varchar(800),
        RecentScheduleID bigint,
        PayFrequency varchar(100),
        PayMethod varchar(100),
        DisplayType varchar(100)
    )
    


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

    if @FilterIsApplied is not null
    begin
        set @sqlFilter = @sqlFilter + '' and ((@FilterIsApplied = 1 and PBR.PayBillID is not null)
            OR (@FilterIsApplied = 0 and PBR.PayBillID is null)) ''
    end 

    if @FilterPayStatus is not null
    begin
        set @sqlFilter = @sqlFilter + '' and (((@FilterPayStatus & Power(2, 0)) > 0 and PP.PaidAmount = 0)
            OR ((@FilterPayStatus & Power(2, 1)) > 0 and PP.PayAmount = PP.PaidAmount)
            OR ((@FilterPayStatus & Power(2, 2)) > 0 and PP.PayAmount > PP.PaidAmount and PP.PaidAmount <> 0)) ''
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
        set @sqlP = @sqlP + '' and PA.ApplyDate >= @FilterApplyDateMin ''
    end

    if @FilterApplyDateMax is not null
    begin
        set @sqlP = @sqlP + '' and PA.ApplyDate <= @FilterApplyDateMax ''
    end

    if @FilterApplyMethod is not null
    begin
        set @sqlP = @sqlP + '' and PA.ApplyType = @FilterApplyMethod ''
    end

    if len(@sqlP) <> 0
    begin
        set @sqlFilter = @sqlFilter + '' and PP.PlanPayID in (select PlanPayID from media.tbb_PayApply PA where 1 = 1 '' +  @sqlP + '')''
    END
    
    set @sql = @sql + ''
insert into #t (
PlanPayID , ContractID, ContractCode, BuildingName , OperatorName , DeveloperName , DeptName, PayCompanyId, VendorID, FeeType, PayAmount, PaidAmount, ExpectDate, PayPeriodBegin, PayPeriodEnd, ContractStatus, Memo , PayFrequency, PayMethod, DisplayType )
select
    PP.PlanPayID , C.ContractID , C.ContractCode , C.ItemName , C.OperatorName , C.DeveloperName , C.DeptName , C.PayCompanyId , PP.VendorID , PP.FeeType , PP.PayAmount , PP.PaidAmount , PP.PlanPayDate , PP.FeeBeginDate , PP.FeeEndDate , C.DealStatus , PP.Memo , PP.PayWay , PP.PayKind , C.DisplayType 
     from media.tbb_PayPlan PP
    join media.tbb_Contract C on PP.ContractID = C.ContractID
    left join (
         select PlanPayID, max(PayBillID) as PayBillID  from media.tbb_PayApply PB1
         group by PlanPayID
       ) PBR on PP.PlanPayID = PBR.PlanPayID
    where
        (C.DealStatus = 3 OR C.DealStatus = 10) -- 执行中或续签
        AND C.IsSignFinished = 1
        and PP.ValidStatus = 0
            ''

    set @sql = @sql + @sqlFilter
    set @sql = @sql + '' order by PP.PlanPayID desc ''

    print @sql
    EXECUTE sp_executesql
    @sql
    , N''@FilterDeveloperName varchar(30), @FilterOperatorName varchar(30), @FilterOperatorID bigint, @FilterVendorID bigint, @FilterApplyMethod int, @FilterIsApplied int, @FilterPayStatus int, @FilterDeptID int, @FilterExpectDateMin date, @FilterExpectDateMax date, @FilterApplyDateMin date, @FilterApplyDateMax date, @FilterPayPeriodBeginMin date, @FilterPayPeriodBeginMax date, @FilterPayPeriodEndMin date, @FilterPayPeriodEndMax date, @FilterDisplayType varchar(50), @FilterContractCode varchar(50), @FilterFeeType
 varchar(20), @FilterBuildingID bigint, @SearchMode varchar(20)''
    , @FilterDeveloperName = @FilterDeveloperName
    , @FilterOperatorName = @FilterOperatorName
    , @FilterOperatorID = @FilterOperatorID
    , @FilterVendorID = @FilterVendorID
    , @FilterApplyMethod = @FilterApplyMethod
    , @FilterIsApplied = @FilterIsApplied
    , @FilterPayStatus = @FilterPayStatus
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

    select @TotalCount = COUNT(*) from #t

    SELECT T.PlanPayID, SUM(P.CloseAmount + R.CloseAmount) AS CloseAmount
    INTO #Closed
    FROM   #t T, 
    (
        SELECT PayBillID, PlanPayID, CloseAmount FROM  media.tbb_PayBill
        WHERE ValidStatus = 0
    ) P ,
    (    
    SELECT PayBillID, isnull(SUM(CloseAmount), 0) AS CloseAmount FROM  media.tbb_ReturnBill
    WHERE ValidStatus = 0
    GROUP BY PayBillID
    ) R   
    
    WHERE  T.rn > ( @PageIndex - 1 ) * @PageSize
           AND T.rn <= @PageSize * @PageIndex
           and T.PlanPayID = P.PlanPayID
           and P.PayBillID = R.PayBillID

    group by T.PlanPayID

    SELECT rn ,
            T.PlanPayID AS ID,
            T.ContractID ,
            T.ContractCode ,
            T.BuildingName ,
            T.OperatorName ,
            T.DeveloperName ,
            T.DeptName ,
            T.PayCompanyId ,
            T.VendorID ,
            V.VendorName as VendorName ,
            T.FeeType ,
            T.PayAmount ,
            T.PaidAmount ,
            T.ExpectDate ,
            T.PayPeriodBegin ,
            T.PayPeriodEnd ,
            T.ContractStatus ,
            T.Memo ,
            T.RecentScheduleID ,
            T.PayFrequency ,
            T.PayMethod ,
            T.DisplayType ,
            isnull(C.CloseAmount, 0) as CloseAmount
            
    FROM   #t T
    left join #Closed C on T.PlanPayID = C.PlanPayID
    left join media.tbb_Vendor V on V.VendorID  = T.VendorID
    
    WHERE  T.rn > ( @PageIndex - 1 ) * @PageSize
           AND T.rn <= @PageSize * @PageIndex
    order by rn

    drop table #dept
    drop table #t
    drop table #Closed

    set nocount off

end










' 
END
GO
