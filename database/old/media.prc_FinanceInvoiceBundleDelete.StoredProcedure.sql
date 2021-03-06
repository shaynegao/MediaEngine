IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[media].[prc_FinanceInvoiceBundleDelete]') AND type in (N'P', N'PC'))
DROP PROCEDURE [media].[prc_FinanceInvoiceBundleDelete]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[media].[prc_FinanceInvoiceBundleDelete]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'

CREATE PROCEDURE [media].[prc_FinanceInvoiceBundleDelete]
	@VerifyID	BIGINT
AS
	SET NOCOUNT ON 
	
	declare @Result varchar(120)

	IF EXISTS (SELECT * FROM media.tbb_Invoice WHERE VerifyID = @VerifyID AND InvoiceStatus <> 0 )
	BEGIN
		SELECT @Result = ''当前状态不允许删除''
	END
	ELSE
	BEGIN
		DELETE IT
		FROM media.tbb_Invoice I
		JOIN media.tbi_InvoiceTaxes IT ON I.InvoiceID = IT.InvoiceID 
		WHERE I.VerifyID = @VerifyID
		
		DELETE media.tbb_Invoice WHERE VerifyID = @VerifyID

		-- 删除关联主表
		DELETE media.tbb_VerifyInvoice WHERE VerifyID = @VerifyID
		-- 删除关联关系（付款和退款）
		DELETE media.tbb_Bill_Invoice WHERE VerifyID = @VerifyID	
		
		SELECT @Result = ''OK''
	END
	
	select @Result as ''Result''
	

' 
END
GO
