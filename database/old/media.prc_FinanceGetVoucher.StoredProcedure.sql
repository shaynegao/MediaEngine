IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[media].[prc_FinanceGetVoucher]') AND type in (N'P', N'PC'))
DROP PROCEDURE [media].[prc_FinanceGetVoucher]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[media].[prc_FinanceGetVoucher]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'


CREATE procedure [media].[prc_FinanceGetVoucher] (
 	@iDo		INT,   -- 1.计划付费-租金 2.摊销-租金 3.付款 4.付款退回
 	
 	@FilterContractCodeLike  tinyint = 1,    -- 1: like 0: not like
 	@FilterContractCode varchar(30) = '''',
 	@FilterCity 		int = null,
 	@FilterMonth 		VARCHAR(6) ,   			-- yyyyMM
 	@FilterMonthLike 	tinyint = 0,  				-- 0: == 1: <=
 	
 	@FilterPayCompany 	int = null,
 	@FilterSignCompany 	int = null,
 	@FilterCheckAccount int = null,
 	@FilterContractType     varchar(500) = '''',			-- comma separate
 	@FilterDisplayType		varchar(500) = '''',			-- comma separate
 	@FilterFeeType  	varchar(500) = '''',			-- comma separate
 	@FilterPayMethod  	varchar(500) = '''',			-- comma separate
 
     @PageSize             int,
     @PageIndex            int,
     @TotalCount           int OUTPUT,
     @TotalAmount		  DECIMAL(20, 6) OUTPUT
 ) as
BEGIN

	SET NOCOUNT ON 
	
	DECLARE @contracttypes TABLE (a VARCHAR(100))
	DECLARE @displaytypes TABLE (a VARCHAR(100))
	DECLARE @feetypes TABLE (a VARCHAR(100))
	DECLARE @paymethods TABLE (a VARCHAR(100))

	--IF @FilterContractType <> ''''
	--BEGIN
	--	INSERT INTO @contracttypes( a )
	--	SELECT a from media.f_split(@FilterContractType, '','')
	--END
	--IF @FilterDisplayType <> ''''
	--BEGIN
	--	INSERT INTO @displaytypes( a )
	--	SELECT a from media.f_split(@FilterDisplayType, '','')
	--END
	--IF @FilterFeeType IS NOT NULL AND @FilterFeeType <> ''''
	--BEGIN
	--	INSERT INTO @feetypes ( a )
	--	SELECT a from media.f_split(@FilterFeeType, '','')
	--END

	--IF @FilterPayMethod IS NOT NULL AND @FilterPayMethod <> ''''
	--BEGIN
	--	INSERT INTO @paymethods ( a )
	--	SELECT a from media.f_split(@FilterPayMethod, '','')
	--END


	--IF @iDo = 1
	--BEGIN
	
	--	CREATE TABLE #t1
	--	(
	--		rn int IDENTITY(1,1) PRIMARY KEY,
	--		ContractCode varchar(100),
	--		MainContractCode varchar(100),
	--		DeveloperID  varchar(100),
	--		DeveloperName varchar(100),
	--		OperatorID varchar(100),
	--		OperatorName varchar(100),
	--		DeptName varchar(100),
	--		BuildingChsName  varchar(100),
	--		VendorID  bigint,
	--		VendorName varchar(100),
	--		Amount decimal(20, 6),
	--		FeeType varchar(100), 
	--		BuildingID	bigint,
	--		CityName  varchar(100),
	--		PayCompanyID INT,
	--		PayCompanyName varchar(100),
	--		ContractTypeCode  varchar(100),
	--		ContractTypeName   varchar(100),
	--		PayCompanyShortName varchar(100),
	--		SignCompanyName  varchar(100),
	--		CheckAccountName  varchar(100),
	--	    --- 分割线 ---	
	--		ExpectDate datetime, -- 计划支付时间
	--		ChargePayDate  DATETIME, -- 应付记账时间
	--		PayFrequencyText varchar(100),
	--		PayMethodText varchar(100),
	--		PayPeriodBegin datetime,
	--		PayPeriodEnd datetime	 	
	--	)
		
	--	INSERT INTO #t1	
	--	        ( ContractCode ,
	--	          MainContractCode ,
	--	          DeveloperID ,
	--	          DeveloperName ,
	--	          OperatorID ,
	--	          OperatorName ,
	--	          DeptName ,
	--	          BuildingChsName ,
	--	          VendorID ,
	--	          VendorName ,
	--	          Amount ,
	--	          FeeType ,
	--	          BuildingID ,
	--	          CityName ,
	--	          PayCompanyID ,
	--	          PayCompanyName ,
	--	          ContractTypeCode ,
	--	          ContractTypeName ,
	--	          PayCompanyShortName ,
	--	          SignCompanyName ,
	--	          CheckAccountName ,
	--	          ExpectDate ,
	--	          ChargePayDate ,
	--	          PayFrequencyText ,
	--	          PayMethodText ,
	--	          PayPeriodBegin ,
	--	          PayPeriodEnd
	--	        )
		
	--	select 
	--	 -- 合同号
	--	  C.ContractCode 
	--	 -- 主合同号
	--	 , C.MainContractCode 
	--	 -- 开发人员
 --       , U1.UserCode
 --       , U1.UserName 
 --       , U2.UserCode 
 --       , U2.UserName 
	--	, D.DeptName
	--	, C.ItemName
	--	, V.VendorID
	--	, V.VendorName
	--	, PPH.PayAmount
	--	, ''租金''
	--    , C.ItemID
	--	, BA.AreaName
	--	, C.PayCompanyID
	--	, C.PayCompanyName
	--	, C.ContractType
	--	, PR1.ResourceName
	--	, P1.PayCompanyCode
	--	, C.SignCompanyName
	--	, C.CheckAccount
	--	, PPH.PlanPayDate
	--	, PPH.ChargePayDate
	--	, PR2.ResourceName
	--	, PR3.ResourceName
	--	, PPH.FeeBeginDate
	--	, PPH.FeeEndDate
		   
	--	 from media.tbb_Contract C
	-- 		join media.tbb_PayPlan_His PPH on C.ContractID = PPH.ContractID
	-- 		JOIN media.tbb_Building B ON C.ItemID = B.BuildingID
	-- 		LEFT JOIN basic.tbb_User U1 ON U1.UserID = C.DeveloperID
	--		LEFT JOIN basic.tbb_User U2 ON U2.UserID = C.OperatorID
	--		LEFT JOIN basic.tbd_Area BA ON BA.AreaID = B.CityID
	-- 		LEFT JOIN basic.tbb_Department D ON C.DeptID = D.DeptID
	-- 		LEFT JOIN media.tbb_Vendor V ON PPH.VendorID = V.VendorID
	-- 	--	LEFT JOIN media.tbr_Contract_Vendor CV ON CV.ContractID = C.ContractID
	-- 		LEFT JOIN basic.tbb_PayCompany P1 ON p1.PayCompanyID = C.PayCompanyID
	--		LEFT JOIN basic.tbd_PubResource PR1 ON PR1.ResourceTypeCode = ''EA112'' AND PR1.ResourceCode = C.ContractType
	--	    LEFT JOIN basic.tbd_PubResource PR2 ON PR2.ResourceTypeCode = ''BM004'' AND PR2.ResourceCode = PPH.PayKind
	--	    LEFT JOIN basic.tbd_PubResource PR3 ON PR3.ResourceTypeCode = ''EA035'' AND PR3.ResourceCode = PPH.PayWay
	   
	--	 where PPH.FeeType = ''EA040001''
	--		AND (@FilterContractCode = ''''  
	--			OR  ( @FilterContractCodeLike = 1 AND C.ContractCode LIKE ''%'' + @FilterContractCode + ''%'' )  
	--			OR  ( @FilterContractCodeLike = 0 AND C.ContractCode NOT LIKE ''%'' + @FilterContractCode + ''%'' ) )
		 
	-- 		-- 所属城市
	-- 		AND ISNULL(@FilterCity, B.CityID ) = B.CityID
	-- 		and (@FilterPayCompany is null OR C.PayCompanyID = @FilterPayCompany)
	-- 		and (@FilterSignCompany is null OR C.SignCompanyID = @FilterSignCompany)
	-- 		and (@FilterCheckAccount is null OR C.CheckAccount = @FilterCheckAccount)
	-- 		-- 查询月份
	-- 		and ((@FilterMonthLike = 0 and convert(varchar(6), PPH.ChargePayDate, 112) = @FilterMonth)
	-- 			or (@FilterMonthLike = 1 and convert(varchar(6), PPH.ChargePayDate, 112) <= @FilterMonth))
			
	--		AND  (@FilterContractType = '''' OR C.ContractType IN (SELECT a FROM @contracttypes))
	--		AND  (@FilterDisplayType = '''' OR C.DisplayType IN (SELECT a FROM @displaytypes))
			
	--		SELECT @TotalCount = COUNT(*), @TotalAmount = SUM(Amount) FROM #t1
		
	--		SELECT *             
	--		FROM   #t1 T
	--		WHERE  T.rn > ( @PageIndex - 1 ) * @PageSize
	--			   AND T.rn <= @PageSize * @PageIndex
				   
	--		DROP TABLE #t1
			   
	--END
	--ELSE
	--IF @ido = 2 
	--BEGIN
 --       -- FItem 资源类型 EA112XXX old:contract_shuxing
	--	CREATE TABLE #t2
	--	(
	--		rn int IDENTITY(1,1) PRIMARY KEY,
	--		ContractCode varchar(100),
	--		MainContractCode varchar(100),
	--		DeveloperID  varchar(100),
	--		DeveloperName varchar(100),
	--		OperatorID varchar(100),
	--		OperatorName varchar(100),
	--		DeptName varchar(100),
	--		BuildingChsName  varchar(100),
	--		VendorID  bigint,
	--		VendorName varchar(100),
	--		AmortizeAmount decimal(20, 2),
	--		FeeType varchar(100), 
	--		BuildingID	bigint,
	--		CityName  varchar(100),
	--		PayCompanyID INT,
	--		PayCompanyName varchar(100),
	--		ContractTypeCode  varchar(100),
	--		ContractTypeName   varchar(100),
	--		PayCompanyShortName varchar(100),
	--		SignCompanyName  varchar(100),
	--		CheckAccountName  varchar(100) 	
	--	)
		
	--	INSERT INTO #t2
	--	        ( ContractCode ,
	--	          MainContractCode ,
	--	          DeveloperID ,
	--	          DeveloperName ,
	--	          OperatorID ,
	--	          OperatorName ,
	--	          DeptName ,
	--	          BuildingChsName ,
	--	          VendorID ,
	--	          VendorName ,
	--	          AmortizeAmount ,
	--	          FeeType ,
	--	          BuildingID ,
	--	          CityName ,
	--	          PayCompanyID,
	--	          PayCompanyName ,
	--	          ContractTypeCode,
	--	          ContractTypeName ,
	--	          PayCompanyShortName ,
	--	          SignCompanyName ,
	--	          CheckAccountName
	--	        )
		 
 --       SELECT
 --             C.ContractCode
	--		, C.MainContractCode 
 --           , U1.UserCode
 --           , U1.UserName 
 --           , U2.UserCode 
 --           , U2.UserName 
 --           , D.DeptName
 --           , C.ItemName
 --       	, CV.VendorID
	--		, CV.VendorName
	--		, A.AmortizeAmount
	--		, ''租金''
	--		, C.ItemID
	--		, BA.AreaName
	--		, C.PayCompanyID
	--		, C.PayCompanyName
	--		, C.ContractType
	--		, PR1.ResourceName
	--		, P1.PayCompanyCode
	--		, C.SignCompanyName
	--		, C.CheckAccount
 --        FROM
 --       (
	--		SELECT ContractID, AmortizeYear, AmortizeMonth, SUM(AmortizeAmount) AS AmortizeAmount FROM media.tbs_CostAmortize_His CAH
	--		GROUP BY ContractID, AmortizeYear, AmortizeMonth
 --       ) A 
 --       JOIN media.tbb_Contract C ON A.ContractID = C.ContractID
 --       JOIN media.tbb_Building B ON C.ItemID = B.BuildingID
	--	LEFT JOIN media.tbr_Contract_Vendor CV ON CV.ContractID = C.ContractID
	--	LEFT JOIN basic.tbb_Department D ON C.DeptID = D.DeptID
	--	LEFT JOIN basic.tbb_User U1 ON U1.UserID = C.DeveloperID
	--	LEFT JOIN basic.tbb_User U2 ON U2.UserID = C.OperatorID
	--	LEFT JOIN basic.tbd_Area BA ON BA.AreaID = B.CityID
	--	LEFT JOIN basic.tbb_PayCompany P1 ON p1.PayCompanyID = C.PayCompanyID
	--	LEFT JOIN basic.tbd_PubResource PR1 ON PR1.ResourceTypeCode = ''EA112'' AND PR1.ResourceCode = C.ContractType
	-- WHERE    
	--       (@FilterContractCode = ''''  
	--			OR  ( @FilterContractCodeLike = 1 AND C.ContractCode LIKE ''%'' + @FilterContractCode + ''%'' )  
	--			OR  ( @FilterContractCodeLike = 0 AND C.ContractCode NOT LIKE ''%'' + @FilterContractCode + ''%'' ) )
		 
	-- 		-- 所属城市
	-- 		AND ISNULL(@FilterCity, B.CityID ) = B.CityID
	-- 		and (@FilterPayCompany is null OR C.PayCompanyID = @FilterPayCompany)
	-- 		and (@FilterSignCompany is null OR C.SignCompanyID = @FilterSignCompany)
	-- 		and (@FilterCheckAccount is null OR C.CheckAccount = @FilterCheckAccount)
	-- 		-- 查询月份
	-- 		and ((@FilterMonthLike = 0 and (A.AmortizeYear * 100 + A.AmortizeMonth) = CAST(@FilterMonth AS INT))
	-- 			or (@FilterMonthLike = 1 and (A.AmortizeYear * 100 + A.AmortizeMonth) <= CAST(@FilterMonth AS INT)))
			
	--		AND  (@FilterContractType = '''' OR C.ContractType IN (SELECT a FROM @contracttypes))
	--		AND  (@FilterDisplayType = '''' OR C.DisplayType IN (SELECT a FROM @displaytypes))
			
	--	SELECT @TotalCount = COUNT(*), @TotalAmount = SUM(AmortizeAmount) FROM #t2
		
	--	SELECT *             
	--	FROM   #t2 T
	--	WHERE  T.rn > ( @PageIndex - 1 ) * @PageSize
	--		   AND T.rn <= @PageSize * @PageIndex
			
		
	--	DROP TABLE #t2
  
	--END
	--ELSE
	--IF @ido = 3
	--BEGIN
		
	--	CREATE TABLE #t3
	--	(
	--		rn int IDENTITY(1,1) PRIMARY KEY,
	--		ContractCode varchar(100),
	--		MainContractCode varchar(100),
	--		DeveloperID  varchar(100),
	--		DeveloperName varchar(100),
	--		OperatorID varchar(100),
	--		OperatorName varchar(100),
	--		DeptName varchar(100),
	--		BuildingChsName  varchar(100),
	--		VendorID  bigint,
	--		VendorName varchar(100),
	--		Amount decimal(10, 2),
	--		FeeType varchar(100), 
	--		BuildingID	bigint,
	--		CityName  varchar(100),
	--		PayCompanyID INT,
	--		PayCompanyName varchar(100),
	--		ContractTypeCode  varchar(100),
	--		ContractTypeName   varchar(100),
	--		PayCompanyShortName varchar(100),
	--		SignCompanyName  varchar(100),
	--		CheckAccountName  varchar(100),
	--	    --- 分割线 ---	
	--		ExpectDate datetime, -- 计划支付时间
	--		RealPayDate DATETIME,
	--		PayFrequencyText varchar(100),
	--		PayMethodText varchar(100),
	--		PayPeriodBegin datetime,
	--		PayPeriodEnd datetime	 	
	--	)
		
	--	INSERT INTO #t3	
	--	        ( ContractCode ,
	--	          MainContractCode ,
	--	          DeveloperID ,
	--	          DeveloperName ,
	--	          OperatorID ,
	--	          OperatorName ,
	--	          DeptName ,
	--	          BuildingChsName ,
	--	          VendorID ,
	--	          VendorName ,
	--	          Amount ,
	--	          FeeType ,
	--	          BuildingID ,
	--	          CityName ,
	--	          PayCompanyID ,
	--	          PayCompanyName ,
	--	          ContractTypeCode ,
	--	          ContractTypeName ,
	--	          PayCompanyShortName ,
	--	          SignCompanyName ,
	--	          CheckAccountName ,
	--	          ExpectDate ,
	--	          RealPayDate,
	--	          PayFrequencyText ,
	--	          PayMethodText ,
	--	          PayPeriodBegin ,
	--	          PayPeriodEnd
	--	        )
		
	--	select 
	--	 -- 合同号
	--	  C.ContractCode 
	--	 -- 主合同号
	--	 , C.MainContractCode 
	--	 -- 开发人员
 --       , U1.UserCode
 --       , U1.UserName 
 --       , U2.UserCode 
 --       , U2.UserName 
	--	, D.DeptName
	--	, C.ItemName
	--	, V.VendorID
	--	, V.VendorName
	--	, PBH.PayAmount
	--	, PR4.ResourceName
	--    , C.ItemID
	--	, BA.AreaName
	--	, C.PayCompanyID
	--	, C.PayCompanyName
	--	, C.ContractType
	--	, PR1.ResourceName
	--	, P1.PayCompanyCode
	--	, C.SignCompanyName
	--	, C.CheckAccount
	--	, PP.PlanPayDate
	--	, PBH.PayDate
	--	, PR2.ResourceName -- 实际
	--	, PR3.ResourceName
	--	, PP.FeeBeginDate
	--	, PP.FeeEndDate
		   
	--	 from media.tbb_Contract C
	--		JOIN media.tbb_PayPlan PP ON C.ContractID = PP.ContractID
	-- 		join media.tbb_PayBill_His PBH on PP.PlanPayID = PBH.PlanPayID
	-- 		JOIN media.tbb_Building B ON C.ItemID = B.BuildingID
	-- 		LEFT JOIN basic.tbb_User U1 ON U1.UserID = C.DeveloperID
	--		LEFT JOIN basic.tbb_User U2 ON U2.UserID = C.OperatorID
	--		LEFT JOIN basic.tbd_Area BA ON BA.AreaID = B.CityID
	-- 		LEFT JOIN basic.tbb_Department D ON C.DeptID = D.DeptID
	-- 		LEFT JOIN media.tbb_Vendor V ON PP.VendorID = V.VendorID
	-- 		LEFT JOIN basic.tbb_PayCompany P1 ON p1.PayCompanyID = C.PayCompanyID
	--		LEFT JOIN basic.tbd_PubResource PR1 ON PR1.ResourceTypeCode = ''EA112'' AND PR1.ResourceCode = C.ContractType
	--	    LEFT JOIN basic.tbd_PubResource PR2 ON PR2.ResourceTypeCode = ''BM004'' AND PR2.ResourceCode = PBH.PayKind
	--	    LEFT JOIN basic.tbd_PubResource PR3 ON PR3.ResourceTypeCode = ''EA035'' AND PR3.ResourceCode = PP.PayWay
	--	    LEFT JOIN basic.tbd_PubResource PR4 ON PR4.ResourceTypeCode = ''EA040'' AND PR4.ResourceCode = PP.FeeType
	   
	--	 where  (@FilterContractCode = ''''  
	--			OR  ( @FilterContractCodeLike = 1 AND C.ContractCode LIKE ''%'' + @FilterContractCode + ''%'' )  
	--			OR  ( @FilterContractCodeLike = 0 AND C.ContractCode NOT LIKE ''%'' + @FilterContractCode + ''%'' ) )
		 
	-- 		-- 所属城市
	-- 		AND ISNULL(@FilterCity, B.CityID ) = B.CityID
	-- 		and (@FilterPayCompany is null OR C.PayCompanyID = @FilterPayCompany)
	-- 		and (@FilterSignCompany is null OR C.SignCompanyID = @FilterSignCompany)
	-- 		and (@FilterCheckAccount is null OR C.CheckAccount = @FilterCheckAccount)
	-- 		-- 查询月份
	-- 		and ((@FilterMonthLike = 0 and convert(varchar(6), PBH.PayDate, 112) = @FilterMonth)
	-- 			or (@FilterMonthLike = 1 and convert(varchar(6),  PBH.PayDate, 112) <= @FilterMonth))
			
	--		AND  (@FilterContractType = '''' OR C.ContractType IN (SELECT a FROM @contracttypes))
	--		AND  (@FilterDisplayType = '''' OR C.DisplayType IN (SELECT a FROM @displaytypes))
	--		AND  (ISNULL(@FilterFeeType, '''') = '''' OR PP.FeeType IN (SELECT a FROM @feetypes))
	--		AND  (ISNULL(@FilterPayMethod, '''') = '''' OR PP.PayKind IN (SELECT a FROM @paymethods))
			
	--		SELECT @TotalCount = COUNT(*), @TotalAmount = SUM(Amount) FROM #t3

	--		SELECT *             
	--		FROM   #t3 T
	--		WHERE  T.rn > ( @PageIndex - 1 ) * @PageSize
	--			   AND T.rn <= @PageSize * @PageIndex
		
	--		DROP TABLE #t3
	--END 
	--IF @ido = 4
	--BEGIN
		
	--	CREATE TABLE #t4
	--	(
	--		rn int IDENTITY(1,1) PRIMARY KEY,
	--		ContractCode varchar(100),
	--		MainContractCode varchar(100),
	--		DeveloperID  varchar(100),
	--		DeveloperName varchar(100),
	--		OperatorID varchar(100),
	--		OperatorName varchar(100),
	--		DeptName varchar(100),
	--		BuildingChsName  varchar(100),
	--		VendorID  bigint,
	--		VendorName varchar(100),
	--		Amount decimal(10, 2),
	--		FeeType varchar(100), 
	--		BuildingID	bigint,
	--		CityName  varchar(100),
	--		PayCompanyID INT,
	--		PayCompanyName varchar(100),
	--		ContractTypeCode  varchar(100),
	--		ContractTypeName   varchar(100),
	--		PayCompanyShortName varchar(100),
	--		SignCompanyName  varchar(100),
	--		CheckAccountName  varchar(100),
	--	    --- 分割线 ---	
	--		ExpectDate datetime, -- 计划支付时间
	--		ChargePayDate  DATETIME, -- 应付记账时间
	--		PayFrequencyText varchar(100),
	--		PayMethodText varchar(100),
	--		PayPeriodBegin datetime,
	--		PayPeriodEnd DATETIME,
	--		ReturnDate DATE	 	
	--	)
		
	--	INSERT INTO #t4	
	--	        ( ContractCode ,
	--	          MainContractCode ,
	--	          DeveloperID ,
	--	          DeveloperName ,
	--	          OperatorID ,
	--	          OperatorName ,
	--	          DeptName ,
	--	          BuildingChsName ,
	--	          VendorID ,
	--	          VendorName ,
	--	          Amount ,
	--	          FeeType ,
	--	          BuildingID ,
	--	          CityName ,
	--	          PayCompanyID ,
	--	          PayCompanyName ,
	--	          ContractTypeCode ,
	--	          ContractTypeName ,
	--	          PayCompanyShortName ,
	--	          SignCompanyName ,
	--	          CheckAccountName ,
	--	          ExpectDate ,
	--	          PayFrequencyText ,
	--	          PayMethodText ,
	--	          PayPeriodBegin ,
	--	          PayPeriodEnd ,
	--	          ReturnDate
	--	        )
		
	--	select 
	--	 -- 合同号
	--	  C.ContractCode 
	--	 -- 主合同号
	--	 , C.MainContractCode 
	--	 -- 开发人员
 --       , U1.UserCode
 --       , U1.UserName 
 --       , U2.UserCode 
 --       , U2.UserName 
	--	, D.DeptName
	--	, C.ItemName
	--	, V.VendorID
	--	, V.VendorName
	--	, RBH.ReturnAmount
	--	, PR4.ResourceName
	--    , C.ItemID
	--	, BA.AreaName
	--	, C.PayCompanyID
	--	, C.PayCompanyName
	--	, C.ContractType
	--	, PR1.ResourceName
	--	, P1.PayCompanyCode
	--	, C.SignCompanyName
	--	, C.CheckAccount
	--	, PP.PlanPayDate
	--	, PR2.ResourceName
	--	, PR3.ResourceName
	--	, PP.FeeBeginDate
	--	, PP.FeeEndDate
	--	, RBH.ReturnDate
		 
	--	 from media.tbb_Contract C
	--		JOIN media.tbb_PayPlan PP ON C.ContractID = PP.ContractID
	--		JOIN media.tbb_PayBill PB ON PP.PlanPayID = PB.PlanPayID
	--		JOIN media.tbb_ReturnBill_His RBH ON PB.PayBillID = RBH.PayBillID
	-- 		JOIN media.tbb_Building B ON C.ItemID = B.BuildingID
	-- 		LEFT JOIN basic.tbb_User U1 ON U1.UserID = C.DeveloperID
	--		LEFT JOIN basic.tbb_User U2 ON U2.UserID = C.OperatorID
	--		LEFT JOIN basic.tbd_Area BA ON BA.AreaID = B.CityID
	-- 		LEFT JOIN basic.tbb_Department D ON C.DeptID = D.DeptID
	-- 		LEFT JOIN media.tbb_Vendor V ON PP.VendorID = V.VendorID
	-- 		LEFT JOIN basic.tbb_PayCompany P1 ON p1.PayCompanyID = C.PayCompanyID
	--		LEFT JOIN basic.tbd_PubResource PR1 ON PR1.ResourceTypeCode = ''EA112'' AND PR1.ResourceCode = C.ContractType
	--	    LEFT JOIN basic.tbd_PubResource PR2 ON PR2.ResourceTypeCode = ''BM004'' AND PR2.ResourceCode = PB.PayKind
	--	    LEFT JOIN basic.tbd_PubResource PR3 ON PR3.ResourceTypeCode = ''EA035'' AND PR3.ResourceCode = PP.PayWay
	--		LEFT JOIN basic.tbd_PubResource PR4 ON PR4.ResourceTypeCode = ''EA040'' AND PR4.ResourceCode = PP.FeeType
	   
	--	 where (@FilterContractCode = ''''  
	--			OR  ( @FilterContractCodeLike = 1 AND C.ContractCode LIKE ''%'' + @FilterContractCode + ''%'' )  
	--			OR  ( @FilterContractCodeLike = 0 AND C.ContractCode NOT LIKE ''%'' + @FilterContractCode + ''%'' ) )
		 
	-- 		-- 所属城市
	-- 		AND ISNULL(@FilterCity, B.CityID ) = B.CityID
	-- 		and (@FilterPayCompany is null OR C.PayCompanyID = @FilterPayCompany)
	-- 		and (@FilterSignCompany is null OR C.SignCompanyID = @FilterSignCompany)
	-- 		and (@FilterCheckAccount is null OR C.CheckAccount = @FilterCheckAccount)
	-- 		-- 查询月份
	-- 		and ((@FilterMonthLike = 0 and convert(varchar(6), RBH.ReturnDate, 112) = @FilterMonth)
	-- 			or (@FilterMonthLike = 1 and convert(varchar(6), RBH.ReturnDate, 112) <= @FilterMonth))
			
	--		AND  (@FilterContractType = '''' OR C.ContractType IN (SELECT a FROM @contracttypes))
	--		AND  (@FilterDisplayType = '''' OR C.DisplayType IN (SELECT a FROM @displaytypes))
	--		AND  (ISNULL(@FilterFeeType, '''') = '''' OR PP.FeeType IN (SELECT a FROM @feetypes))
	--		AND  (ISNULL(@FilterPayMethod, '''') = '''' OR PP.PayKind IN (SELECT a FROM @paymethods))
			
	--		SELECT @TotalCount = COUNT(*), @TotalAmount = SUM(Amount) FROM #t4
		
	--		SELECT *             
	--		FROM   #t4 T
	--		WHERE  T.rn > ( @PageIndex - 1 ) * @PageSize
	--			   AND T.rn <= @PageSize * @PageIndex
		
	--		DROP TABLE #t4
	--END 	

end

' 
END
GO
