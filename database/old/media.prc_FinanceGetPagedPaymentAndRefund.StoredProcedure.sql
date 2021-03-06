IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[media].[prc_FinanceGetPagedPaymentAndRefund]') AND type in (N'P', N'PC'))
DROP PROCEDURE [media].[prc_FinanceGetPagedPaymentAndRefund]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[media].[prc_FinanceGetPagedPaymentAndRefund]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'

create procedure [media].[prc_FinanceGetPagedPaymentAndRefund] @FilterPlanPayID   bigint = null,
       -- 付费主体
       @FilterPayCompanyID   varchar(50) = null,
       -- 支付主体
       @FilterVendorID         bigint = null,
       -- 费用类别
       @FilterFeeType        varchar(20) = null,
       -- 实际付款日期
       @FilterPayDateMin  date = null,
       @FilterPayDateMax  date = null,
       -- 支付类型
       @FilterPayMethods       varchar(100) = null,
       -- 合同编号
       @FilterContractCode   varchar(50) = ''%'',
       -- 项目
       @FilterBuildingID     bigint = null,
       -- 付费开始日期
       @FilterPayPeriodBeginMin date = null,
       @FilterPayPeriodBeginMax date = null,
       -- 付费结束日期
       @FilterPayPeriodEndMin date = null,
       @FilterPayPeriodEndMax date = null,
 
       @UserID               bigint,
       @SearchMode           varchar(20),
       @PageSize             int,
       @PageIndex            int,
       @TotalCount           int output as
begin
      set nocount on

      DECLARE @FilterOperatorID BIGINT

      -- Parameter Adjust
      if  @FilterContractCode is null or @FilterContractCode = ''''
          set @FilterContractCode = ''%''
      if @FilterFeeType = ''''
          set @FilterFeeType = null

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


      declare @sql        nvarchar(max)
      declare @sqlFilter  nvarchar(1000)
      declare @sqlP       nvarchar(200)

      select @sql = '''', @sqlFilter = '''', @sqlP = ''''

      if @FilterOperatorID is not null
      begin
          set @sqlFilter = @sqlFilter + '' and C.OperatorID = @FilterOperatorID ''
      end 

	  if @FilterBuildingID is not null
		begin
			-- set @sqlFilter = @sqlFilter + '' and C.ItemID = @FilterBuildingID ''
			set @sqlFilter = @sqlFilter + '' and C.ContractID in (select ContractID from media.tbr_Contract_Building where ValidStatus = 1 AND BuildingID = @FilterBuildingID ) ''
		end 

      if @FilterContractCode <> ''%''
      begin
          set @sqlFilter = @sqlFilter + '' and C.ContractCode like @FilterContractCode ''
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
      if @FilterPlanPayID is not null
      begin
          set @sqlFilter = @sqlFilter + '' and PP.PlanPayID = @FilterPlanPayID ''
      end

     create table #T
     (
       rn  int identity(1,1),
       CombinedID   VARCHAR(30),
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
       
       ActualPayeeBankName VARCHAR(100),
       ActualPayeeName VARCHAR(100),
       ActualPayeeAccountNumber VARCHAR(44),
       ActualPayMethod VARCHAR(50),
       
       PayCompanyId int,
       PayCompanyName VARCHAR(100),
       --费用类别
       FeeType varchar(20),
       -- 未开票金额
       UnInvoiceAmount  decimal(10,2),

       --付费开始时间
       PayPeriodBegin date,
       --付费截止时间
       PayPeriodEnd date,
       --支付主体
       VendorName varchar(100)
     )



      set @sql = @sql + ''


     INSERT INTO #t
             (CombinedID, ContractCode, BuildingName, DeptName, OperatorName, ExpectDate, ActualPayDate,
               ActualPayAmount, ActualPayeeBankName, ActualPayeeName, ActualPayeeAccountNumber, ActualPayMethod, 
               FeeType, PayPeriodBegin, PayPeriodEnd, VendorName, UnInvoiceAmount, PayCompanyId, PayCompanyName)

   select CombinedID, ContractCode, BuildingName, DeptName, OperatorName, ExpectDate, ActualPayDate,
               ActualPayAmount, ActualPayeeBankName, ActualPayeeName, ActualPayeeAccountNumber, ActualPayMethod, 
               FeeType, PayPeriodBegin, PayPeriodEnd, VendorName, UnInvoiceAmount, PayCompanyId, PayCompanyName from (

     select
         ''''P'''' + CAST(PB.PayBillID AS VARCHAR(29)) as CombinedID
         ,C.ContractCode
         , C.ItemName as BuildingName
        , C.DeptName
         , C.OperatorName
         , PP.PlanPayDate as ExpectDate
         , PB.PayDate as ActualPayDate
         , PB.PayAmount as ActualPayAmount
         , PA.AccountBank as ActualPayeeBankName
         , PA.AccountName as ActualPayeeName
         , PA.AccountNumber as ActualPayeeAccountNumber
         , PB.PayKind as ActualPayMethod
         , PP.FeeType
         , PP.FeeBeginDate as PayPeriodBegin
         , PP.FeeEndDate as PayPeriodEnd
         , V.VendorName
         , (PB.PayAmount - PB.CloseAmount) as UnInvoiceAmount
         , C.PayCompanyId
       , PC.PayCompanyName
     From media.tbb_paybill PB
     join media.tbb_PayPlan PP on PB.PlanPayID = PP.PlanPayID
     join media.tbb_Contract C on PP.ContractID = C.ContractID
     left join media.tbb_Vendor V on PP.VendorID = V.VendorID
     LEFT JOIN media.tbi_PayAccount PA ON PB.PayBillID = PA.PayBillID
     LEFT JOIN basic.tbb_PayCompany PC ON PC.PayCompanyID = C.PayCompanyId
     where 
      (C.DealStatus = 3 OR C.DealStatus = 10) -- 执行中或续签
       AND C.IsSignFinished = 1
       AND PP.ValidStatus = 0
       and PB.ValidStatus = 0
       and (PB.PayDate >= isnull(@FilterPayDateMin, PB.PayDate) AND PB.PayDate <= isnull(@FilterPayDateMax, PB.PayDate))
       and (isnull(@FilterPayMethods, '''''''') = '''''''' OR PB.PayKind in (select a from [media].[f_split](@FilterPayMethods,'''','''')))

       '' + @sqlFilter
       + ''union all
   select
         ''''R'''' + CAST(RB.ReturnBillID AS VARCHAR(29))
         ,C.ContractCode
         , C.ItemName as BuildingName
        , C.DeptName
         , C.OperatorName
         , PP.PlanPayDate as ExpectDate
         , RB.ReturnDate as ActualPayDate
         , RB.ReturnAmount * -1 as ActualPayAmount
         , RA.AccountBank as ActualPayeeBankName
         , RA.AccountName as ActualPayeeName
         , RA.AccountNumber as ActualPayeeAccountNumber
         , RB.ReturnKind as ActualPayMethod
         , PP.FeeType
         , PP.FeeBeginDate as PayPeriodBegin
         , PP.FeeEndDate as PayPeriodEnd
         , V.VendorName
         ,(RB.ReturnAmount - RB.CloseAmount) as UnInvoiceAmount
         , C.PayCompanyId
       , PC.PayCompanyName
     From media.tbb_ReturnBill RB
     join media.tbb_paybill PB on RB.PayBillID = PB.PayBillID
     join media.tbb_PayPlan PP on PB.PlanPayID = PP.PlanPayID
     join media.tbb_Contract C on PP.ContractID = C.ContractID
     left join media.tbb_Vendor V on PP.VendorID = V.VendorID
     LEFT JOIN media.tbi_ReturnAccount RA ON RA.ReturnBillID = RB.ReturnBillID
     LEFT JOIN basic.tbb_PayCompany PC ON PC.PayCompanyID = C.PayCompanyId
     where (C.DealStatus = 3 OR C.DealStatus = 10) -- 执行中或续签
       AND C.IsSignFinished = 1
       AND PP.ValidStatus = 0
       -- TODO 退款的状态
       and (RB.ReturnDate >= isnull(@FilterPayDateMin, RB.ReturnDate) AND RB.ReturnDate <= isnull(@FilterPayDateMax, RB.ReturnDate))
       and PB.ValidStatus = 0
       and (isnull(@FilterPayMethods, '''''''') = '''''''' OR RB.ReturnKind in (select a from [media].[f_split](@FilterPayMethods,'''','''')))

              ''

      set @sql = @sql + @sqlFilter
      set @sql = @sql + '' ) A order by ActualPayDate desc, ContractCode ''

      print @sql
      EXECUTE sp_executesql
      @sql
      , N'' @FilterPlanPayID bigint, @FilterOperatorID bigint, @FilterVendorID bigint, @FilterPayPeriodBeginMin date, @FilterPayPeriodBeginMax date, @FilterPayPeriodEndMin date, @FilterPayPeriodEndMax date,  @FilterContractCode varchar(50), @FilterFeeType
   varchar(20), @FilterBuildingID bigint, @SearchMode varchar(20), @FilterPayDateMin date, @FilterPayDateMax date, @FilterPayMethods varchar(100)''
      , @FilterPlanPayID = @FilterPlanPayID
      , @FilterOperatorID = @FilterOperatorID
      , @FilterVendorID = @FilterVendorID
      , @FilterPayPeriodBeginMin = @FilterPayPeriodBeginMin
      , @FilterPayPeriodBeginMax = @FilterPayPeriodBeginMax
      , @FilterPayPeriodEndMin = @FilterPayPeriodEndMin
      , @FilterPayPeriodEndMax = @FilterPayPeriodEndMax
      , @FilterContractCode = @FilterContractCode
      , @FilterFeeType = @FilterFeeType
      , @FilterBuildingID = @FilterBuildingID
      , @SearchMode = @SearchMode
      , @FilterPayDateMin = @FilterPayDateMin
      , @FilterPayDateMax = @FilterPayDateMax
      , @FilterPayMethods = @FilterPayMethods

     select @TotalCount = COUNT(*) from #T

     SELECT *
     FROM   #t T
     WHERE  T.rn > ( @PageIndex - 1 ) * @PageSize
            AND T.rn <= @PageSize * @PageIndex
     ORDER BY rn

     drop table #dept, #T

      set nocount off

  end
' 
END
GO
