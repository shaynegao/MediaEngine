IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[media].[prc_FinanceInvoiceBundleToVerify]') AND type in (N'P', N'PC'))
DROP PROCEDURE [media].[prc_FinanceInvoiceBundleToVerify]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[media].[prc_FinanceInvoiceBundleToVerify]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'

CREATE PROCEDURE [media].[prc_FinanceInvoiceBundleToVerify]
	@VerifyID	BIGINT
AS
	SET NOCOUNT ON 
	
	declare @Result varchar(120)

	IF EXISTS (SELECT * FROM media.tbb_Invoice WHERE VerifyID = @VerifyID AND InvoiceStatus <> 0 )
	BEGIN
		SELECT @Result = ''当前状态不允许报批''
	END
	ELSE
	BEGIN
		UPDATE media.tbb_Invoice
		SET InvoiceStatus = 5
		WHERE VerifyID = @VerifyID
		
		SELECT @Result = ''OK''
	END
	
	select @Result as ''Result''
	

' 
END
GO
