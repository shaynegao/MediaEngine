IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[media].[prc_FinanceGetPagedPayment]') AND type in (N'P', N'PC'))
DROP PROCEDURE [media].[prc_FinanceGetPagedPayment]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[media].[prc_FinanceGetPagedPayment]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'

create procedure [media].[prc_FinanceGetPagedPayment] @FilterContractCode   varchar(50) = ''%'',
     -- 部门
     @FilterDeptID           int = null,
     -- 合同类型
     @FilterDisplayType    varchar(50) = null,
     -- 项目
     @FilterBuildingID     bigint = null,
     -- 开发人员
     @FilterDeveloperName      varchar(50) = null,
     -- 维护人员
     @FilterOperatorName       varchar(50) = null,
     -- 实际付款日期
     @FilterPayDateMin  date = null,
     @FilterPayDateMax  date = null,
     -- 付费开始日期
     @FilterPayPeriodBeginMin date = null,
     @FilterPayPeriodBeginMax date = null,
     -- 付费结束日期
     @FilterPayPeriodEndMin date = null,
     @FilterPayPeriodEndMax date = null,
     -- 费用类别
     @FilterFeeType        varchar(20) = null,
     -- 支付主体
     @FilterVendorID         bigint = null,
     -- 是否有退款
     @FilterHasRefund         int = null,
     -- 开票情况
     @FilterInvoiceStatus int = null,
 
     @UserID               bigint,
     @SearchMode           varchar(20),
     @PageSize             int,
     @PageIndex            int,
     @TotalCount           int output as
begin
    set nocount on

    DECLARE @FilterOperatorID BIGINT

    -- Parameter Adjust

    if @FilterDisplayType = ''''
        set @FilterDisplayType = null
    if @FilterFeeType = ''''
      set @FilterFeeType = NULL
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

    select @sql = '''', @sqlFilter = ''''

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

    if @FilterPayDateMin is not null
    begin
        set @sqlFilter = @sqlFilter + '' and PB.PayDate >= @FilterPayDateMin ''
    end

    if @FilterPayDateMax is not null
    begin
        set @sqlFilter = @sqlFilter + '' and PB.PayDate <= @FilterPayDateMax ''
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

    create table #T
    (
      rn  int identity(1,1),
      PaymentID   bigint,
      --合同号
      ContractCode varchar(30),
      --项目名称
      BuildingName   varchar(100),
      --部门
      DeptName   varchar(100),
      --维护人员
      OperatorName  varchar(100),
      --计划支付时间
      ExpectDate date,
      --实际付款日期
      ActualPayDate   date,
      --实际付款金额
      ActualPayAmount decimal(10,2),

      --费用类别
      FeeType varchar(20),
      -- 开票金额
      ClosedAmount  decimal(10,2),

      -- --结算方式
      -- PayMethod varchar(20),
      -- --银行科目代码
      -- SubjectID varchar(100),
      -- --合同类型
      -- DisplayType varchar(20),
      -- --合同状态
      -- [State]   varchar(20),
	  ReturnAmount  decimal(10,2),
      --付费开始时间
      PayPeriodBegin date,
      --付费截止时间
      PayPeriodEnd date,
      --支付主体
      VendorName varchar(100)
    )

    set @sql = @sql + ''
   INSERT INTO #t
            (PaymentID, ContractCode, BuildingName, DeptName, OperatorName, ExpectDate, ActualPayDate,
              ActualPayAmount, FeeType, ClosedAmount, ReturnAmount, PayPeriodBegin, PayPeriodEnd, VendorName)
              
    select
        PB.PayBillID
        ,C.ContractCode
        , C.ItemName
        , C.DeptName
        , C.OperatorName
        , PP.PlanPayDate
        , PB.PayDate
        , PB.PayAmount
        , PP.FeeType
        , PB.CloseAmount
        , PB.ReturnAmount
        , PP.FeeBeginDate
        , PP.FeeEndDate
        , V.VendorName

    From media.tbb_paybill PB
    join media.tbb_PayPlan PP on PB.PlanPayID = PP.PlanPayID
    join media.tbb_Contract C on PP.ContractID = C.ContractID
    left join media.tbb_Vendor V on PP.VendorID = V.VendorID
    where
        (C.DealStatus = 3 OR C.DealStatus = 10) -- 执行中或续签
        AND C.IsSignFinished = 1
        AND PB.ValidStatus = 0
        AND PP.ValidStatus = 0
            ''

    set @sql = @sql + @sqlFilter
    set @sql = @sql + '' ORDER  BY PB.PayDate desc, C.ContractCode  ''

    --print @sql
    EXECUTE sp_executesql
    @sql
    , N''@FilterDeveloperName varchar(30), @FilterOperatorName varchar(30), @FilterOperatorID bigint, @FilterVendorID bigint,  @FilterDeptID int, @FilterPayDateMin date, @FilterPayDateMax date, @FilterPayPeriodBeginMin date, @FilterPayPeriodBeginMax date, @FilterPayPeriodEndMin date, @FilterPayPeriodEndMax date, @FilterDisplayType varchar(50), @FilterContractCode varchar(50), @FilterFeeType
 varchar(20), @FilterBuildingID bigint, @SearchMode varchar(20)''
    , @FilterDeveloperName = @FilterDeveloperName
    , @FilterOperatorName = @FilterOperatorName
    , @FilterOperatorID = @FilterOperatorID
    , @FilterVendorID = @FilterVendorID
    , @FilterDeptID = @FilterDeptID
    , @FilterPayDateMin = @FilterPayDateMin
    , @FilterPayDateMax = @FilterPayDateMax
    , @FilterPayPeriodBeginMin = @FilterPayPeriodBeginMin
    , @FilterPayPeriodBeginMax = @FilterPayPeriodBeginMax
    , @FilterPayPeriodEndMin = @FilterPayPeriodEndMin
    , @FilterPayPeriodEndMax = @FilterPayPeriodEndMax
    , @FilterDisplayType = @FilterDisplayType
    , @FilterContractCode = @FilterContractCode
    , @FilterFeeType = @FilterFeeType
    , @FilterBuildingID = @FilterBuildingID
    , @SearchMode = @SearchMode

    select @TotalCount = COUNT(*) from #T

    SELECT *
    FROM   #t T
    WHERE  T.rn > ( @PageIndex - 1 ) * @PageSize
           AND T.rn <= @PageSize * @PageIndex
    order by rn

	drop table #dept, #T

  set nocount off

end
' 
END
GO
