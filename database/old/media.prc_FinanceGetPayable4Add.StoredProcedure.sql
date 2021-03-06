IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[media].[prc_FinanceGetPayable4Add]') AND type in (N'P', N'PC'))
DROP PROCEDURE [media].[prc_FinanceGetPayable4Add]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[media].[prc_FinanceGetPayable4Add]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'

create procedure [media].[prc_FinanceGetPayable4Add] @FilterPayCompanyID	int,
  	@FilterDeptID			bigint,
  	@FilterExpectDateMin  date,
  	@FilterExpectDateMax  date,
  	@FilterDisplayType    varchar(50) = null,
  	@FilterContractCode   varchar(50) = ''%'',
  	@FilterFeeType	    varchar(20) = null,
  	@FilterBuildingID   bigint = null,
  	@FilterInstallCond    int = null,
  	@UserID               bigint as
begin
	set nocount on

    -- Dept 
    CREATE TABLE #dept (DeptID  INT)
            
    INSERT INTO #dept (DeptID)
    SELECT DISTINCT DeptID FROM  basic.VW_UserDept WHERE UserID = @UserID
      
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

    set @sqlFilter = @sqlFilter + '' and C.DeptID IN (SELECT DeptID FROM #dept) ''

    if @FilterFeeType is not null
    begin
        set @sqlFilter = @sqlFilter + '' and PP.FeeType = @FilterFeeType ''
    end 

    if @FilterExpectDateMin is not null
    begin
        set @sqlFilter = @sqlFilter + '' and PP.PlanPayDate >= @FilterExpectDateMin ''
    end

    if @FilterExpectDateMax is not null
    begin
        set @sqlFilter = @sqlFilter + '' and PP.PlanPayDate <= @FilterExpectDateMax ''
    end

    set @sql = @sql + ''

	select
	PP.PlanPayID
	-- 合同编号
	, C.ContractID
	, C.ContractCode
	-- 项目
	, C.ItemName as BuildingName
	-- 维护人员
	, C.DeveloperName
	, C.OperatorName
	-- 部门
	, C.DeptName
	-- 付费主体
	, C.PayCompanyID
	, PC.PayCompanyName
	-- 支付主体
	, V.VendorID
	, V.VendorName
	-- 费用类别
	, PP.FeeType
	-- 支付金额
	, PP.PayAmount
	, PP.PaidAmount
	-- 计划支付日期
	, PP.PlanPayDate as ExpectDate
	-- 付费开始日期
	, PP.FeeBeginDate as PayPeriodBegin
	-- 付费结束日期
	, PP.FeeEndDate as PayPeriodEnd
	-- 合同状态
	, C.DealStatus as ContractStatus
	-- 公司可用媒体数
	, ISNULL(GC.UsableCnt, 0) as UsableCnt
	-- 已安装数
	, ISNULL(GC.InstalledCnt, 0) as InstalledCnt
	-- 临时拆机数
	, ISNULL(GC.TempUninstallCnt, 0) as TempUninstallCnt
	-- 开户行
	, AX.AccountBank as PayeeBankName
	-- 用户名
	, AX.AccountName as PayeeAccountNumber
	-- 账号
	, AX.AccountNumber as PayeeName
	-- 备注
	, PP.Memo
	 from media.tbb_PayPlan PP
	join media.tbb_Contract C on PP.ContractID = C.ContractID
	join media.tbb_Vendor V on V.VendorID  = PP.VendorID
	JOIN basic.tbb_PayCompany PC ON C.PayCompanyID = PC.PayCompanyID
	LEFT JOIN (
	
		SELECT C.ContractID, (C.SignedLocationCount  - C.PresentUsingCount 
		 - C.PresentOwnsCount ) AS UsableCnt, Install.InstalledCnt, Install.TempUninstallCnt
		FROM media.tbb_Contract C
		LEFT JOIN (
			SELECT CML.ContractID,
			SUM(CASE WHEN MB.InstallStatus = 1 THEN 1 ELSE 0 END) AS InstalledCnt,
			SUM(CASE WHEN MB.InstallStatus = 2 THEN 1 ELSE 0 END) AS TempUninstallCnt
			FROM media.tbr_Contract_MediaLocation  CML 
			JOIN media.tbb_MediaLocation ML ON CML.LocationID = ML.LocationID
			JOIN assemble.tbb_MediaDevice MB ON ML.LocationID = MB.LocationID
			GROUP BY CML.ContractID )
		 Install ON C.ContractID = Install.ContractID
	
	) GC ON GC.ContractID = C.ContractID	
	left join (
		 select PPA.PlanPayID, VA.AccountBank, VA.AccountName, VA.AccountNumber 
		 from media.tbb_VendorAccount VA join media.tbi_PlanPayAccount PPA
			on VA.AccountID = PPA.AccountID
		) AX on AX.PlanPayID = PP.PlanPayID
		
	
	where 
 		(C.DealStatus = 3 OR C.DealStatus = 10) -- 执行中或续签
        AND C.IsSignFinished = 1
		AND (PP.PayAmount - PP.CloseAmount) > PP.PaidAmount -- 有未付金额
		AND PP.ValidStatus = 0
		and not exists (select 1  from media.tbb_PayApply PA
			where (PA.auditstatus = 0 OR PA.auditstatus = 1 ) and PA.PlanPayID = PP.PlanPayID)
		AND (@FilterInstallCond IS NULL 
			OR (@FilterInstallCond = 1 AND GC.UsableCnt <= ISNULL(GC.InstalledCnt, 0))
			OR (@FilterInstallCond = 2 AND GC.UsableCnt >= ISNULL(GC.InstalledCnt, 0) + ISNULL(GC.TempUninstallCnt, 0))
		)
            ''

    set @sql = @sql + @sqlFilter
    set @sql = @sql + '' ORDER BY PP.PlanPayID DESC  ''

    print @sql
    EXECUTE sp_executesql
    @sql
    , N''@FilterInstallCond int, @FilterDeptID int, @FilterExpectDateMin date, @FilterExpectDateMax date, @FilterDisplayType varchar(50), @FilterContractCode varchar(50), @FilterFeeType
 varchar(20), @FilterBuildingID bigint, @FilterPayCompanyID int''
    , @FilterInstallCond = @FilterInstallCond
    , @FilterDeptID = @FilterDeptID
    , @FilterExpectDateMin = @FilterExpectDateMin
    , @FilterExpectDateMax = @FilterExpectDateMax
    , @FilterDisplayType = @FilterDisplayType
    , @FilterContractCode = @FilterContractCode
    , @FilterFeeType = @FilterFeeType
    , @FilterBuildingID = @FilterBuildingID
    , @FilterPayCompanyID = @FilterPayCompanyID





	drop table #dept


end
' 
END
GO
