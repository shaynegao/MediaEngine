IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[media].[prc_FinanceGetPagedInvoice]') AND type in (N'P', N'PC'))
DROP PROCEDURE [media].[prc_FinanceGetPagedInvoice]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[media].[prc_FinanceGetPagedInvoice]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'

create procedure [media].[prc_FinanceGetPagedInvoice] @FilterInvoiceCode   varchar(50) = ''%'',
     -- 发票类型
     @FilterInvoiceType   varchar(50),
     -- 合同编号
     @FilterContractCode   varchar(50) = ''%'',
     -- 收款单位
     @FilterInvoicePayeeName   varchar(50) = ''%'',
     -- 项目
     @FilterBuildingID     bigint = null,
     -- 开发人员
     @FilterDeveloperName      varchar(50) = null,
     -- 维护人员
     @FilterOperatorName       varchar(50) = null,
     -- 开票日期
     @FilterReceivedDateMin  date = null,
     @FilterReceivedDateMax  date = null,
     -- 录入日期
     @FilterCreatedDateMin date = null,
     @FilterCreatedDateMax date = null,
     -- 支付主体
     @FilterVendorID         bigint = null,
     @FilterInvoiceStatus    int = null,
   
     @UserID               bigint,
     @SearchMode           varchar(20),
     @PageSize             int,
     @PageIndex            int,
     @TotalCount           int output as
begin
    set nocount on
    
    create table #tuser
    (
        CreatorID bigint
    )
    

    if LOWER(@SearchMode) = ''my''
		BEGIN
			INSERT INTO #tuser ( CreatorID ) VALUES  ( @UserID )
		END 
    else    
    IF LOWER(@SearchMode) = ''mydept''
		BEGIN
			INSERT INTO #tuser (CreatorID)
			SELECT DISTINCT U1.UserID FROM basic.tbb_Department D 
				JOIN basic.tbb_User U ON D.DeptID = U.DeptID
				JOIN basic.tbb_Department D1 ON D1.DeptNo LIKE D.DeptNo + ''%''
				JOIN basic.tbb_User U1 ON D1.DeptID = U1.DeptID
			WHERE U.UserID = @UserID
		END
    else
    IF LOWER(@SearchMode) = ''finance''
   		BEGIN
			INSERT INTO #tuser (CreatorID)
			SELECT DISTINCT U.UserID FROM  basic.VW_UserDept UD
			JOIN basic.tbb_User U ON UD.DeptID = U.DeptID
			WHERE UD.UserID = @UserID
		END 

--SELECT * FROM  #tuser


   create table #T
   (
     rn  int identity(1,1),
     VerifyID 	 bigint
   )       

   
  INSERT INTO #t 
    (  VerifyID )

	SELECT DISTINCT 
      I.VerifyID
  FROM media.tbb_Invoice I	
	left join media.tbi_InvoiceTaxes IT on I.InvoiceID = IT.InvoiceID
	where I.InvoiceType = @FilterInvoiceType
	  AND (@FilterInvoiceCode = ''%'' or I.InvoiceCode like @FilterInvoiceCode)
 	  and (I.ReceiveDate >= isnull(@FilterReceivedDateMin, I.ReceiveDate) AND I.ReceiveDate <= isnull(@FilterReceivedDateMax, I.ReceiveDate))
      and (DATEDIFF(d, isnull(@FilterCreatedDateMin, I.CreateTime), I.CreateTime) >= 0 AND DATEDIFF(d, I.CreateTime ,isnull(@FilterCreatedDateMax, I.CreateTime)) >= 0)
      and isnull(@FilterInvoiceStatus, I.invoicestatus) = I.invoicestatus
      AND (LOWER(@SearchMode) = ''my'' OR I.invoicestatus IN (5, 10))
      AND (LOWER(@SearchMode) = ''all'' OR I.CreatorID IN (SELECT CreatorID FROM  #tuser)) 

    select @TotalCount = COUNT(*) from #T

    SELECT I.InvoiceID
      ,I.VerifyID
      ,I.InvoiceType
      ,I.InvoiceCode
      ,I.InvoiceAmount
      ,I.VendorName AS InvoicePayeeName
      ,I.ReceiveDate
      ,I.InvoiceStatus AS InvoiceStatusCode
      ,IT.TaxAmount
      ,IT.TaxRate
      ,I.InvoiceID AS InvoiceSerial
    FROM   #t V
    JOIN media.tbb_Invoice I ON I.VerifyID = V.VerifyID
	left join media.tbi_InvoiceTaxes IT on I.InvoiceID = IT.InvoiceID
    WHERE  V.rn > ( @PageIndex - 1 ) * @PageSize 
           AND V.rn <= @PageSize * @PageIndex 
	ORDER BY I.VerifyID DESC, I.InvoiceID           
           
           
    drop table #T   
    drop table #tuser
    
    set nocount off     
        
end
' 
END
GO
