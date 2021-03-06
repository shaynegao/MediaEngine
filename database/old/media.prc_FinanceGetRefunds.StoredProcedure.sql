IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[media].[prc_FinanceGetRefunds]') AND type in (N'P', N'PC'))
DROP PROCEDURE [media].[prc_FinanceGetRefunds]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[media].[prc_FinanceGetRefunds]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'


CREATE PROCEDURE [media].[prc_FinanceGetRefunds]
	@PaymentID   bigint
AS
	
	SELECT  RB.ReturnBillID AS RefundID ,
	        RB.PayBillID ,
	        RB.ReturnKind AS PayMethod ,
	        RB.ReturnAmount AS Amount ,
	        RB.ReturnDate AS RefundDate,
	        RB.ValidStatus AS AuditStatus,
	        RB.CloseAmount ,
	        RB.LastUpdateTime,
			RA.AccountBank AS RefundBankName,
			RA.AccountName AS RefundName,
			RA.AccountNumber AS RefundAccountNumber ,
			RB.ReturnReason AS RefundReason
	FROM media.tbb_ReturnBill RB
	LEFT JOIN media.tbi_ReturnAccount RA ON RB.ReturnBillID = RA.ReturnBillID
	WHERE RB.PayBillID = @PaymentID
	
	


' 
END
GO
